
; ===== bios/stage2/stage2.asm =====
format  binary
use16
org     8000h                          ; Stage2 is loaded here by Stage1

; ---------------- Stage2 self-describing header (first 16 bytes) ------------
ST2_HDR:
    db  'ST2H'                         ; magic
	ST2_TOTAL_BYTES dd  ST2_END - $$       ; exact assembler size
	ST2_TOTAL_SECT  dd  (ST2_TOTAL_BYTES+511)/512
	ST_ENTRY_OFS	dd	start - $$
	ST2_VERSION     dd  0x00010000         ; v1.0

; ---------------- includes / config -----------------------------------------
include 'config.inc'                   ; constants + print macros
include 'a20.asm'
include 'e820.asm'

; ---------------- real-mode entry -------------------------------------------

start:
    cli
    cld
    push cs
    pop  ds

    ; text mode 80x25
    mov  ax, 0x0003
    int  0x10
    xor  ax, ax          ; keep AL=0 so any stray teletype won’t print a glyph

	; ---- setup stack ----
    mov ax, 0x7000
    mov ss, ax
    mov sp, 0xFFFE

	; ---- enable A20 ----
	call enable_a20
	jc	.hang_rm

    ; store DL before other calls (safest)
    mov  [boot_info+0], dl

    ; ---- E820 ----

    call e820_query	
	cld                       ; belt & suspenders

    ; fill the rest
    call fill_bootinfo

; ---- boot info ----
    mov [boot_info+0], dl
    call fill_bootinfo

; ---- switch to Protected Mode ----
    call pm_switch

; ---- fallback loop ----
.hang_rm:
    hlt
    jmp .hang_rm

; ---------------- end-of-image marker for header size ------------------------
ST2_END:

include 'print_vga.asm'
include 'pm32.asm'                     ; pm_switch + pm_entry32 proof print
