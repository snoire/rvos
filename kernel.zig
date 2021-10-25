const uart = @import("uart.zig");

export fn start_kernel() noreturn {
    _ = uart.write("Hello, RVOS!\n");

    while (true) {}     // stop here!
}
