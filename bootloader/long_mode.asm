
; prints a message indicating that long mode is supposed
check_succeed:
	mov esi, success_64_msg
	call print_vga
	call halt

; prints a message indicating that long mode is not supported
check_failed:
	mov esi, error_64_msg
	call	print_vga
	call halt


; ===================== Byte definition section ===================== ;
success_64_msg db "%gCPU supports long mode%, initialization in proccess...", 0x0
error_64_msg db "CPU does not support long mode, the switch to long mode has %rfailed%", 0x0
