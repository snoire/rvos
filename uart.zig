const std = @import("std");
const Uart = @import("mmio.zig").Uart;

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
    // Enable FIFO
    Uart.fcr.write(u8, fcr.fifo_enable);

    // Set the word length to 8 bits
    Uart.lcr.write(u8, lcr.word_size_8bits);
}

fn putc(char: u8) void {
    while (Uart.lsr.read(u8) & lsr.thr_empty == 0) {}
    Uart.thr.write(u8, char);
}

fn writeFn(_: void, string: []const u8) !usize {
    for (string) |char| {
        putc(char);
    }

    return string.len;
}

const writer = std.io.Writer(void, error{}, writeFn){ .context = {} };

pub fn print(comptime format: []const u8, args: anytype) void {
    std.fmt.format(writer, format, args) catch unreachable;
}
