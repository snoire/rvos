const std = @import("std");
const PLIC = @import("mmio.zig").PLIC;
const arch = @import("root").arch;
const uart = @import("uart.zig");

/// Enable these interrupts with these priorities.
const interrupts = [_]struct { id: u6, priority: u3 }{
    // The UART's Data Received interrupt.
    .{ .id = 10, .priority = 1 },
};

pub fn init() void {
    var hart = arch.r_tp(); // start.S 中把 hartid 放在 tp 里了

    for (interrupts) |interrupt| {
        // Set priority for UART0.
        //
        // Each PLIC interrupt source can be assigned a priority by writing
        // to its 32-bit memory-mapped priority register.
        // The QEMU-virt (the same as FU540-C000) supports 7 levels of priority.
        // A priority value of 0 is reserved to mean "never interrupt" and
        // effectively disables the interrupt.
        // Priority 1 is the lowest active priority, and priority 7 is the highest.
        // Ties between global interrupts of the same priority are broken by
        // the Interrupt ID; interrupts with the lowest ID have the highest
        // effective priority.
        //
        PLIC.priority.writeOffset(
            u3,
            4 * interrupt.id,
            interrupt.priority,
        );

        // Enable UART0
        //
        // Each global interrupt can be enabled by setting the corresponding
        // bit in the enables registers.
        // 0b1: enable, 0b0: disable
        //
        PLIC.enable.writeOffset(
            u64,    // 有两个 Enable 寄存器，所以应该是两倍的 usize
            hart * 0x80,
            //PLIC.enable.readOffset(usize, hart * 0x80) | @as(usize, 0b1) << interrupt.id,
            PLIC.enable.read(u64) | (@as(u64, 0b1) << interrupt.id),
        );
    }

    // Set priority threshold for UART0.
    //
    // PLIC will mask all interrupts of a priority less than or equal to threshold.
    // Maximum threshold is 7.
    // For example, a threshold value of zero permits all interrupts with
    // non-zero priority, whereas a value of 7 masks all interrupts.
    // Notice, the threshold is global for PLIC, not for each interrupt source.
    //
    PLIC.threshold.writeOffset(
        u3,
        hart * 0x1000,
        0,
    );

    // enable machine-mode external interrupts.
    arch.w_mie(arch.r_mie() | arch.mie.meie);

    // enable machine-mode global interrupts.
    arch.w_mstatus(arch.r_mstatus() | arch.mstatus.mie);
}

// DESCRIPTION:
//	Query the PLIC what interrupt we should serve.
//	Perform an interrupt claim by reading the claim register, which
//	returns the ID of the highest-priority pending interrupt or zero if there
//	is no pending interrupt.
//	A successful claim also atomically clears the corresponding pending bit
//	on the interrupt source.
// RETURN VALUE:
//	the ID of the highest-priority pending interrupt or zero if there
//	is no pending interrupt.
//
pub fn claim() ?u6 {
    var hart = arch.r_tp();
    const id = PLIC.claim.readOffset(u6, hart * 0x1000);
    return if (id == 0) null else id;
}

//
// DESCRIPTION:
// 	Writing the interrupt ID it received from the claim (irq) to the
//	complete register would signal the PLIC we've served this IRQ.
//	The PLIC does not check whether the completion ID is the same as the
//	last claim ID for that target. If the completion ID does not match an
//	interrupt source that is currently enabled for the target, the completion
//	is silently ignored.
// RETURN VALUE: none
//
pub fn complete(id: u6) void {
    var hart = arch.r_tp();
    PLIC.complete.writeOffset(u6, hart * 0x1000, id);
}

pub fn handle() void {
    const id = claim().?;

    switch (id) {
        10 => uart.handleInterrupt(),
        else => {
            var buf = [_]u8{0} ** 128;

            @panic(std.fmt.bufPrint(
                buf[0..],
                "unhandled PLIC interrupt, source {}",
                .{id},
            ) catch unreachable);
        },
    }
    complete(id);
}
