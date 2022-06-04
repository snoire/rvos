const std = @import("std");
const print = @import("kernel.zig").print;

// 在 ld 中定义的这些只是 symbol，不占空间，u0 没法取地址，不然我就写 u0 了
extern var _heap_start: u1;
// 值其实体现在它们的地址上：heap_size == &_heap_size
extern const _heap_size: u8;

// 必须 init 之后才能用哦
pub var fba: std.heap.FixedBufferAllocator = undefined;
//pub const allocator = &fba.allocator;

pub fn init() void {
    const heap_start_ptr = @ptrCast([*]u8, &_heap_start);
    const heap_slice = heap_start_ptr[0..@ptrToInt(&_heap_size)];
    // fba 必须是全局变量，不然函数返回之后就没了
    fba = std.heap.FixedBufferAllocator.init(heap_slice);

    // debug 信息
    print("HEAP:   {*} -> {*}\n", .{ &_heap_start, &_heap_size });
    print("heap_slice: {*}\n", .{heap_slice});
}
