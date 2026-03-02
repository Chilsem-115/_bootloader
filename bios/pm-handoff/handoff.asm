; ===== bios/pm-handoff/handoff.asm =====
format  binary
use16
org     8000h                          ; Handoff loader is loaded here by the MBR

; ---------------- Handoff self-describing header (first 16 bytes) -----------
; Keep header math in symbols so offsets stay obvious to the MBR.
HANDOFF_SIZE        = HANDOFF_END - $$
HANDOFF_SECTORS     = (HANDOFF_SIZE + 511) / 512
HANDOFF_ENTRY_OFS   = start - $$

HANDOFF_HDR:
    db  'HND2'                             ; magic
    HANDOFF_TOTAL_BYTES dd  HANDOFF_SIZE   ; exact assembler size
    HANDOFF_TOTAL_SECT dd  HANDOFF_SECTORS ; size in 512-byte sectors
    HANDOFF_ENTRY_PTR  dd  HANDOFF_ENTRY_OFS
    HANDOFF_VERSION    dd  0x00010000      ; v1.0

; ---------------- includes / config -----------------------------------------
include 'config.inc'                   ; constants + print macros
include '../shared.inc'
include 'a20.asm'
include 'e820.asm'
include 'load_checkup.asm'

; ---------------- real-mode entry -------------------------------------------

start:
    cli
    cld
    push cs
    pop  ds

    ; setup stack BEFORE we call helpers that push/pop a lot
    mov ax, 0x7000
    mov ss, ax
    mov sp, 0xFFFE

    sti

	mov	[BootDrive], dl

	; load the checkup payload into 0x00002000
	call load_checkup
	jc	disk_fail

	; set 80x25 text mode / clear screen
	mov  ax, 0x0003
	int  0x10
	xor  ax, ax          ; AL=0 so stray teletype won't print junk

	; enable A20
	call enable_a20
	jc   .hang_rm

	; write boot drive into boot_info[0]
	mov dl, [BootDrive]
	mov [boot_info+0], dl

	; query memory map via E820
	call e820_query
	cld

	; finalize boot_info (re-store boot drive defensively)
	mov dl, [BootDrive]
	mov [boot_info+0], dl
	call fill_bootinfo

	; switch to Protected Mode and never come back
	call pm_switch

; ---- fallback real-mode hang if something set CF ----
.hang_rm:
	mov si, dbg_enter
	PRINT_Z
	hlt
	jmp .hang_rm

; ---- disk read failure hang (load_checkup jc here) ----
disk_fail:
	cli

.hang:
	hlt
	jmp .hang

; ---------------- end-of-image marker for header size ------------------------
HANDOFF_END:

include 'print_vga.asm'
include 'pm32.asm'                     ; pm_switch + pm_entry32
