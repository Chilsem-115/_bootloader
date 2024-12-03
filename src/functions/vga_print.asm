section .text
    global print_string

; Procedure to print a string passed via SI register
print_string:
    mov di, 0xB8000        ; DI points to the start of the VGA buffer (text mode)
    mov ax, 0x0F           ; Set the attribute (white on black)
    
print_char:
    mov al, [si]           ; Load the current character from the string
    cmp al, 0              ; Check if it's the null terminator (0x00)
    je done                ; If it's null terminator, we're done

    cmp al, 0xA            ; Check if the character is a newline (0x0A)
    je newline             ; If it's newline, jump to handle newline

    cmp al, 0x0D           ; Check if the character is a carriage return (0x0D)
    je carriage_return     ; If it's carriage return, jump to handle it

    ; Otherwise, write the character and its attribute
    mov [di], ax           ; Write the character and attribute to the VGA buffer
    add di, 2              ; Move to the next position (each character takes 2 bytes)
    inc si                 ; Move to the next character in the string
    jmp print_char         ; Repeat for the next character

newline:
    ; Handle newline (0x0A)
    add di, 160            ; Move down by 1 line (80 columns * 2 bytes per character = 160 bytes)
    inc si                 ; Move to the next character
    jmp print_char         ; Continue writing the next character

carriage_return:
    ; Handle carriage return (0x0D)
    and di, 0xF800         ; Mask out the column bits (set DI to the start of the current row)
    inc si                 ; Move to the next character
    jmp print_char         ; Continue writing the next character

done:
    ret                    ; Return to the caller
