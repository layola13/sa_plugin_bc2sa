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

fn isHexDigit(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
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

    if (t.len >= 2 and t[0] == '{' and t[t.len - 1] == '}') {
        // Struct size needs the field layout (defined below); this
        // function's signature has no allocator, so compute the layout
        // with a scratch arena.
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const layout = (aggLayout(arena.allocator(), t) catch return null) orelse return null;
        return layout.size;
    }

    return null;
}

fn alignUp(value: u64, alignment: u64) u64 {
    if (alignment <= 1) return value;
    return (value + alignment - 1) & ~(alignment - 1);
}

fn aggAlign(ty_text: []const u8) u64 {
    const t = trim(ty_text);
    if (t.len > 0 and t[0] == '{') {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const layout = (aggLayout(arena.allocator(), t) catch return 8) orelse return 8;
        return layout.@"align";
    }
    if (t.len > 0 and t[0] == '[') {
        const body = trim(t[1 .. t.len - 1]);
        const x_idx = std.mem.indexOf(u8, body, " x ") orelse return 8;
        return aggAlign(body[x_idx + 3 ..]);
    }
    return @min(typeBytes(t) orelse 8, 8);
}

const AggField = struct { ty: []const u8, offset: u64 };
const AggLayout = struct {
    fields: std.array_list.Managed(AggField),
    size: u64,
    @"align": u64,
};

/// LLVM struct layout: fields in order, each aligned to its natural
/// alignment, struct size rounded up to the largest field alignment.
/// (Packed structs `<{ ... }>` are not produced by rustc for the value
/// types in scope and stay unsupported.)
fn aggLayout(allocator: std.mem.Allocator, ty_text: []const u8) !?AggLayout {
    const t = trim(ty_text);
    if (t.len < 2 or t[0] != '{' or t[t.len - 1] != '}') return null;
    var fields = std.array_list.Managed(AggField).init(allocator);
    errdefer fields.deinit();
    const inner = trim(t[1 .. t.len - 1]);
    if (inner.len == 0) return .{ .fields = fields, .size = 0, .@"align" = 1 };
    const field_texts = try splitTopLevelComma(allocator, inner);
    defer allocator.free(field_texts);
    var cur: u64 = 0;
    var max_align: u64 = 1;
    for (field_texts) |field_text| {
        const fty = trim(field_text);
        const fsize = typeBytes(fty) orelse return null;
        const falign = aggAlign(fty);
        const off = alignUp(cur, falign);
        try fields.append(.{ .ty = fty, .offset = off });
        cur = off + fsize;
        if (falign > max_align) max_align = falign;
    }
    return .{ .fields = fields, .size = alignUp(cur, max_align), .@"align" = max_align };
}

/// Walk a constant index path into an aggregate type: returns the byte
/// offset and the resulting (sub-)type.
fn walkAggPath(allocator: std.mem.Allocator, ty_text: []const u8, indices: []const u64) !?struct { offset: u64, ty: []const u8 } {
    var cur_ty = trim(ty_text);
    var off: u64 = 0;
    for (indices) |idx| {
        if (cur_ty.len > 0 and cur_ty[0] == '{') {
            var layout = (try aggLayout(allocator, cur_ty)) orelse return null;
            defer layout.fields.deinit();
            if (idx >= layout.fields.items.len) return null;
            const field = layout.fields.items[@intCast(idx)];
            off += field.offset;
            cur_ty = field.ty;
        } else if (cur_ty.len > 0 and cur_ty[0] == '[') {
            const body = trim(cur_ty[1 .. cur_ty.len - 1]);
            const x_idx = std.mem.indexOf(u8, body, " x ") orelse return null;
            const count = std.fmt.parseInt(u64, trim(body[0..x_idx]), 10) catch return null;
            if (idx >= count) return null;
            const elem = trim(body[x_idx + 3 ..]);
            const esize = typeBytes(elem) orelse return null;
            off += idx * esize;
            cur_ty = elem;
        } else {
            return null;
        }
    }
    return .{ .offset = off, .ty = cur_ty };
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

    // Constant expressions inttoptr/ptrtoint used as operands (the
    // empty-Vec dangling pointer `inttoptr (i64 8 to ptr)` is the probe
    // case): the cast is the identity on the operand value in SA's flat
    // register model, so reduce to the operand itself. The expression
    // may sit behind a type token (`ptr inttoptr (i64 8 to ptr)`).
    if (std.mem.indexOf(u8, value, "inttoptr (") != null or std.mem.indexOf(u8, value, "ptrtoint (") != null) {
        const start = std.mem.indexOf(u8, value, "inttoptr (") orelse std.mem.indexOf(u8, value, "ptrtoint (").?;
        const expr = value[start..];
        const open = std.mem.indexOfScalar(u8, expr, '(').?;
        const inner = expr[open + 1 ..];
        const to_idx = std.mem.lastIndexOf(u8, inner, " to ") orelse return error.UnsupportedInstruction;
        return saValue(allocator, inner[0..to_idx]);
    }
    value = llvmTypedValueToValue(value);

    if (value.len == 0) return error.InvalidIr;
    if (std.mem.startsWith(u8, value, "%")) return sanitizeIdent(allocator, value, "r");
    if (std.mem.startsWith(u8, value, "@")) {
        const name = try sanitizeIdent(allocator, value, "g_");
        defer allocator.free(name);
        return try std.fmt.allocPrint(allocator, "&{s}", .{name});
    }
    // `undef` is poison: any value is a legal refinement; 0 is the
    // canonical choice (phi incoming edges are the common case).
    if (std.mem.eql(u8, value, "null") or std.mem.eql(u8, value, "zeroinitializer") or std.mem.eql(u8, value, "undef")) return try allocator.dupe(u8, "0");
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
    // Aggregate-typed parameters are passed as a pointer to the value's
    // slot memory (see the aggregate slot model at appendExtractValue):
    // the SA parameter is the slot address, typed ptr.
    if (isAggType(fragment)) {
        var name_token2: ?[]const u8 = null;
        var parts2 = std.mem.tokenizeAny(u8, fragment, " \t\r\n");
        while (parts2.next()) |part| {
            if (std.mem.startsWith(u8, part, "%")) name_token2 = part;
        }
        const name2 = if (name_token2) |token|
            try sanitizeIdent(allocator, token, "arg")
        else
            try std.fmt.allocPrint(allocator, "arg{d}", .{index});
        return .{ .name = name2, .ty = "ptr" };
    }
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

/// If the header prefix (everything before the `@name`) ends with an
/// aggregate type, that aggregate is the return type.
fn aggRetFromPrefix(prefix: []const u8) ?[]const u8 {
    var i: usize = 0;
    var found: ?[]const u8 = null;
    while (i < prefix.len) : (i += 1) {
        if (prefix[i] == '{' or prefix[i] == '[') {
            if (parseTypeText(prefix[i..])) |parsed| {
                if (trim(parsed.rest).len == 0) found = parsed.ty;
            }
        }
    }
    return found;
}

fn appendFunctionHeader(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, line: []const u8, is_declare: bool) !void {
    const keyword = if (is_declare) "declare" else "define";
    if (!startsWithWord(line, keyword)) return error.InvalidIr;

    const at = std.mem.indexOfScalar(u8, line, '@') orelse return error.InvalidIr;
    const prefix = trim(line[keyword.len..at]);
    // Aggregate returns use the sret convention: the header gains a
    // hidden first parameter `bc2sa_sret: ptr` (address of the caller's
    // result slot) and the SA return type becomes void.
    const agg_ret = aggRetFromPrefix(prefix);
    const ret_ty: ?[]const u8 = if (agg_ret == null) try returnTypeFromPrefix(prefix) else null;

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
    if (agg_ret != null) {
        try out.appendSlice("bc2sa_sret: ptr");
        if (trim(line[open + 1 .. close]).len > 0) try out.appendSlice(", ");
    }
    try appendParamList(out, allocator, line[open + 1 .. close]);
    try out.append(')');
    if (ret_ty) |rt| {
        if (!std.mem.eql(u8, rt, "void")) {
            try listPrint(out, " -> {s}", .{rt});
        }
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
    const parsed = parseTypeText(rest) orelse return error.UnsupportedInstruction;
    const alloc_ty = parsed.ty;
    if (std.mem.indexOfScalar(u8, alloc_ty, '%') != null) return error.UnsupportedInstruction;
    const size = typeBytes(alloc_ty) orelse return error.UnsupportedInstruction;
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = stack_alloc {d}\n", .{ dst, size });
}

fn appendLoad(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8, ctx: *FnCtx) !void {
    const args = try splitTopLevelComma(allocator, rest);
    defer allocator.free(args);
    if (args.len < 2) return error.UnsupportedInstruction;

    if (isAggType(args[0])) {
        const parsed = parseTypeText(args[0]) orelse return error.UnsupportedInstruction;
        const size = typeBytes(parsed.ty) orelse return error.UnsupportedInstruction;
        const base = try saValue(allocator, args[1]);
        defer allocator.free(base);
        const slot = try aggSlotName(allocator, lhs);
        defer allocator.free(slot);
        try listPrint(out, "  {s} = stack_alloc {d}\n", .{ slot, size });
        try emitAggCopyAt(out, allocator, ctx, slot, base, parsed.ty);
        return;
    }

    const value_ty = firstTypeToken(args[0]) orelse return error.UnsupportedInstruction;
    const sa_ty = typeTokenToSa(value_ty) orelse return error.UnsupportedInstruction;
    const base = try saValue(allocator, args[1]);
    defer allocator.free(base);
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ dst, base, sa_ty });
}

