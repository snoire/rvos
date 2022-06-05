const std = @import("std");
const root = @import("kernel.zig");
const lock = @import("lock.zig");

const print = root.print;
const allocator = root.allocator;
const TimerList = std.ArrayList(Timer);

pub const Timer = struct {
    func: fn (data: *anyopaque) void,
    arg: *anyopaque,
    tick: usize,
};

pub var timer_list: TimerList = undefined;
var spinlock: lock.SpinLock = undefined;

pub fn init() void {
    timer_list = TimerList.initCapacity(allocator, 10) catch |err| @panic(@errorName(err));
    spinlock = lock.SpinLock.init();
}

pub fn create(t: Timer) void {
    // use lock to protect the shared timer_list between multiple tasks
    var held = spinlock.acquire();
    defer held.release();

    timer_list.append(t) catch |err| @panic(@errorName(err));
}
