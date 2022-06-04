const std = @import("std");
const root = @import("kernel.zig");

const print = root.print;

extern var _heap_start: u1; // 在 ld 中定义的这些只是 symbol，不占空间，u0 没法取地址，不然我就写 u0 了
extern const _heap_size: u8; // 值其实体现在它们的地址上：heap_size == &_heap_size
extern const _text_start: u8;
extern const _text_end: u8;
extern const _rodata_start: u8;
extern const _rodata_end: u8;
extern const _data_start: u8;
extern const _data_end: u8;
extern const _bss_start: u8;
extern const _bss_end: u8;

// 必须 init 之后才能用哦
pub var fba: std.heap.FixedBufferAllocator = undefined;

pub fn init() void {
    const heap_start_ptr = @ptrCast([*]u8, &_heap_start);
    const heap_slice = heap_start_ptr[0..@ptrToInt(&_heap_size)];
    // fba 必须是全局变量，不然函数返回之后就没了
    fba = std.heap.FixedBufferAllocator.init(heap_slice);
}

pub fn info() void {
    print(
        \\TEXT:   0x{x} -> 0x{x}
        \\RODATA: 0x{x} -> 0x{x}
        \\DATA:   0x{x} -> 0x{x}
        \\BSS:    0x{x} -> 0x{x}
        \\HEAP:   0x{x} -> 0x{x}
        \\HEAP_SIZE = 0x{x:0>8}, num of pages = {d}
        \\
    , .{
        @ptrToInt(&_text_start),
        @ptrToInt(&_text_end),
        @ptrToInt(&_rodata_start),
        @ptrToInt(&_rodata_end),
        @ptrToInt(&_data_start),
        @ptrToInt(&_data_end),
        @ptrToInt(&_bss_start),
        @ptrToInt(&_bss_end),
        @ptrToInt(&_heap_start),
        @ptrToInt(&_heap_start) + @ptrToInt(&_heap_size),
        @ptrToInt(&_heap_size),
        @ptrToInt(&_heap_size) / 4096,
    });
}