fn appendStore(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, rest: []const u8, ctx: *FnCtx) !void {
    const args = try splitTopLevelComma(allocator, rest);
    defer allocator.free(args);
    if (args.len < 2) return error.UnsupportedInstruction;

    const parsed0 = parseTypeText(args[0]) orelse return error.UnsupportedInstruction;
    if (isAggType(parsed0.ty)) {
        const base = try saValue(allocator, args[1]);
        defer allocator.free(base);
        try emitAggValueTo(out, allocator, ctx, base, parsed0.rest, parsed0.ty);
        return;
    }

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

fn appendReturn(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, rest: []const u8, ctx: *FnCtx) !void {
    const t = trim(rest);
    if (std.mem.eql(u8, t, "void") or t.len == 0) {
        try out.appendSlice("  return\n");
        return;
    }
    if (ctx.agg_ret_ty) |agg_ty| {
        // sret: copy the returned aggregate into the caller's slot
        // address held in bc2sa_sret, then return void.
        const parsed = parseTypeText(t) orelse return error.UnsupportedInstruction;
        try emitAggValueTo(out, allocator, ctx, "bc2sa_sret", parsed.rest, agg_ty);
        try out.appendSlice("  return\n");
        return;
    }
    try out.appendSlice("  return ");
    try appendValue(out, allocator, t);
    try out.append('\n');
}

fn intTypeBits(ty_text: []const u8) ?u32 {
    const t = trim(ty_text);
    if (std.mem.eql(u8, t, "i1")) return 1;
    if (std.mem.eql(u8, t, "i8")) return 8;
    if (std.mem.eql(u8, t, "i16")) return 16;
    if (std.mem.eql(u8, t, "i32")) return 32;
    if (std.mem.eql(u8, t, "i64")) return 64;
    return null;
}

fn appendCast(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, op: []const u8, rest: []const u8) !void {
    const to_idx = std.mem.lastIndexOf(u8, rest, " to ") orelse return error.UnsupportedInstruction;
    const source = trim(rest[0..to_idx]);
    const dest_ty_text = trim(rest[to_idx + 4 ..]);
    const dest_ty_token = firstTypeToken(dest_ty_text) orelse return error.UnsupportedInstruction;
    const dest_ty = typeTokenToSa(dest_ty_token) orelse return error.UnsupportedInstruction;
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    // zext is defined by LLVM on the *source type width*: the result is
    // the low w bits of the source, zero-filled. SA registers are flat
    // 64-bit slots and a sub-word `load ... as i8` sign-extends into the
    // register, so a bare SA `zext` of that register propagates the sign
    // bits instead of masking (measured: fnv1a_stream diverges from the
    // native value at the first hashed byte >= 0x80; the sign-extended
    // variant reproduces the wrong result bit-for-bit). Lower zext to an
    // explicit mask, which is exact for every source-value producer.
    if (std.mem.eql(u8, op, "zext")) {
        const src_token = firstTypeToken(source) orelse return error.UnsupportedInstruction;
        const src_bits = intTypeBits(src_token) orelse return error.UnsupportedInstruction;
        const dst_bits = intTypeBits(dest_ty_token) orelse return error.UnsupportedInstruction;
        if (src_bits < dst_bits and src_bits < 64) {
            const mask: u64 = (@as(u64, 1) << @as(u6, @intCast(src_bits))) - 1;
            try listPrint(out, "  {s} = and ", .{dst});
            try appendValue(out, allocator, source);
            try listPrint(out, ", {d}\n", .{mask});
            return;
        }
    }
    // inttoptr/ptrtoint/addrspacecast are identity casts on SA's flat
    // register values; SA spells them as bitcast (mirrors sci's own
    // llvm2sa mapping).
    const sa_op = if (std.mem.eql(u8, op, "inttoptr") or std.mem.eql(u8, op, "ptrtoint") or std.mem.eql(u8, op, "addrspacecast")) "bitcast" else op;
    try listPrint(out, "  {s} = {s} ", .{ dst, sa_op });
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

/// Parse one LLVM type at the start of `text` (after trimming): a scalar
/// token, a `{ ... }` struct type, or a `[ N x T ]` array type. Returns the
/// type text and the remainder of the string.
fn parseTypeText(text: []const u8) ?struct { ty: []const u8, rest: []const u8 } {
    const t = trim(text);
    if (t.len == 0) return null;
    if (t[0] == '{') {
        const close = findMatching(t, 0, '{', '}') orelse return null;
        return .{ .ty = t[0 .. close + 1], .rest = trim(t[close + 1 ..]) };
    }
    if (t[0] == '[') {
        const close = findMatching(t, 0, '[', ']') orelse return null;
        return .{ .ty = t[0 .. close + 1], .rest = trim(t[close + 1 ..]) };
    }
    var end: usize = 0;
    while (end < t.len and !std.ascii.isWhitespace(t[end]) and t[end] != ',') : (end += 1) {}
    if (end == 0) return null;
    return .{ .ty = t[0..end], .rest = trim(t[end..]) };
}

fn isAggType(ty_text: []const u8) bool {
    const t = trim(ty_text);
    return t.len > 0 and (t[0] == '{' or t[0] == '[');
}

fn parsePhi(allocator: std.mem.Allocator, line: []const u8) !struct { lhs: []const u8, ty: []const u8, incoming: []const []const u8 } {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidIr;
    const lhs = trim(line[0..eq]);
    const rhs = trim(line[eq + 1 ..]);
    if (!std.mem.startsWith(u8, rhs, "phi ")) return error.UnsupportedPhi;
    const body = trim(rhs["phi ".len..]);
    const parsed = parseTypeText(body) orelse return error.UnsupportedPhi;
    const incoming = try splitTopLevelComma(allocator, parsed.rest);
    if (incoming.len == 0) {
        allocator.free(incoming);
        return error.UnsupportedPhi;
    }
    return .{ .lhs = lhs, .ty = parsed.ty, .incoming = incoming };
}

fn phiSlotName(allocator: std.mem.Allocator, lhs: []const u8) ![]u8 {
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    return try std.fmt.allocPrint(allocator, "bc2sa_phi_slot_{s}", .{dst});
}

fn phiValueSlotName(allocator: std.mem.Allocator, lhs: []const u8, ty: []const u8) ![]u8 {
    if (isAggType(ty)) return aggSlotName(allocator, lhs);
    return phiSlotName(allocator, lhs);
}

fn appendPhiSlots(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, phi_lines: []const []const u8) !void {
    for (phi_lines) |phi_line| {
        const phi = try parsePhi(allocator, phi_line);
        defer allocator.free(phi.incoming);
        const size = typeBytes(phi.ty) orelse return error.UnsupportedPhi;
        const slot = try phiValueSlotName(allocator, phi.lhs, phi.ty);
        defer allocator.free(slot);
        try listPrint(out, "  {s} = stack_alloc {d}\n", .{ slot, size });
    }
}

fn appendPhiLoad(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, line: []const u8) !void {
    const phi = try parsePhi(allocator, line);
    defer allocator.free(phi.incoming);
    // Aggregate phis live in their slot; there is no register to load.
    if (isAggType(phi.ty)) return;
    const sa_ty = typeTokenToSa(phi.ty) orelse return error.UnsupportedPhi;
    const dst = try sanitizeIdent(allocator, phi.lhs, "r");
    defer allocator.free(dst);
    const slot = try phiSlotName(allocator, phi.lhs);
    defer allocator.free(slot);
    try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ dst, slot, sa_ty });
}

fn appendPhiStoresForBlock(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx, phi_lines: []const []const u8, block: []const u8) !void {
    for (phi_lines) |phi_line| {
        const phi = try parsePhi(allocator, phi_line);
        defer allocator.free(phi.incoming);
        const agg = isAggType(phi.ty);
        const sa_ty: ?[]const u8 = if (agg) null else (typeTokenToSa(phi.ty) orelse return error.UnsupportedPhi);
        const slot = try phiValueSlotName(allocator, phi.lhs, phi.ty);
        defer allocator.free(slot);
        for (phi.incoming) |incoming_text| {
            const pair_text = trim(incoming_text);
            if (pair_text.len < 2 or pair_text[0] != '[' or pair_text[pair_text.len - 1] != ']') return error.UnsupportedPhi;
            const pair = try splitTopLevelComma(allocator, pair_text[1 .. pair_text.len - 1]);
            defer allocator.free(pair);
            if (pair.len != 2) return error.UnsupportedPhi;
            const incoming_block = stripLlvmSigil(llvmTypedValueToValue(pair[1]));
            if (!std.mem.eql(u8, trim(incoming_block), trim(block))) continue;
            if (agg) {
                try emitAggValueTo(out, allocator, ctx, slot, pair[0], phi.ty);
            } else {
                const value = try saValue(allocator, pair[0]);
                defer allocator.free(value);
                try listPrint(out, "  store {s}+0, {s} as {s}\n", .{ slot, value, sa_ty.? });
            }
        }
    }
}

