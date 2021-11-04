//! This file manages all memory-mapped IO with a fancy set of helpers.

const std = @import("std");
const assert = std.debug.assert;

/// A mixin usable with `pub usingnamespace MMIO(@This())` on any enum(usize).
/// Adds IO functions for interacting with MMIO addresses defined in the enum members.
fn MMIO(comptime T: type) type {
    return struct {
        pub fn write(self: T, comptime U: type, data: U) void {
            writeOffset(self, U, 0, data);
        }
        pub fn read(self: T, comptime U: type) U {
            return self.readOffset(U, 0);
        }

        pub fn writeOffset(self: T, comptime U: type, offset: usize, data: U) void {
            comptime assert(@typeInfo(U) == .Int);
            // 是 T.base，而不是 self.base
            const ptr = @intToPtr([*]volatile U, T.base + @intCast(usize, @enumToInt(self)));
            ptr[offset] = data;
        }
        pub fn readOffset(self: T, comptime U: type, offset: usize) U {
            comptime assert(@typeInfo(U) == .Int);
            const ptr = @intToPtr([*]volatile U, T.base + @intCast(usize, @enumToInt(self)));
            return ptr[offset];
        }
    };
}

/// MMIO addresses for the UART.
pub const Uart = enum(u3) {
    /// Base address, write/read data
    // 在同一个文件中访问，好像不需要加 pub
    const base = 0x1000_0000;
    const Self = @This();

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
    pub const thr: Self = .rhr;
    /// FIFO Control Register (W)
    pub const fcr: Self = .isr;

    /// Divisor Latch, LSB (R/W)
    pub const dll: Self = .rhr;
    /// Divisor Latch, MSB (R/W)
    pub const dlm: Self = .ier;
    /// Prescaler Division (W)
    pub const psd: Self = .lsr;

    pub usingnamespace MMIO(Self);
};

/// MMIO adresses for the Core Local Interrupter.
pub const CLINT = enum(usize) {
    /// The machine time counter. QEMU increments this at a frequency of 10Mhz.
    mtime = 0x0200_bff8,
    /// The machine time compare register, a timer interrupt is fired iff mtimecmp >= mtime
    mtimecmp = 0x0200_4000,

    pub usingnamespace MMIO(@This());
};

/// MMIO addresses for the Platform Level Interrupt Controller.
pub const PLIC = enum(usize) {
    const base = 0x0c00_0000;
    const Self = @This();

    /// Sets the priority of a particular interrupt source
    priority = 0x0,
    /// Contains a list of interrupts that have been triggered (are pending)
    pending = 0x1000,
    /// Enable/disable certain interrupt sources
    enable = 0x2000,
    /// Sets the threshold that interrupts must meet before being able to trigger.
    threshold = 0x20_0000,
    /// Returns the next interrupt in priority order
    claim = 0x20_0004,

    /// Completes handling of a particular interrupt
    pub const complete: Self = .claim;

    pub usingnamespace MMIO(@This());
};
