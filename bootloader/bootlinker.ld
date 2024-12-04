OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)

SECTIONS
{
    /* Stage 1: starts at 0x7C00 */
    . = 0x7C00;
    .stage1 :
    {
        *(.text.stage1)
        *(.rodata.stage1)
        *(.data.stage1)
        *(.bss.stage1)
    }

    /* Stage 2: starts at 0x1000 */
    . = 0x1000;
    .stage2 :
    {
        *(.text.stage2)
        *(.rodata.stage2)
        *(.data.stage2)
        *(.bss.stage2)
    }
}