/// Cross-block value analysis (probe REPORT.md, ruling 1).
///
/// The SA referee requires every computed register to be declared in the
/// block that uses it; only function parameters and `stack_alloc` slot
/// pointers are function-level. LLVM SSA values, however, are routinely
/// used in blocks other than their defining block — most importantly phi
/// incoming values stored on predecessor edges (M1: the value was defined
/// in an earlier, non-predecessor block) and phi results consumed by later
/// blocks (M2: a loop header phi loaded once and reused in the latch).
///
/// Strategy (chosen over full SSA slotting, which would rewrite every
/// definition and destabilize all existing lowerings): a value whose uses
/// span blocks gets a dedicated stack slot. Its definition, in its home
/// block, is followed by a store into the slot; every use in a foreign
/// block is preceded (once per block) by a reload that re-declares the
/// same register name from the slot in that block. In-block uses keep the
/// original register form untouched. Phi values reuse their existing phi
/// slot as the backing store.
const ValueDef = struct {
    ty: []const u8,
    home: []const u8,
    is_phi: bool,
};

const AggParam = struct {
    reg: []const u8,
    ty: []const u8,
    slot: []u8,
};

const FnCtx = struct {
    allocator: std.mem.Allocator,
    defs: std.StringHashMapUnmanaged(ValueDef) = .empty,
    cross: std.StringHashMapUnmanaged(bool) = .empty,
    reloaded: std.StringHashMapUnmanaged(bool) = .empty,
    current_block: []const u8 = "entry",
    agg_ret_ty: ?[]const u8 = null,
    tmp_counter: usize = 0,
    agg_params: [8]AggParam = undefined,
    agg_param_count: usize = 0,

    fn deinit(self: *FnCtx) void {
        self.defs.deinit(self.allocator);
        self.cross.deinit(self.allocator);
        self.reloaded.deinit(self.allocator);
        for (self.agg_params[0..self.agg_param_count]) |param| {
            self.allocator.free(param.slot);
            self.allocator.free(param.reg);
        }
    }

    fn freshTmp(self: *FnCtx) ![]u8 {
        self.tmp_counter += 1;
        return try std.fmt.allocPrint(self.allocator, "bc2sa_t{d}", .{self.tmp_counter});
    }

    fn slotName(self: *FnCtx, name: []const u8, def: ValueDef) ![]u8 {
        if (def.is_phi) return phiSlotName(self.allocator, name);
        const san = try sanitizeIdent(self.allocator, name, "r");
        defer self.allocator.free(san);
        return try std.fmt.allocPrint(self.allocator, "bc2sa_xslot_{s}", .{san});
    }

    fn isCross(self: *FnCtx, name: []const u8) bool {
        return self.cross.get(name) orelse false;
    }

    /// Emit a same-name reload for `name` in the current block if it is a
    /// cross-block value defined elsewhere and not yet reloaded here.
    fn emitReload(self: *FnCtx, out: *std.array_list.Managed(u8), name: []const u8) !void {
        if (!self.isCross(name)) return;
        const def = self.defs.get(name) orelse return;
        if (std.mem.eql(u8, def.home, self.current_block)) return;
        if (self.reloaded.get(name) orelse false) return;
        const sa_ty = typeTokenToSa(def.ty) orelse return;
        const slot = try self.slotName(name, def);
        defer self.allocator.free(slot);
        const san = try sanitizeIdent(self.allocator, name, "r");
        defer self.allocator.free(san);
        try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ san, slot, sa_ty });
        try self.reloaded.put(self.allocator, name, true);
    }

    fn emitReloadsForLine(self: *FnCtx, out: *std.array_list.Managed(u8), line: []const u8, skip_lhs: bool) !void {
        var names = std.array_list.Managed([]const u8).init(self.allocator);
        defer names.deinit();
        try scanValueNames(line, &names);
        const lhs = if (skip_lhs) defLhsName(line) else null;
        for (names.items) |name| {
            if (lhs) |l| {
                if (std.mem.eql(u8, l, name)) continue;
            }
            try self.emitReload(out, name);
        }
    }

    /// Phi incoming values for the current block are *uses in this block*
    /// (the edge store is emitted here), even when the value's home is a
    /// third block (M1). Reload them before the edge stores.
    fn emitReloadsForPhiIncoming(self: *FnCtx, out: *std.array_list.Managed(u8), phi_lines: []const []const u8) !void {
        for (phi_lines) |phi_line| {
            const phi = try parsePhi(self.allocator, phi_line);
            defer self.allocator.free(phi.incoming);
            for (phi.incoming) |incoming_text| {
                const pair_text = trim(incoming_text);
                if (pair_text.len < 2 or pair_text[0] != '[' or pair_text[pair_text.len - 1] != ']') continue;
                const pair = try splitTopLevelComma(self.allocator, pair_text[1 .. pair_text.len - 1]);
                defer self.allocator.free(pair);
                if (pair.len != 2) continue;
                const incoming_block = stripLlvmSigil(llvmTypedValueToValue(pair[1]));
                if (!std.mem.eql(u8, trim(incoming_block), trim(self.current_block))) continue;
                var names = std.array_list.Managed([]const u8).init(self.allocator);
                defer names.deinit();
                try scanValueNames(pair[0], &names);
                for (names.items) |name| try self.emitReload(out, name);
            }
        }
    }
};

/// Aggregate slot model: every LLVM aggregate-typed SSA value %x is
/// materialized in memory at the stack slot `bc2sa_agg_x`; operations
/// that produce or consume aggregates work field-by-field on that
/// memory. Aggregate function returns use an sret convention (hidden
/// first parameter `bc2sa_sret`), aggregate parameters are pointers to
/// the caller's slot memory. This mirrors how the translator already
/// lowers phi values into slots and keeps SA's flat register model.
fn aggSlotName(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const san = try sanitizeIdent(allocator, name, "r");
    defer allocator.free(san);
    return try std.fmt.allocPrint(allocator, "bc2sa_agg_{s}", .{san});
}

/// Returns a register holding `base + offset` (a fresh temp), or a copy
/// of `base` itself when offset is 0. Caller frees the result.
fn ptrAt(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx, base: []const u8, offset: u64) ![]u8 {
    if (offset == 0) return try allocator.dupe(u8, base);
    const tmp = try ctx.freshTmp();
    try listPrint(out, "  {s} = ptr_add {s}, {d}\n", .{ tmp, base, offset });
    return tmp;
}

fn emitAggLeafCopy(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx, dst_base: []const u8, src_base: []const u8, ty_text: []const u8) !void {
    const sa_ty = typeTokenToSa(ty_text) orelse return error.UnsupportedInstruction;
    const v = try ctx.freshTmp();
    defer allocator.free(v);
    try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ v, src_base, sa_ty });
    try listPrint(out, "  store {s}+0, {s} as {s}\n", .{ dst_base, v, sa_ty });
}

/// Field-wise copy of an aggregate value held in memory.
fn emitAggCopyAt(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx, dst_base: []const u8, src_base: []const u8, ty_text: []const u8) !void {
    const t = trim(ty_text);
    if (!isAggType(t)) {
        try emitAggLeafCopy(out, allocator, ctx, dst_base, src_base, t);
        return;
    }
    if (t[0] == '{') {
        var layout = (try aggLayout(allocator, t)) orelse return error.UnsupportedInstruction;
        defer layout.fields.deinit();
        for (layout.fields.items) |field| {
            const dptr = try ptrAt(out, allocator, ctx, dst_base, field.offset);
            defer allocator.free(dptr);
            const sptr = try ptrAt(out, allocator, ctx, src_base, field.offset);
            defer allocator.free(sptr);
            try emitAggCopyAt(out, allocator, ctx, dptr, sptr, field.ty);
        }
        return;
    }
    // [ N x T ]
    const body = trim(t[1 .. t.len - 1]);
    const x_idx = std.mem.indexOf(u8, body, " x ") orelse return error.UnsupportedInstruction;
    const count = std.fmt.parseInt(u64, trim(body[0..x_idx]), 10) catch return error.UnsupportedInstruction;
    const elem = trim(body[x_idx + 3 ..]);
    const esize = typeBytes(elem) orelse return error.UnsupportedInstruction;
    var i: u64 = 0;
    while (i < count) : (i += 1) {
        const dptr = try ptrAt(out, allocator, ctx, dst_base, i * esize);
        defer allocator.free(dptr);
        const sptr = try ptrAt(out, allocator, ctx, src_base, i * esize);
        defer allocator.free(sptr);
        try emitAggCopyAt(out, allocator, ctx, dptr, sptr, elem);
    }
}

fn emitAggZeroAt(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx, base: []const u8, ty_text: []const u8) !void {
    const t = trim(ty_text);
    if (!isAggType(t)) {
        const sa_ty = typeTokenToSa(t) orelse return error.UnsupportedInstruction;
        try listPrint(out, "  store {s}+0, 0 as {s}\n", .{ base, sa_ty });
        return;
    }
    if (t[0] == '{') {
        var layout = (try aggLayout(allocator, t)) orelse return error.UnsupportedInstruction;
        defer layout.fields.deinit();
        for (layout.fields.items) |field| {
            const ptr = try ptrAt(out, allocator, ctx, base, field.offset);
            defer allocator.free(ptr);
            try emitAggZeroAt(out, allocator, ctx, ptr, field.ty);
        }
        return;
    }
    const body = trim(t[1 .. t.len - 1]);
    const x_idx = std.mem.indexOf(u8, body, " x ") orelse return error.UnsupportedInstruction;
    const count = std.fmt.parseInt(u64, trim(body[0..x_idx]), 10) catch return error.UnsupportedInstruction;
    const elem = trim(body[x_idx + 3 ..]);
    const esize = typeBytes(elem) orelse return error.UnsupportedInstruction;
    var i: u64 = 0;
    while (i < count) : (i += 1) {
        const ptr = try ptrAt(out, allocator, ctx, base, i * esize);
        defer allocator.free(ptr);
        try emitAggZeroAt(out, allocator, ctx, ptr, elem);
    }
}

/// An aggregate constant may be printed bare (`{ i64 1, i1 true }`) or,
/// for nested arrays, prefixed by its type (`[4 x i8] [i8 1, ...]`).
/// Returns the bare constant body.
fn stripAggConstTypePrefix(const_text: []const u8) []const u8 {
    const ct = trim(const_text);
    if (ct.len > 0 and (ct[0] == '[' or ct[0] == '%')) {
        if (parseTypeText(ct)) |parsed| {
            const rest = trim(parsed.rest);
            if (rest.len > 0 and (rest[0] == '{' or rest[0] == '[')) return rest;
        }
    }
    return ct;
}

fn emitAggConstInitAt(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx, base: []const u8, const_text: []const u8, ty_text: []const u8) !void {
    const t = trim(ty_text);
    const ct = stripAggConstTypePrefix(const_text);
    if (std.mem.eql(u8, ct, "zeroinitializer")) {
        try emitAggZeroAt(out, allocator, ctx, base, t);
        return;
    }
    if (std.mem.eql(u8, ct, "undef")) return;
    if (!isAggType(t)) {
        const sa_ty = typeTokenToSa(t) orelse return error.UnsupportedInstruction;
        const value = try saValue(allocator, ct);
        defer allocator.free(value);
        try listPrint(out, "  store {s}+0, {s} as {s}\n", .{ base, value, sa_ty });
        return;
    }
    if (ct.len < 2 or (ct[0] != '{' and ct[0] != '[')) return error.UnsupportedInstruction;
    const open_ch: u8 = ct[0];
    const close_ch: u8 = if (open_ch == '{') '}' else ']';
    const close = findMatching(ct, 0, open_ch, close_ch) orelse return error.UnsupportedInstruction;
    const inner = trim(ct[1..close]);
    const field_texts = try splitTopLevelComma(allocator, inner);
    defer allocator.free(field_texts);
    if (t[0] == '{') {
        var layout = (try aggLayout(allocator, t)) orelse return error.UnsupportedInstruction;
        defer layout.fields.deinit();
        if (field_texts.len != layout.fields.items.len) return error.UnsupportedInstruction;
        for (layout.fields.items, field_texts) |field, ftext| {
            const ptr = try ptrAt(out, allocator, ctx, base, field.offset);
            defer allocator.free(ptr);
            try emitAggConstInitAt(out, allocator, ctx, ptr, ftext, field.ty);
        }
        return;
    }
    const body = trim(t[1 .. t.len - 1]);
    const x_idx = std.mem.indexOf(u8, body, " x ") orelse return error.UnsupportedInstruction;
    const count = std.fmt.parseInt(u64, trim(body[0..x_idx]), 10) catch return error.UnsupportedInstruction;
    const elem = trim(body[x_idx + 3 ..]);
    const esize = typeBytes(elem) orelse return error.UnsupportedInstruction;
    if (field_texts.len != count) return error.UnsupportedInstruction;
    for (field_texts, 0..) |ftext, i| {
        const ptr = try ptrAt(out, allocator, ctx, base, @as(u64, @intCast(i)) * esize);
        defer allocator.free(ptr);
        try emitAggConstInitAt(out, allocator, ctx, ptr, ftext, elem);
    }
}

/// Materialize an aggregate value (register slot / zero / constant) into
/// the memory at `dst_base`.
fn emitAggValueTo(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx, dst_base: []const u8, value_text: []const u8, ty_text: []const u8) !void {
    const v = trim(value_text);
    if (std.mem.startsWith(u8, v, "%")) {
        const slot = try aggSlotName(allocator, v);
        defer allocator.free(slot);
        try emitAggCopyAt(out, allocator, ctx, dst_base, slot, ty_text);
        return;
    }
    if (std.mem.startsWith(u8, v, "@")) {
        const base = try saValue(allocator, v);
        defer allocator.free(base);
        try emitAggCopyAt(out, allocator, ctx, dst_base, base, ty_text);
        return;
    }
    if (std.mem.eql(u8, v, "zeroinitializer")) {
        try emitAggZeroAt(out, allocator, ctx, dst_base, ty_text);
        return;
    }
    if (std.mem.eql(u8, v, "undef")) return;
    try emitAggConstInitAt(out, allocator, ctx, dst_base, v, ty_text);
}

fn parseIndexList(allocator: std.mem.Allocator, texts: []const []const u8) ![]u64 {
    const indices = try allocator.alloc(u64, texts.len);
    errdefer allocator.free(indices);
    for (texts, 0..) |text, i| {
        indices[i] = std.fmt.parseInt(u64, trim(text), 10) catch return error.UnsupportedInstruction;
    }
    return indices;
}

fn appendExtractValue(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8, ctx: *FnCtx) !void {
    const parsed = parseTypeText(rest) orelse return error.UnsupportedInstruction;
    if (!isAggType(parsed.ty)) return error.UnsupportedInstruction;
    const parts = try splitTopLevelComma(allocator, parsed.rest);
    defer allocator.free(parts);
    if (parts.len < 2) return error.UnsupportedInstruction;
    const indices = try parseIndexList(allocator, parts[1..]);
    defer allocator.free(indices);
    const walked = (try walkAggPath(allocator, parsed.ty, indices)) orelse return error.UnsupportedInstruction;
    const source = trim(parts[0]);

    if (isAggType(walked.ty)) {
        const size = typeBytes(walked.ty) orelse return error.UnsupportedInstruction;
        const dst_slot = try aggSlotName(allocator, lhs);
        defer allocator.free(dst_slot);
        try listPrint(out, "  {s} = stack_alloc {d}\n", .{ dst_slot, size });
        if (std.mem.startsWith(u8, source, "%") or std.mem.startsWith(u8, source, "@")) {
            const src_base = if (std.mem.startsWith(u8, source, "%")) try aggSlotName(allocator, source) else try saValue(allocator, source);
            defer allocator.free(src_base);
            const sptr = try ptrAt(out, allocator, ctx, src_base, walked.offset);
            defer allocator.free(sptr);
            try emitAggCopyAt(out, allocator, ctx, dst_slot, sptr, walked.ty);
        } else if (std.mem.eql(u8, source, "zeroinitializer")) {
            try emitAggZeroAt(out, allocator, ctx, dst_slot, walked.ty);
        } else if (std.mem.eql(u8, source, "undef")) {
            // poison: leave the fresh slot unwritten
        } else {
            const sub = try walkConstText(allocator, source, parsed.ty, indices);
            defer allocator.free(sub);
            try emitAggConstInitAt(out, allocator, ctx, dst_slot, sub, walked.ty);
        }
        return;
    }

    // leaf result
    const sa_ty = typeTokenToSa(walked.ty) orelse return error.UnsupportedInstruction;
    const dst = try sanitizeIdent(allocator, lhs, "r");
    defer allocator.free(dst);
    if (std.mem.startsWith(u8, source, "%") or std.mem.startsWith(u8, source, "@")) {
        const src_base = if (std.mem.startsWith(u8, source, "%")) try aggSlotName(allocator, source) else try saValue(allocator, source);
        defer allocator.free(src_base);
        const sptr = try ptrAt(out, allocator, ctx, src_base, walked.offset);
        defer allocator.free(sptr);
        try listPrint(out, "  {s} = load {s}+0 as {s}\n", .{ dst, sptr, sa_ty });
        return;
    }
    if (std.mem.eql(u8, source, "zeroinitializer") or std.mem.eql(u8, source, "undef")) {
        try listPrint(out, "  {s} = add 0, 0\n", .{dst});
        return;
    }
    // constant aggregate source: walk the constant text to the leaf
    const leaf_const = try walkConstText(allocator, source, parsed.ty, indices);
    defer allocator.free(leaf_const);
    const value = try saValue(allocator, leaf_const);
    defer allocator.free(value);
    try listPrint(out, "  {s} = add {s}, 0\n", .{ dst, value });
}

