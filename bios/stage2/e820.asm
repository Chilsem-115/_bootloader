; ===== bios/stage2/e820.asm =====
use16

; expects in config/data (defined ONCE):
;   MEMMAP_BUF_SEG, MEMMAP_BUF_OFS, MEMMAP_MAX_ENTRIES
;   entry_count  dw 0
;   e820_cookie  dd 0

e820_query:

    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    di
    push    ds
    push    es


    mov     word [entry_count], 0
    xor     ebx, ebx
    mov     [e820_cookie], ebx

.next:
    ; ES:DI -> next 24-byte slot in your map buffer
    mov     ax, MEMMAP_BUF_SEG
    mov     es, ax
    mov     di, MEMMAP_BUF_OFS
    mov     ax, [entry_count]
    mov     bx, 24
    mul     bx                    ; DX:AX = AX*24
    add     di, ax

    ; BIOS: INT 15h, AX=E820h
    mov     eax, 0E820h
    mov     edx, 0534D4150h       ; 'SMAP'
    mov     ecx, 24               ; request 24 bytes (ACPI 3+)
    mov     ebx, [e820_cookie]    ; continuation cookie
    int     15h
    jc      .done                 ; CF=1 => end/error

    cmp     eax, 0534D4150h
    jne     .done                 ; must echo 'SMAP'

    ; remember next cookie early
    mov     [e820_cookie], ebx

    ; BIOS wrote ECX bytes at ES:DI; clamp and count
    cmp     ecx, 20
    jb      .maybe_end
    cmp     ecx, 24
    jbe     .size_ok
    mov     ecx, 24
.size_ok:
    inc     word [entry_count]

    ; cap total
    cmp     word [entry_count], MEMMAP_MAX_ENTRIES
    jae     .done

.maybe_end:
    mov     ebx, [e820_cookie]
    test    ebx, ebx
    jnz     .next

.done:
    cld                           ; leave DF forward for PRINT_*
    pop     es
    pop     ds
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
