const root = @import("kernel.zig");
const csr = @import("csr.zig");

const print = root.print;

extern fn switch_to(to: *TaskRegs) callconv(.C) void; // 返回类型不能是 noreturn
comptime {
    asm (
        \\# a0: pointer to the context of the next task
        \\.globl switch_to
        \\.align 4
        \\switch_to:
        \\        csrrw   t6, mscratch, t6        # swap t6 and mscratch
        \\        beqz    t6, 1f                  # Notice: previous task may be NULL
        \\
        \\        # save context of prev task
        \\        sw ra, 0(t6)
        \\        sw sp, 4(t6)
        \\        sw gp, 8(t6)
        \\        sw tp, 12(t6)
        \\        sw t0, 16(t6)
        \\        sw t1, 20(t6)
        \\        sw t2, 24(t6)
        \\        sw s0, 28(t6)
        \\        sw s1, 32(t6)
        \\        sw a0, 36(t6)
        \\        sw a1, 40(t6)
        \\        sw a2, 44(t6)
        \\        sw a3, 48(t6)
        \\        sw a4, 52(t6)
        \\        sw a5, 56(t6)
        \\        sw a6, 60(t6)
        \\        sw a7, 64(t6)
        \\        sw s2, 68(t6)
        \\        sw s3, 72(t6)
        \\        sw s4, 76(t6)
        \\        sw s5, 80(t6)
        \\        sw s6, 84(t6)
        \\        sw s7, 88(t6)
        \\        sw s8, 92(t6)
        \\        sw s9, 96(t6)
        \\        sw s10, 100(t6)
        \\        sw s11, 104(t6)
        \\        sw t3, 108(t6)
        \\        sw t4, 112(t6)
        \\        sw t5, 116(t6)
        \\
        \\        # we don't save t6 here, due to we have used
        \\        # it as base, we have to save t6 in an extra step
        \\        # outside of reg_save
        \\
        \\        # Save the actual t6 register, which we swapped into
        \\        # mscratch
        \\        mv      t5, t6          # t5 points to the context of current task
        \\        csrr    t6, mscratch    # read t6 back from mscratch
        \\        sw      t6, 120(t5)     # save t6 with t5 as base
        \\
        \\1:
        \\        # switch mscratch to point to the context of the next task
        \\        csrw    mscratch, a0
        \\
        \\        # Restore all GP registers
        \\        # Use t6 to point to the context of the new task
        \\        mv      t6, a0
        \\
        \\        lw ra, 0(t6)
        \\        lw sp, 4(t6)
        \\        lw gp, 8(t6)
        \\        lw tp, 12(t6)
        \\        lw t0, 16(t6)
        \\        lw t1, 20(t6)
        \\        lw t2, 24(t6)
        \\        lw s0, 28(t6)
        \\        lw s1, 32(t6)
        \\        lw a0, 36(t6)
        \\        lw a1, 40(t6)
        \\        lw a2, 44(t6)
        \\        lw a3, 48(t6)
        \\        lw a4, 52(t6)
        \\        lw a5, 56(t6)
        \\        lw a6, 60(t6)
        \\        lw a7, 64(t6)
        \\        lw s2, 68(t6)
        \\        lw s3, 72(t6)
        \\        lw s4, 76(t6)
        \\        lw s5, 80(t6)
        \\        lw s6, 84(t6)
        \\        lw s7, 88(t6)
        \\        lw s8, 92(t6)
        \\        lw s9, 96(t6)
        \\        lw s10, 100(t6)
        \\        lw s11, 104(t6)
        \\        lw t3, 108(t6)
        \\        lw t4, 112(t6)
        \\        lw t5, 116(t6)
        \\        lw t6, 120(t6)
        \\
        \\        # Do actual context switching.
        \\        ret
        \\
        \\.end
    );
}

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
