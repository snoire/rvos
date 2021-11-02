const std = @import("std");
pub const arch = @import("riscv.zig");

const uart = @import("uart.zig").Uart{};
pub const print = uart.writer().print;

const page = @import("page.zig");
const allocator = page.allocator;

const task = @import("task.zig");
const trap = @import("trap.zig");

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    try print("\nKERNEL PANIC: {s}\n", .{msg});
    while (true) {}
}

export fn start_kernel() noreturn {
    uart.init();
    page.init();
    task.Tasks.init();
    trap.init();

    main() catch {
        @panic("ops!\n");
    };

    while (true) {} // stop here!
}

fn main() !void {
    try print("Hello, RVOS!\n", .{});

    page.info();
    task.tasks.info();

    task.tasks.schedule();
    try print("Would not go here!\n", .{});
}
