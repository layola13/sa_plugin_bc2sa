const std = @import("std");

pub const TranslateError = error{
    OutOfMemory,
    InvalidBitcode,
    InvalidIr,
    LlvmDisFailed,
    LlvmDisNotFound,
    UnsupportedBitcodeInput,
    UnsupportedInstruction,
    UnsupportedPhi,
    StaticMemoryOverflow,
};

const bitcode_magic = [_]u8{ 'B', 'C', 0xc0, 0xde };
const max_bitcode_bytes = 64 * 1024 * 1024;
const max_ir_bytes = 64 * 1024 * 1024;
// NOTE: multi-version candidates, newest first. Must stay a subset of the
// absolute paths whitelisted in `sap.json` process.exec: the plugin sandbox
// denies spawning anything not on that list. LLVM 23 is required to read
// bitcode emitted by rustc 1.99 (LLVM 23.1.1, bitcode summary version 14);
// older llvm-dis releases reject it as an unknown summary version. On the
// Colab box `/usr/bin/llvm-dis-23` is a symlink to the rustup llvm-tools
// component binary (LLVM 23.1.1-rust-1.99.1-stable).
const llvm_dis_candidates = [_][]const u8{ "/usr/bin/llvm-dis-23", "/usr/lib/llvm-23/bin/llvm-dis", "/usr/bin/llvm-dis-22", "/usr/bin/llvm-dis-21", "/usr/bin/llvm-dis-20", "/usr/bin/llvm-dis-19", "/usr/bin/llvm-dis-18", "/usr/bin/llvm-dis-17", "/usr/bin/llvm-dis-16", "/usr/bin/llvm-dis-15", "/usr/bin/llvm-dis-14" };
const clang_candidates = [_][]const u8{ "/usr/bin/clang", "/usr/bin/clang-23", "/usr/lib/llvm-23/bin/clang" };
const llvm_as_candidates = [_][]const u8{ "/usr/bin/llvm-as-23", "/usr/bin/llvm-as-20", "/usr/bin/llvm-as-17", "/usr/bin/llvm-as-16", "/usr/bin/llvm-as-15", "/usr/bin/llvm-as-14" };

/// NOTE(Zig 0.17): ambient filesystem/subprocess access was removed; every
/// fs/process op needs an explicit `Io`. Lazily created once per process.
var threaded_storage: ?std.Io.Threaded = null;
var current_io: ?std.Io = null;

fn io() std.Io {
    if (current_io) |v| return v;
    threaded_storage = std.Io.Threaded.init(std.heap.page_allocator, .{ .argv0 = .empty });
    const v = threaded_storage.?.io();
    current_io = v;
    return v;
}

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t\r\n");
}

fn startsWithWord(text: []const u8, word: []const u8) bool {
    if (!std.mem.startsWith(u8, text, word)) return false;
    if (text.len == word.len) return true;
    const next = text[word.len];
    return std.ascii.isWhitespace(next) or next == '(' or next == '@';
}

fn stripLlvmSigil(text: []const u8) []const u8 {
    const t = trim(text);
    if (t.len == 0) return t;
    if (t[0] == '%' or t[0] == '@') return t[1..];
    return t;
}

fn isIdentChar(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '_';
}

/// NOTE(Zig 0.17): managed lists lost `.writer()`. This unbuffered adapter
/// recovers `listPrint(out, fmt, args)` for text emission.
const ListWriter = struct {
    writer: std.Io.Writer,
    list: *std.array_list.Managed(u8),

    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const self: *ListWriter = @fieldParentPtr("writer", w);
        if (w.end > 0) {
            self.list.appendSlice(w.buffer[0..w.end]) catch return error.WriteFailed;
            w.end = 0;
        }
        for (data[0 .. data.len - 1]) |slice| {
            self.list.appendSlice(slice) catch return error.WriteFailed;
        }
        const last = data[data.len - 1];
        var r: usize = 0;
        while (r < splat) : (r += 1) {
            self.list.appendSlice(last) catch return error.WriteFailed;
        }
        return std.Io.Writer.countSplat(data, splat);
    }

    fn init(list: *std.array_list.Managed(u8)) ListWriter {
        return .{
            .writer = .{ .vtable = &.{ .drain = drain }, .buffer = &.{} },
            .list = list,
        };
    }
};

fn listPrint(list: *std.array_list.Managed(u8), comptime fmt: []const u8, args: anytype) !void {
    var lw = ListWriter.init(list);
    try lw.writer.print(fmt, args);
}

fn sanitizeIdent(allocator: std.mem.Allocator, raw: []const u8, prefix: []const u8) ![]u8 {
    var source = stripLlvmSigil(raw);
    source = trim(source);
    if (source.len >= 2 and source[0] == '"' and source[source.len - 1] == '"') {
        source = source[1 .. source.len - 1];
    }

    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();

    if (source.len == 0 or !(std.ascii.isAlphabetic(source[0]) or source[0] == '_')) {
        try out.appendSlice(prefix);
    }

    for (source) |c| {
        try out.append(if (isIdentChar(c)) c else '_');
    }

    if (out.items.len == 0) try out.appendSlice(prefix);
    return try out.toOwnedSlice();
}

fn labelName(allocator: std.mem.Allocator, raw: []const u8) ![]u8 {
    const base = try sanitizeIdent(allocator, raw, "block_");
    defer allocator.free(base);
    if (std.mem.startsWith(u8, base, "L_")) return try allocator.dupe(u8, base);
    return try std.fmt.allocPrint(allocator, "L_{s}", .{base});
}

fn stripCommentOutsideString(line: []const u8) []const u8 {
    var in_string = false;
    var escaped = false;
    for (line, 0..) |c, idx| {
        if (in_string) {
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                in_string = false;
            }
            continue;
        }
        if (c == '"') {
            in_string = true;
        } else if (c == ';') {
            return line[0..idx];
        }
    }
    return line;
}

fn stripMetadataSuffix(line: []const u8) []const u8 {
    const markers = [_][]const u8{
        ", !dbg ",
        ", !tbaa ",
        ", !range ",
        ", !nonnull ",
        ", !align ",
        ", !noundef ",
    };
    var end = line.len;
    for (markers) |marker| {
        if (std.mem.indexOf(u8, line[0..end], marker)) |idx| end = @min(end, idx);
    }
    return trim(line[0..end]);
}

fn cleanInstructionLine(line: []const u8) []const u8 {
    return stripMetadataSuffix(stripCommentOutsideString(line));
}

fn findMatching(text: []const u8, open_idx: usize, open_ch: u8, close_ch: u8) ?usize {
    var depth: usize = 0;
    var in_string = false;
    var escaped = false;
    var idx = open_idx;
    while (idx < text.len) : (idx += 1) {
        const c = text[idx];
        if (in_string) {
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                in_string = false;
            }
            continue;
        }
        if (c == '"') {
            in_string = true;
            continue;
        }
        if (c == open_ch) {
            depth += 1;
        } else if (c == close_ch) {
            if (depth == 0) return null;
            depth -= 1;
            if (depth == 0) return idx;
        }
    }
    return null;
}

fn splitTopLevelComma(allocator: std.mem.Allocator, text: []const u8) ![]const []const u8 {
    const t = trim(text);
    if (t.len == 0) return try allocator.alloc([]const u8, 0);

    var list = std.array_list.Managed([]const u8).init(allocator);
    errdefer list.deinit();

    var paren_depth: usize = 0;
    var bracket_depth: usize = 0;
    var brace_depth: usize = 0;
    var in_string = false;
    var escaped = false;
    var start: usize = 0;

    for (t, 0..) |c, idx| {
        if (in_string) {
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == '\\') {
                escaped = true;
            } else if (c == '"') {
                in_string = false;
            }
            continue;
        }

        switch (c) {
            '"' => in_string = true,
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth != 0) paren_depth -= 1;
            },
            '[' => bracket_depth += 1,
            ']' => {
                if (bracket_depth != 0) bracket_depth -= 1;
            },
            '{' => brace_depth += 1,
            '}' => {
                if (brace_depth != 0) brace_depth -= 1;
            },
            ',' => {
                if (paren_depth == 0 and bracket_depth == 0 and brace_depth == 0) {
                    const part = trim(t[start..idx]);
                    if (part.len == 0) return error.InvalidIr;
                    try list.append(part);
                    start = idx + 1;
                }
            },
            else => {},
        }
    }

    const tail = trim(t[start..]);
    if (tail.len == 0) return error.InvalidIr;
    try list.append(tail);
    return try list.toOwnedSlice();
}

