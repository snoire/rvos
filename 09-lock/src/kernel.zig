const std = @import("std");
const csr = @import("csr.zig");
const uart = @import("uart.zig");
const page = @import("page.zig");
const task = @import("task.zig");
const trap = @import("trap.zig");
const plic = @import("plic.zig");
const timer = @import("clint.zig").timer;

pub const print = uart.print;
pub const allocator = page.fba.allocator();

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    print("KERNEL PANIC: {s}!\n", .{msg});
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
    timer.init();

    main() catch |e| {
        @panic(std.meta.tagName(e));
    };

    while (true) {}
}

fn main() !void {
    print("Hello, RVOS!\n", .{});

    page.info();
    print("\n", .{});

    // schedule() 的 switch_to 最后会执行 mret，第一次调用 schedule() 时
    // 不是在 trap handler 里，所以需要手动设置 mpp 和 mpie
    // https://github.com/plctlab/riscv-operating-system-mooc/issues/3
    // https://www.programmerall.com/article/92912333203
    csr.set("mstatus", csr.mstatus.mpp | csr.mstatus.mpie);
    task.schedule();

    unreachable;
}
