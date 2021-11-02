const print = @import("root").print;
extern fn trap_vector() callconv(.C) void;

// Machine-mode interrupt vector
inline fn w_mtvec(x: u64) void {
    return asm volatile ("csrw mtvec, %[value]"
        :
        : [value] "r" (x),
    );
}

pub fn init() void {
    // set the trap-vector base-address for machine-mode
    w_mtvec(@ptrToInt(trap_vector));
}

export fn trap_handler(epc: u32, cause: u32) u32 {
    var return_pc: u32 = epc;
    var cause_code: u32 = cause & 0xfff;

    if (cause & 0x80000000 != 0) {
        switch (cause_code) {
            3 => try print("software interruption!\n", .{}),
            7 => try print("timer interruption!\n", .{}),
            11 => try print("external interruption!\n", .{}),
            else => try print("unknown async exception!\n", .{}),
        }
    } else {
        // Synchronous trap - exception
        try print("Sync exceptions!, code = {d}\n", .{cause_code});
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

    try print("Yeah! I'm return back from trap!\n", .{});
}
