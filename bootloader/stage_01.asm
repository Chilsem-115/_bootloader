org 0x7c00
[bits 16]

; Set up the stack
cli						; Disable interrupts
xor ax, ax				; Clear AX register (set to 0)
mov ds, ax				; Data segment to 0
mov es, ax				; Extra segment to 0
mov ss, ax				; Stack segment to 0
mov sp, 0x7C00			; Set stack pointer to 0x7C00

; Clear the screen
clear_screen:
	mov ax, 0x0600			; Scroll function, clear entire screen
	mov bh, 0x07			; Attribute (white on black)
	mov cx, 0x0000			; Start at top-left corner (row 0, column 0)
	mov dx, 0x184F			; Bottom-right corner (row 24, column 79)
	int 0x10				; Call BIOS video interrupt

; Set up video interrupt
	mov ah, 0x01          ; Function 01h - Set Cursor Shape
	mov ch, 0x20          ; Start line (0x20 makes it invisible)
	mov cl, 0x20          ; End line (0x20 makes it invisible)
	int 0x10              ; Call BIOS video interrupt

; Load the stage 2 into memory
	mov ah, 0x02			; BIOS disk read function (AH=0x02)
	mov al, 1			; Number of sectors to read
	mov ch, 0			; Cylinder (track) 0
	mov cl, 2			; Sector 2 (where the kernel is stored)
	mov dh, 0			; Head 0
	mov dl, 0x80			; Drive 0x80 (first hard drive)
	mov bx, 0x8000			; Load the kernel into memory at address 0x1000
	int 0x13				; Call BIOS interrupt to read the sector

; Jump to the kernel (loaded at 0x1000)
	jmp 0x8000				; Jump to address 0x1000 where the kernel is loaded

; Print routine
times 510 - ($ - $$) db 0		; Pad the bootloader to 510 bytes
dw 0xAA55					; Bootloader signature
