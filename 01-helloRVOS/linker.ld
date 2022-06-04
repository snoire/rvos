OUTPUT_ARCH( "riscv" )

ENTRY( _start )

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
}
