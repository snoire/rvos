const root = @import("kernel.zig");
const csr = @import("csr.zig");
const trap = @import("trap.zig");

const print = root.print;

extern fn switch_to(to: *TaskRegs) callconv(.C) void; // 返回类型不能是 noreturn

const TaskRegs = packed struct {
    // Layout must be kept in sync with switch_to
    // ignore x0
    ra: u32,
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

    pub fn new(func: fn () void, thread_stack: []u8) TaskRegs {
        return TaskRegs{ .ra = @ptrToInt(func), .sp = @ptrToInt(&thread_stack[thread_stack.len - 1]) };
    }
};

const Task = struct {
    const STACK_SIZE = 1024;

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
    for (two_tasks) |*task, i| {
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
    schedule();
}

pub fn init() void {
    // 初始化 mscratch
    csr.write("mscratch", 0);

    // 给全局变量赋值
    top = 0;
    current = 1;

    inline for (.{ user_task0, user_task1 }) |func| {
        // 没法用这种方法创建结构体的实例
        //two_tasks.tasks[two_tasks.top] = Task.create(func);

        // 下面的方法可以得到预期结果，先创建，再赋值
        // 但是中间变量会多复制一次。。
        //var task = Task{};
        //task.context = TaskRegs.new(func, &task.stack);
        //two_tasks[top] = task;

        two_tasks[top].context = TaskRegs.new(func, &two_tasks[top].stack);
        top += 1;
    }
}

fn user_task0() void {
    print("Task 0: Created!\n", .{});

    while (true) {
        print("Task 0: Running...\n", .{});
        trap.tests(); // exception!!
        delay(1000);
        yield();
    }
}

fn user_task1() void {
    print("Task 1: Created!\n", .{});

    while (true) {
        print("Task 1: Running...\n", .{});
        delay(1000);
        yield();
    }
}

fn delay(x: usize) void {
    var i: usize = 50000 * x;
    var ptr: *volatile usize = &i;
    while (ptr.* > 0) {
        ptr.* -= 1;
    }
}
