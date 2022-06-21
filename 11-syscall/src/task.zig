const builtin = @import("builtin");
const root = @import("kernel.zig");
const csr = @import("csr.zig");
const trap = @import("trap.zig");
const clint = @import("clint.zig");
const swtimer = @import("swtimer.zig");
const syscall = @import("syscall.zig");

const print = root.print;

extern fn switch_to(to: *TaskRegs) callconv(.C) void; // 返回类型不能是 noreturn

pub const TaskRegs = packed struct {
    // Layout must be kept in sync with switch_to
    // ignore x0
    ra: u32 = 0,
    sp: u32,
    gp: u32 = 0,
    tp: u32 = 0,
    t0: u32 = 0,
    t1: u32 = 0,
    t2: u32 = 0,
    s0: u32 = 0,
    s1: u32 = 0,
    a0: u32 = 0,
    a1: u32 = 0,
    a2: u32 = 0,
    a3: u32 = 0,
    a4: u32 = 0,
    a5: u32 = 0,
    a6: u32 = 0,
    a7: u32 = 0,
    s2: u32 = 0,
    s3: u32 = 0,
    s4: u32 = 0,
    s5: u32 = 0,
    s6: u32 = 0,
    s7: u32 = 0,
    s8: u32 = 0,
    s9: u32 = 0,
    s10: u32 = 0,
    s11: u32 = 0,
    t3: u32 = 0,
    t4: u32 = 0,
    t5: u32 = 0,
    t6: u32 = 0,
    // upon is trap frame

    // save the pc to run in next schedule cycle
    pc: u32, // offset: 31 *4 = 124

    pub fn new(thread_stack: []u8, func: fn () void) TaskRegs {
        return TaskRegs{
            .sp = @ptrToInt(&thread_stack[thread_stack.len - 1]),
            .pc = @ptrToInt(func),
        };
    }
};

const Task = struct {
    // 栈太小的话，会覆盖 context 的空间，mepc 地址不对导致执行 mret 异常
    const STACK_SIZE = if (builtin.mode == .Debug) 2048 else 1024;

    context: TaskRegs,
    stack: [STACK_SIZE]u8 = [_]u8{65} ** STACK_SIZE, // 这里的默认初始化也没有用到，two_tasks 是 undefined

    //pub fn create(func: fn () void) Task {
    //    return .{
    //        .context = TaskRegs.new(func, @this().stack???),
    //    };
    //}
};

// 为了让 switch_to 能访问到，它必须是全局变量
const MAX_TASKS = 2;
pub var two_tasks: [MAX_TASKS]Task = undefined; // 在堆里分配会好写一点吗？

var top: usize = undefined;
var current: usize = undefined;

pub fn info() void {
    for (two_tasks) |*task, i| { // 必须是 *task 才能拿到原变量的地址
        print("task{d}: stack: {*} -> {*} {c}\n", .{
            i,
            &task.stack[0],
            &task.stack[Task.STACK_SIZE - 1],
            task.stack[0],
        });
    }
}

pub fn schedule() void { // 返回类型不能是 noreturn
    current = (current + 1) % top;
    switch_to(&two_tasks[current].context);
}

pub inline fn yield() void {
    // trigger a machine-level software interrupt
    const hart = 0;
    clint.software.trigger(hart);
}

pub fn init() void {
    // 初始化 mscratch
    csr.write("mscratch", 0);

    // 给全局变量赋值
    top = 0;
    current = 1;

    inline for (.{ user_task0, user_task1 }) |func| {
        two_tasks[top].context = TaskRegs.new(&two_tasks[top].stack, func);
        top += 1;
    }
}

const UserData = struct {
    counter: usize,
    str: []const u8,
};

pub var person = UserData{ .counter = 0, .str = "Jack" };

pub fn callback(arg: *anyopaque) void {
    var data = @ptrCast(*UserData, @alignCast(@alignOf(*UserData), arg));
    data.counter += 1;
    print("======> TIMEOUT: {s}: {}\n", .{ data.str, data.counter });
}

fn user_task0() void {
    @setAlignStack(16);
    print("Task 0: Created!\n", .{});
    //yield();

    //swtimer.create(.{ .func = callback, .arg = &person, .tick = 3 });
    //swtimer.create(.{ .func = callback, .arg = &person, .tick = 5 });
    //swtimer.create(.{ .func = callback, .arg = &person, .tick = 7 });

    var hartid: u32 = 65;
    print("ptr: 0x{x}\n", .{@ptrToInt(&hartid)});
    _ = syscall.gethid(&hartid);

    const string = "string";
    _ = syscall.echostr(string[0..4]);

    print("hartid: " ++ "\x1b[32m" ++ "{}\n" ++ "\x1b[m", .{hartid});

    while (true) {
        print("Task 0: Running...\n", .{});
        delay(1000);
    }
}

fn user_task1() void {
    @setAlignStack(16);
    print("Task 1: Created!\n", .{});

    while (true) {
        print("Task 1: Running...\n", .{});
        delay(1000);
    }
}

pub fn delay(x: usize) void {
    var i: usize = 50000 * x;
    var ptr: *volatile usize = &i;
    while (ptr.* > 0) {
        ptr.* -= 1;
    }
}
