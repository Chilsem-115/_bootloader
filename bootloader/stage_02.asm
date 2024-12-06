[bits 16]

start:
    ; Disable interrupts
    cli

    ; Setup stack
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Load GDT
    lgdt [gdt_descriptor]

    ; Enable protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to protected mode
    jmp 0x08:protected_mode

[bits 32]
protected_mode:
    ; Update segment registers
    mov ax, 0x10            ; Data segment selector (from the GDT)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Write character 'A' to VGA memory in direct mode
    mov edi, 0xb8000        ; VGA text mode memory address (start of video memory)
    mov al, 'A'             ; ASCII value of 'A'
    mov ah, 0x6            ; Attribute byte (white text on black background)
    mov [edi], ax           ; Write the character and attribute to VGA memory

    ; Hang the CPU
    cli
    hlt
    jmp $

; Global Descriptor Table
gdt_start:
    dq 0x0000000000000000   ; Null descriptor
    dq 0x00cf9a000000ffff   ; Code segment descriptor (for 32-bit mode)
    dq 0x00cf92000000ffff   ; Data segment descriptor (for 32-bit mode)

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start
gdt_end:
