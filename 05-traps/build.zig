const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // build os.elf
    {
        const os = b.addExecutable("os.elf", "src/kernel.zig");
        const mode = b.standardReleaseOptions();
        os.setBuildMode(mode);

        var sub_set = std.Target.Cpu.Feature.Set.empty;
        const float: std.Target.riscv.Feature = .c;
        sub_set.addFeature(@enumToInt(float));

        os.setTarget(.{
            .cpu_arch = .riscv32,
            .os_tag = .freestanding,
            .abi = .none,
            .cpu_features_sub = sub_set,
        });

        os.setLinkerScriptPath(.{ .path = "linker.ld" });
        os.addAssemblyFile("src/entry.S");

        os.override_dest_dir = .{ .custom = "./" };
        os.install();

        const compile_step = b.step("os", "Compiles kernel");
        compile_step.dependOn(&os.step);
    }

    const qemu_args = [_][]const u8{
        "-nographic",
        "-smp",
        "1",
        "-machine",
        "virt",
        "-bios",
        "none",
        "-kernel",
        "zig-out/os.elf",
    };

    // run qemu
    {
        var qemu_tls = b.step("run", "Run os.elf in QEMU");
        var qemu = b.addSystemCommand(&[_][]const u8{"qemu-system-riscv32"});
        qemu.addArgs(&qemu_args);

        qemu.step.dependOn(b.getInstallStep());
        qemu_tls.dependOn(&qemu.step);
    }

    // run qemu with gdb server
    {
        var qemu_tls = b.step("qemu", "Run os.elf in QEMU with gdb server");
        var qemu = b.addSystemCommand(&[_][]const u8{"qemu-system-riscv32"});
        qemu.addArgs(&(qemu_args ++ [_][]const u8{ "-s", "-S" }));

        qemu.step.dependOn(b.getInstallStep());
        qemu_tls.dependOn(&qemu.step);
    }

    // debug with gdb
    {
        var gdb_tls = b.step("gdb", "Debug with gdb");
        var gdb = b.addSystemCommand(&[_][]const u8{
            //"gdb-multiarch",
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
