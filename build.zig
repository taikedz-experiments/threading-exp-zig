const std = @import("std");

pub fn build(b:*std.Build) void {
    const exe = b.addExecutable(.{
        .name = "sleepy-thread",
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    b.installArtifact(exe);
}

