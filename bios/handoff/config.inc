; ===== bios/handoff/config.inc =====

; ---- constants / selectors / buffers ----
MEMMAP_BUF_SEG      = 3000h
MEMMAP_BUF_OFS      = 0000h
MEMMAP_MAX_ENTRIES  = 32

; Keep PM/LM stack above page-table scratch region [0x00100000, 0x00906000).
PM_STACK_TOP        = 0x01000000

CODE_SEL            = 0x08
DATA_SEL            = 0x10
LONG_CODE_SEL       = 0x18
LONG_DATA_SEL       = 0x20

; ---- strings ----

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
