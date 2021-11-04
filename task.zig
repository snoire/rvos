const print = @import("root").print;
const arch = @import("root").arch;
const trap = @import("trap.zig");
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

    regs: TaskRegs = .{ .ra = 0, .sp = 0 },
    stack: [STACK_SIZE]u8 = [_]u8{0} ** STACK_SIZE,
};

// 为了让 switch_to 能访问到，它必须是全局变量
var two_tasks: Tasks = undefined;
pub const tasks = &two_tasks;

pub const Tasks = struct {
    const MAX_TASKS = 10;
    tasks: [MAX_TASKS]Task,
    top: usize,
    current: usize,

    pub fn init() void {
        // 初始化 mscratch
        arch.w_mscratch(0);

        // 给全局变量 two_tasks 赋值
        two_tasks.top = 0;
        two_tasks.current = 1;

        inline for (.{ user_task0, user_task1 }) |func| {
            // 不能用这种方法创建结构体的实例，不然两个结构体 stack 是相同的
            //two_tasks.tasks[two_tasks.top] = Task.create(func);
            // 下面的方法可以得到预期结果，先创建，再赋值
            var task = Task{};
            task.regs = TaskRegs.new(func, &task.stack);

            two_tasks.tasks[two_tasks.top] = task;
            two_tasks.top += 1;
        }
    }

    pub fn info(self: *Tasks) void {
        comptime var i = 0;
        inline for (.{ user_task0, user_task1 }) |func| {
            print("task{d}: {any}, stack: {*} -> {*}\n", .{
                i,
                func,
                &self.tasks[i].stack[0],
                &self.tasks[i].stack[self.tasks[i].stack.len - 1],
            });
            i += 1;
        }
    }

    pub fn schedule(self: *Tasks) void { // 返回类型不能是 noreturn
        self.current = (self.current + 1) % self.top;
        switch_to(&self.tasks[self.current].regs);
    }

    pub inline fn yield(self: *Tasks) void {
        self.schedule();
    }
};

fn user_task0() void {
    print("Task 0: Created!\n", .{});

    while (true) {
        print("Task 0: Running...\n", .{});
        //trap.tests(); // exception!!

        delay(1000);
        tasks.yield();
    }
}

fn user_task1() void {
    print("Task 1: Created!\n", .{});

    while (true) {
        print("Task 1: Running...\n", .{});
        delay(1000);
        tasks.yield();
    }
}

fn delay(x: usize) void {
    var i: usize = 50000 * x;
    var ptr: *volatile usize = &i;
    while (ptr.* > 0) {
        ptr.* -= 1;
    }
}
