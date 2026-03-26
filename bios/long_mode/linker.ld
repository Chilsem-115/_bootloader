
/* Zig: 64-bit stage payload, linked to run at physical/virtual 0x00020000. */
ENTRY			(_start)

SECTIONS
{
	. = 0x00020000;

	.text	: ALIGN(16) { *( .text.start ) *( .text .text.* ) }
	.rodata	: ALIGN(16) { *( .rodata .rodata.* ) }
	.data	: ALIGN(16) { *( .data .data.* ) }
	.bss	: ALIGN(16) { __bss_start = .; *(.bss .bss.* COMMON) __bss_end = .; }

	/DISCARD/ : {
		*(.eh_frame_hdr)
		*(.eh_frame)
		*(.comment)
		*(.note*)
		*(.got*)
	}
}
