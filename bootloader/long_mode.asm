
; prints a message indicating that long mode is supposed
check_succeed:
	mov esi, success_64_msg
	call print_vga
; checking if long mode can be used or not through extended function
	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000001
	jb	.NoLongmode

; detecting longmode
	mov eax, 0x80000001
	cpuid
	test edx, 1 shl 29
	jz	.NoLongmode

	mov esi, yes_longmode
	call print_vga

	jmp hang

.NoLongmode:
	mov esi, no_longmode
	call print_vga
	call hang

; prints a message indicating that long mode is not supported
check_failed:
	mov esi, error_64_msg
	call	print_vga
	call hang


; ===================== Byte definition section ===================== ;
success_64_msg	db "%gCPU supports long mode%, initialization in proccess...", 0x0
error_64_msg	db "CPU does not support long mode, the switch to long mode has %rfailed%", 0x0
no_longmode		db "Long mode is not supported in this machine", 0x0
yes_longmode	db "Longmode is %gsupported% in this machine!", 0x0
