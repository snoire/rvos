// Machine Status Register, mstatus
pub const mstatus = struct {
    pub const mpp = 3 << 11;
    pub const spp = 1 << 8;
    pub const mpie = 1 << 7;
    pub const spie = 1 << 5;
    pub const upie = 1 << 4;
    pub const mie = 1 << 3;
    pub const sie = 1 << 1;
    pub const uie = 1 << 0;
};

// Machine-mode Interrupt Enable
pub const mie = struct {
    pub const msie = 1 << 3; // software
    pub const mtie = 1 << 7; // timer
    pub const meie = 1 << 11; // external
};

pub fn read(comptime name: []const u8) usize {
    return asm volatile ("csrr %[ret], " ++ name
        : [ret] "=r" (-> usize),
    );
}

pub fn write(comptime name: []const u8, value: usize) void {
    asm volatile ("csrw " ++ name ++ ", %[value]"
        :
        : [value] "r" (value),
    );
}

pub fn set(comptime name: []const u8, mask: usize) void {
    asm volatile ("csrs " ++ name ++ ", %[mask]"
        :
        : [mask] "r" (mask),
    );
}

pub fn clear(comptime name: []const u8, mask: usize) void {
    asm volatile ("csrc " ++ name ++ ", %[mask]"
        :
        : [mask] "r" (mask),
    );
}
