const std = @import("std");
const io = std.io;
const fs = std.fs;
const wasi = fs.wasi;

pub fn main() !void {
    const stdout = io.getStdOut().outStream();
    // Get allocator. Fixed buffer for now as this is only for testing.
    var buffer: [10000]u8 = undefined;
    const allocator = &std.heap.FixedBufferAllocator.init(&buffer).allocator;
    // Fetch preopens from runtime.
    var preopens = wasi.PreopenList.init(allocator);
    errdefer preopens.deinit();
    try preopens.populate();

    // Create new file for writing
    if (preopens.find(".")) |pr| {
        const dir = fs.Dir{ .fd = pr.fd };
        var file = try dir.createFile("new_file", .{});
    } else {
        try stdout.print("Capabilities insufficient", .{});
    }
}