fn typeTokenToSa(token: []const u8) ?[]const u8 {
    const t = trim(token);
    if (t.len == 0) return null;
    if (std.mem.eql(u8, t, "void")) return "void";
    if (std.mem.eql(u8, t, "i1")) return "i1";
    if (std.mem.eql(u8, t, "i8")) return "i8";
    if (std.mem.eql(u8, t, "i16")) return "i16";
    if (std.mem.eql(u8, t, "i32")) return "i32";
    if (std.mem.eql(u8, t, "i64")) return "i64";
    if (std.mem.eql(u8, t, "float")) return "f32";
    if (std.mem.eql(u8, t, "double")) return "f64";
    if (std.mem.eql(u8, t, "ptr")) return "ptr";
    if (std.mem.endsWith(u8, t, "*")) return "ptr";
    if (std.mem.startsWith(u8, t, "%") and std.mem.endsWith(u8, t, "*")) return "ptr";
    return null;
}

fn typeBytes(type_text: []const u8) ?u64 {
    const t = trim(type_text);
    if (std.mem.eql(u8, t, "i1") or std.mem.eql(u8, t, "i8")) return 1;
    if (std.mem.eql(u8, t, "i16")) return 2;
    if (std.mem.eql(u8, t, "i32") or std.mem.eql(u8, t, "float")) return 4;
    if (std.mem.eql(u8, t, "i64") or std.mem.eql(u8, t, "double") or std.mem.eql(u8, t, "ptr") or std.mem.endsWith(u8, t, "*")) return 8;

    if (t.len >= 5 and t[0] == '[' and t[t.len - 1] == ']') {
        const body = trim(t[1 .. t.len - 1]);
        const x_idx = std.mem.indexOf(u8, body, " x ") orelse return null;
        const count = std.fmt.parseInt(u64, trim(body[0..x_idx]), 10) catch return null;
        const elem = typeBytes(body[x_idx + 3 ..]) orelse return null;
        return std.math.mul(u64, count, elem) catch null;
    }

    return null;
}

fn arrayBoundFromType(type_text: []const u8) ?u64 {
    const t = trim(type_text);
    if (t.len < 5 or t[0] != '[' or t[t.len - 1] != ']') return null;
    const body = trim(t[1 .. t.len - 1]);
    const x_idx = std.mem.indexOf(u8, body, " x ") orelse return null;
    return std.fmt.parseInt(u64, trim(body[0..x_idx]), 10) catch null;
}

fn firstTypeToken(fragment: []const u8) ?[]const u8 {
    var parts = std.mem.tokenizeAny(u8, fragment, " \t\r\n");
    while (parts.next()) |part| {
        if (typeTokenToSa(part) != null) return part;
        if (std.mem.startsWith(u8, part, "[") or std.mem.startsWith(u8, part, "{")) return null;
    }
    return null;
}

fn returnTypeFromPrefix(prefix: []const u8) ![]const u8 {
    var last: ?[]const u8 = null;
    var parts = std.mem.tokenizeAny(u8, prefix, " \t\r\n");
    while (parts.next()) |part| {
        if (typeTokenToSa(part) != null) last = part;
    }
    const token = last orelse return error.UnsupportedInstruction;
    return typeTokenToSa(token).?;
}

fn llvmTypedValueToValue(text: []const u8) []const u8 {
    const t = trim(text);
    if (t.len == 0) return t;
    if (std.mem.startsWith(u8, t, "getelementptr")) return t;

    var parts = std.mem.tokenizeAny(u8, t, " \t\r\n");
    var last: []const u8 = t;
    while (parts.next()) |part| {
        last = part;
    }

    if (std.mem.startsWith(u8, last, "%") or std.mem.startsWith(u8, last, "@")) return last;
    if (std.mem.eql(u8, last, "null") or std.mem.eql(u8, last, "true") or std.mem.eql(u8, last, "false")) return last;
    if (std.fmt.parseInt(i64, last, 10)) |_| return last else |_| {}
    return t;
}

fn saValue(allocator: std.mem.Allocator, raw: []const u8) ![]u8 {
    var value = trim(raw);
    value = trim(std.mem.trimEnd(u8, value, ","));
    value = llvmTypedValueToValue(value);

    if (value.len == 0) return error.InvalidIr;
    if (std.mem.startsWith(u8, value, "%")) return sanitizeIdent(allocator, value, "r");
    if (std.mem.startsWith(u8, value, "@")) {
        const name = try sanitizeIdent(allocator, value, "g_");
        defer allocator.free(name);
        return try std.fmt.allocPrint(allocator, "&{s}", .{name});
    }
    if (std.mem.eql(u8, value, "null") or std.mem.eql(u8, value, "zeroinitializer")) return try allocator.dupe(u8, "0");
    if (std.mem.eql(u8, value, "true")) return try allocator.dupe(u8, "1");
    if (std.mem.eql(u8, value, "false")) return try allocator.dupe(u8, "0");
    if (std.fmt.parseInt(i64, value, 10)) |_| return try allocator.dupe(u8, value) else |_| {}
    if (std.fmt.parseFloat(f64, value)) |number| return try std.fmt.allocPrint(allocator, "{d}", .{number}) else |_| {}
    if (std.mem.startsWith(u8, value, "0x")) {
        if (std.fmt.parseInt(u64, value[2..], 16)) |bits| {
            const number: f64 = @bitCast(bits);
            return try std.fmt.allocPrint(allocator, "{d}", .{number});
        } else |_| {}
    }

    if (std.mem.startsWith(u8, value, "getelementptr")) {
        return try saGetElementPtrConstant(allocator, value);
    }

    return error.UnsupportedInstruction;
}

fn saGetElementPtrConstant(allocator: std.mem.Allocator, expr: []const u8) ![]u8 {
    const open = std.mem.indexOfScalar(u8, expr, '(') orelse return error.UnsupportedInstruction;
    const close = findMatching(expr, open, '(', ')') orelse return error.UnsupportedInstruction;
    const args = try splitTopLevelComma(allocator, expr[open + 1 .. close]);
    defer allocator.free(args);
    if (args.len < 2) return error.UnsupportedInstruction;

    const base = llvmTypedValueToValue(args[1]);
    if (!std.mem.startsWith(u8, base, "@")) return error.UnsupportedInstruction;
    for (args[2..]) |arg| {
        const value = llvmTypedValueToValue(arg);
        if (!std.mem.eql(u8, value, "0")) return error.UnsupportedInstruction;
    }

    const name = try sanitizeIdent(allocator, base, "g_");
    defer allocator.free(name);
    return try std.fmt.allocPrint(allocator, "&{s}", .{name});
}

fn appendValue(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    const translated = try saValue(allocator, value);
    defer allocator.free(translated);
    try out.appendSlice(translated);
}

fn parseParam(allocator: std.mem.Allocator, fragment: []const u8, index: usize) !struct { name: []u8, ty: []const u8 } {
    const ty_token = firstTypeToken(fragment) orelse return error.UnsupportedInstruction;
    const ty = typeTokenToSa(ty_token) orelse return error.UnsupportedInstruction;

    var name_token: ?[]const u8 = null;
    var parts = std.mem.tokenizeAny(u8, fragment, " \t\r\n");
    while (parts.next()) |part| {
        if (std.mem.startsWith(u8, part, "%")) name_token = part;
    }

    const name = if (name_token) |token|
        try sanitizeIdent(allocator, token, "arg")
    else
        try std.fmt.allocPrint(allocator, "arg{d}", .{index});

    return .{ .name = name, .ty = ty };
}

fn appendParamList(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, params_text: []const u8) !void {
    const params = try splitTopLevelComma(allocator, params_text);
    defer allocator.free(params);

    for (params, 0..) |param_text, idx| {
        if (idx != 0) try out.appendSlice(", ");
        const param = try parseParam(allocator, param_text, idx);
        defer allocator.free(param.name);
        try listPrint(out, "{s}: {s}", .{ param.name, param.ty });
    }
}

