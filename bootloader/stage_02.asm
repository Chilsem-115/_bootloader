[org 0x8000]
[bits 16]

%include "bootloader_defs.asm"

Global _start		; Define _start as the entry point
_start:

mov ah, 0x0E
mov al, 'A'
int 0x10


	mov si, msg_stage_02		; Load address of the message
	call print_string



	lgdt [gdt_descriptor]	; Load GDT

	; Enable protected mode
	mov eax, cr0
	or eax, 0x1			; Set PE (Protection Enable) bit in CR0
	mov cr0, eax

	; Far jump to enter protected mode and clear prefetch queue
	jmp 0x08:protected_mode_start
	
; Function to print a null-terminated string using BIOS interrupt 0x10
print_string:
	mov al, [si]			; Load character from string
	test al, al				; Check if it is the null terminator
	jz print_done			; If null terminator, return
	mov ah, 0x0E			; BIOS function to print a character
	mov bh, 0x00			; Page number (0 for the default screen)
	mov bl, 0x07			; Text attribute (light grey on black)
	int 0x10				; Call BIOS interrupt to print the character
	inc si					; Move to next character in string
	jmp print_string		; Repeat until null terminator

print_done:
	ret

; Message to print
message db 'Bootloader stage 2 has been loaded successfully!', 0

[bits 32]
protected_mode_start:
	; Update segment registers to use GDT
	mov ax, 0x10			; Data segment selector in GDT (index 1)
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax				; Stack segment for the protected mode code

	; Setup the stack for 32-bit mode
	mov esp, 0x90000		; Set the stack pointer (example address)

	; Load the kernel from disk (assuming it's at LBA 3 for example)
	mov ax, 3				; LBA = 3 (Kernel starts here)
	mov cl, 1				; Read 1 sector
	mov bx, 0x10000			; Load the kernel at 0x10000
	call disk_read

	; Now jump to the kernel's entry point (assuming it's at 0x10000)
	jmp 0x10000				; Jump to the kernel (entry point)

	; Hang the system (infinite loop to halt the CPU)
hang:
	halt
	jmp hang

; Global Descriptor Table (GDT)
gdt_start:
	; Null descriptor (index 0)
	dq 0x0				; No base and limit

	; 32-bit Code Segment Descriptor (index 1)
	dw 0xFFFF			; Segment limit (15:0)
	dw 0x0000			; Base address (15:0)
	db 0x00				; Base address (23:16)
	db 10011010b		; Access byte: executable, readable, present
	db 11001111b		; Flags: 4KB granularity, 32-bit
	db 0x00				; Base address (31:24)

	; 32-bit Data Segment Descriptor (index 2)
	dw 0xFFFF			; Segment limit (15:0)
	dw 0x0000			; Base address (15:0)
	db 0x00				; Base address (23:16)
	db 10010010b		; Access byte: writable, present
	db 11001111b		; Flags: 4KB granularity, 32-bit
	db 0x00				; Base address (31:24)

gdt_end:

; GDT descriptor
gdt_descriptor:
	dw gdt_end - gdt_start - 1	; Limit (size of GDT - 1)
	dd gdt_start				; Address of GDT (base)

; Disk read routines
disk_read:
	push ax						; Save registers
	push bx
	push cx
	push dx
	push di

	; LBA to CHS conversion
	push cx						; Temporarily save CL (number of sectors)
	call lba_to_chs				; Convert LBA to CHS
	pop ax						; Restore CL (sectors to read)

	; Perform disk read using BIOS interrupt 0x13
	mov ah, 0x02				; BIOS function to read sectors
	mov di, 3					; Retry count

.retry:
	pusha						; Save all registers
	stc							; Set carry flag
	int 0x13						; Call BIOS interrupt 0x13 (disk read)
	jnc .done					; Jump if carry is clear (successful)

	; Read failed, retry
	popa
	call disk_reset

	dec di
	test di, di
	jnz .retry


.done:
	popa						; Restore registers
	pop di
	pop dx
	pop cx
	pop bx
	pop ax						; Restore all registers
	ret

	; All attempts exhausted, jump to error handling
fail:
	jmp floppy_error

disk_reset:
	pusha
	mov ah, 0
	stc
	int 0x13
	jc floppy_error
	popa
	ret

lba_to_chs:
	push ax
	push dx

	; Convert LBA to CHS (Cylinder, Head, Sector)
	xor dx, dx				; Clear dx
	div word [bdb_sectors_per_track]	; Divide LBA by sectors per track
	mov cx, dx				; CX = sector (LBA mod sectors per track)

	xor dx, dx				; Clear dx again
	div word [bdb_heads]		; Divide by the number of heads
	mov dh, dl				; Head = remainder
	mov ch, al				; Cylinder (lower 8 bits)
	shl ah, 6
	or cl, ah				; Cylinder (upper 2 bits in CL)

	pop ax
	mov dl, al				; Restore DL (drive number)
	pop ax
	ret

floppy_error:
	mov si, msg_read_failed
	call print_string
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 0x16					; Wait for keypress
	jmp 0x0FFFF:0			; Reboot

msg_stage_02:		db 'Stage 2 has been initiated!', ENDL, 0
msg_read_failed:	db 'Read from disk failed!', ENDL, 0
