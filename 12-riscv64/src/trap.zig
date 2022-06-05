const std = @import("std");
const builtin = @import("builtin");
const root = @import("kernel.zig");

const csr = @import("csr.zig");
const plic = @import("plic.zig");
const task = @import("task.zig");
const clint = @import("clint.zig");
const syscall = @import("syscall.zig");

const print = root.print;
extern fn trap_vector() callconv(.C) void;

const mcause = struct {
    const interrupt = enum(u8) {
        @"User software interrupt" = 0,
        @"Supervisor software interrupt" = 1,
        @"Machine software interrupt" = 3,

        @"User timer interrupt" = 4,
        @"Supervisor timer interrupt" = 5,
        @"Machine timer interrupt" = 7,

        @"User external interrupt" = 8,
        @"Supervisor external interrupt" = 9,
        @"Machine external interrupt" = 11,
    };

    const exception = enum(u8) {
        @"Instruction address misaligned" = 0,
        @"Instruction address fault" = 1,
        @"Illegal instruction" = 2,
        @"Breakpoint" = 3,
        @"Load address misaligned" = 4,
        @"Load access fault" = 5,
        @"Store/AMO address misaligned" = 6,
        @"Store/AMO access fault" = 7,
        @"Environment call from U-mode" = 8,
        @"Environment call from S-mode" = 9,

        @"Environment call from M-mode" = 11,
        @"Instruction page fault" = 12,
        @"Load page fault" = 13,

        @"Store/AMO page fault" = 15,
    };
};

pub fn init() void {
    // set the trap-vector base-address for machine-mode
    csr.write("mtvec", @ptrToInt(trap_vector));
}

export fn trap_handler(epc: usize, cause: usize, cxt: *task.TaskRegs) usize {
    var return_pc: usize = epc;
    const highest_bit = @bitSizeOf(usize) - 1;
    const cause_code: usize = cause & ~@as(usize, (1 << highest_bit));

    if (cause >> highest_bit == 1) { // Asynchronous trap - interrupt
        const code = @intToEnum(mcause.interrupt, cause_code);
        print("\x1b[32m" ++ "{s}\n" ++ "\x1b[m", .{@tagName(code)});

        switch (code) {
            .@"Machine software interrupt" => {
                clint.software.answer(0);
                task.schedule();
            },
            .@"Machine timer interrupt" => {
                clint.timer.handler();
            },
            .@"Machine external interrupt" => {
                plic.handler();
            },
            else => print("unknown async exception!\n", .{}),
        }
    } else { // Synchronous trap - exception
        const code = @intToEnum(mcause.exception, cause_code);
        switch (code) {
            .@"Environment call from U-mode" => {
                print("System call from U-mode!\n", .{});
                syscall.call(cxt);
                return_pc += 4;
            },
            else => @panic(@tagName(code)),
        }
    }

    return return_pc;
}

pub fn tests() void {
    // Synchronous exception code = 7
    // Store/AMO access fault
    @intToPtr(*allowzero volatile usize, 0).* = 100;

    // Synchronous exception code = 5
    // Load access fault
    var a = @intToPtr(*allowzero volatile usize, 0).*;
    _ = a;

    print("Yeah! I'm return back from trap!\n", .{});
}