/// Walk a constant aggregate's text along a constant index path;
/// returns the sub-constant text at the path (a fresh copy).
fn walkConstText(allocator: std.mem.Allocator, source: []const u8, agg_ty: []const u8, indices: []const u64) ![]u8 {
    var cur_const = try allocator.dupe(u8, stripAggConstTypePrefix(source));
    errdefer allocator.free(cur_const);
    var cur_ty = agg_ty;
    for (indices) |idx| {
        const body = stripAggConstTypePrefix(cur_const);
        if (body.len < 2 or (body[0] != '{' and body[0] != '[')) return error.UnsupportedInstruction;
        const close = findMatching(body, 0, body[0], if (body[0] == '{') '}' else ']') orelse return error.UnsupportedInstruction;
        const field_texts = try splitTopLevelComma(allocator, trim(body[1..close]));
        defer allocator.free(field_texts);
        if (idx >= field_texts.len) return error.UnsupportedInstruction;
        const next = try allocator.dupe(u8, trim(field_texts[@intCast(idx)]));
        allocator.free(cur_const);
        cur_const = next;
        if (cur_ty[0] == '{') {
            var layout = (try aggLayout(allocator, cur_ty)) orelse return error.UnsupportedInstruction;
            defer layout.fields.deinit();
            cur_ty = layout.fields.items[@intCast(idx)].ty;
        } else {
            const arr_body = trim(cur_ty[1 .. cur_ty.len - 1]);
            const x_idx = std.mem.indexOf(u8, arr_body, " x ") orelse return error.UnsupportedInstruction;
            cur_ty = trim(arr_body[x_idx + 3 ..]);
        }
    }
    return cur_const;
}

fn appendInsertValue(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rest: []const u8, ctx: *FnCtx) !void {
    const parsed = parseTypeText(rest) orelse return error.UnsupportedInstruction;
    if (!isAggType(parsed.ty)) return error.UnsupportedInstruction;
    const parts = try splitTopLevelComma(allocator, parsed.rest);
    defer allocator.free(parts);
    if (parts.len < 3) return error.UnsupportedInstruction;
    const indices = try parseIndexList(allocator, parts[2..]);
    defer allocator.free(indices);
    const walked = (try walkAggPath(allocator, parsed.ty, indices)) orelse return error.UnsupportedInstruction;

    const size = typeBytes(parsed.ty) orelse return error.UnsupportedInstruction;
    const dst_slot = try aggSlotName(allocator, lhs);
    defer allocator.free(dst_slot);
    try listPrint(out, "  {s} = stack_alloc {d}\n", .{ dst_slot, size });
    try emitAggValueTo(out, allocator, ctx, dst_slot, trim(parts[0]), parsed.ty);

    const elem_parsed = parseTypeText(parts[1]) orelse return error.UnsupportedInstruction;
    const dptr = try ptrAt(out, allocator, ctx, dst_slot, walked.offset);
    defer allocator.free(dptr);
    if (isAggType(walked.ty)) {
        try emitAggValueTo(out, allocator, ctx, dptr, elem_parsed.rest, walked.ty);
    } else {
        const sa_ty = typeTokenToSa(walked.ty) orelse return error.UnsupportedInstruction;
        const value = try saValue(allocator, parts[1]);
        defer allocator.free(value);
        try listPrint(out, "  store {s}+0, {s} as {s}\n", .{ dptr, value, sa_ty });
    }
}

fn defLhsName(line: []const u8) ?[]const u8 {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return null;
    const lhs = trim(line[0..eq]);
    if (lhs.len < 2 or lhs[0] != '%') return null;
    if (std.mem.indexOfAny(u8, lhs, " \t") != null) return null;
    return stripLlvmSigil(lhs);
}

/// Collect `%name` value references in a line fragment. Names may contain
/// letters, digits, '.', '$', '-', '_' (LLVM unquoted identifiers).
fn scanValueNames(text: []const u8, names: *std.array_list.Managed([]const u8)) !void {
    var i: usize = 0;
    while (i < text.len) {
        if (text[i] != '%') {
            i += 1;
            continue;
        }
        var j = i + 1;
        while (j < text.len and (isIdentChar(text[j]) or text[j] == '.' or text[j] == '$' or text[j] == '-')) : (j += 1) {}
        if (j > i + 1) try names.append(text[i + 1 .. j]);
        i = @max(j, i + 1);
    }
}

/// Best-effort LLVM result type text for a definition line; null when the
/// shape is not one we can slot (aggregates are handled by the aggregate
/// slot machinery, not the cross-block slots).
fn resultTypeOfDef(allocator: std.mem.Allocator, line: []const u8) !?[]const u8 {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return null;
    const rhs = trim(line[eq + 1 ..]);
    var words = std.mem.tokenizeAny(u8, rhs, " \t\r\n");
    const op = words.next() orelse return null;
    const rest_start = std.mem.indexOf(u8, rhs, op) orelse return null;
    const rest = trim(rhs[rest_start + op.len ..]);

    if (std.mem.eql(u8, op, "phi")) {
        const phi = try parsePhi(allocator, line);
        defer allocator.free(phi.incoming);
        return phi.ty;
    }
    if (std.mem.eql(u8, op, "icmp") or std.mem.eql(u8, op, "fcmp")) return "i1";
    if (std.mem.eql(u8, op, "alloca") or std.mem.eql(u8, op, "getelementptr")) return "ptr";
    if (std.mem.eql(u8, op, "select")) {
        const args = try splitTopLevelComma(allocator, rest);
        defer allocator.free(args);
        if (args.len != 3) return null;
        const parsed = parseTypeText(args[1]) orelse return null;
        return parsed.ty;
    }
    if (std.mem.eql(u8, op, "call") or std.mem.indexOf(u8, rhs, " call ") != null) {
        const call_idx = std.mem.indexOf(u8, rhs, "call ") orelse return null;
        const call_text = trim(rhs[call_idx + "call ".len ..]);
        const at = std.mem.indexOfScalar(u8, call_text, '@') orelse return null;
        const prefix = trim(call_text[0..at]);
        if (std.mem.indexOfScalar(u8, prefix, '{')) |brace| {
            const parsed = parseTypeText(prefix[brace..]) orelse return null;
            return parsed.ty;
        }
        var last: ?[]const u8 = null;
        var parts = std.mem.tokenizeAny(u8, prefix, " \t\r\n");
        while (parts.next()) |part| {
            if (typeTokenToSa(part) != null) last = part;
        }
        return last;
    }
    if (std.mem.eql(u8, op, "extractvalue")) {
        const parsed = parseTypeText(rest) orelse return null;
        const parts = try splitTopLevelComma(allocator, parsed.rest);
        defer allocator.free(parts);
        if (parts.len < 2) return null;
        const indices = try allocator.alloc(u64, parts.len - 1);
        defer allocator.free(indices);
        for (parts[1..], 0..) |text, i| {
            indices[i] = std.fmt.parseInt(u64, trim(text), 10) catch return null;
        }
        const walked = (try walkAggPath(allocator, parsed.ty, indices)) orelse return null;
        return walked.ty;
    }
    if (std.mem.eql(u8, op, "insertvalue")) {
        const parsed = parseTypeText(rest) orelse return null;
        return parsed.ty;
    }
    const is_cast = std.mem.eql(u8, op, "trunc") or std.mem.eql(u8, op, "zext") or std.mem.eql(u8, op, "sext") or std.mem.eql(u8, op, "bitcast") or std.mem.eql(u8, op, "inttoptr") or std.mem.eql(u8, op, "ptrtoint") or std.mem.eql(u8, op, "fptosi") or std.mem.eql(u8, op, "fptoui") or std.mem.eql(u8, op, "sitofp") or std.mem.eql(u8, op, "uitofp");
    if (is_cast) {
        const to_idx = std.mem.lastIndexOf(u8, rest, " to ") orelse return null;
        const parsed = parseTypeText(rest[to_idx + 4 ..]) orelse return null;
        return parsed.ty;
    }
    const body = if (llvmBinaryOpToSa(op) != null) skipOverflowFlags(rest) else rest;
    const parsed = parseTypeText(body) orelse return null;
    return parsed.ty;
}