fn appendFunctionHeader(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, line: []const u8, is_declare: bool) !void {
    const keyword = if (is_declare) "declare" else "define";
    if (!startsWithWord(line, keyword)) return error.InvalidIr;

    const at = std.mem.indexOfScalar(u8, line, '@') orelse return error.InvalidIr;
    const prefix = trim(line[keyword.len..at]);
    const ret_ty = try returnTypeFromPrefix(prefix);

    const after_at = line[at..];
    const open_rel = std.mem.indexOfScalar(u8, after_at, '(') orelse return error.InvalidIr;
    const raw_name = after_at[0..open_rel];
    const open = at + open_rel;
    const close = findMatching(line, open, '(', ')') orelse return error.InvalidIr;
    const name = try sanitizeIdent(allocator, raw_name, "fn_");
    defer allocator.free(name);

    if (is_declare) {
        try listPrint(out, "@extern {s}(", .{name});
    } else {
        try listPrint(out, "@export {s}(", .{name});
    }
    try appendParamList(out, allocator, line[open + 1 .. close]);
    try out.append(')');
    if (!std.mem.eql(u8, ret_ty, "void")) {
        try listPrint(out, " -> {s}", .{ret_ty});
    }
    if (!is_declare) try out.append(':');
    try out.append('\n');
}

fn appendLabel(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, raw_label: []const u8) !void {
    const label = try labelName(allocator, raw_label);
    defer allocator.free(label);
    try listPrint(out, "{s}:\n", .{label});
}

fn llvmBinaryOpToSa(op: []const u8) ?[]const u8 {
    inline for ([_]struct { llvm: []const u8, sa: []const u8 }{
        .{ .llvm = "add", .sa = "add" },
        .{ .llvm = "sub", .sa = "sub" },
        .{ .llvm = "mul", .sa = "mul" },
        .{ .llvm = "sdiv", .sa = "sdiv" },
        .{ .llvm = "udiv", .sa = "udiv" },
        .{ .llvm = "srem", .sa = "srem" },
        .{ .llvm = "urem", .sa = "urem" },
        .{ .llvm = "and", .sa = "and" },
        .{ .llvm = "or", .sa = "or" },
        .{ .llvm = "xor", .sa = "xor" },
        .{ .llvm = "shl", .sa = "shl" },
        .{ .llvm = "lshr", .sa = "lshr" },
        .{ .llvm = "ashr", .sa = "ashr" },
    }) |item| {
        if (std.mem.eql(u8, op, item.llvm)) return item.sa;
    }
    return null;
}

fn llvmIcmpToSa(pred: []const u8) ?[]const u8 {
    inline for ([_]struct { llvm: []const u8, sa: []const u8 }{
        .{ .llvm = "eq", .sa = "eq" },
        .{ .llvm = "ne", .sa = "ne" },
        .{ .llvm = "slt", .sa = "slt" },
        .{ .llvm = "sle", .sa = "sle" },
        .{ .llvm = "sgt", .sa = "sgt" },
        .{ .llvm = "sge", .sa = "sge" },
        .{ .llvm = "ult", .sa = "ult" },
        .{ .llvm = "ule", .sa = "ule" },
        .{ .llvm = "ugt", .sa = "ugt" },
        .{ .llvm = "uge", .sa = "uge" },
    }) |item| {
        if (std.mem.eql(u8, pred, item.llvm)) return item.sa;
    }
    return null;
}

fn skipOverflowFlags(text: []const u8) []const u8 {
    var rest = trim(text);
    while (true) {
        const first_space = std.mem.indexOfAny(u8, rest, " \t") orelse return rest;
        const word = rest[0..first_space];
        if (!(std.mem.eql(u8, word, "nsw") or std.mem.eql(u8, word, "nuw") or std.mem.eql(u8, word, "exact"))) return rest;
        rest = trim(rest[first_space..]);
    }
}

fn appendBinaryOp(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, op: []const u8, rest: []const u8) !void {
    const sa_op = llvmBinaryOpToSa(op) orelse return error.UnsupportedInstruction;
    const body = skipOverflowFlags(rest);
    const ty_token = firstTypeToken(body) orelse return error.UnsupportedInstruction;
    const after_ty = trim(body[(std.mem.indexOf(u8, body, ty_token) orelse 0) + ty_token.len ..]);
    const args = try splitTopLevelComma(allocator, after_ty);
    defer allocator.free(args);
    if (args.len != 2) return error.UnsupportedInstruction;

    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = {s} ", .{ dst, sa_op });
    try appendValue(out, allocator, args[0]);
    try out.appendSlice(", ");
    try appendValue(out, allocator, args[1]);
    try out.append('\n');
}

fn appendIcmp(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8) !void {
    var parts = std.mem.tokenizeAny(u8, rest, " \t\r\n");
    const pred = parts.next() orelse return error.InvalidIr;
    const sa_op = llvmIcmpToSa(pred) orelse return error.UnsupportedInstruction;
    const ty_token = parts.next() orelse return error.UnsupportedInstruction;
    if (typeTokenToSa(ty_token) == null) return error.UnsupportedInstruction;
    const after_ty_start = std.mem.indexOf(u8, rest, ty_token) orelse return error.InvalidIr;
    const args_text = trim(rest[after_ty_start + ty_token.len ..]);
    const args = try splitTopLevelComma(allocator, args_text);
    defer allocator.free(args);
    if (args.len != 2) return error.UnsupportedInstruction;

    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = {s} ", .{ dst, sa_op });
    try appendValue(out, allocator, args[0]);
    try out.appendSlice(", ");
    try appendValue(out, allocator, args[1]);
    try out.append('\n');
}

fn appendAlloca(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8) !void {
    const comma = std.mem.indexOfScalar(u8, rest, ',') orelse rest.len;
    const alloc_ty = trim(rest[0..comma]);
    if (std.mem.indexOfScalar(u8, alloc_ty, '%') != null) return error.UnsupportedInstruction;
    const size = typeBytes(alloc_ty) orelse return error.UnsupportedInstruction;
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = stack_alloc {d}\n", .{ dst, size });
}

fn appendLoad(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8) !void {
    const args = try splitTopLevelComma(allocator, rest);
    defer allocator.free(args);
    if (args.len < 2) return error.UnsupportedInstruction;

    const value_ty = firstTypeToken(args[0]) orelse return error.UnsupportedInstruction;
    const sa_ty = typeTokenToSa(value_ty) orelse return error.UnsupportedInstruction;
    const base = try saValue(allocator, args[1]);
    defer allocator.free(base);
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ dst, base, sa_ty });
}

fn appendStore(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, rest: []const u8) !void {
    const args = try splitTopLevelComma(allocator, rest);
    defer allocator.free(args);
    if (args.len < 2) return error.UnsupportedInstruction;

    const value_ty = firstTypeToken(args[0]) orelse return error.UnsupportedInstruction;
    const sa_ty = typeTokenToSa(value_ty) orelse return error.UnsupportedInstruction;
    const value = try saValue(allocator, args[0]);
    defer allocator.free(value);
    const base = try saValue(allocator, args[1]);
    defer allocator.free(base);
    try listPrint(out, "  store {s}+0, {s} as {s}\n", .{ base, value, sa_ty });
}

fn appendBranch(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, rest: []const u8) !void {
    const t = trim(rest);
    if (std.mem.startsWith(u8, t, "label ")) {
        const label = try labelName(allocator, llvmTypedValueToValue(t["label ".len..]));
        defer allocator.free(label);
        try listPrint(out, "  jmp {s}\n", .{label});
        return;
    }

    const args = try splitTopLevelComma(allocator, t);
    defer allocator.free(args);
    if (args.len != 3) return error.UnsupportedInstruction;
    const cond = try saValue(allocator, args[0]);
    defer allocator.free(cond);
    const true_label = try labelName(allocator, llvmTypedValueToValue(args[1]));
    defer allocator.free(true_label);
    const false_label = try labelName(allocator, llvmTypedValueToValue(args[2]));
    defer allocator.free(false_label);
    try listPrint(out, "  br {s} -> {s}, {s}\n", .{ cond, true_label, false_label });
}

