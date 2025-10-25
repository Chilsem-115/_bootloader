; ===== bios/stage2/pm32.asm =====
use16

; ---------------- flat GDT (code 0x08, data 0x10) ----------------
align 8
gdt_start:
    dq 0
    dq 0x00CF9A000000FFFF    ; 0x08: 32-bit code
    dq 0x00CF92000000FFFF    ; 0x10: 32-bit data

gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; ---------------- boot_info (filled in RM) ----------------
boot_info:
boot_drive        db 0
e820_ptr          dw MEMMAP_BUF_OFS
                  dw MEMMAP_BUF_SEG
e820_count        dw 0
vbe_info_ptr      dw 0, 0
kernel_buf_ptr    dd 0
kernel_buf_len    dd 0

fill_bootinfo:
    mov ax, MEMMAP_BUF_OFS
    mov [e820_ptr], ax
    mov ax, MEMMAP_BUF_SEG
    mov [e820_ptr+2], ax
    mov ax, [entry_count]
    mov [e820_count], ax
    ret

; ---------------- Real → Protected Mode switch (force 16:32 far jump) -------
pm_switch:
    cli
    lgdt [gdt_desc]
    mov eax, cr0
    or  eax, 1                  ; CR0.PE = 1
    mov cr0, eax

    ; Encode FAR JMP with 32-bit offset explicitly: 66 EA imm32, imm16
    db  066h, 0EAh
    dd  pm_entry32              ; 32-bit offset
    dw  0x0008                  ; code selector

; ---------------- 32-bit landing pad (prints PMOK) ---------------------------
use32
pm_entry32:
    mov ax, 0x10                ; data selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, PM_STACK_TOP
    cld

    ; -------- print "PMOK" at row 0, col 0 in bright green --------
    mov     dh, 0            ; row
    mov     dl, 0            ; col
    mov     bl, 0x0F         ; attribute (print_vga will change on %g/%r/%b)

    ; “PMOK” at top-left (VGA text buffer @ 0xB8000)
;    mov     edi, 0xB8000
;    mov     ax, 0x0F50          ; 'P' + attr
;    mov     word [edi],   ax
;    mov     ax, 0x0F4D          ; 'M'
;    mov     word [edi+2], ax
;    mov     ax, 0x0F4F          ; 'O'
;    mov     word [edi+4], ax
;    mov     ax, 0x0F4B          ; 'K'
;    mov     word [edi+6], ax

    mov     esi, msg_pmok
    call    print_vga

    mov     ebx, boot_info      ; keep for later

.hang_pm:
    hlt
    jmp .hang_pm

msg_pmok	db 'Initializing protected mode (PM): %g[OK]%', 0
