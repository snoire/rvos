const std = @import("std");
const root = @import("kernel.zig");
const csr = @import("csr.zig");
const task = @import("task.zig");

const print = root.print;

const Clint = struct {
    const Self = @This();
    const base = 0x0200_0000;

    /// trigger a machine-level software interrupt
    fn msip(hart: u3, val: u1) void {
        const ptr = @intToPtr([*]volatile u32, base);
        ptr[hart] = val;
    }

    /// The machine time counter. QEMU increments this at a frequency of 10Mhz.
    fn mtime() u64 {
        return @intToPtr(*volatile u64, base + 0xbff8).*;
    }
    /// The machine time compare register, a timer interrupt is fired iff mtimecmp >= mtime
    fn mtimecmp(hart: u3, time: u64) void {
        const ptr = @intToPtr([*]volatile u64, base + 0x4000);
        ptr[hart] = time;
    }
};

pub const timer = struct {
    // 10000000 ticks per-second
    const interval = 1000_0000;
    var tick: u64 = 0;

    fn load(invl: u64) void {
        const hart = 0;
        Clint.mtimecmp(hart, Clint.mtime() + invl);
    }

    pub fn init() void {
        // On reset, mtime is cleared to zero, but the mtimecmp registers
        // are not reset. So we have to init the mtimecmp manually.
        load(interval);

        // enable machine-mode timer interrupts.
        csr.set("mie", csr.mie.mtie);

        // enable machine-mode global interrupts.
        csr.set("mstatus", csr.mstatus.mie);
    }

    pub fn handler() void {
        tick += 1;

        print("tick: {}\n", .{tick});
        load(interval);

        // Preemptive Multitasking!!
        task.schedule();
    }
};

pub const software = struct {
    pub fn init() void {
        // enable machine-mode software interrupts.
        csr.set("mie", csr.mie.msie);

        // enable machine-mode global interrupts.
        csr.set("mstatus", csr.mstatus.mie);
    }

    /// trigger a machine-level software interrupt
    pub fn trigger(hart: u3) void {
        Clint.msip(hart, 1);
    }

    /// answer a machine-level software interrupt
    pub fn answer(hart: u3) void {
        Clint.msip(hart, 0);
    }
};
