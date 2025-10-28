
/* Zig Stage-3: 32-bit, physical load = 0x0010_0000, no paging. */
ENTRY			(_start)

SECTIONS
{
  . = 0x00002000;

  .text		: ALIGN(16) { *(.text.start) *(.text .text.*) }
  .rodata	: ALIGN(16) { *(.rodata .rodata.*) }
  .data		: ALIGN(16) { *(.data .data.*) }
  .bss		: ALIGN(16) { __bss_start = .; *(.bss .bss.* COMMON) __bss_end = .;
  }
}
