// bc2sa probe driver (Agent AM, 2026-10-27): drives the plugin's public
// entry points directly, bypassing the shadowed `sa bc2sa` CLI path.
//   driver bc  <input.bc> <output.sa>   -> translateBitcodeFile
//   driver ir  <input.ll> <output.sa>   -> translateIrSource (manual dis path)
// On translation error prints "DRIVER_ERROR <name>" to stderr and exits 3.
const std = @import("std");
const bc2sa = @import("bc2sa");

var threaded_storage: ?std.Io.Threaded = null;
var current_io: ?std.Io = null;

fn io() std.Io {
    if (current_io) |v| return v;
    threaded_storage = std.Io.Threaded.init(std.heap.page_allocator, .{ .argv0 = .empty });
    const v = threaded_storage.?.io();
    current_io = v;
    return v;
}

pub fn main(init: std.process.Init) !void {
    const alloc = std.heap.page_allocator;
    var it = std.process.Args.Iterator.init(init.minimal.args);
    _ = it.next(); // self
    const mode = it.next() orelse {
        std.debug.print("usage: driver <bc|ir> <input> <output>\n", .{});
        std.process.exit(2);
    };
    const input = it.next() orelse {
        std.debug.print("usage: driver <bc|ir> <input> <output>\n", .{});
        std.process.exit(2);
    };
    const output = it.next() orelse {
        std.debug.print("usage: driver <bc|ir> <input> <output>\n", .{});
        std.process.exit(2);
    };

    const out: []u8 = blk: {
        if (std.mem.eql(u8, mode, "bc")) {
            break :blk bc2sa.translateBitcodeFile(alloc, input) catch |err| {
                std.debug.print("DRIVER_ERROR {s}\n", .{@errorName(err)});
                std.process.exit(3);
            };
        } else if (std.mem.eql(u8, mode, "ir")) {
            const src = std.Io.Dir.cwd().readFileAlloc(io(), input, alloc, .limited(64 * 1024 * 1024)) catch |err| {
                std.debug.print("DRIVER_ERROR read:{s}\n", .{@errorName(err)});
                std.process.exit(3);
            };
            break :blk bc2sa.translateIrSource(alloc, src) catch |err| {
                std.debug.print("DRIVER_ERROR {s}\n", .{@errorName(err)});
                std.process.exit(3);
            };
        } else {
            std.debug.print("unknown mode {s}\n", .{mode});
            std.process.exit(2);
        }
    };
    try std.Io.Dir.cwd().writeFile(io(), .{ .sub_path = output, .data = out });
    std.debug.print("DRIVER_OK bytes={d}\n", .{out.len});
}