fn appendReturn(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, rest: []const u8) !void {
    const t = trim(rest);
    if (std.mem.eql(u8, t, "void") or t.len == 0) {
        try out.appendSlice("  return\n");
        return;
    }
    try out.appendSlice("  return ");
    try appendValue(out, allocator, t);
    try out.append('\n');
}

fn appendCast(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, op: []const u8, rest: []const u8) !void {
    const to_idx = std.mem.lastIndexOf(u8, rest, " to ") orelse return error.UnsupportedInstruction;
    const source = trim(rest[0..to_idx]);
    const dest_ty_text = trim(rest[to_idx + 4 ..]);
    const dest_ty_token = firstTypeToken(dest_ty_text) orelse return error.UnsupportedInstruction;
    const dest_ty = typeTokenToSa(dest_ty_token) orelse return error.UnsupportedInstruction;
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = {s} ", .{ dst, op });
    try appendValue(out, allocator, source);
    try listPrint(out, " as {s}\n", .{dest_ty});
}

fn llvmFloatOpToSa(op: []const u8) ?[]const u8 {
    inline for ([_]struct { llvm: []const u8, sa: []const u8 }{
        .{ .llvm = "fadd", .sa = "fadd" },
        .{ .llvm = "fsub", .sa = "fsub" },
        .{ .llvm = "fmul", .sa = "fmul" },
        .{ .llvm = "fdiv", .sa = "fdiv" },
    }) |item| {
        if (std.mem.eql(u8, op, item.llvm)) return item.sa;
    }
    return null;
}

fn llvmFcmpToSa(pred: []const u8) ?[]const u8 {
    // Ordered and unordered variants collapse onto the same SA fcmp op;
    // NaN semantics stay conservative: anything unordered-flavored that SA
    // cannot express (ord/uno) is rejected instead of miscompiled.
    inline for ([_]struct { llvm: []const u8, sa: []const u8 }{
        .{ .llvm = "oeq", .sa = "fcmp_eq" },
        .{ .llvm = "ueq", .sa = "fcmp_eq" },
        .{ .llvm = "one", .sa = "fcmp_ne" },
        .{ .llvm = "une", .sa = "fcmp_ne" },
        .{ .llvm = "olt", .sa = "fcmp_lt" },
        .{ .llvm = "ult", .sa = "fcmp_lt" },
        .{ .llvm = "ole", .sa = "fcmp_le" },
        .{ .llvm = "ule", .sa = "fcmp_le" },
        .{ .llvm = "ogt", .sa = "fcmp_gt" },
        .{ .llvm = "ugt", .sa = "fcmp_gt" },
        .{ .llvm = "oge", .sa = "fcmp_ge" },
        .{ .llvm = "uge", .sa = "fcmp_ge" },
    }) |item| {
        if (std.mem.eql(u8, pred, item.llvm)) return item.sa;
    }
    return null;
}

fn appendFloatOp(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, op: []const u8, rest: []const u8) !void {
    const sa_op = llvmFloatOpToSa(op) orelse return error.UnsupportedInstruction;
    const ty_token = firstTypeToken(rest) orelse return error.UnsupportedInstruction;
    const sa_ty = typeTokenToSa(ty_token) orelse return error.UnsupportedInstruction;
    if (!std.mem.eql(u8, sa_ty, "f32") and !std.mem.eql(u8, sa_ty, "f64")) return error.UnsupportedInstruction;
    const after_ty = trim(rest[(std.mem.indexOf(u8, rest, ty_token) orelse 0) + ty_token.len ..]);
    const args = try splitTopLevelComma(allocator, after_ty);
    defer allocator.free(args);
    if (args.len != 2) return error.UnsupportedInstruction;

    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = {s} ", .{ dst, sa_op });
    try appendValue(out, allocator, args[0]);
    try out.appendSlice(", ");
    try appendValue(out, allocator, args[1]);
    try out.append('\n');
}

fn appendFcmp(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8) !void {
    var parts = std.mem.tokenizeAny(u8, rest, " \t\r\n");
    const pred = parts.next() orelse return error.InvalidIr;
    const sa_op = llvmFcmpToSa(pred) orelse return error.UnsupportedInstruction;
    const ty_token = parts.next() orelse return error.UnsupportedInstruction;
    const sa_ty = typeTokenToSa(ty_token) orelse return error.UnsupportedInstruction;
    if (!std.mem.eql(u8, sa_ty, "f32") and !std.mem.eql(u8, sa_ty, "f64")) return error.UnsupportedInstruction;
    const after_ty_start = std.mem.indexOf(u8, rest, ty_token) orelse return error.InvalidIr;
    const args_text = trim(rest[after_ty_start + ty_token.len ..]);
    const args = try splitTopLevelComma(allocator, args_text);
    defer allocator.free(args);
    if (args.len != 2) return error.UnsupportedInstruction;

    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = {s} ", .{ dst, sa_op });
    try appendValue(out, allocator, args[0]);
    try out.appendSlice(", ");
    try appendValue(out, allocator, args[1]);
    try out.append('\n');
}

fn appendSelect(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8) !void {
    const args = try splitTopLevelComma(allocator, rest);
    defer allocator.free(args);
    if (args.len != 3) return error.UnsupportedInstruction;

    const cond_ty = firstTypeToken(args[0]) orelse return error.UnsupportedInstruction;
    if (!std.mem.eql(u8, typeTokenToSa(cond_ty) orelse return error.UnsupportedInstruction, "i1")) {
        return error.UnsupportedInstruction;
    }

    const true_ty = firstTypeToken(args[1]) orelse return error.UnsupportedInstruction;
    const false_ty = firstTypeToken(args[2]) orelse return error.UnsupportedInstruction;
    const sa_ty = typeTokenToSa(true_ty) orelse return error.UnsupportedInstruction;
    if (!std.mem.eql(u8, sa_ty, typeTokenToSa(false_ty) orelse return error.UnsupportedInstruction)) {
        return error.UnsupportedInstruction;
    }
    const size = typeBytes(true_ty) orelse return error.UnsupportedInstruction;

    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    const slot = try std.fmt.allocPrint(allocator, "bc2sa_select_slot_{s}", .{dst});
    defer allocator.free(slot);
    const true_label = try std.fmt.allocPrint(allocator, "L_BC2SA_SELECT_TRUE_{s}", .{dst});
    defer allocator.free(true_label);
    const false_label = try std.fmt.allocPrint(allocator, "L_BC2SA_SELECT_FALSE_{s}", .{dst});
    defer allocator.free(false_label);
    const join_label = try std.fmt.allocPrint(allocator, "L_BC2SA_SELECT_JOIN_{s}", .{dst});
    defer allocator.free(join_label);

    try listPrint(out, "  {s} = stack_alloc {d}\n", .{ slot, size });
    try out.appendSlice("  br ");
    try appendValue(out, allocator, args[0]);
    try listPrint(out, " -> {s}, {s}\n", .{ true_label, false_label });

    try listPrint(out, "{s}:\n", .{true_label});
    try listPrint(out, "  store {s}+0, ", .{slot});
    try appendValue(out, allocator, args[1]);
    try listPrint(out, " as {s}\n", .{sa_ty});
    try listPrint(out, "  jmp {s}\n", .{join_label});

    try listPrint(out, "{s}:\n", .{false_label});
    try listPrint(out, "  store {s}+0, ", .{slot});
    try appendValue(out, allocator, args[2]);
    try listPrint(out, " as {s}\n", .{sa_ty});
    try listPrint(out, "  jmp {s}\n", .{join_label});

    try listPrint(out, "{s}:\n", .{join_label});
    try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ dst, slot, sa_ty });
}

