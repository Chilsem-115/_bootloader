ENTRY(_start)

SECTIONS
{
    . = 0x0;  /* Start the kernel at this address */

	.text :
    { *(.text) }
    .data :
    { *(.data) }
    .bss :
    { *(.bss) }
}
