const std = @import("std");
const bc2sa = @import("llvm2sa.zig");
const plugin_api = @import("plugin_api");

const skills = [_]plugin_api.SkillSection{
    .{
        .name = "bc2sa",
        .summary = "Translate LLVM bitcode back into SA source",
        .items = &.{
            "bc2sa <file.bc>",
            "bitcode-only input",
            "stdout emits translated SA source",
        },
    },
};

const StreamCtx = struct {
    stream: plugin_api.HostStream,
};

const CaptureCtx = struct {
    buffer: *std.ArrayList(u8),
};

fn writeAll(ctx: *const anyopaque, bytes: []const u8) anyerror!usize {
    const self = @as(*const StreamCtx, @ptrCast(@alignCast(ctx)));
    const write_all = self.stream.write_all orelse return error.WriteFailed;
    if (write_all(self.stream.ctx, bytes.ptr, bytes.len) != @intFromEnum(plugin_api.AbiStatus.ok)) return error.WriteFailed;
    return bytes.len;
}

fn captureWriteAll(ctx: ?*anyopaque, bytes: [*]const u8, len: usize) callconv(.c) u32 {
    const self = @as(*CaptureCtx, @ptrCast(@alignCast(ctx.?)));
    self.buffer.appendSlice(bytes[0..len]) catch return @intFromEnum(plugin_api.AbiStatus.failed);
    return @intFromEnum(plugin_api.AbiStatus.ok);
}

fn makeCaptureStream(ctx: *CaptureCtx) plugin_api.HostStream {
    return .{ .ctx = ctx, .write_all = captureWriteAll };
}

fn cArgvToSlice(argv: []const [*:0]const u8, allocator: std.mem.Allocator) ![]const []const u8 {
    var out = try allocator.alloc([]const u8, argv.len);
    errdefer allocator.free(out);
    for (argv, 0..) |arg, idx| {
        out[idx] = std.mem.span(arg);
    }
    return out;
}

fn runLlvm2SaCommand(ctx: *const plugin_api.Context, argv: []const []const u8, stdout: std.io.AnyWriter, stderr: std.io.AnyWriter) anyerror!?u8 {
    if (argv.len < 2) return null;
    if (!std.mem.eql(u8, argv[1], "bc2sa")) return null;
    if (argv.len < 3) return error.MissingSourcePath;
    if (argv.len > 3) return error.UnexpectedArgument;
    const translated = bc2sa.translateBitcodeFile(ctx.allocator, argv[2]) catch |err| {
        try writeTranslateError(stderr, err);
        return 1;
    };
    defer ctx.allocator.free(translated);
    try stdout.writeAll(translated);
    return 0;
}

fn writeTranslateError(writer: std.io.AnyWriter, err: anyerror) !void {
    const detail = switch (err) {
        error.StaticMemoryOverflow => .{
            .code = "SA-CLI-019",
            .message = "static memory overflow detected in LLVM bitcode",
            .hint = "reduce the constant GEP/index offset or widen the fixed-size array before translating",
        },
        else => {
            try writer.print("error: {s}\n", .{@errorName(err)});
            return;
        },
    };

    try writer.print("error[{s}]: {s}\n", .{ detail.code, detail.message });
    try writer.print("  help: {s}\n", .{detail.hint});
}

fn isBc2SaCliError(err: anyerror) bool {
    return switch (err) {
        error.MissingSourcePath,
        error.UnexpectedArgument,
        error.InvalidPath,
        error.FileNotFound,
        error.NotDir,
        error.AccessDenied,
        => true,
        else => false,
    };
}

fn bc2saCliHint(err: anyerror) []const u8 {
    return switch (err) {
        error.MissingSourcePath => "usage: sa bc2sa <file.bc>",
        error.UnexpectedArgument => "remove the extra argument; bc2sa accepts exactly one bitcode file",
        error.InvalidPath => "check the bitcode input path",
        error.FileNotFound, error.NotDir => "check that the bitcode input exists and is a file",
        error.AccessDenied => "check filesystem permissions for the bitcode input",
        else => "check bc2sa command arguments",
    };
}

fn writeBc2SaCliError(writer: std.io.AnyWriter, err: anyerror) !void {
    const message = switch (err) {
        error.MissingSourcePath => "missing required bitcode input",
        error.UnexpectedArgument => "unexpected bc2sa argument",
        error.InvalidPath => "invalid bitcode input path",
        error.FileNotFound => "bitcode input not found",
        error.NotDir => "bitcode input path is not a directory",
        error.AccessDenied => "bitcode input access denied",
        else => @errorName(err),
    };
    try writer.print("error[SA-BC2SA-CLI]: {s}\n", .{message});
    try writer.print("  help: {s}\n", .{bc2saCliHint(err)});
}

