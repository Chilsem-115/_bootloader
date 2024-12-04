OUTPUT_FORMAT("elf32-i386")
ENTRY(kernel_start)

SECTIONS
{
    /* Kernel starts at 1MB */
    . = 0x100000;

    .text :
    {
        *(.text)
    }

    .data :
    {
        *(.data)
    }

    .bss :
    {
        *(.bss COMMON)
        /* Align the BSS section to ensure proper memory alignment */
        . = ALIGN(4);
    }
}