fn appendSwitch(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, text: []const u8, switch_id: usize) !void {
    const open = std.mem.indexOfScalar(u8, text, '[') orelse return error.UnsupportedInstruction;
    const close = std.mem.lastIndexOfScalar(u8, text, ']') orelse return error.InvalidIr;
    if (close < open) return error.InvalidIr;

    const header = try splitTopLevelComma(allocator, trim(text["switch".len..open]));
    defer allocator.free(header);
    if (header.len != 2) return error.UnsupportedInstruction;
    const switch_ty = firstTypeToken(header[0]) orelse return error.UnsupportedInstruction;
    const sa_ty = typeTokenToSa(switch_ty) orelse return error.UnsupportedInstruction;
    const switch_value = try saValue(allocator, header[0]);
    defer allocator.free(switch_value);
    const default_text = trim(header[1]);
    if (!std.mem.startsWith(u8, default_text, "label ")) return error.UnsupportedInstruction;
    const default_label = try labelName(allocator, llvmTypedValueToValue(default_text["label ".len..]));
    defer allocator.free(default_label);

    var cases = std.array_list.Managed([]const []const u8).init(allocator);
    defer {
        for (cases.items) |parts| allocator.free(parts);
        cases.deinit();
    }
    var case_lines = std.mem.splitScalar(u8, text[open + 1 .. close], '\n');
    while (case_lines.next()) |raw_case| {
        const case_line = trim(raw_case);
        if (case_line.len == 0) continue;
        {
            const parts = try splitTopLevelComma(allocator, case_line);
            defer allocator.free(parts);
            if (parts.len == 0 or parts.len % 2 != 0) return error.UnsupportedInstruction;
            var part_idx: usize = 0;
            while (part_idx < parts.len) : (part_idx += 2) {
                const pair = try allocator.alloc([]const u8, 2);
                pair[0] = parts[part_idx];
                pair[1] = parts[part_idx + 1];
                cases.append(pair) catch |err| {
                    allocator.free(pair);
                    return err;
                };
            }
        }
    }

    if (cases.items.len == 0) {
        try listPrint(out, "  jmp {s}\n", .{default_label});
        return;
    }

    for (cases.items, 0..) |parts, idx| {
        const case_ty = firstTypeToken(parts[0]) orelse return error.UnsupportedInstruction;
        if (!std.mem.eql(u8, sa_ty, typeTokenToSa(case_ty) orelse return error.UnsupportedInstruction)) {
            return error.UnsupportedInstruction;
        }
        const case_value = try saValue(allocator, parts[0]);
        defer allocator.free(case_value);
        const case_label_text = trim(parts[1]);
        if (!std.mem.startsWith(u8, case_label_text, "label ")) return error.UnsupportedInstruction;
        const case_label = try labelName(allocator, llvmTypedValueToValue(case_label_text["label ".len..]));
        defer allocator.free(case_label);

        const cmp_name = try std.fmt.allocPrint(allocator, "bc2sa_switch_cmp_{d}_{d}", .{ switch_id, idx });
        defer allocator.free(cmp_name);
        try listPrint(out, "  {s} = eq {s}, {s}\n", .{ cmp_name, switch_value, case_value });

        if (idx + 1 == cases.items.len) {
            try listPrint(out, "  br {s} -> {s}, {s}\n", .{ cmp_name, case_label, default_label });
        } else {
            const next_label = try std.fmt.allocPrint(allocator, "L_BC2SA_SWITCH_NEXT_{d}_{d}", .{ switch_id, idx });
            defer allocator.free(next_label);
            try listPrint(out, "  br {s} -> {s}, {s}\n", .{ cmp_name, case_label, next_label });
            try listPrint(out, "{s}:\n", .{next_label});
        }
    }
}

fn isPhiInstruction(line: []const u8) bool {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return false;
    var words = std.mem.tokenizeAny(u8, trim(line[eq + 1 ..]), " \t\r\n");
    return if (words.next()) |op| std.mem.eql(u8, op, "phi") else false;
}

fn parsePhi(allocator: std.mem.Allocator, line: []const u8) !struct { lhs: []const u8, ty: []const u8, incoming: []const []const u8 } {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidIr;
    const lhs = trim(line[0..eq]);
    const rhs = trim(line[eq + 1 ..]);
    if (!std.mem.startsWith(u8, rhs, "phi ")) return error.UnsupportedPhi;
    const body = trim(rhs["phi ".len..]);
    const ty = firstTypeToken(body) orelse return error.UnsupportedPhi;
    const ty_idx = std.mem.indexOf(u8, body, ty) orelse return error.InvalidIr;
    const incoming = try splitTopLevelComma(allocator, trim(body[ty_idx + ty.len ..]));
    if (incoming.len == 0) {
        allocator.free(incoming);
        return error.UnsupportedPhi;
    }
    return .{ .lhs = lhs, .ty = ty, .incoming = incoming };
}

fn phiSlotName(allocator: std.mem.Allocator, lhs: []const u8) ![]u8 {
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    return try std.fmt.allocPrint(allocator, "bc2sa_phi_slot_{s}", .{dst});
}

fn appendPhiSlots(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, phi_lines: []const []const u8) !void {
    for (phi_lines) |phi_line| {
        const phi = try parsePhi(allocator, phi_line);
        defer allocator.free(phi.incoming);
        const size = typeBytes(phi.ty) orelse return error.UnsupportedPhi;
        const slot = try phiSlotName(allocator, phi.lhs);
        defer allocator.free(slot);
        try listPrint(out, "  {s} = stack_alloc {d}\n", .{ slot, size });
    }
}

fn appendPhiLoad(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, line: []const u8) !void {
    const phi = try parsePhi(allocator, line);
    defer allocator.free(phi.incoming);
    const sa_ty = typeTokenToSa(phi.ty) orelse return error.UnsupportedPhi;
    const dst = try sanitizeIdent(allocator, phi.lhs, "r");
    defer allocator.free(dst);
    const slot = try phiSlotName(allocator, phi.lhs);
    defer allocator.free(slot);
    try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ dst, slot, sa_ty });
}

fn appendPhiStoresForBlock(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, phi_lines: []const []const u8, block: []const u8) !void {
    for (phi_lines) |phi_line| {
        const phi = try parsePhi(allocator, phi_line);
        defer allocator.free(phi.incoming);
        const sa_ty = typeTokenToSa(phi.ty) orelse return error.UnsupportedPhi;
        const slot = try phiSlotName(allocator, phi.lhs);
        defer allocator.free(slot);
        for (phi.incoming) |incoming_text| {
            const pair_text = trim(incoming_text);
            if (pair_text.len < 2 or pair_text[0] != '[' or pair_text[pair_text.len - 1] != ']') return error.UnsupportedPhi;
            const pair = try splitTopLevelComma(allocator, pair_text[1 .. pair_text.len - 1]);
            defer allocator.free(pair);
            if (pair.len != 2) return error.UnsupportedPhi;
            const incoming_block = stripLlvmSigil(llvmTypedValueToValue(pair[1]));
            if (!std.mem.eql(u8, trim(incoming_block), trim(block))) continue;
            const value = try saValue(allocator, pair[0]);
            defer allocator.free(value);
            try listPrint(out, "  store {s}+0, {s} as {s}\n", .{ slot, value, sa_ty });
        }
    }
}

fn appendFunctionBody(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, header: []const u8, body: []const []const u8) !void {
    try appendFunctionHeader(out, allocator, header, false);

    var phi_lines = std.array_list.Managed([]const u8).init(allocator);
    defer phi_lines.deinit();
    for (body) |line| if (isPhiInstruction(line)) try phi_lines.append(line);

    var switch_text = std.array_list.Managed(u8).init(allocator);
    defer switch_text.deinit();
    var pending_switch = false;
    var switch_id: usize = 0;
    var need_entry_label = true;
    var phi_slots_emitted = false;
    var current_block: []const u8 = "entry";

    for (body) |raw_body_line| {
        const line = trim(cleanInstructionLine(raw_body_line));
        if (line.len == 0) continue;
        if (pending_switch) {
            try switch_text.appendSlice(line);
            try switch_text.append('\n');
            if (std.mem.indexOfScalar(u8, line, ']') != null) {
                try appendPhiStoresForBlock(out, allocator, phi_lines.items, current_block);
                try appendSwitch(out, allocator, switch_text.items, switch_id);
                switch_id += 1;
                switch_text.clearRetainingCapacity();
                pending_switch = false;
            }
            continue;
        }
        if (std.mem.endsWith(u8, line, ":")) {
            try appendLabel(out, allocator, line[0 .. line.len - 1]);
            current_block = line[0 .. line.len - 1];
            need_entry_label = false;
            if (!phi_slots_emitted) {
                try appendPhiSlots(out, allocator, phi_lines.items);
                phi_slots_emitted = true;
            }
            continue;
        }
        if (need_entry_label) {
            try out.appendSlice("L_ENTRY:\n");
            try appendPhiSlots(out, allocator, phi_lines.items);
            phi_slots_emitted = true;
            need_entry_label = false;
        }
        if (startsWithWord(line, "switch")) {
            switch_text.clearRetainingCapacity();
            try switch_text.appendSlice(line);
            try switch_text.append('\n');
            if (std.mem.indexOfScalar(u8, line, ']') != null) {
                try appendPhiStoresForBlock(out, allocator, phi_lines.items, current_block);
                try appendSwitch(out, allocator, switch_text.items, switch_id);
                switch_id += 1;
                switch_text.clearRetainingCapacity();
            } else {
                pending_switch = true;
            }
            continue;
        }
        if (startsWithWord(line, "br") or startsWithWord(line, "ret")) {
            try appendPhiStoresForBlock(out, allocator, phi_lines.items, current_block);
        }
        if (isPhiInstruction(line)) {
            try appendPhiLoad(out, allocator, line);
        } else {
            try appendInstruction(out, allocator, line);
        }
    }
    if (pending_switch) return error.InvalidIr;
    try out.append('\n');
}

