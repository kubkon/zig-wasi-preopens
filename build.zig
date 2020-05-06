const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();

    var exe = b.addExecutable("wasi_preopens", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .wasi });

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
