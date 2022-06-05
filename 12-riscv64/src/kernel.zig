const std = @import("std");
const csr = @import("csr.zig");
const uart = @import("uart.zig");
const page = @import("page.zig");
const task = @import("task.zig");
const trap = @import("trap.zig");
const plic = @import("plic.zig");
const clint = @import("clint.zig");
const swtimer = @import("swtimer.zig");

const softintr = clint.software;
const timerintr = clint.timer;

pub const print = uart.print;
pub const allocator = page.fba.allocator();

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    csr.clear("mstatus", csr.mstatus.mie); // disable interrupt

    print("\x1b[31m" ++ "KERNEL PANIC: {s}!\n" ++ "\x1b[m", .{msg});
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
    plic.init();
    softintr.init();
    timerintr.init();
    swtimer.init();

    main() catch |err| {
        @panic(std.meta.tagName(err));
    };

    while (true) {}
}

fn main() !void {
    print("Hello, RVOS!\n", .{});

    page.info();
    print("\n", .{});

    // switch to user mode
    csr.clear("mstatus", csr.mstatus.mpp);
    csr.set("mstatus", csr.mstatus.mpie);
    task.schedule();

    unreachable;
}