fn appendGetElementPtr(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8) !void {
    var body = trim(rest);
    if (std.mem.startsWith(u8, body, "inbounds ")) body = trim(body["inbounds ".len..]);
    const args = try splitTopLevelComma(allocator, body);
    defer allocator.free(args);
    if (args.len < 3) return error.UnsupportedInstruction;

    if (arrayBoundFromType(args[0])) |bound| {
        var prefix_is_zero = true;
        if (args.len > 3) {
            for (args[2 .. args.len - 1]) |idx_text| {
                const idx_value = llvmTypedValueToValue(idx_text);
                if (!std.mem.eql(u8, idx_value, "0")) {
                    prefix_is_zero = false;
                    break;
                }
            }
        }
        if (prefix_is_zero) {
            const last_idx_value = llvmTypedValueToValue(args[args.len - 1]);
            if (std.fmt.parseInt(u64, last_idx_value, 10)) |idx| {
                if (idx >= bound) return error.StaticMemoryOverflow;
            } else |_| {}
        }
    }

    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    const base = try saValue(allocator, args[1]);
    defer allocator.free(base);
    const offset = try saValue(allocator, args[args.len - 1]);
    defer allocator.free(offset);
    try listPrint(out, "  {s} = ptr_add {s}, {s}\n", .{ dst, base, offset });
}

fn appendCall(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: ?[]const u8, rest: []const u8) !void {
    const call_idx = std.mem.indexOf(u8, rest, "call ") orelse return error.UnsupportedInstruction;
    const call_text = trim(rest[call_idx + "call ".len ..]);
    const at = std.mem.indexOfScalar(u8, call_text, '@') orelse return error.UnsupportedInstruction;
    const open_rel = std.mem.indexOfScalar(u8, call_text[at..], '(') orelse return error.InvalidIr;
    const open = at + open_rel;
    const close = findMatching(call_text, open, '(', ')') orelse return error.InvalidIr;
    const raw_callee = call_text[at..open];
    const callee = try sanitizeIdent(allocator, raw_callee, "fn_");
    defer allocator.free(callee);

    if (lhs) |lhs_text| {
        const dst = try sanitizeIdent(allocator, lhs_text, "r");
        defer allocator.free(dst);
        try listPrint(out, "  {s} = call @{s}(", .{ dst, callee });
    } else {
        try listPrint(out, "  call @{s}(", .{callee});
    }

    const args = try splitTopLevelComma(allocator, call_text[open + 1 .. close]);
    defer allocator.free(args);
    for (args, 0..) |arg, idx| {
        if (idx != 0) try out.appendSlice(", ");
        try appendValue(out, allocator, arg);
    }
    try out.appendSlice(")\n");
}

fn appendAssignmentInstruction(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rhs: []const u8) !void {
    var words = std.mem.tokenizeAny(u8, rhs, " \t\r\n");
    const op = words.next() orelse return error.InvalidIr;
    const rest_start = std.mem.indexOf(u8, rhs, op) orelse return error.InvalidIr;
    const rest = trim(rhs[rest_start + op.len ..]);

    if (std.mem.eql(u8, op, "phi")) return error.UnsupportedPhi;
    if (llvmBinaryOpToSa(op) != null) return appendBinaryOp(out, allocator, lhs, op, rest);
    if (llvmFloatOpToSa(op) != null) return appendFloatOp(out, allocator, lhs, op, rest);
    if (std.mem.eql(u8, op, "icmp")) return appendIcmp(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "fcmp")) return appendFcmp(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "alloca")) return appendAlloca(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "load")) return appendLoad(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "getelementptr")) return appendGetElementPtr(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "select")) return appendSelect(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "call") or std.mem.indexOf(u8, rhs, " call ") != null) return appendCall(out, allocator, lhs, rhs);
    if (std.mem.eql(u8, op, "trunc") or std.mem.eql(u8, op, "zext") or std.mem.eql(u8, op, "sext") or std.mem.eql(u8, op, "bitcast")) {
        return appendCast(out, allocator, lhs, op, rest);
    }

    return error.UnsupportedInstruction;
}

fn appendInstruction(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, line: []const u8) !void {
    const cleaned = cleanInstructionLine(line);
    const t = trim(cleaned);
    if (t.len == 0) return;

    if (std.mem.indexOfScalar(u8, t, '=')) |eq_idx| {
        const lhs = trim(t[0..eq_idx]);
        const rhs = trim(t[eq_idx + 1 ..]);
        return appendAssignmentInstruction(out, allocator, lhs, rhs);
    }

    if (startsWithWord(t, "ret")) return appendReturn(out, allocator, t["ret".len..]);
    if (startsWithWord(t, "br")) return appendBranch(out, allocator, t["br".len..]);
    if (startsWithWord(t, "store")) return appendStore(out, allocator, t["store".len..]);
    if (std.mem.indexOf(u8, t, "call ") != null) return appendCall(out, allocator, null, t);

    return error.UnsupportedInstruction;
}

fn decodeLlvmCString(allocator: std.mem.Allocator, literal: []const u8) ![]u8 {
    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();

    var i: usize = 0;
    while (i < literal.len) {
        if (literal[i] != '\\') {
            try out.append(literal[i]);
            i += 1;
            continue;
        }

        if (i + 2 >= literal.len) return error.InvalidIr;
        const hi = std.fmt.charToDigit(literal[i + 1], 16) catch {
            switch (literal[i + 1]) {
                '\\' => {
                    try out.append('\\');
                    i += 2;
                    continue;
                },
                '"' => {
                    try out.append('"');
                    i += 2;
                    continue;
                },
                else => return error.InvalidIr,
            }
        };
        const lo = std.fmt.charToDigit(literal[i + 2], 16) catch return error.InvalidIr;
        try out.append(@as(u8, @intCast((hi << 4) | lo)));
        i += 3;
    }

    return try out.toOwnedSlice();
}

fn appendSaQuotedByte(out: *std.array_list.Managed(u8), byte: u8) !void {
    switch (byte) {
        '\\' => try out.appendSlice("\\\\"),
        '"' => try out.appendSlice("\\\""),
        '\n' => try out.appendSlice("\\n"),
        '\r' => try out.appendSlice("\\r"),
        '\t' => try out.appendSlice("\\t"),
        0 => try out.appendSlice("\\0"),
        else => {
            if (byte >= 0x20 and byte <= 0x7e) {
                try out.append(byte);
            } else {
                try listPrint(out, "\\x{X:0>2}", .{byte});
            }
        },
    }
}

fn appendConstDecl(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, line: []const u8) !bool {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return false;
    const raw_name = trim(line[0..eq]);
    if (!std.mem.startsWith(u8, raw_name, "@")) return false;
    if (std.mem.indexOf(u8, line[eq + 1 ..], " constant ") == null) return false;
    const c_idx = std.mem.indexOf(u8, line[eq + 1 ..], " c\"") orelse return false;
    const literal_start = eq + 1 + c_idx + 3;
    const literal_end = std.mem.lastIndexOfScalar(u8, line, '"') orelse return error.InvalidIr;
    if (literal_end < literal_start) return error.InvalidIr;

    const bytes = try decodeLlvmCString(allocator, line[literal_start..literal_end]);
    defer allocator.free(bytes);
    const name = try sanitizeIdent(allocator, raw_name, "g_");
    defer allocator.free(name);

    if (std.unicode.utf8ValidateSlice(bytes)) {
        try listPrint(out, "@const {s} = utf8:\"", .{name});
        for (bytes) |byte| try appendSaQuotedByte(out, byte);
        try out.appendSlice("\"\n");
    } else {
        try listPrint(out, "@const {s} = hex:", .{name});
        for (bytes) |byte| try listPrint(out, "\\x{X:0>2}", .{byte});
        try out.append('\n');
    }
    return true;
}

