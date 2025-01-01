[org 0x8000]
[bits 16]

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

[bits	32]
protected_mode:
	; Update segment registers
	mov	ax,	0x10			; Data segment selector (from the GDT)
	mov	ds,	ax
	mov	es,	ax
	mov	fs,	ax
	mov	gs,	ax
	mov	ss,	ax

; Write a string to VGA memory in direct mode
	mov	esi, msg
	call	print_vga

; halting the system and entering the infinite loop
	cli
	hlt
	jmp	$

msg	db	"         The boot process was: %gsuccessful!% Welcome to %rAscensionOS!%",	0

%include	"print_vga.asm"

; Global Descriptor Table
gdt_start:
	dq	0x0000000000000000			; Null descriptor
	dq	0x00cf9a000000ffff			; Code segment descriptor (for 32-bit mode)
	dq	0x00cf92000000ffff			; Data segment descriptor (for 32-bit mode)

gdt_descriptor:
	dw	gdt_end	-	gdt_start	-	1
	dd	gdt_start
gdt_end:
