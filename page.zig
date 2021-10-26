const std = @import("std");
const print = @import("kernel.zig").print;

// 在 ld 中定义的这些只是 symbol，不占空间，u0 没法取地址，不然我就写 u0 了
extern var _heap_start: u1;
// 值其实体现在它们的地址上：heap_size == &_heap_size
extern const _heap_size: u8;

var fba: std.heap.FixedBufferAllocator = undefined;
// 必须 init 之后才能用
pub const allocator = &fba.allocator;

pub fn init() void {
    const heap_start_ptr = @ptrCast([*]u8, &_heap_start);
    const heap_slice = heap_start_ptr[0..@ptrToInt(&_heap_size)];
    // fba 必须是全局变量，不然函数返回之后就没了
    fba = std.heap.FixedBufferAllocator.init(heap_slice);
}

extern const _text_start: u8;
extern const _text_end: u8;
extern const _rodata_start: u8;
extern const _rodata_end: u8;
extern const _data_start: u8;
extern const _data_end: u8;
extern const _bss_start: u8;
extern const _bss_end: u8;

pub fn info() void {
    try print(
        \\HEAP_START = {x:0>8}, HEAP_SIZE = {x:0>8}, num of pages = {d}
        \\TEXT:   0x{x} -> 0x{x}
        \\RODATA: 0x{x} -> 0x{x}
        \\DATA:   0x{x} -> 0x{x}
        \\BSS:    0x{x} -> 0x{x}
        \\HEAP:   0x{x} -> 0x{x}
        \\
    , .{
        @ptrToInt(&_heap_start),
        @ptrToInt(&_heap_size),
        @ptrToInt(&_heap_size) / 4096,
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
    });
}

//pub fn tests() void {
//