pub fn translateIrSource(allocator: std.mem.Allocator, source: []const u8) ![]u8 {
    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();

    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |raw_line| {
        const trimmed_line = trim(raw_line);
        if (trimmed_line.len == 0) continue;
        if (std.mem.startsWith(u8, trimmed_line, ";")) continue;

        if (try appendConstDecl(&out, allocator, trimmed_line)) continue;
        const cleaned = cleanInstructionLine(trimmed_line);
        const line = trim(cleaned);
        if (line.len == 0) continue;
        if (startsWithWord(line, "declare")) {
            try appendFunctionHeader(&out, allocator, line, true);
            continue;
        }
        if (startsWithWord(line, "define")) {
            var body = std.array_list.Managed([]const u8).init(allocator);
            defer body.deinit();
            var closed = false;
            while (lines.next()) |raw_body_line| {
                const body_line = trim(cleanInstructionLine(trim(raw_body_line)));
                if (body_line.len == 0) continue;
                if (std.mem.eql(u8, body_line, "}")) {
                    closed = true;
                    break;
                }
                try body.append(body_line);
            }
            if (!closed) return error.InvalidIr;
            try appendFunctionBody(&out, allocator, line, body.items);
            continue;
        }
        // A stray closing brace outside any function is malformed IR.
        // Any other top-level line (source_filename, target triple /
        // datalayout, module asm, attribute groups) carries no executable
        // semantics and is ignored.
        if (std.mem.eql(u8, line, "}")) return error.InvalidIr;
        continue;
    }

    return try out.toOwnedSlice();
}

/// One disassembly attempt. A candidate that exists but rejects the input
/// (e.g. an older llvm-dis facing a newer bitcode summary version) must NOT
/// short-circuit the chain: the failure reason is recorded and the next
/// candidate is tried. Only when every candidate has failed is an error
/// returned, with all reasons preserved in `lastDisassemblyFailure`.
const DisAttempt = union(enum) {
    ok: []u8,
    not_found,
    failed: []u8,
};

var dis_failure_buf: [8192]u8 = undefined;
var dis_failure_len: usize = 0;

/// Per-candidate failure report from the most recent `disassembleBitcode`
/// call that exhausted the whole chain (empty when the last call succeeded
/// or never ran). One line per candidate: `<path>: <reason>`.
pub fn lastDisassemblyFailure() []const u8 {
    return dis_failure_buf[0..dis_failure_len];
}

fn setDisassemblyFailure(report: []const u8) void {
    const n = @min(report.len, dis_failure_buf.len);
    @memcpy(dis_failure_buf[0..n], report[0..n]);
    dis_failure_len = n;
}

fn firstLine(text: []const u8) []const u8 {
    const t = trim(text);
    const nl = std.mem.indexOfScalar(u8, t, '\n') orelse return t;
    return trim(t[0..nl]);
}

fn runDisTool(allocator: std.mem.Allocator, exe: []const u8, path: []const u8, use_clang: bool) !DisAttempt {
    const dis_argv = [_][]const u8{ exe, "-o", "-", path };
    const clang_argv = [_][]const u8{ exe, "-S", "-emit-llvm", path, "-o", "-" };
    const argv: []const []const u8 = if (use_clang) &clang_argv else &dis_argv;
    const result = std.process.run(allocator, io(), .{
        .argv = argv,
        .stdout_limit = .limited(max_ir_bytes),
        .stderr_limit = .limited(max_ir_bytes),
    }) catch |err| switch (err) {
        error.FileNotFound => return .not_found,
        else => return .{ .failed = try std.fmt.allocPrint(allocator, "spawn failed: {s}", .{@errorName(err)}) },
    };
    defer allocator.free(result.stderr);

    switch (result.term) {
        .exited => |code| {
            if (code == 0) {
                if (result.stdout.len == 0) {
                    allocator.free(result.stdout);
                    return .{ .failed = try allocator.dupe(u8, "exit 0 but produced no output") };
                }
                return .{ .ok = result.stdout };
            }
            allocator.free(result.stdout);
            const why = firstLine(result.stderr);
            return .{ .failed = if (why.len > 0)
                try std.fmt.allocPrint(allocator, "exit {d}: {s}", .{ code, why })
            else
                try std.fmt.allocPrint(allocator, "exit {d}", .{code}) };
        },
        else => {
            allocator.free(result.stdout);
            return .{ .failed = try allocator.dupe(u8, "terminated abnormally") };
        },
    }
}

fn disassembleWithCandidates(allocator: std.mem.Allocator, path: []const u8, dis_candidates: []const []const u8, clang_cands: []const []const u8) ![]u8 {
    var report = std.array_list.Managed(u8).init(allocator);
    defer report.deinit();
    var any_ran = false;

    for (dis_candidates) |candidate| {
        switch (try runDisTool(allocator, candidate, path, false)) {
            .ok => |ir| {
                setDisassemblyFailure("");
                return ir;
            },
            .not_found => try listPrint(&report, "{s}: not found\n", .{candidate}),
            .failed => |reason| {
                any_ran = true;
                defer allocator.free(reason);
                try listPrint(&report, "{s}: {s}\n", .{ candidate, reason });
            },
        }
    }
    for (clang_cands) |candidate| {
        switch (try runDisTool(allocator, candidate, path, true)) {
            .ok => |ir| {
                setDisassemblyFailure("");
                return ir;
            },
            .not_found => try listPrint(&report, "{s}: not found\n", .{candidate}),
            .failed => |reason| {
                any_ran = true;
                defer allocator.free(reason);
                try listPrint(&report, "{s}: {s}\n", .{ candidate, reason });
            },
        }
    }
    setDisassemblyFailure(report.items);
    return if (any_ran) error.LlvmDisFailed else error.LlvmDisNotFound;
}

fn disassembleBitcode(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return disassembleWithCandidates(allocator, path, llvm_dis_candidates[0..], clang_candidates[0..]);
}

pub fn translateBitcodeFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const source = std.Io.Dir.cwd().readFileAlloc(io(), path, allocator, .limited(max_bitcode_bytes)) catch |err| switch (err) {
        error.FileNotFound => return error.UnsupportedBitcodeInput,
        else => return err,
    };
    defer allocator.free(source);

    if (source.len < bitcode_magic.len or !std.mem.eql(u8, source[0..bitcode_magic.len], bitcode_magic[0..])) {
        return error.UnsupportedBitcodeInput;
    }

    const ir = try disassembleBitcode(allocator, path);
    defer allocator.free(ir);
    return try translateIrSource(allocator, ir);
}

fn llvmAs(allocator: std.mem.Allocator, input_path: []const u8, output_path: []const u8) !void {
    for (llvm_as_candidates) |candidate| {
        const argv = [_][]const u8{ candidate, input_path, "-o", output_path };
        const result = std.process.run(allocator, io(), .{
            .argv = argv[0..],
        }) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);
        switch (result.term) {
            .exited => |code| if (code == 0) return,
            else => {},
        }
    }
    return error.SkipZigTest;
}

test "bc2sa translates real llvm bitcode" {
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.writeFile(io(), .{ .sub_path = "sample.ll", .data = 
        \\define i32 @main(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %0 = add i32 %lhs, %rhs
        \\  %1 = icmp sgt i32 %0, 2
        \\  br i1 %1, label %ok, label %err
        \\ok:
        \\  ret i32 %0
        \\err:
        \\  ret i32 0
        \\}
        \\
    });
    const ll_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path, "sample.ll" });
    defer std.testing.allocator.free(ll_path);
    const tmp_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path });
    defer std.testing.allocator.free(tmp_path);
    const bc_path = try std.fs.path.join(std.testing.allocator, &.{ tmp_path, "sample.bc" });
    defer std.testing.allocator.free(bc_path);
    try llvmAs(std.testing.allocator, ll_path, bc_path);

    const out = try translateBitcodeFile(std.testing.allocator, bc_path);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "@export main(lhs: i32, rhs: i32) -> i32:"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "L_entry:"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "r0 = add lhs, rhs"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "r1 = sgt r0, 2"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "br r1 -> L_ok, L_err"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "return r0"));
}

