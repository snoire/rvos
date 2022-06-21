const std = @import("std");
const root = @import("kernel.zig");
const csr = @import("csr.zig");
const task = @import("task.zig");

const print = root.print;
const EnumField = std.builtin.Type.EnumField;
const comptimePrint = std.fmt.comptimePrint;

const syscall = enum(u8) {
    gethid,
    echo,
    _,
};

fn slice(ptr: [*]const u8, len: usize) []const u8 {
    var s: []const u8 = undefined;
    s.ptr = ptr;
    s.len = len;
    return s;
}

// kernel space

pub fn call(ctx: *task.TaskRegs) void {
    const sysnum = @intToEnum(syscall, ctx.a7);
    switch (sysnum) {
        .gethid => ctx.a0 = gethartid(@intToPtr(*u32, ctx.a0)),
        .echo => sys_echo(slice(@intToPtr([*]const u8, ctx.a0), ctx.a1)),
        else => print("unknown syscall\n", .{}),
    }
}

fn gethartid(id: *u32) u32 {
    print("--> sys_gethid, arg0 = 0x{x}\n", .{@ptrToInt(id)});
    id.* = csr.read("mhartid");
    return 0;
}

fn sys_echo(str: []const u8) void {
    print("echo: {s}\n", .{str});
}

// user space

comptime {
    const info = @typeInfo(syscall).Enum;
    inline for (info.fields) |scall| {
        asm (entry(scall));
    }
}

fn entry(comptime scall: EnumField) []const u8 {
    return comptimePrint(
        \\.global {0s}
        \\{0s}:
        \\ li a7, {1d}
        \\ ecall
        \\ ret
        \\
    , .{ scall.name, scall.value });
}

pub extern fn gethid(hartid: *u32) u32;
extern fn echo(ptr: [*]const u8, len: usize) void;

pub fn echostr(str: []const u8) void {
    echo(str.ptr, str.len);
}
