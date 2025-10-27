use16

; --- tiny BIOS teletype printer for debug ---
; input: AL = ascii
dbg_putc:
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07        ; light grey on black
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; print 1 hex digit from low nibble of AL
dbg_hex_nib:
    push ax
    and al, 0x0F
    cmp al, 10
    jb  .digit
    add al, 'A' - 10
    jmp .out
.digit:
    add al, '0'
.out:
    call dbg_putc
    pop ax
    ret

; print AX as 4 hex digits
dbg_hex16:
	push ax
	push bx
	mov bx, ax          ; BX = value
	mov al, bh
	shr al, 4
	call dbg_hex_nib
	mov al, bh
	call dbg_hex_nib
    mov al, bl
    shr al, 4
    call dbg_hex_nib
    mov al, bl
    call dbg_hex_nib
    pop bx
    pop ax
    ret

; print EAX as 8 hex digits
dbg_hex32:
    push ax
    push dx
    mov dx, ax          ; save AX because we'll smash AX
    ; high word first
    mov ax, word [esp+4]    ; careful: we don't have a normal stack frame here,
                            ; but we can't easily index 32-bit regs from 16-bit.
                            ; Simpler approach: we'll just expect caller to give us
                            ; the value split: high in DX, low in AX.
    ; so we're not actually using this version, see note below.
    pop dx
    pop ax
    ret
; NOTE:
; 16-bit code can't easily treat EAX as a full 32-bit arg with our tiny helper
; without burning more code. We'll just dump 16-bit chunks instead:
; - segment (BP)
; - offset (DX)
; - sector count (BX)
; - LBA low16 / high16 (from EDI)

; --------------------------------------------------

load_stage3:
    ; save caller state
    push ds
    push si
    push ax
    push bx
    push cx
    push dx
    push di
    push bp
    push es

    mov si, dbg_enter
    PRINT_Z

    mov     eax, 0x00002000        ; destination linear
    mov     cx,  STAGE3_SECTORS    ; total sectors
    mov     edi, STAGE3_LBA        ; starting LBA

.next_chunk:
    test    cx, cx
    jz      .done_ok

    ; derive seg:ofs
    mov     ebx, eax
    mov     dx,  bx
    and     dx,  0x000F            ; DX = ofs
    shr     ebx, 4
    mov     bp,  bx                ; BP = seg

    ; compute chunk size
    push    cx
    mov     bx, dx
    neg     bx
    mov     si, bx
    shr     si, 9
    jnz     .have_win
    mov     si, 128
.have_win:
    mov     bx, si
    cmp     bx, 127
    jbe     .cap127
    mov     bx, 127
.cap127:
    pop     cx
    cmp     bx, cx
    jbe     .chunk_ok
    mov     bx, cx
.chunk_ok:
    ; BX = chunk sectors

    ; fill DAP
    mov     [DAP_COUNT], bx
    mov     [DAP_OFF],   dx
    mov     [DAP_SEG],   bp
    mov     dword [DAP_LBA],   edi
    mov     dword [DAP_LBA+4], 0

    ; === DEBUG DUMP BEFORE INT 13h ===
    ; print "\nDRV="
    mov si, dbg_drv
    PRINT_Z
    mov al, [BootDrive]
    cbw                 ; AL -> AX sign-extend
    call dbg_hex16

    ; print " SEG="
    mov si, dbg_seg
    PRINT_Z
    mov ax, bp
    call dbg_hex16

    ; print ":"
    mov al, ':'
    call dbg_putc

    mov ax, dx
    call dbg_hex16

    ; print " CNT="
    mov si, dbg_cnt
    PRINT_Z
    mov ax, [DAP_COUNT]
    call dbg_hex16

    ; print " LBA="
    mov si, dbg_lba
    PRINT_Z
    ; we'll dump EDI as two 16-bit halves: high16 then low16
    mov ax, di         ; low16
    call dbg_hex16
    mov ax, di         ; di reused, but we also want high16 of EDI
    ; to get high16 of EDI in 16-bit code:
    push di
    shr edi, 16
    mov ax, di
    call dbg_hex16
    pop di
    ; newline
    mov al, 13
    call dbg_putc
    mov al, 10
    call dbg_putc

    ; mark "B"
    mov si, dbg_before
    PRINT_Z

    ; BIOS read
    push    cs
    pop     ds
    mov     si, DAP
    mov     dl, [BootDrive]
    mov     ah, 42h
    int     13h
    jc      .disk_fail

    mov si, dbg_after
    PRINT_Z

    ; advance pointers
    mov     bp, [DAP_COUNT]
    mov     bx, bp
    shl     bx, 9
    movzx   edx, bx
    add     eax, edx

    movzx   ebp, bp
    add     edi, ebp

    sub     cx,  bp
    jmp     .next_chunk

.done_ok:
    clc
    jmp     .epilogue

.disk_fail:
    mov si, dbg_fail
    PRINT_Z
    stc

.epilogue:
    pop     es
    pop     bp
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    pop     si
    pop     ds
    ret

; --- debug strings ---
dbg_enter  db '[ENTER_LOAD3]',13,10,0
dbg_before db '[B]',13,10,0
dbg_after  db '[A]',13,10,0
dbg_fail   db '[CF!]',13,10,0
dbg_drv    db 'DRV=',0
dbg_seg    db ' SEG=',0
dbg_cnt    db ' CNT=',0
dbg_lba    db ' LBA=',0