/// Two-pass analysis: record every SSA definition (name -> type, home
/// block), then mark definitions whose uses span foreign blocks as
/// cross-block (slot-backed). Phi incoming values count as uses in the
/// named predecessor block.
fn analyzeCrossBlockValues(ctx: *FnCtx, body: []const []const u8) !void {
    const allocator = ctx.allocator;
    var block: []const u8 = "entry";
    for (body) |raw_line| {
        const line = trim(raw_line);
        if (line.len == 0) continue;
        if (std.mem.endsWith(u8, line, ":")) {
            block = line[0 .. line.len - 1];
            continue;
        }
        const name = defLhsName(line) orelse continue;
        // alloca results are stack_alloc slot pointers: function-level by
        // SA's own rules, already legal in every block. Slotting them
        // would *redefine* the pointer register in foreign blocks and
        // trap RegisterRedefinition (fnv1a_stream's %buf, probe M2 case).
        {
            const eq = std.mem.indexOfScalar(u8, line, '=') orelse continue;
            var rhs_words = std.mem.tokenizeAny(u8, trim(line[eq + 1 ..]), " \t\r\n");
            if (rhs_words.next()) |op| {
                if (std.mem.eql(u8, op, "alloca")) continue;
            }
        }
        const ty = (try resultTypeOfDef(allocator, line)) orelse continue;
        if (isAggType(ty)) continue;
        if (typeBytes(ty) == null or typeTokenToSa(ty) == null) continue;
        try ctx.defs.put(allocator, name, .{ .ty = ty, .home = block, .is_phi = isPhiInstruction(line) });
    }

    block = "entry";
    for (body) |raw_line| {
        const line = trim(raw_line);
        if (line.len == 0) continue;
        if (std.mem.endsWith(u8, line, ":")) {
            block = line[0 .. line.len - 1];
            continue;
        }
        if (isPhiInstruction(line)) {
            const phi = try parsePhi(allocator, line);
            defer allocator.free(phi.incoming);
            for (phi.incoming) |incoming_text| {
                const pair_text = trim(incoming_text);
                if (pair_text.len < 2 or pair_text[0] != '[' or pair_text[pair_text.len - 1] != ']') continue;
                const pair = try splitTopLevelComma(allocator, pair_text[1 .. pair_text.len - 1]);
                defer allocator.free(pair);
                if (pair.len != 2) continue;
                const pred = trim(stripLlvmSigil(llvmTypedValueToValue(pair[1])));
                var names = std.array_list.Managed([]const u8).init(allocator);
                defer names.deinit();
                try scanValueNames(pair[0], &names);
                for (names.items) |name| try markUse(ctx, name, pred);
            }
            continue;
        }
        var names = std.array_list.Managed([]const u8).init(allocator);
        defer names.deinit();
        try scanValueNames(line, &names);
        const lhs = defLhsName(line);
        for (names.items) |name| {
            if (lhs) |l| {
                if (std.mem.eql(u8, l, name)) continue;
            }
            try markUse(ctx, name, block);
        }
    }
}

fn markUse(ctx: *FnCtx, name: []const u8, use_block: []const u8) !void {
    const def = ctx.defs.get(name) orelse return;
    if (!std.mem.eql(u8, def.home, use_block)) {
        try ctx.cross.put(ctx.allocator, name, true);
    }
}

fn appendCrossBlockSlots(out: *std.array_list.Managed(u8), ctx: *FnCtx) !void {
    var it = ctx.cross.keyIterator();
    while (it.next()) |key| {
        const name = key.*;
        const def = ctx.defs.get(name) orelse continue;
        if (def.is_phi) continue; // phi values already own a phi slot
        const size = typeBytes(def.ty) orelse continue;
        const slot = try ctx.slotName(name, def);
        defer ctx.allocator.free(slot);
        try listPrint(out, "  {s} = stack_alloc {d}\n", .{ slot, size });
    }
}

/// Copy each aggregate parameter's incoming memory (the parameter
/// register holds its address) into the parameter's own agg slot.
fn appendAggParamPrologue(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, ctx: *FnCtx) !void {
    for (ctx.agg_params[0..ctx.agg_param_count]) |param| {
        const size = typeBytes(param.ty) orelse return error.UnsupportedInstruction;
        try listPrint(out, "  {s} = stack_alloc {d}\n", .{ param.slot, size });
        try emitAggCopyAt(out, allocator, ctx, param.slot, param.reg, param.ty);
    }
}

fn appendFunctionBody(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, header: []const u8, body: []const []const u8) !void {
    try appendFunctionHeader(out, allocator, header, false);

    var phi_lines = std.array_list.Managed([]const u8).init(allocator);
    defer phi_lines.deinit();
    for (body) |line| if (isPhiInstruction(line)) try phi_lines.append(line);

    var ctx = FnCtx{ .allocator = allocator };
    defer ctx.deinit();
    try analyzeCrossBlockValues(&ctx, body);

    // Aggregate return type (sret header was already emitted by
    // appendFunctionHeader) and aggregate parameters: each agg param
    // arrives as a pointer to caller memory; the prologue copies it
    // into the parameter's own agg slot, from which body code reads.
    if (std.mem.indexOfScalar(u8, header, '@')) |at_idx| {
        ctx.agg_ret_ty = aggRetFromPrefix(trim(header["define".len..at_idx]));
        const open = std.mem.indexOfScalar(u8, header, '(') orelse return error.InvalidIr;
        const close = findMatching(header, open, '(', ')') orelse return error.InvalidIr;
        const params = try splitTopLevelComma(allocator, header[open + 1 .. close]);
        defer allocator.free(params);
        for (params, 0..) |param_text, pidx| {
            const parsed = parseTypeText(param_text) orelse continue;
            if (!isAggType(parsed.ty)) continue;
            if (ctx.agg_param_count >= ctx.agg_params.len) return error.UnsupportedInstruction;
            var name_token: ?[]const u8 = null;
            var tokens = std.mem.tokenizeAny(u8, parsed.rest, " \t\r\n");
            while (tokens.next()) |token| {
                if (std.mem.startsWith(u8, token, "%")) name_token = token;
            }
            const reg = if (name_token) |token| try sanitizeIdent(allocator, token, "arg") else try std.fmt.allocPrint(allocator, "arg{d}", .{pidx});
            defer allocator.free(reg);
            const slot = try aggSlotName(allocator, name_token orelse reg);
            ctx.agg_params[ctx.agg_param_count] = .{ .reg = try allocator.dupe(u8, reg), .ty = parsed.ty, .slot = slot };
            ctx.agg_param_count += 1;
        }
    }

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
                try ctx.emitReloadsForPhiIncoming(out, phi_lines.items);
                try appendPhiStoresForBlock(out, allocator, &ctx, phi_lines.items, current_block);
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
            ctx.current_block = current_block;
            ctx.reloaded.clearRetainingCapacity();
            need_entry_label = false;
            if (!phi_slots_emitted) {
                try appendPhiSlots(out, allocator, phi_lines.items);
                try appendCrossBlockSlots(out, &ctx);
                try appendAggParamPrologue(out, allocator, &ctx);
                phi_slots_emitted = true;
            }
            continue;
        }
        if (need_entry_label) {
            try out.appendSlice("L_ENTRY:\n");
            try appendPhiSlots(out, allocator, phi_lines.items);
            try appendCrossBlockSlots(out, &ctx);
            try appendAggParamPrologue(out, allocator, &ctx);
            phi_slots_emitted = true;
            need_entry_label = false;
        }
        if (startsWithWord(line, "switch")) {
            try ctx.emitReloadsForLine(out, line, false);
            switch_text.clearRetainingCapacity();
            try switch_text.appendSlice(line);
            try switch_text.append('\n');
            if (std.mem.indexOfScalar(u8, line, ']') != null) {
                try ctx.emitReloadsForPhiIncoming(out, phi_lines.items);
                try appendPhiStoresForBlock(out, allocator, &ctx, phi_lines.items, current_block);
                try appendSwitch(out, allocator, switch_text.items, switch_id);
                switch_id += 1;
                switch_text.clearRetainingCapacity();
            } else {
                pending_switch = true;
            }
            continue;
        }
        if (startsWithWord(line, "br") or startsWithWord(line, "ret")) {
            try ctx.emitReloadsForPhiIncoming(out, phi_lines.items);
            try ctx.emitReloadsForLine(out, line, false);
            try appendPhiStoresForBlock(out, allocator, &ctx, phi_lines.items, current_block);
        } else if (!isPhiInstruction(line)) {
            try ctx.emitReloadsForLine(out, line, true);
        }
        if (isPhiInstruction(line)) {
            try appendPhiLoad(out, allocator, line);
        } else {
            try appendInstruction(out, allocator, line, &ctx);
        }
        // A cross-block definition is complete: publish it to its slot so
        // foreign blocks can reload it. (Phi loads already read their slot.)
        if (!isPhiInstruction(line)) {
            if (defLhsName(line)) |name| {
                if (ctx.isCross(name)) {
                    if (ctx.defs.get(name)) |def| {
                        if (std.mem.eql(u8, def.home, current_block)) {
                            const sa_ty = typeTokenToSa(def.ty) orelse return error.UnsupportedInstruction;
                            const slot = try ctx.slotName(name, def);
                            defer allocator.free(slot);
                            const san = try sanitizeIdent(allocator, name, "r");
                            defer allocator.free(san);
                            try listPrint(out, "  store {s}+0, {s} as {s}\n", .{ slot, san, sa_ty });
                        }
                    }
                }
            }
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

fn appendCallArg(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, arg: []const u8) !void {
    // An aggregate-typed argument is passed as the address of its slot.
    if (parseTypeText(arg)) |parsed| {
        if (isAggType(parsed.ty)) {
            const value = trim(parsed.rest);
            if (!std.mem.startsWith(u8, value, "%")) return error.UnsupportedInstruction;
            // attribute words may precede the value; the value is the
            // last whitespace-separated token
            const name = llvmTypedValueToValue(value);
            const slot = try aggSlotName(allocator, name);
            defer allocator.free(slot);
            try out.appendSlice(slot);
            return;
        }
    }
    try appendValue(out, allocator, arg);
}

fn appendCall(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: ?[]const u8, rest: []const u8, ctx: *FnCtx) !void {
    const call_idx = std.mem.indexOf(u8, rest, "call ") orelse return error.UnsupportedInstruction;
    const call_text = trim(rest[call_idx + "call ".len ..]);
    const at = std.mem.indexOfScalar(u8, call_text, '@') orelse return error.UnsupportedInstruction;
    const open_rel = std.mem.indexOfScalar(u8, call_text[at..], '(') orelse return error.InvalidIr;
    const open = at + open_rel;
    const close = findMatching(call_text, open, '(', ')') orelse return error.InvalidIr;
    const raw_callee = call_text[at..open];
    const callee = try sanitizeIdent(allocator, raw_callee, "fn_");
    defer allocator.free(callee);

    const args = try splitTopLevelComma(allocator, call_text[open + 1 .. close]);
    defer allocator.free(args);

    // Aggregate return: the caller allocates the result slot and passes
    // its address as the hidden first (sret) argument.
    if (aggRetFromPrefix(trim(call_text[0..at]))) |agg_ty| {
        const size = typeBytes(agg_ty) orelse return error.UnsupportedInstruction;
        const slot = if (lhs) |lhs_text| try aggSlotName(allocator, lhs_text) else try ctx.freshTmp();
        defer allocator.free(slot);
        try listPrint(out, "  {s} = stack_alloc {d}\n", .{ slot, size });
        try listPrint(out, "  call @{s}({s}", .{ callee, slot });
        for (args) |arg| {
            try out.appendSlice(", ");
            try appendCallArg(out, allocator, arg);
        }
        try out.appendSlice(")\n");
        return;
    }

    if (lhs) |lhs_text| {
        const dst = try sanitizeIdent(allocator, lhs_text, "r");
        defer allocator.free(dst);
        try listPrint(out, "  {s} = call @{s}(", .{ dst, callee });
    } else {
        try listPrint(out, "  call @{s}(", .{callee});
    }

    for (args, 0..) |arg, idx| {
        if (idx != 0) try out.appendSlice(", ");
        try appendCallArg(out, allocator, arg);
    }
    try out.appendSlice(")\n");
}

fn appendAssignmentInstruction(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, lhs: []const u8, rhs: []const u8, ctx: *FnCtx) !void {
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
    if (std.mem.eql(u8, op, "load")) return appendLoad(out, allocator, lhs, rest, ctx);
    if (std.mem.eql(u8, op, "getelementptr")) return appendGetElementPtr(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "select")) return appendSelect(out, allocator, lhs, rest);
    if (std.mem.eql(u8, op, "extractvalue")) return appendExtractValue(out, allocator, lhs, rest, ctx);
    if (std.mem.eql(u8, op, "insertvalue")) return appendInsertValue(out, allocator, lhs, rest, ctx);
    if (std.mem.eql(u8, op, "call") or std.mem.indexOf(u8, rhs, " call ") != null) return appendCall(out, allocator, lhs, rhs, ctx);
    if (std.mem.eql(u8, op, "trunc") or std.mem.eql(u8, op, "zext") or std.mem.eql(u8, op, "sext") or std.mem.eql(u8, op, "bitcast") or std.mem.eql(u8, op, "inttoptr") or std.mem.eql(u8, op, "ptrtoint") or std.mem.eql(u8, op, "addrspacecast")) {
        return appendCast(out, allocator, lhs, op, rest);
    }

    return error.UnsupportedInstruction;
}

