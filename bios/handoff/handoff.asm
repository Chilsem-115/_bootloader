; ===== bios/handoff/handoff.asm =====
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
include 'load_payload.asm'

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

	; load the long-mode stage payload into 0x00020000
	call load_payload
	jc	disk_fail

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

	; force classic VGA text mode (80x25 color text), no framebuffer metadata
	mov  ax, 0x0003
	int  0x10
	and  byte [boot_flags], 0xFE
	mov  word [fb_width], 0
	mov  word [fb_height], 0
	mov  word [fb_pitch], 0
	mov  byte [fb_bpp], 0
	mov  dword [fb_addr], 0

	; switch to Protected Mode and never come back
	call pm_switch

; ---- fallback real-mode hang if something set CF ----
.hang_rm:
	mov si, dbg_enter
	PRINT_Z
	hlt
	jmp .hang_rm

; ---- disk read failure hang (load_payload jc here) ----
disk_fail:
	cli

.hang:
	hlt
	jmp .hang

; ---------------- end-of-image marker for header size ------------------------
HANDOFF_END:

include 'print_vga.asm'
include 'mode_switch.asm'              ; pm_switch + long-mode entry
