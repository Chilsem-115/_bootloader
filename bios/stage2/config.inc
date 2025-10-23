; ===== bios/stage2/config.inc =====

; ---- constants / selectors / buffers ----
MEMMAP_BUF_SEG      = 2000h
MEMMAP_BUF_OFS      = 0000h
MEMMAP_MAX_ENTRIES  = 32

PM_STACK_TOP        = 0x00200000

CODE_SEL            = 0x08
DATA_SEL            = 0x10

; ---- strings ----
banner			db 'Stage2: BIOS real-mode stub',0
a20_msg			db 'A20: enabling...',0
e820_msg		db 'E820: querying memory map...',0
e820_success	db 'E820: Successful'

; ---- E820 bookkeeping ----
E820_entry		rb 24
continuation	dd 0
entry_count		dw 0
e820_cookie		dd 0          ; EBX continuation cookie between calls

; ---- FASM macro: print zero-terminated string at label in SI-like arg ----
macro PRINT_Z si_already_set {
    local ..loop, ..done       ; *** unique labels per expansion ***
    pushf
    push ax
    push bx
    push ds
    push si

    ; assume SI already holds pointer to your ASCIIZ (like before)
    push cs
    pop  ds                    ; strings live with code
    cld                        ; forward string ops

  ..loop:
    lodsb
    test al, al
    jz   ..done
    mov  ah, 0Eh               ; BIOS teletype
    xor  bh, bh                ; *** force page 0 every char ***
    int  10h
    jmp  ..loop

  ..done:
    pop  si
    pop  ds
    pop  bx
    pop  ax
    popf
}

macro CRLF {
    pusha
    mov  ah, 0x0E
    mov  bh, 0
    mov  bl, 0x07
    mov  al, 13
    int  0x10
    mov  al, 10
    int  0x10
    popa
}

macro PRINT_OK {
	pusha
	mov si, ok_str
	PRINT_Z si
	popa
}

macro PRINT_FAIL {
	pusha
	mov si, fail_str
	PRINT_Z si
	popa
}

ok_str   db ' [OK]',0
fail_str db ' [FAIL]',0

