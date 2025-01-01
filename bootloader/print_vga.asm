print_vga:
    mov edi, 0xb8000        ; VGA memory address for the first character
    mov ah, 0xF             ; Attribute byte
    push ebx
	xor ebx, ebx

.loop:
    mov al, [esi + ebx]      ; Load the character at msg + bx into al
    cmp al, 0               ; Check if it's the null terminator (end of string)
    je .done                ; If null, jump to done
	
	cmp al, '%'
	je .check

    mov [edi], eax           ; Write character (al) and attribute (ah) to VGA memory
    add edi, 2              ; Move to the next character space (2 bytes per character)

    inc ebx                  ; Increment bx to move to the next character in msg
    jmp .loop               ; Repeat the loop

.check
	inc ebx
	mov al, [esi + ebx]
	cmp al, 'r'
	je .red
	cmp al, 'g'
	je .green
	cmp al, 'b'
	je .blue
	
	jmp .loop

.red:
	mov ah, 0xC
	inc ebx
	mov al, [esi + ebx]
	cmp al, '%'
	je	.restore
    cmp al, 0
    je .done
	mov [edi], eax
	add edi, 2
	jmp .red

.green:
	mov ah, 0xA
	inc ebx
	mov al, [esi + ebx]
	cmp al, '%'
	je	.restore
    cmp al, 0
    je .done
	mov [edi], eax
	add edi, 2
	jmp .green

.blue:
	mov ah, 0x9
	inc ebx
	mov al, [esi + ebx]
	cmp al, '%'
	je	.restore
    cmp al, 0
    je .done
	mov [edi], eax
	add edi, 2
	jmp .blue

.restore
	mov ah, 0xF
	inc ebx
	mov al, [esi + ebx]
	jmp .loop

.done:
    pop ebx
    ret
