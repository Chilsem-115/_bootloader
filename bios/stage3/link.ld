
ENTRY(_main_entry_)

SECTIONS {
	. = 0x00100000;
	.text : { *(.text*) }
	.rodata : { *(.rodata*) }
	.data : { *(.data*) }
	.bss  : { *(.bss*) *(COMMON) }
}
