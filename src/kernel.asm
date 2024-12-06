[bits 32]
[global _start]

section .text
kernel_start:
    ; Setup a basic stack for the kernel (just in case)
    mov esp, 0x90000   ; Set the stack pointer (32-bit addressing)

    ; Print "Kernel is running!" at the top-left corner of the screen
    mov si, message    ; Load the address of the message
    call print_string

    ; Halt the CPU (infinite loop)
hang:
    jmp hang

; Function to print a null-terminated string to the screen (VGA text mode)
print_string:
    mov al, [si]         ; Load the current character from the string
    test al, al          ; Check if it's the null terminator
    jz print_done        ; If it's null, we're done
    mov ah, 0x0F         ; Set the text attribute (white on black)
    mov bx, 0xB8000      ; VGA text buffer starting address
    mov di, 0            ; Offset in the buffer (start at the top-left corner)
    mov [bx + di], ax    ; Store character and attribute in the VGA buffer
    inc si               ; Move to the next character in the string
    inc di               ; Move to the next screen position
    jmp print_string     ; Continue printing the string

print_done:
    ret

; Message to print
message db 'Kernel is running!', 0
