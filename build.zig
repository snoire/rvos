const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const os = b.addExecutable("os.elf", "kernel.zig");
    const mode = b.standardReleaseOptions();
    os.setBuildMode(mode);

    os.setTarget(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
    });

    os.setLinkerScriptPath(.{ .path = "linker.ld" });
    os.addAssemblyFile("start.S");
    os.addAssemblyFile("entry.S");

    os.install();

    const compile_step = b.step("os", "Compiles kernel");
    compile_step.dependOn(&os.step);

    // qemu
    var qemu_tls = b.step("run", "Run os.elf in QEMU");
    var qemu = b.addSystemCommand(&[_][]const u8{"qemu-system-riscv32"});
    qemu.addArgs(&[_][]const u8{
        "-nographic",
        "-smp",
        "1",
        "-machine",
        "virt",
        "-bios",
        "none",
        "-kernel",
        "zig-out/bin/os.elf",
    });

    qemu.step.dependOn(b.getInstallStep());
    qemu_tls.dependOn(&qemu.step);
}
