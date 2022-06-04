/// 顶层声明与顺序无关，为了确保 _start 在程序开头，需要在链接脚本中重新组织程序
/// 用 readelf -We os.elf 命令查看编译出的 section/segment 结构
export fn _start() linksection(".text_start") callconv(.Naked) noreturn {
    asm volatile (
        \\  csrr    t0, mhartid
        \\  bnez    t0, park
    );

    asm volatile ("park:");
    while (true) {
        asm volatile ("wfi");
    }
}
