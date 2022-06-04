const std = @import("std");

const Uart = enum(u3) {
    const Self = @This();
    const base = 0x10000000;
    const ptr = @intToPtr([*]volatile u8, base);

    /// Receiver/Transmitter Holding Register (R/W)
    rthr = 0,
    /// Interrupt Enable Register (R/W)
    ier = 1,
    /// Interrupt Status Register (R)
    isr = 2,
    /// Line Control Register (R/W)
    lcr = 3,
    /// Modem Control Register (R/W)
    mcr = 4,
    /// Line Status Register (R)
    lsr = 5,
    /// Modem Status Register (R)
    msr = 6,
    /// Scratch Pad Register (R/W)
    spr = 7,

    /// divisor latch least
    const dll: Self = .rthr;
    /// divisor latch most
    const dlm: Self = .ier;

    /// FIFO Control Register (W)
    const fcr: Self = .isr;

    fn write(self: Self, data: u8) void {
        ptr[@enumToInt(self)] = data;
    }

    fn read(self: Self) u8 {
        return ptr[@enumToInt(self)];
    }

    fn set(self: Self, mask: u8) void {
        ptr[@enumToInt(self)] |= mask;
    }

    fn isSet(self: Self, mask: u8) bool {
        return ptr[@enumToInt(self)] & mask == mask;
    }
};

const lcr = struct {
    const baud_latch = struct {
        const disable = 0b0000_0000;
        const enable = 0b1000_0000;
    };
    const word = struct {
        const @"5bits" = 0b00;
        const @"6bits" = 0b01;
        const @"7bits" = 0b10;
        const @"8bits" = 0b11;
    };
};

const lsr = struct {
    const data_ready = 1 << 0;
    const overrun_error = 1 << 1;
    const parity_error = 1 << 2;
    const framing_error = 1 << 3;
    const break_interrupt = 1 << 4;
    const thr_empty = 1 << 5;
    const transmitter_empty = 1 << 6;
    const fifo_data_error = 1 << 7;
};

pub fn init() void {
    // disable interrupts.
    Uart.ier.write(0x00);

    // Setting baud rate
    Uart.lcr.set(lcr.baud_latch.enable);
    Uart.dll.write(0x01);
    Uart.dlm.write(0x00);

    // Continue setting the asynchronous data communication format.
    Uart.lcr.write(lcr.word.@"8bits");

    // enable receive interrupts.
    Uart.ier.set(0x01);
}

fn putc(char: u8) void {
    while (!Uart.lsr.isSet(lsr.thr_empty)) {}
    Uart.rthr.write(char);
}

fn write(_: void, string: []const u8) error{}!usize {
    for (string) |char| {
        putc(char);
    }
    return string.len;
}

const Writer = std.io.Writer(void, error{}, write);

pub fn print(comptime format: []const u8, args: anytype) void {
    std.fmt.format(Writer{ .context = {} }, format, args) catch unreachable;
}

/// Return a as of yet unread char or null.
fn getc() ?u8 {
    return if (Uart.lsr.isSet(lsr.data_ready)) Uart.rthr.read() else null;
}

/// This gets called by the PLIC handler in plic.zig
pub fn handleInterrupt() void {
    while (true) {
        if (getc()) |char| {
            print("{c}\n", .{char});
        } else {
            break;
        }
    }
}
