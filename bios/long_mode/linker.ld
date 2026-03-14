
/* Zig: 32-bit stage, physical load = 0x0010_0000; paging starts disabled. */
ENTRY			(_start)

SECTIONS
{
  . = 0x00002000;

  .text		: ALIGN(16) { *(.text.start) *(.text .text.*) }
  .rodata	: ALIGN(16) { *(.rodata .rodata.*) }
  .data		: ALIGN(16) { *(.data .data.*) }
  .bss		: ALIGN(16) { __bss_start = .; *(.bss .bss.* COMMON) __bss_end = .; }
}
