const print = @import("root").print;
const arch = @import("root").arch;
extern fn trap_vector() callconv(.C) void;

pub fn init() void {
    // set the trap-vector base-address for machine-mode
    arch.w_mtvec(@ptrToInt(trap_vector));
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
    }

    return_pc += 2; // 反汇编看，触发异常的指令长度为 2
    return return_pc;
}

pub fn tests() void { // safe, fast, small 模式下这个函数都被优化没了。。
    // Synchronous exception code = 7
    // Store/AMO access fault
    //const ptr = @intToPtr(?*u32, 0x0);
    //ptr.* = 100;
    //
    @intToPtr([*c]u32, 0).* = 100; // 而且这一行被翻译成两条指令

    // Synchronous exception code = 5
    // Load access fault
    //var a: c_int = @intToPtr([*c]u32, 0).*;
    //_ = a;

    print("Yeah! I'm return back from trap!\n", .{});
}
