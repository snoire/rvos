// Transmitter Holding Register (W)
const register_thr = 0;
// Line Status Register (R)
const register_lsr = 5;
const lsr_thr_empty = 0x20;

const UART = 0x10000000;
const ptr = @intToPtr([*]volatile u8, UART);

fn set(register: u8, mask: u8) void {
    ptr[register] |= mask;
}

fn isSet(register: u8, mask: u8) bool {
    return ptr[register] & mask == mask;
}

fn writeChar(char: u8) void {
    while (!isSet(register_lsr, lsr_thr_empty)) {}
    set(register_thr, char);
}

pub fn write(string: []const u8) usize {
    for (string) |char| {
        writeChar(char);
    }
    return string.len;
}
