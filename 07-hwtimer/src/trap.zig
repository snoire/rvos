const std = @import("std");
const builtin = @import("builtin");
const root = @import("kernel.zig");

const csr = @import("csr.zig");
const plic = @import("plic.zig");
const timer = @import("timer.zig");

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
            7 => {
                print("timer interruption!\n", .{});
                timer.handler();
            },
            11 => {
                print("external interruption!\n", .{});
                plic.handler();
            },
            else => print("unknown async exception!\n", .{}),
        }
    } else {
        // Synchronous trap - exception
        print("Sync exceptions!, code = {d}\n", .{cause_code});
        @panic("OOPS! Sync exceptions!");
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
