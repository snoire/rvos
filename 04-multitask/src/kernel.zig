const std = @import("std");
const uart = @import("uart.zig");
const page = @import("page.zig");
const task = @import("task.zig");

pub const print = uart.print;
pub const allocator = page.fba.allocator();

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
    task.init();

    main() catch |e| {
        @panic(std.meta.tagName(e));
    };

    while (true) {} // stop here!
}

fn main() !void {
    print("Hello, RVOS!\n", .{});

    page.info();
    task.info();

    task.schedule();
    print("Would not go here!\n", .{});
}
