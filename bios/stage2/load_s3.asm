


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
    mov bl, 0x07        ; light grey
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

; print EDI as 32-bit hex using two dbg_hex16 calls:
; high16 first, then low16
dbg_hex32_from_edi:
    push ax
    push dx
    push di

    ; low16 of EDI is DI
    ; we also need the high16, so copy EDI and shift
    mov dx, di          ; save low16 in DX
    push di
    shr edi, 16
    mov ax, di          ; now AX = high16
    call dbg_hex16
    pop di
    mov ax, dx          ; AX = low16
    call dbg_hex16

    pop di
    pop dx
    pop ax
    ret

; --------------------------------------------------------------------
; load_stage3:
;   loads STAGE3_SECTORS sectors starting at STAGE3_LBA
;   into physical 0x00002000
; --------------------------------------------------------------------

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

    ; ===========================
    ; DEBUG BLOCK 0:
    ; print "S3LBA=" <STAGE3_LBA> " S3SEC=" <STAGE3_SECTORS>
    ; ===========================

    mov si, dbg_hdr
    PRINT_Z

    ; print S3LBA=
    mov si, dbg_lba2
    PRINT_Z

    mov edi, STAGE3_LBA        ; put STAGE3_LBA into EDI
    call dbg_hex32_from_edi    ; spits high16low16

    ; space
    mov al, ' '
    call dbg_putc

    ; print S3SEC=
    mov si, dbg_sec2
    PRINT_Z

    mov ax, STAGE3_SECTORS     ; 16-bit is fine
    call dbg_hex16

    ; newline
    mov al, 13
    call dbg_putc
    mov al, 10
    call dbg_putc

    ; ===========================
    ; normal loader logic starts
    ; ===========================

    ; destination linear address
    mov     eax, 0x00002000        ; where stage3 should live

    ; CX = remaining sectors
    mov     cx,  STAGE3_SECTORS    ; <--- this is what we just printed

    ; EDI = current LBA
    mov     edi, STAGE3_LBA        ; <--- this too

.next_chunk:
    test    cx, cx
    jz      .done_ok

    ; derive segment:offset from eax
    mov     ebx, eax
    mov     dx,  bx
    and     dx,  0x000F            ; DX = ofs
    shr     ebx, 4
    mov     bp,  bx                ; BP = seg

    ; compute max sectors for this call
    push    cx

    mov     bx, dx
    neg     bx
    mov     si, bx                 ; bytes left in 64K window
    shr     si, 9                  ; /512 => sectors
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
    ; BX = chunk sectors this round

    ; build DAP
    mov     [DAP_COUNT], bx
    mov     [DAP_OFF],   dx
    mov     [DAP_SEG],   bp
    mov     dword [DAP_LBA],   edi
    mov     dword [DAP_LBA+4], 0

    ; DEBUG BLOCK 1:
    ; this is your old per-chunk debug (DRV/SEG/CNT/LBA)
    mov si, dbg_drv
    PRINT_Z
    mov al, [BootDrive]
    cbw
    call dbg_hex16

    mov si, dbg_seg
    PRINT_Z
    mov ax, bp
    call dbg_hex16
    mov al, ':'
    call dbg_putc
    mov ax, dx
    call dbg_hex16

    mov si, dbg_cnt
    PRINT_Z
    mov ax, [DAP_COUNT]
    call dbg_hex16

    mov si, dbg_lba
    PRINT_Z
    ; print EDI again as 32-bit
    push edi
    call dbg_hex32_from_edi
    pop edi

    ; newline for readability
    mov al, 13
    call dbg_putc
    mov al, 10
    call dbg_putc

    ; mark "[B]"
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

    ; "[A]"
    mov si, dbg_after
    PRINT_Z

    ; advance dest address
    mov     bp, [DAP_COUNT]       ; BP = sectors read
    mov     bx, bp
    shl     bx, 9                 ; bytes = sectors * 512
    movzx   edx, bx
    add     eax, edx              ; bump dest linear

    movzx   ebp, bp
    add     edi, ebp              ; bump LBA

    sub     cx,  bp               ; remaining -= this chunk
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

; --- debug strings for PRINT_Z ---
dbg_enter  db '[ENTER_LOAD3]',13,10,0
dbg_hdr    db '[S3 DEBUG]',0
dbg_lba2   db 'S3LBA=',0
dbg_sec2   db 'S3SEC=',0

dbg_before db '[B]',13,10,0
dbg_after  db '[A]',13,10,0
dbg_fail   db '[CF!]',13,10,0

dbg_drv    db 'DRV=',0
dbg_seg    db ' SEG=',0
dbg_cnt    db ' CNT=',0
dbg_lba    db ' LBA=',0
