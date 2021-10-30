const print = @import("kernel.zig").print;  // root
pub extern fn switch_to(to: *TaskRegs) callconv(.C) void;

pub const TaskRegs = packed struct {
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

    //const Self = @This();

    pub fn new(func: fn () noreturn, thread_stack: []u8) TaskRegs {
        return TaskRegs{ .ra = @ptrToInt(func), .sp = @ptrToInt(&thread_stack[thread_stack.len - 1]) };
    }

    //pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, stream: anytype) !void {
    //    _ = fmt;
    //    try stream.writeAll(@typeName(Self));
    //    try stream.writeAll("{rsp=0x");
    //    try std.fmt.formatInt(self.rsp, 16, .lower, options, stream);
    //    try stream.writeAll("}");
    //}
};

pub const Task = struct {
    regs: TaskRegs,
    stack: []u8,

    //const Self = @This();
    pub fn create(func: fn () noreturn) Task {
        var task: Task = undefined;
        var stack = [_]u8{0} ** 1024;
        task.regs = TaskRegs.new(func, &stack);
        task.stack = &stack;
        return task;
    }

    //pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, stream: anytype) !void {
    //    _ = fmt;
    //    try stream.writeAll(@typeName(Self));
    //    try stream.writeAll("{");
    //    try std.fmt.formatType(self.regs, fmt, options, stream, 1);
    //    try stream.writeAll("}");
    //}
};

fn w_mscratch(x: u64) void {
    return asm volatile("csrw mscratch, %[value]"
        :
        : [value] "r" (x));
}

fn sched_init() void {
    w_mscratch(0);
}

pub fn user_task0() noreturn {
    try print("Task 0: Created!\n", .{});

    while (true) {
        try print("Task 0: Running...\n", .{});
        delay(1000);
    }
}

fn delay(x: usize) void {
    var i: usize = 50000 * x;
    var ptr: *volatile usize = &i;
    while (ptr.* > 0) {
        ptr.* -= 1;
    }
}
