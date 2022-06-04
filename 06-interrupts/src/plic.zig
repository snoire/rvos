const std = @import("std");
const csr = @import("csr.zig");
const uart = @import("uart.zig");

const print = uart.print;

// https://github.com/qemu/qemu/blob/master/include/hw/riscv/virt.h
const IRQ = enum(u6) {
    uart = 10,
    rtc = 11,
};

pub const Plic = struct {
    const Self = @This();
    const base = 0x0c00_0000;

    /// Sets the priority of a particular interrupt source
    fn priority(irq: IRQ, pri: u3) void {
        const ptr = @intToPtr([*]volatile u32, base);
        ptr[@enumToInt(irq)] = pri;
    }

    /// Enable/disable certain interrupt sources
    fn enable(hart: u3, irq: IRQ) void {
        const ptr = @intToPtr(*volatile u64, base + 0x2000 + @as(usize, hart) * 0x80);
        ptr.* |= @as(u64, 1) << @enumToInt(irq);
    }

    /// Sets the threshold that interrupts must meet before being able to trigger.
    fn threshold(hart: u3, thr: u3) void {
        const ptr = @intToPtr(*volatile u32, base + 0x20_0000 + @as(usize, hart) * 0x1000);
        ptr.* = thr;
    }

    ///	Query the PLIC what interrupt we should serve.
    fn claim(hart: u3) ?IRQ {
        const ptr = @intToPtr(*volatile u32, base + 0x20_0004 + @as(usize, hart) * 0x1000);
        const irq = ptr.*;
        return if (irq != 0) @intToEnum(IRQ, irq) else null;
    }

    ///	Writing the interrupt ID it received from the claim (irq) to the
    ///	complete register would signal the PLIC we've served this IRQ.
    fn complete(hart: u3, irq: IRQ) void {
        const ptr = @intToPtr(*volatile u32, base + 0x20_0004 + @as(usize, hart) * 0x1000);
        ptr.* = @enumToInt(irq);
    }
};

pub fn init() void {
    const hart = 0;

    // Set priority for UART0.
    Plic.priority(.uart, 1);

    // Enable UART0
    Plic.enable(hart, .uart);

    // Set priority threshold for UART0.
    Plic.threshold(hart, 0);

    // enable machine-mode external interrupts.
    csr.set("mie", csr.mie.meie);

    // enable machine-mode global interrupts.
    csr.set("mstatus", csr.mstatus.mie);
}

pub fn handle() void {
    const hart = 0;
    const irq = Plic.claim(hart) orelse @panic("irq is 0?");

    switch (irq) {
        .uart => uart.handleInterrupt(),
        else => {
            var buf = [_]u8{0} ** 128;

            @panic(std.fmt.bufPrint(
                buf[0..],
                "unhandled PLIC interrupt, source {s}",
                .{std.meta.tagName(irq)},
            ) catch unreachable);
        },
    }

    Plic.complete(hart, irq);
}
