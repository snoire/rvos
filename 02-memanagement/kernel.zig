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

const len = 12;

fn main() !void {
    print("Hello, RVOS!\n", .{});
    var buf: [len]u8 = [_]u8{65} ** len;
    print("buf[len - 1]: {c}\n", .{buf[len - 1]});

    // test
    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    memory[0] = 128;
    print("memory addr: {*}, memory[0]: {}\n", .{ memory, memory[0] });

    var x: u8 = 254;
    x += 1;
    print("got here\n", .{});
}