fn appendInstruction(out: *std.array_list.Managed(u8), allocator: std.mem.Allocator, line: []const u8, ctx: *FnCtx) !void {
    const cleaned = cleanInstructionLine(line);
    const t = trim(cleaned);
    if (t.len == 0) return;

    if (std.mem.indexOfScalar(u8, t, '=')) |eq_idx| {
        const lhs = trim(t[0..eq_idx]);
        const rhs = trim(t[eq_idx + 1 ..]);
        return appendAssignmentInstruction(out, allocator, lhs, rhs, ctx);
    }

    if (startsWithWord(t, "ret")) return appendReturn(out, allocator, t["ret".len..], ctx);
    if (startsWithWord(t, "br")) return appendBranch(out, allocator, t["br".len..]);
    if (startsWithWord(t, "store")) return appendStore(out, allocator, t["store".len..], ctx);
    // LLVM `unreachable` is a trap by definition; SA's panic code 102
    // is the sa_std UNREACHABLE code (panic.sa).
    if (std.mem.eql(u8, t, "unreachable")) {
        try out.appendSlice("  panic(102)\n");
        return;
    }
    if (std.mem.indexOf(u8, t, "call ") != null) return appendCall(out, allocator, null, t, ctx);

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

/// IR text normalization layer (probe REPORT.md, ruling 3, classes 1-4).
///
/// Placement decision: this lives in the translator itself, at the single
/// funnel both entry points share (`translateIrSource`, reached by the
/// bitcode path after disassembly and by direct IR callers). The dialect
/// drift comes from the *disassembler's* LLVM version, so normalizing in a
/// driver script would leave library/plugin users exposed to whichever
/// llvm-dis happens to be installed; normalizing here makes the parser's
/// accepted dialect independent of the tool that produced the text.
///
/// Four rewrites, each semantics-preserving by construction:
///  1. `icmp samesign <pred>` -> `icmp <pred>` (samesign is an LLVM 18+
///     printing flag asserting a proof obligation the comparison opcode
///     does not depend on; SA icmp has no such flag).
///  2. Trailing instruction metadata suffixes (`, !llvm.loop !N`,
///     `, !range !N`, stacked in any order) stripped to a fixpoint.
///     Metadata is annotation-only in LLVM; only whole suffixes at end of
///     indented instruction lines are removed.
///  3. `f0x<hex>` float literals -> decimal. 16 hex digits are f64 bits,
///     8 are f32 bits; the conversion is bit-exact. Skipped inside `c"..."`
///     string constants and for non-finite values.
///  4. `llvm.experimental.noalias.scope.decl` declare/call lines dropped:
///     an annotation-only intrinsic with no execution semantics whose
///     `metadata` operand type the parser cannot represent.
pub fn normalizeIrSource(allocator: std.mem.Allocator, source: []const u8) ![]u8 {
    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();
    var lines = std.mem.splitScalar(u8, source, '\n');
    var first = true;
    while (lines.next()) |raw_line| {
        if (!first) try out.append('\n');
        first = false;
        if (std.mem.indexOf(u8, raw_line, "llvm.experimental.noalias.scope.decl") != null) continue;
        const trimmed = trim(raw_line);
        if (trimmed.len == 0 or trimmed[0] == ';') {
            try out.appendSlice(raw_line);
            continue;
        }
        var line = raw_line;
        var owned_line: ?[]u8 = null;
        defer if (owned_line) |buf| allocator.free(buf);
        if (line.len > 0 and (line[0] == ' ' or line[0] == '\t')) {
            if (std.mem.indexOf(u8, line, "icmp samesign ") != null) {
                owned_line = try std.mem.replaceOwned(u8, allocator, line, "icmp samesign ", "icmp ");
                line = owned_line.?;
            }
            line = stripTrailingMetadataSuffix(line);
        }
        if (std.mem.indexOf(u8, line, " c\"") == null) {
            try appendHexFloatNormalized(&out, line);
        } else {
            try out.appendSlice(line);
        }
    }
    return try out.toOwnedSlice();
}

fn stripTrailingMetadataSuffix(line: []const u8) []const u8 {
    var t = std.mem.trimEnd(u8, line, " \t\r");
    while (true) {
        const idx = std.mem.lastIndexOf(u8, t, ", !") orelse return t;
        const tail = t[idx + 3 ..];
        // tail must be exactly: <metadata-name> " !" <node-number>
        var i: usize = 0;
        while (i < tail.len and (isIdentChar(tail[i]) or tail[i] == '.')) : (i += 1) {}
        if (i == 0 or i >= tail.len or tail[i] != ' ') return t;
        i += 1;
        if (i >= tail.len or tail[i] != '!') return t;
        i += 1;
        const digits_start = i;
        while (i < tail.len and std.ascii.isDigit(tail[i])) : (i += 1) {}
        if (i != tail.len or i == digits_start) return t;
        t = std.mem.trimEnd(u8, t[0..idx], " \t\r");
    }
}

fn appendHexFloatNormalized(out: *std.array_list.Managed(u8), line: []const u8) !void {
    var i: usize = 0;
    while (i < line.len) {
        const is_token_start = i == 0 or !(isIdentChar(line[i - 1]) or line[i - 1] == '.');
        if (is_token_start and i + 2 < line.len and line[i] == 'f' and line[i + 1] == '0' and line[i + 2] == 'x') {
            var j = i + 3;
            while (j < line.len and isHexDigit(line[j])) : (j += 1) {}
            const digits = line[i + 3 .. j];
            var replaced = false;
            if (digits.len == 16) {
                if (std.fmt.parseInt(u64, digits, 16)) |bits| {
                    const v: f64 = @bitCast(bits);
                    if (std.math.isFinite(v)) {
                        try listPrint(out, "{d}", .{v});
                        replaced = true;
                    }
                } else |_| {}
            } else if (digits.len == 8) {
                if (std.fmt.parseInt(u32, digits, 16)) |bits| {
                    const v: f32 = @bitCast(bits);
                    if (std.math.isFinite(v)) {
                        try listPrint(out, "{d}", .{v});
                        replaced = true;
                    }
                } else |_| {}
            }
            if (!replaced) try out.appendSlice(line[i..j]);
            i = j;
            continue;
        }
        try out.append(line[i]);
        i += 1;
    }
}

pub fn translateIrSource(allocator: std.mem.Allocator, source: []const u8) ![]u8 {
    const normalized = try normalizeIrSource(allocator, source);
    defer allocator.free(normalized);

    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();

    var lines = std.mem.splitScalar(u8, normalized, '\n');
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

test "bc2sa phi cross-block uses reload from slots (M1 and M2)" {
    // M2 (probe REPORT.md ruling 1): a phi result loaded once in the loop
    // header and reused in the latch/exit blocks was rejected by the SA
    // referee (UnknownRegister). The latch and exit blocks must each
    // re-declare the register from the phi slot.
    const m2 =
        \\define i32 @m2(i32 %n) {
        \\entry:
        \\  br label %head
        \\head:
        \\  %i = phi i32 [ 0, %entry ], [ %inc, %latch ]
        \\  %c = icmp slt i32 %i, %n
        \\  br i1 %c, label %latch, label %exit
        \\latch:
        \\  %inc = add i32 %i, 1
        \\  br label %head
        \\exit:
        \\  ret i32 %i
        \\}
        \\
    ;
    const out2 = try translateIrSource(std.testing.allocator, m2);
    defer std.testing.allocator.free(out2);
    // header load + latch reload + exit reload of the phi register
    try std.testing.expect(std.mem.containsAtLeast(u8, out2, 3, "i = load bc2sa_phi_slot_i+0 as i32"));

    // M1: a phi edge store emitted into predecessor %edge references %t,
    // which is defined in %bb2 (not the direct predecessor). %t must be
    // slot-published at its definition and reloaded on the edge.
    const m1 =
        \\define i32 @m1(i32 %n) {
        \\entry:
        \\  br label %bb2
        \\bb2:
        \\  %t = mul i32 %n, 3
        \\  %c = icmp sgt i32 %n, 0
        \\  br i1 %c, label %edge, label %join
        \\edge:
        \\  br label %join
        \\join:
        \\  %r = phi i32 [ %t, %edge ], [ 0, %bb2 ]
        \\  ret i32 %r
        \\}
        \\
    ;
    const out1 = try translateIrSource(std.testing.allocator, m1);
    defer std.testing.allocator.free(out1);
    try std.testing.expect(std.mem.containsAtLeast(u8, out1, 1, "bc2sa_xslot_t = stack_alloc 4"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out1, 1, "store bc2sa_xslot_t+0, t as i32"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out1, 1, "t = load bc2sa_xslot_t+0 as i32"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out1, 1, "store bc2sa_phi_slot_r+0, t as i32"));
}

test "bc2sa zext lowers to a source-width mask" {
    // SA's flat registers let a sub-word load sign-extend into the full
    // register; a bare zext then keeps the sign bits (fnv1a_stream byte
    // >= 0x80 divergence). zext must mask to the source width.
    const ir =
        \\define i64 @zx(ptr %p) {
        \\entry:
        \\  %b = load i8, ptr %p, align 1
        \\  %w = zext i8 %b to i64
        \\  ret i64 %w
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "w = and b, 255"));
    try std.testing.expect(!std.mem.containsAtLeast(u8, out, 1, "zext"));
}

test "bc2sa inttoptr constant expression and instruction form" {
    // probe min_itp.ll: dangling-pointer constant expression in a store
    const ir =
        \\define void @itp(ptr %p) {
        \\entry:
        \\  store ptr inttoptr (i64 8 to ptr), ptr %p, align 8
        \\  %q = inttoptr i64 16 to ptr
        \\  store i64 1, ptr %q, align 8
        \\  ret void
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "store p+0, 8 as ptr"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "q = bitcast 16 as ptr"));
}

