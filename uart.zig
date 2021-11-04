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
    //// Enable FIFO
    //Uart.fcr.write(u8, fcr.fifo_enable);

    //// Set the word length to 8 bits
    //Uart.lcr.write(u8, lcr.word_size_8bits);

    //* disable interrupts. */
    Uart.ier.write(u8, 0x00);

    // Setting baud rate. Just a demo here if we care about the divisor,
    // but for our purpose [QEMU-virt], this doesn't really do anything.
    //
    // Notice that the divisor register DLL (divisor latch least) and DLM (divisor
    // latch most) have the same base address as the receiver/transmitter and the
    // interrupt enable register. To change what the base address points to, we
    // open the "divisor latch" by writing 1 into the Divisor Latch Access Bit
    // (DLAB), which is bit index 7 of the Line Control Register (LCR).
    //
    // Regarding the baud rate value, see [1] "BAUD RATE GENERATOR PROGRAMMING TABLE".
    // We use 38.4K when 1.8432 MHZ crystal, so the corresponding value is 3.
    // And due to the divisor register is two bytes (16 bits), so we need to
    // split the value of 3(0x0003) into two bytes, DLL stores the low byte,
    // DLM stores the high byte.
    //
    Uart.lcr.write(u8, Uart.lcr.read(u8) | (1 << 7));
    Uart.dll.write(u8, 0x03);
    Uart.dlm.write(u8, 0x00);

    // Continue setting the asynchronous data communication format.
    // - number of the word length: 8 bits
    // - number of stop bits：1 bit when word length is 8 bits
    // - no parity
    // - no break control
    // - disabled baud latch
    //
    Uart.lcr.write(u8, 0 | (3 << 0));

    // enable receive interrupts.
    Uart.ier.write(u8, Uart.ier.read(u8) | (1 << 0));
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

/// Return a as of yet unread char or null.
fn getc() ?u8 {
    if (Uart.lsr.read(u8) & lsr.data_ready == 1) {
        return Uart.rhr.read(u8);
    } else {
        return null;
    }
}

/// This gets called by the PLIC handler in plic.zig
pub fn handleInterrupt() void {
    while (true) {
        const char = getc();
        if (char == null) {
            break;
        } else {
            print("{c}\n", .{char});
        }
    }
}
