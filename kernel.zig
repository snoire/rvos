const std = @import("std");

const uart = @import("uart.zig").Uart{};
pub const print = uart.writer().print;

const page = @import("page.zig");
const allocator = page.allocator;

const task = @import("task.zig");

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    try print("KERNEL PANIC: ", .{});
    try print("{s}", .{msg});
    while (true) {}
}

export fn start_kernel() noreturn {
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

    var task0 = task.Task.create(task.user_task0);
    task.switch_to(&task0.regs);
}
