pub inline fn r_tp() u32 {
    return asm volatile ("mv %[ret], tp"
        : [ret] "=r" (-> u32),
    );
}

// which hart (core) is this?
pub inline fn r_mhartid() u32 {
    return asm volatile ("csrr %0, mhartid"
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
