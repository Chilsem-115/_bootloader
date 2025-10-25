use32

; print_vga (PM 32-bit)
; ESI -> ASCIIZ string with controls: %r / %g / %b / %% / % (reset)
; DH  = row, DL = col, BL = starting attribute
; Clobbers: EAX, ECX, EDI
; Preserves: ESI, EDX, EBX

print_vga:
    push eax
    push ecx
    push edx
    push ebx
    push esi
    push edi
    cld

    ; compute VGA destination in EDI
    xor eax, eax
    mov al, dh
    mov edi, eax
    shl edi, 5          ; *32
    shl eax, 7          ; *128
    add edi, eax        ; row*160
    xor eax, eax
    mov al, dl
    shl eax, 1          ; col*2
    add edi, eax
    add edi, 0xB8000

    mov ah, bl          ; current attr in AH; original attr stays in BL

.next_ch:
    lodsb               ; AL = [ESI++]
    test al, al
    jz   .done

    cmp  al, '%'
    je   .ctrl

    mov  [edi], ax      ; store char + attr
    add  edi, 2
    jmp  .next_ch

.ctrl:
    ; Peek next char without consuming it
    mov  al, [esi]
    test al, al
    jz   .close_at_end      ; "%<NUL>" — treat as reset and finish cleanly

    cmp  al, 'r'
    je   .set_red
    cmp  al, 'g'
    je   .set_green
    cmp  al, 'b'
    je   .set_blue
    cmp  al, '%'
    je   .emit_percent

    ; Any other char after '%' means "reset to start attr" (closing %)
    ; Do NOT consume that next char; just restore AH and continue.
    mov  ah, bl
    jmp  .next_ch

.set_red:
    inc  esi
    mov  ah, 0x0C           ; light red
    jmp  .next_ch
.set_green:
    inc  esi
    mov  ah, 0x0A           ; light green
    jmp  .next_ch
.set_blue:
    inc  esi
    mov  ah, 0x09           ; light blue
    jmp  .next_ch
.emit_percent:
    inc  esi                ; consume the '%'
    mov  al, '%'
    mov  [edi], ax
    add  edi, 2
    jmp  .next_ch

.close_at_end:
    ; Trailing '%' at end of string: reset attr and stop (no over-read)
    mov  ah, bl
    jmp  .done

.done:
    pop  edi
    pop  esi
    pop  ebx
    pop  edx
    pop  ecx
    pop  eax
    ret