fn runLlvm2SaCommandAbi(ctx: *const plugin_api.Context, argv: [*]const [*:0]const u8, argv_len: usize, stdout: plugin_api.HostStream, stderr: plugin_api.HostStream, out_code: *u8) callconv(.c) u32 {
    out_code.* = 0;
    var stdout_ctx = StreamCtx{ .stream = stdout };
    var stderr_ctx = StreamCtx{ .stream = stderr };
    const stdout_writer = std.io.AnyWriter{ .context = &stdout_ctx, .writeFn = writeAll };
    const stderr_writer = std.io.AnyWriter{ .context = &stderr_ctx, .writeFn = writeAll };
    const args = cArgvToSlice(argv[0..argv_len], ctx.allocator) catch return @intFromEnum(plugin_api.AbiStatus.failed);
    defer ctx.allocator.free(args);

    const result = runLlvm2SaCommand(ctx, args, stdout_writer, stderr_writer) catch |err| {
        if (!isBc2SaCliError(err)) return @intFromEnum(plugin_api.AbiStatus.failed);
        writeBc2SaCliError(stderr_writer, err) catch return @intFromEnum(plugin_api.AbiStatus.failed);
        out_code.* = 1;
        return @intFromEnum(plugin_api.AbiStatus.ok);
    };
    if (result) |code| {
        out_code.* = code;
        return @intFromEnum(plugin_api.AbiStatus.ok);
    }
    return @intFromEnum(plugin_api.AbiStatus.unknown_command);
}

const descriptor = plugin_api.PluginDescriptor{
    .abi_version = plugin_api.abi_version,
    .descriptor_size = @as(u32, @intCast(@sizeOf(plugin_api.PluginDescriptor))),
    .name = "bc2sa",
    .init = null,
    .prebuild = null,
    .postbuild = null,
    .handle_command = runLlvm2SaCommandAbi,
    .skills_ptr = skills[0..].ptr,
    .skills_len = skills.len,
};

pub export var saasm_plugin_descriptor_v1: plugin_api.PluginDescriptor = descriptor;

pub export fn saasm_plugin_descriptor_v1_fn(out: *plugin_api.PluginDescriptor) callconv(.c) void {
    out.* = saasm_plugin_descriptor_v1;
}

test "bc2sa plugin exports runtime descriptor and skills" {
    const exported = &saasm_plugin_descriptor_v1;
    try std.testing.expectEqual(plugin_api.abi_version, exported.abi_version);
    try std.testing.expectEqualStrings("bc2sa", std.mem.span(exported.name));
    try std.testing.expectEqual(@as(usize, 1), exported.skills_len);
    try std.testing.expectEqualStrings("bc2sa", exported.skills_ptr[0].name);
    try std.testing.expectEqualStrings("bc2sa <file.bc>", exported.skills_ptr[0].items[0]);
}

test "bc2sa plugin abi maps missing input to cli diagnostic" {
    var stdout_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stdout_buf.deinit();
    var stderr_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stderr_buf.deinit();
    var stdout_ctx = CaptureCtx{ .buffer = &stdout_buf };
    var stderr_ctx = CaptureCtx{ .buffer = &stderr_buf };
    var out_code: u8 = 255;
    const c_argv = [_][*:0]const u8{ "sa", "bc2sa" };

    const status = runLlvm2SaCommandAbi(
        &plugin_api.Context{ .allocator = std.testing.allocator },
        c_argv[0..].ptr,
        c_argv.len,
        makeCaptureStream(&stdout_ctx),
        makeCaptureStream(&stderr_ctx),
        &out_code,
    );

    try std.testing.expectEqual(@as(u32, @intFromEnum(plugin_api.AbiStatus.ok)), status);
    try std.testing.expectEqual(@as(u8, 1), out_code);
    try std.testing.expectEqual(@as(usize, 0), stdout_buf.items.len);
    try std.testing.expect(std.mem.containsAtLeast(u8, stderr_buf.items, 1, "error[SA-BC2SA-CLI]: missing required bitcode input"));
    try std.testing.expect(std.mem.containsAtLeast(u8, stderr_buf.items, 1, "usage: sa bc2sa <file.bc>"));
    try std.testing.expect(!std.mem.containsAtLeast(u8, stderr_buf.items, 1, "PluginFailed"));
}

test "bc2sa plugin formats static memory overflow diagnostic" {
    var stderr_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stderr_buf.deinit();
    var capture_ctx = CaptureCtx{ .buffer = &stderr_buf };
    var stderr_ctx = StreamCtx{ .stream = makeCaptureStream(&capture_ctx) };
    const stderr_writer = std.io.AnyWriter{ .context = &stderr_ctx, .writeFn = writeAll };

    try writeTranslateError(stderr_writer, error.StaticMemoryOverflow);
    try std.testing.expect(std.mem.containsAtLeast(u8, stderr_buf.items, 1, "error[SA-CLI-019]: static memory overflow detected in LLVM bitcode"));
    try std.testing.expect(std.mem.containsAtLeast(u8, stderr_buf.items, 1, "reduce the constant GEP/index offset or widen the fixed-size array before translating"));
}
