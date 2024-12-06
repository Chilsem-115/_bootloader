[org 0x0]
[bits 16]

mov [BOOT_DISK], dl               ; Store the boot disk number

; Print the message in real mode using BIOS interrupt 0x10
mov si, message                  ; Load the address of the message
call print_string                ; Call the print function

; GDT initialization
CODE_SEG equ GDT_code - GDT_start
DATA_SEG equ GDT_data - GDT_start

cli
lgdt [GDT_descriptor] ; Load GDT descriptor
mov eax, cr0
or eax, 1             ; Set PE (Protection Enable) bit to enter protected mode
mov cr0, eax

; Far jump format: jmp [segment selector], offset
jmp CODE_SEG:start_protected_mode ; Jump to protected mode

jmp hang               ; In case something goes wrong

hang:
    halt
    jmp hang

; GDT initialization section
GDT_start:
    GDT_null:
        dd 0x0
        dd 0x0

    GDT_code:                 ; Code segment descriptor
        dw 0xffff             ; Limit (16-bit max)
        dw 0x0                ; Base address (start at 0)
        db 0x0
        db 0b10011010         ; Granularity, type, access byte (code segment)
        db 0b11001111
        db 0x0

    GDT_data:                 ; Data segment descriptor
        dw 0xffff             ; Limit (16-bit max)
        dw 0x0                ; Base address (start at 0)
        db 0x0
        db 0b10010010         ; Granularity, type, access byte (data segment)
        db 0b11001111
        db 0x0

GDT_end:

GDT_descriptor:
    dw GDT_end - GDT_start - 1  ; GDT size in bytes
    dd GDT_start                ; Address of the GDT

[bits 32] ; Protected mode code

start_protected_mode:
    ; Set up the segment registers for protected mode
    mov ax, DATA_SEG
    mov ds, ax                 ; Load data segment
    mov ss, ax                 ; Load stack segment (same as data segment)
    
    ; Set up the code segment (CS) for 32-bit access
    mov ax, CODE_SEG
    mov cs, ax                 ; Load code segment (32-bit selector)

    ; Now, we can safely write to VGA buffer at 0xb8000
    ; Since DS is already set correctly, we use a 32-bit offset for accessing VGA memory
    mov al, 'A'                ; Character to print
    mov ah, 0x0F               ; Attribute (white on black)
    
    ; Set the offset to 0xb8000
    lea di, [0xb8000]          ; Load the effective address (di = 0xb8000)

    ; Write to VGA memory at the offset
    mov [di], ax               ; Write the character and attribute

    ; Infinite loop to keep the system running in protected mode
    jmp $

BOOT_DISK: db 0               ; Placeholder for the boot disk number

times 510-($-$$) db 0         ; Fill the rest of the boot sector
dw 0xaa55                    ; Boot signature

; Real mode message to print before jumping to protected mode
message db 'Stage 2 has been initiated successfully', 0

; Function to print a string using BIOS interrupt 0x10 (AH=0x0E)
print_string:
    mov ah, 0x0E         ; BIOS teletype output function
    mov bh, 0x00         ; Page number (0)
    
print_char:
    lodsb                ; Load byte at [DS:SI] into AL
    or al, al            ; Check if it's the null terminator (end of string)
    jz done              ; If it's zero, end the string
    int 0x10             ; Call BIOS interrupt 0x10 (AH = 0x0E)
    jmp print_char       ; Repeat for the next character

done:
    ret
