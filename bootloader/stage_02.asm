org 0x8000

start:
	; Disable interrupts
	cli

	; Setup stack
	xor	ax,	ax
	mov	ss,	ax
	mov	sp,	0x7c00

	; Load GDT
	lgdt	[gdt_descriptor]

	; Enable protected mode
	mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax

	; Far jump to protected mode
	jmp	0x08:protected_mode

use32
protected_mode:
	; Update segment registers
	mov	ax,	0x10			; Data segment selector (from the GDT)
	mov	ds,	ax
	mov	es,	ax
	mov	fs,	ax
	mov	gs,	ax
	mov	ss,	ax

	mov edi, 0xb8000 ; setup pointer to the direct VGA

; Write a string to VGA memory in direct mode
	mov	esi, msg
	call	print_vga

	pushfd
	pop eax
	mov ecx, eax

	xor eax, 0x200000 ; 1 << 21

	push eax
	popfd
	pushfd
	pop eax
	push ecx
	popfd
	xor eax, ecx
	jz	check_failed
	jnz check_succeed

	call hang

; halting the system and entering the infinite loop
hang:
	cli
	hlt
	jmp	$


msg	db	"The boot process was: %gsuccessful!% Welcome to %rAscensionOS!%  ", 0x0

include 'long_mode.asm'
include	'print_vga.asm'

	
; Global Descriptor Table
gdt_start:
GDT_NULL:		dq	0x0							; Null descriptor
GDT_BOOT_DS:	dq	0x00cf9a000000ffff			; Code segment descriptor (for 32-bit mode)
GDT_BOOT_CS:	dq	0x00cf92000000ffff			; Data segment descriptor (for 32-bit mode)
GDT_CS64:		dq	0x00209A0000000000			; Code segment descriptor (for 64 bit mode)
GDT_DS64:		dq	0x0000920000000000			; Data segment descriptor (for 64 bit mode)

gdt_descriptor:
	dw	gdt_end	- gdt_start	- 1
	dd	gdt_start

gdt_end:
