const csr = @import("csr.zig");

pub fn lock() void {
    csr.clear("mstatus", csr.mstatus.mie);
}

pub fn unlock() void {
    csr.set("mstatus", csr.mstatus.mie);
}
