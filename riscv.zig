pub inline fn r_tp() u32 {
    return asm volatile ("mv %[ret], tp"
        : [ret] "=r" (-> u32),
    );
}

// which hart (core) is this?
pub inline fn r_mhartid() u32 {
    return asm volatile ("csrr %[ret], mhartid"
        : [ret] "=r" (-> u32),
    );
}

// Machine Scratch register, for early trap handler
pub inline fn w_mscratch(x: u64) void {
    return asm volatile ("csrw mscratch, %[value]"
        :
        : [value] "r" (x),
    );
}

// Machine-mode interrupt vector
pub inline fn w_mtvec(x: u32) void {
    return asm volatile ("csrw mtvec, %[value]"
        :
        : [value] "r" (x),
    );
}

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

pub inline fn r_mstatus() u32 {
    return asm volatile ("csrr %[ret], mstatus"
        : [ret] "=r" (-> u32),
    );
}

pub inline fn w_mstatus(x: u32) void {
    return asm volatile ("csrw mstatus, %[value]"
        :
        : [value] "r" (x),
    );
}

// Machine-mode Interrupt Enable
pub const mie = struct {
    pub const msie = 1 << 3; // software
    pub const mtie = 1 << 7; // timer
    pub const meie = 1 << 11; // external
};

pub inline fn r_mie() u32 {
    return asm volatile ("csrr %[ret], mie"
        : [ret] "=r" (-> u32),
    );
}

pub inline fn w_mie(x: u32) void {
    return asm volatile ("csrw mie, %[value]"
        :
        : [value] "r" (x),
    );
}