test "bc2sa extractvalue over an aggregate call result (sret)" {
    // probe min_ev.ll
    const ir =
        \\declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64)
        \\define i64 @ev(i64 %a, i64 %b) {
        \\entry:
        \\  %r = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %a, i64 %b)
        \\  %v = extractvalue { i64, i1 } %r, 0
        \\  %w = extractvalue { i64, i1 } %r, 1
        \\  %x = zext i1 %w to i64
        \\  %y = add i64 %v, %x
        \\  ret i64 %y
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "@extern llvm_ssub_with_overflow_i64(bc2sa_sret: ptr, arg0: i64, arg1: i64)"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_agg_r = stack_alloc 16"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "call @llvm_ssub_with_overflow_i64(bc2sa_agg_r, a, b)"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "v = load bc2sa_agg_r+0 as i64"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_t1 = ptr_add bc2sa_agg_r, 8"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "w = load bc2sa_t1+0 as i1"));
}

test "bc2sa insertvalue and aggregate return (sret out)" {
    // probe min_iv.ll
    const ir =
        \\define { i64, i1 } @iv(i64 %a) {
        \\entry:
        \\  %r = insertvalue { i64, i1 } undef, i64 %a, 0
        \\  ret { i64, i1 } %r
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "@export iv(bc2sa_sret: ptr, a: i64):"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_agg_r = stack_alloc 16"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "store bc2sa_agg_r+0, a as i64"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "store bc2sa_sret+0"));
}

test "bc2sa unreachable lowers to panic(102)" {
    // probe min_un.ll; 102 is sa_std's UNREACHABLE panic code
    const ir =
        \\define i64 @un(i64 %a) {
        \\entry:
        \\  %c = icmp eq i64 %a, 0
        \\  br i1 %c, label %ok, label %bad
        \\ok:
        \\  ret i64 %a
        \\bad:
        \\  unreachable
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "panic(102)"));
}

test "bc2sa extractvalue from a constant aggregate and aggregate alloca" {
    // probe min_ev2.ll
    const ir =
        \\define i64 @evonly(i64 %a) {
        \\entry:
        \\  %p = alloca { i64, i1 }, align 8
        \\  %v = extractvalue { i64, i1 } { i64 5, i1 true }, 0
        \\  ret i64 %v
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "p = stack_alloc 16"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "v = add 5, 0"));
}

test "bc2sa phi with undef incoming stores zero" {
    const ir =
        \\define i64 @pu(i64 %a) {
        \\entry:
        \\  br label %head
        \\head:
        \\  %i = phi i64 [ undef, %entry ], [ %n, %head ]
        \\  %n = add i64 %i, 1
        \\  %c = icmp slt i64 %n, %a
        \\  br i1 %c, label %head, label %exit
        \\exit:
        \\  ret i64 %n
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "store bc2sa_phi_slot_i+0, 0 as i64"));
}

test "bc2sa aggregate load and store round-trip through memory" {
    const ir =
        \\define { i64, i1 } @ldst(ptr %p) {
        \\entry:
        \\  %v = load { i64, i1 }, ptr %p, align 8
        \\  %q = alloca { i64, i1 }, align 8
        \\  store { i64, i1 } %v, ptr %q, align 8
        \\  ret { i64, i1 } %v
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "bc2sa_agg_v = stack_alloc 16"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "store q+0"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "ptr_add q, 8"));
}

test "bc2sa normalization rewrites the four dialect-drift classes" {
    const src =
        \\declare void @llvm.experimental.noalias.scope.decl(metadata)
        \\define i32 @f(i32 %a) !guid !7 {
        \\entry:
        \\  %c = icmp samesign eq i32 %a, 0
        \\  %r = fmul double 2.000000e+00, f0x400921FB54442D18
        \\  call void @llvm.experimental.noalias.scope.decl(metadata !5)
        \\  br i1 %c, label %ok, label %bad, !llvm.loop !4, !noalias !9
        \\ok:
        \\  ret i32 1
        \\bad:
        \\  ret i32 0
        \\}
        \\@msg = constant [5 x i8] c"f0x1\00"
        \\
    ;
    const out = try normalizeIrSource(std.testing.allocator, src);
    defer std.testing.allocator.free(out);
    // class 1: samesign flag dropped
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "%c = icmp eq i32 %a, 0"));
    // class 2: stacked trailing metadata stripped to a fixpoint
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "br i1 %c, label %ok, label %bad\n"));
    // class 3: hex float literal converted bit-exactly (pi)
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "3.141592653589793"));
    // class 4: noalias.scope.decl lines gone entirely
    try std.testing.expect(!std.mem.containsAtLeast(u8, out, 1, "noalias.scope.decl"));
    // negative: unindented define-line metadata is not ours to strip
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "define i32 @f(i32 %a) !guid !7 {"));
    // negative: hex-looking bytes inside a string constant stay untouched
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "c\"f0x1\\00\""));
}

test "bc2sa translates samesign, loop metadata and hex float operands" {
    // All three shapes returned error.UnsupportedInstruction pre-normalizer.
    const ir =
        \\define double @hf(double %a, i32 %n) {
        \\entry:
        \\  %c = icmp samesign sgt i32 %n, 0
        \\  br i1 %c, label %pos, label %neg, !llvm.loop !2
        \\pos:
        \\  %r = fmul double %a, f0x400921FB54442D18
        \\  ret double %r
        \\neg:
        \\  ret double %a
        \\}
        \\
    ;
    const out = try translateIrSource(std.testing.allocator, ir);
    defer std.testing.allocator.free(out);
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "c = sgt n, 0"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "r = fmul a, 3.141592653589793"));
    try std.testing.expect(std.mem.containsAtLeast(u8, out, 1, "br c -> L_pos, L_neg"));
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
