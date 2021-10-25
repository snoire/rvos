const std = @import("std");
const uart = @import("uart.zig").Uart{};
const print = uart.writer().print;

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    try print("KERNEL PANIC: ", .{});
    try print("{s}", .{msg});
    while (true) {}
}

export fn start_kernel() noreturn {
    uart.init();

    try print("Hello, RVOS!\n", .{});
    while (true) {}                     // stop here!
}
