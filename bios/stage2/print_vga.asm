
; ===== print_vga (real mode, 16-bit, FASM) =====
; DS:SI -> ASCIIZ string (supports %r / %g / %b and %%)
; DI     -> byte offset into VGA text buffer (0..(80*25*2-2))
; Writes to ES=0xB800 (set inside). Preserves regs.

use16

print_vga:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    cld

    mov  ax, 0B800h        ; VGA color text memory segment
    mov  es, ax

    mov  ah, 0x0F          ; default attribute: bright white on black

.next_ch:
    lodsb                   ; AL = next byte from DS:SI
    test al, al
    jz   .done              ; end on NUL

    cmp  al, '%'
    je   .ctrl

    stosw                   ; write AL (char) and AH (attr) to ES:DI, DI += 2
    jmp  .next_ch

.ctrl:
    lodsb                   ; read control letter after '%'
    cmp  al, 'r'
    je   .set_red
    cmp  al, 'g'
    je   .set_green
    cmp  al, 'b'
    je   .set_blue
    cmp  al, '%'            ; "%%" -> print a literal '%'
    je   .emit_percent
    ; unknown code: ignore and continue
    jmp  .next_ch

.set_red:
    mov  ah, 0x0C           ; light red
    jmp  .next_ch
.set_green:
    mov  ah, 0x0A           ; light green
    jmp  .next_ch
.set_blue:
    mov  ah, 0x09           ; light blue
    jmp  .next_ch
.emit_percent:
    mov  al, '%'
    stosw
    jmp  .next_ch

.done:
    pop  es
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret


; Input: DH=row (0..24), DL=col (0..79)
; Output: DI = row*160 + col*2
; Clobbers: AX
vga_setpos_dhdl:
    push ax
    xor  ax, ax
    mov  al, dh          ; AX = row
    mov  di, ax
    shl  di, 5           ; row*32
    shl  ax, 7           ; row*128
    add  di, ax          ; row*(128+32)=row*160
    xor  ax, ax
    mov  al, dl          ; AX = col
    shl  ax, 1           ; col*2
    add  di, ax
    pop  ax
    ret
