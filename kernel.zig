const std = @import("std");

const uart = @import("uart.zig").Uart{};
pub const print = uart.writer().print;

const page = @import("page.zig");
const allocator = page.allocator;

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];


pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    try print("\nKERNEL PANIC: {s}\n", .{msg});
    while (true) {}
}

fn get_hartid() callconv(.Inline) usize {
    return asm volatile ("csrr %[value], mhartid"
        : [value] "=r" (-> usize)
    );
}

export fn _start() linksection(".text_start") callconv(.Naked) noreturn {
    if (get_hartid() != 0) {
        asm volatile ("wfi");
    }

    @call(.{ .stack = stack_bytes_slice }, start_kernel, .{});
    while (true) {}
}

fn start_kernel() noreturn {
    uart.init();
    page.init();

    main() catch {
        @panic("ops!\n");
    };

    while (true) {} // stop here!
}

fn main() !void {
    try print("Hello, RVOS!\n", .{});

    page.info();

    //// test
    //const memory = try allocator.alloc(u8, 100);
    //defer allocator.free(memory);

    //memory[0] = 128;
    //try print("memory addr: {*}, memory[0]: {}\n", .{ memory, memory[0] });

    var frame0 = async task0();
    var frame1 = async task1();

    var i: u1 = 0;
    while (true) {
        if (i == 0) {
            resume frame0;
            i = 1;
        } else {
            resume frame1;
            i = 0;
        }
    }

    //var x: u8 = 255;
    //x += 1;
    //try print("got here\n", .{});
}

fn task0() void {
    try print("Task 0: Created!\n", .{});
    suspend {}

    while (true) {
        try print("Task 0: Running...\n", .{});
        delay();
        suspend {}
    }
}

fn task1() void {
    try print("Task 1: Created!\n", .{});
    suspend {}

    while (true) {
        try print("Task 1: Running...\n", .{});
        delay();
        suspend {}
    }
}

fn delay() void {
    var i: usize = 5000 * 5000;
    var ptr: *volatile usize = &i;
    while (ptr.* > 0) {
        ptr.* -= 1;
    }
}
