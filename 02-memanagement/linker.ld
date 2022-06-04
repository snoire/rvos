OUTPUT_ARCH( "riscv" )

ENTRY( _start )

MEMORY
{
    /* llvm 好像不支持 i 这个属性 */
    ram (wxa!r) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS
{
    . = 0x80000000;

    .text : {
        /* 确保 .text_start (_start 函数) 在开头 */
        *(.text_start)
        *(.text .text.*)
    }

    /* 不指定的话，rodata 默认会放在 text 之前 */
    .rodata : { 
        *(.rodata .rodata.*)
    }

    .bss :{
        *(.sbss .sbss.*)
        *(.bss .bss.*)
        *(COMMON)
    }

    PROVIDE(_memory_start = ORIGIN(ram));
    PROVIDE(_memory_end = ORIGIN(ram) + LENGTH(ram));

    PROVIDE(_heap_start = .);
    PROVIDE(_heap_size = _memory_end - _heap_start);
}
