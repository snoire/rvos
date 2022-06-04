const std = @import("std");

const reg = enum(u3) {
    const Self = @This();
    const base = 0x10000000;
    const ptr = @intToPtr([*]volatile u8, base);

    /// Receiver Holding Register (R)
    rhr = 0,
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

    const dll: Self = .rhr;
    const dlm: Self = .ier;

    /// Transmitter Holding Register (W)
    const thr: Self = .rhr;
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

const fcr = struct {
    const fifo_enable = 0x01;
    const rx_fifo_reset = 0x02;
    const tx_fifo_reset = 0x04;
    const dma_mode = 0x08;
    const enable_dma_end = 0x10;
};

const lcr = struct {
    const word_size_5bits = 0x00;
    const word_size_6bits = 0x01;
    const word_size_7bits = 0x02;
    const word_size_8bits = 0x03;
};

const lsr = struct {
    const data_ready = 0x01;
    const overrun_error = 0x02;
    const parity_error = 0x04;
    const framing_error = 0x08;
    const break_interrupt = 0x10;
    const thr_empty = 0x20;
    const transmitter_empty = 0x40;
    const fifo_data_error = 0x80;
};

const Writer = std.io.Writer(void, error{}, write);

pub fn init() void {
    // disable interrupts.
    reg.ier.write(0x00);

    // setting baud rate.
    reg.lcr.set(1 << 7);
    reg.dll.write(0x03);
    reg.dlm.write(0x00);

    reg.lcr.write(3 << 0);
}

fn writeChar(char: u8) void {
    while (!reg.lsr.isSet(lsr.thr_empty)) {}
    reg.thr.write(char);
}

fn write(_: void, string: []const u8) error{}!usize {
    for (string) |char| {
        writeChar(char);
    }

    return string.len;
}

pub fn print(comptime format: []const u8, args: anytype) void {
    std.fmt.format(Writer{ .context = {} }, format, args) catch unreachable;
}
