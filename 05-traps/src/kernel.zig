const std = @import("std");
const uart = @import("uart.zig");
const page = @import("page.zig");
const task = @import("task.zig");
const trap = @import("trap.zig");

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
    trap.init();

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

    print("Would not go here!\n", .{}); // 加上这句话，在 debug 和 fast 模式下会变得很慢??
    //unreachable; // 再加上这句话就不会了
    // 而且禁用 c 扩展也不会
    // 或者 user_task0() 里不调用 trap.tests() 也不会
    // 或者 task.schedule() 放在 task.tasks.schedule() 也不会
    // 搞不懂为啥
}
