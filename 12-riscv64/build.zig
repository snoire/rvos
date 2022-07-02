const std = @import("std");
const set = std.Target.riscv.featureSet;

pub fn build(b: *std.build.Builder) void {
    // build os.elf
    {
        const os = b.addExecutable("os.elf", "src/kernel.zig");
        const mode = b.standardReleaseOptions();
        os.setBuildMode(mode);

        os.setTarget(.{
            .cpu_arch = .riscv64,
            .os_tag = .freestanding,
            .abi = .none,
            .cpu_features_sub = set(&.{ .c, .f, .d }),
        });

        os.setLinkerScriptPath(.{ .path = "linker.ld" });
        os.addAssemblyFile("src/entry.S");
        os.code_model = .medium;

        os.strip = b.option(bool, "strip", "Removes symbols and sections from file") orelse false;
        os.override_dest_dir = .{ .custom = "./" };
        os.install();

        const compile_step = b.step("os", "Compiles kernel");
        compile_step.dependOn(&os.step);
    }

    const qemu_args = [_][]const u8{
        // zig fmt: off
        "-nographic",
        "-smp", "1",
        "-machine", "virt",
        "-bios", "none",
        // Disable pmp. Details please refer to
        // https://gitlab.com/qemu-project/qemu/-/issues/585 or
        // https://gitee.com/unicornx/riscv-operating-system-mooc/issues/I441IC
        "-cpu", "rv64,pmp=false",
        "-kernel", "zig-out/os.elf",
        // zig fmt: on
    };

    // run qemu
    {
        var qemu_tls = b.step("run", "Run os.elf in QEMU");
        var qemu = b.addSystemCommand(&[_][]const u8{"qemu-system-riscv64"});
        qemu.addArgs(&qemu_args);

        qemu.step.dependOn(b.getInstallStep());
        qemu_tls.dependOn(&qemu.step);
    }

    // run qemu with gdb server
    {
        var qemu_tls = b.step("qemu", "Run os.elf in QEMU with gdb server");
        var qemu = b.addSystemCommand(&[_][]const u8{"qemu-system-riscv64"});
        qemu.addArgs(&(qemu_args ++ [_][]const u8{ "-s", "-S" }));

        qemu.step.dependOn(b.getInstallStep());
        qemu_tls.dependOn(&qemu.step);
    }

    // debug with gdb
    {
        var gdb_tls = b.step("gdb", "Debug with gdb");
        var gdb = b.addSystemCommand(&[_][]const u8{
            "riscv64-unknown-elf-gdb",
            "zig-out/os.elf",
            "-q",
            "-x",
            "gdbinit",
        });

        gdb.step.dependOn(b.getInstallStep());
        gdb_tls.dependOn(&gdb.step);
    }

    // display code information
    {
        var objdump_tls = b.step("code", "Display code information");
        var objdump = b.addSystemCommand(&[_][]const u8{
            "riscv64-unknown-elf-objdump",
            "-SD",
            "zig-out/os.elf",
        });

        objdump.step.dependOn(b.getInstallStep());
        objdump_tls.dependOn(&objdump.step);
    }
}