test "bc2sa translates real llvm bitcode with float and select" {
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.writeFile(io(), .{ .sub_path = "float.ll", .data = 
        \\define double @blend(i1 %c, double %a, double %b) {
        \\entry:
        \\  %s = select i1 %c, double %a, double %b
        \\  %r = fadd double %s, 1.5
        \\  ret double %r
        \\}
        \\
    });
    const ll_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path, "float.ll" });
    defer std.testing.allocator.free(ll_path);
    const tmp_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path });
    defer std.testing.allocator.free(tmp_path);
    const bc_path = try std.fs.path.join(std.testing.allocator, &.{ tmp_path, "float.bc" });
    defer std.testing.allocator.free(bc_path);
    try llvmAs(std.testing.allocator, ll_path, bc_path);

    const out = try translateBitcodeFile(std.testing.allocator, bc_path);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_select_slot_s = stack_alloc 8"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "s = load bc2sa_select_slot_s+0 as f64"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "r = fadd s, 1.5"));
}

test "bc2sa rejects text llvm ir on bitcode-only path" {
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.writeFile(io(), .{
        .sub_path = "sample.ll",
        .data = "define i32 @main() {\nentry:\n  ret i32 0\n}\n",
    });
    const sample_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path, "sample.ll" });
    defer std.testing.allocator.free(sample_path);
    try std.testing.expectError(error.UnsupportedBitcodeInput, translateBitcodeFile(std.testing.allocator, sample_path));
}

test "bc2sa rejects constant gep that exceeds static array bound" {
    const ir =
        \\define i32 @main() {
        \\entry:
        \\  %arr = alloca [4 x i8], align 1
        \\  %slot = getelementptr inbounds [4 x i8], ptr %arr, i64 0, i64 4
        \\  ret i32 0
        \\}
        \\
    ;

    try std.testing.expectError(error.StaticMemoryOverflow, translateIrSource(std.testing.allocator, ir));
}

test "bc2sa accepts constant gep inside static array bound" {
    const ir =
        \\define i32 @main() {
        \\entry:
        \\  %arr = alloca [4 x i8], align 1
        \\  %slot = getelementptr inbounds [4 x i8], ptr %arr, i64 0, i64 3
        \\  ret i32 0
        \\}
        \\
    ;

    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "slot = ptr_add arr, 3"));
}

test "bc2sa lowers float arithmetic" {
    const ir =
        \\define double @fadd2(double %a, double %b) {
        \\entry:
        \\  %s = fadd double %a, %b
        \\  ret double %s
        \\}
        \\
    ;

    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "s = fadd a, b"));
}

test "bc2sa lowers float comparison" {
    const ir =
        \\define i1 @flt(double %a, double %b) {
        \\entry:
        \\  %c = fcmp olt double %a, %b
        \\  ret i1 %c
        \\}
        \\
    ;

    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "c = fcmp_lt a, b"));
}

test "bc2sa lowers scalar select through a stack slot" {
    const ir =
        \\define i32 @pick(i1 %c, i32 %a, i32 %b) {
        \\entry:
        \\  %s = select i1 %c, i32 %a, i32 %b
        \\  ret i32 %s
        \\}
        \\
    ;

    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_select_slot_s = stack_alloc 4"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "br c -> L_BC2SA_SELECT_TRUE_s, L_BC2SA_SELECT_FALSE_s"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "s = load bc2sa_select_slot_s+0 as i32"));
}

test "bc2sa lowers switch into eq and branch chain" {
    const ir =
        \\define i32 @dispatch(i32 %v) {
        \\entry:
        \\  switch i32 %v, label %d [
        \\    i32 1, label %one
        \\    i32 2, label %two
        \\  ]
        \\one:
        \\  ret i32 1
        \\two:
        \\  ret i32 2
        \\d:
        \\  ret i32 0
        \\}
        \\
    ;

    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_switch_cmp_0_0 = eq v, 1"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "br bc2sa_switch_cmp_0_0 -> L_one, L_BC2SA_SWITCH_NEXT_0_0"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "br bc2sa_switch_cmp_0_1 -> L_two, L_d"));
}

test "bc2sa lowers scalar phi through a stack slot" {
    const ir =
        \\define i32 @sum(i32 %n) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\  %next = add i32 %i, 1
        \\  %done = icmp sge i32 %next, %n
        \\  br i1 %done, label %exit, label %loop
        \\exit:
        \\  ret i32 %next
        \\}
        \\
    ;

    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_phi_slot_i = stack_alloc 4"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "store bc2sa_phi_slot_i+0, 0 as i32"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "store bc2sa_phi_slot_i+0, next as i32"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "i = load bc2sa_phi_slot_i+0 as i32"));
}

test "bc2sa disassembly falls back past a failing candidate" {
    // Pre-fix behaviour: the first existing candidate that exited nonzero
    // aborted the whole chain with error.LlvmDisFailed, so a too-old
    // llvm-dis permanently blocked newer ones behind it (and clang).
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.writeFile(io(), .{ .sub_path = "sample.ll", .data =
        \\define i32 @main(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %0 = add i32 %lhs, %rhs
        \\  ret i32 %0
        \\}
        \\
    });
    const ll_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path, "sample.ll" });
    defer std.testing.allocator.free(ll_path);
    const tmp_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path });
    defer std.testing.allocator.free(tmp_path);
    const bc_path = try std.fs.path.join(std.testing.allocator, &.{ tmp_path, "sample.bc" });
    defer std.testing.allocator.free(bc_path);
    try llvmAs(std.testing.allocator, ll_path, bc_path);

    // /bin/false always exits 1: the chain must record it and move on to
    // the real llvm-dis-23 instead of short-circuiting. (llvm-as-23 emits
    // LLVM 23 bitcode, which is exactly what older candidates reject.)
    const ir = try disassembleWithCandidates(std.testing.allocator, bc_path, &.{ "/bin/false", "/usr/bin/llvm-dis-23" }, &.{});
    defer std.testing.allocator.free(ir);
    try std.testing.expect(std.mem.containsAtLeast(u8, ir, 1, "define i32 @main"));
    try std.testing.expectEqual(@as(usize, 0), lastDisassemblyFailure().len);
}

test "bc2sa disassembly report lists every candidate failure" {
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.writeFile(io(), .{ .sub_path = "junk.bc", .data = "BC\xc0\xde not really bitcode" });
    const bc_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path, "junk.bc" });
    defer std.testing.allocator.free(bc_path);

    // /bin/false exits 1 silently; /bin/true exits 0 with no output: both
    // are failures, both must appear in the report, and the error must be
    // LlvmDisFailed (candidates ran) rather than a bare short-circuit.
    try std.testing.expectError(error.LlvmDisFailed, disassembleWithCandidates(std.testing.allocator, bc_path, &.{ "/bin/false", "/bin/true" }, &.{}));
    const report = lastDisassemblyFailure();
    try std.testing.expect(std.mem.containsAtLeast(u8, report, 1, "/bin/false: exit 1"));
    try std.testing.expect(std.mem.containsAtLeast(u8, report, 1, "/bin/true: exit 0 but produced no output"));
}

test "bc2sa disassembly distinguishes no candidate installed" {
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.writeFile(io(), .{ .sub_path = "junk.bc", .data = "BC\xc0\xde not really bitcode" });
    const bc_path = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path, "junk.bc" });
    defer std.testing.allocator.free(bc_path);

    try std.testing.expectError(error.LlvmDisNotFound, disassembleWithCandidates(std.testing.allocator, bc_path, &.{"/nonexistent/llvm-dis-99"}, &.{}));
    try std.testing.expect(std.mem.containsAtLeast(u8, lastDisassemblyFailure(), 1, "/nonexistent/llvm-dis-99: not found"));
}
