const io = @import("std").io;

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

    /// Transmitter Holding Register (W)
    const thr: Self = .rhr;
    /// FIFO Control Register (W)
    const fcr: Self = .isr;

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


// Singleton struct to make `std.io.Writer` happy
pub const Uart = struct {
    const Self = @This();
    const Writer = io.Writer(Self, error{}, write);

    pub fn init(_: Self) void {
        // Enable FIFO
        reg.fcr.set(fcr.fifo_enable);

        // Set the word length to 8 bits
        reg.lcr.set(lcr.word_size_8bits);

        // TODO: set the baud rate, and check if other options need to be set
    }

    fn writeChar(_: Self, char: u8) void {
        while (!reg.lsr.isSet(lsr.thr_empty)) {}
        reg.thr.set(char);
    }

    pub fn write(self: Self, string: []const u8) !usize {
        for (string) |char| {
            self.writeChar(char);
        }

        return string.len;
    }

    pub fn writer(self: Self) Writer {
        return .{ .context = self };
    }
};
