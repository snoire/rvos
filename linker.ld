OUTPUT_ARCH( "riscv" )

ENTRY( _start )

PHDRS {
    text PT_LOAD FLAGS(5);   /* R-X */
    rodata PT_LOAD FLAGS(4); /* R-- */
    data PT_LOAD FLAGS(6);   /* RW  */
}

SECTIONS
{
    . = 0x80000000;

    .text : {
		*(.text .text.*)
    } :text

    .rodata : { 
		*(.rodata .rodata.*)
    } :rodata

    .data : { 
		*(.data .data.*)
    } :data

    .bss : { 
		*(.bss .bss.*)
    } :data

    /DISCARD/ : { *(.comment) }
}
