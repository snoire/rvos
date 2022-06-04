const std = @import("std");
const uart = @import("uart.zig");
pub const print = uart.print;

const page = @import("page.zig");
const allocator = page.fba.allocator();

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    print("KERNEL PANIC: {s}\n", .{msg});
    while (true) {}
}

export fn _start() linksection(".text_start") callconv(.Naked) noreturn {
    asm volatile (
        \\  csrr    t0, mhartid
        \\  beqz    t0, hart_id_0
        \\park:
        \\  wfi
        \\  j park
        \\hart_id_0:
    );

    @call(.{ .stack = stack_bytes_slice }, kmain, .{});
}

fn kmain() noreturn {
    uart.init();
    page.init();

    main() catch |e| {
        @panic(std.meta.tagName(e));
    };

    print("-------------- end.. ---------------\n", .{});
    while (true) {} // stop here!
}

fn main() !void {
    print("Hello, RVOS!\n", .{});

    page.info();

    var frame0 = async task0();
    var frame1 = async task1();

    var i: u1 = 0;
    while (true) : (i +%= 1) {
        if (i == 0) {
            resume frame0;
        } else {
            resume frame1;
        }
    }
}

fn task0() void {
    print("Task 0: Created!\n", .{});
    suspend {}

    while (true) {
        print("Task 0: Running...\n", .{});
        delay();
        suspend {}
    }
}

fn task1() void {
    print("Task 1: Created!\n", .{});
    suspend {}

    while (true) {
        print("Task 1: Running...\n", .{});
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
