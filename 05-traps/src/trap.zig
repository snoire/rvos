const std = @import("std");
const builtin = @import("builtin");
const root = @import("kernel.zig");
const csr = @import("csr.zig");

const print = root.print;
extern fn trap_vector() callconv(.C) void;

pub fn init() void {
    // set the trap-vector base-address for machine-mode
    csr.write("mtvec", @ptrToInt(trap_vector));
}

export fn trap_handler(epc: u32, cause: u32) u32 {
    var return_pc: u32 = epc;
    var cause_code: u32 = cause & 0xfff;

    if (cause & 0x80000000 != 0) {
        switch (cause_code) {
            3 => print("software interruption!\n", .{}),
            7 => print("timer interruption!\n", .{}),
            11 => print("external interruption!\n", .{}),
            else => print("unknown async exception!\n", .{}),
        }
    } else {
        // Synchronous trap - exception
        print("Sync exceptions!, code = {d}\n", .{cause_code});
        //@panic("OOPS! What can I do!");

        // 反汇编看，debug 模式触发异常的指令长度为 2，其他模式是 4
        // 用 zig build-exe -target riscv32-freestanding --show-builtin 看，用了压缩指令
        const compress: std.Target.riscv.Feature = .c;
        if (builtin.cpu.features.isEnabled(@enumToInt(compress)) and builtin.mode == .Debug) {
            return_pc += 2;
        } else {
            return_pc += 4;
        }
    }

    return return_pc;
}

pub fn tests() void { // safe, fast, small 模式下这个函数都被优化没了。。
    // Synchronous exception code = 7
    // Store/AMO access fault
    //const ptr = @intToPtr(?*u32, 0x0);
    //ptr.* = 100;
    //
    //@intToPtr(*u32, 0).* = 100; // pointer type '*u32' does not allow address zero
    //@intToPtr([*c]u32, 0).* = 100; // c 指针没有限制
    @intToPtr(*allowzero volatile usize, 0).* = 100; // 加 volatile 才不会被优化

    // Synchronous exception code = 5
    // Load access fault
    var a = @intToPtr(*allowzero volatile usize, 0).*;
    _ = a;

    print("Yeah! I'm return back from trap!\n", .{});
}
