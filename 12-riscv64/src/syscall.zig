const std = @import("std");
const root = @import("kernel.zig");
const csr = @import("csr.zig");
const task = @import("task.zig");

const print = root.print;

pub const Sysnum = enum(u8) {
    gethartid,
};

pub fn call(ctx: *task.TaskRegs) void {
    const sysnum = @intToEnum(Sysnum, ctx.a7);
    switch (sysnum) {
        .gethartid => ctx.a0 = gethartid(@intToPtr(*usize, ctx.a0)),
    }
}

fn gethartid(id: *usize) usize {
    print("--> sys_gethid, arg0 = 0x{x}\n", .{@ptrToInt(id)});
    id.* = csr.read("mhartid");
    return 0;
}
