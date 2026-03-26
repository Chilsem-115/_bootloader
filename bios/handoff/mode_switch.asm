; ===== bios/handoff/mode_switch.asm =====
; Protected-mode switch, enable IA-32e long mode, and handoff to the payload.

use16

; ---------------- flat GDT (32-bit + 64-bit selectors) ----------------------
align 8
gdt_start:
	dq 0
	dq 0x00CF9A000000FFFF    ; 0x08: 32-bit code
	dq 0x00CF92000000FFFF    ; 0x10: 32-bit data
	dq 0x00AF9A000000FFFF    ; 0x18: 64-bit code (L=1, D=0)
	dq 0x00AF92000000FFFF    ; 0x20: 64-bit data
gdt_end:

gdt_desc:
	dw gdt_end - gdt_start - 1
	dd gdt_start

; ---------------- boot_info (filled in RM) ----------------
boot_info:
boot_drive        db 0
boot_flags        db 0
boot_reserved     dw 0
e820_ptr          dd 0
e820_count        dw 0
fb_width          dw 0
fb_height         dw 0
fb_pitch          dw 0
fb_bpp            db 0
fb_reserved       db 0
fb_addr           dd 0
kernel_buf_ptr    dd 0
kernel_buf_len    dd 0

fill_bootinfo:
	mov eax, (MEMMAP_BUF_SEG * 16) + MEMMAP_BUF_OFS
	mov [e820_ptr], eax
	mov ax, [entry_count]
	mov [e820_count], ax
	ret

; ---------------- Real → Protected Mode switch -------------------------------
pm_switch:
	call fill_bootinfo

	cli
	lgdt [gdt_desc]
	mov eax, cr0
	or  eax, 1                  ; CR0.PE
	mov cr0, eax

	; Force far jump with 32-bit offset (16->32 transition).
	db 066h, 0EAh
	dd pm_entry32
	dw CODE_SEL

; ---------------- 32-bit landing pad ----------------------------------------
use32
PML4_BASE       equ 0x00100000
PDPT_BASE       equ 0x00101000
PD_BASE         equ 0x00102000
IA32_EFER_MSR   equ 0xC0000080
PAGE_PRESENT_RW equ 0x003
PAGE_PS         equ 0x080

pm_entry32:
	mov ax, DATA_SEL
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov esp, PM_STACK_TOP
	cld

	; Zero 3 pages: PML4 + PDPT + PD.
	mov edi, PML4_BASE
	xor eax, eax
	mov ecx, (4096 * 3) / 4
	rep stosd

	; PML4[0] -> PDPT
	mov dword [PML4_BASE + 0], PDPT_BASE + PAGE_PRESENT_RW
	mov dword [PML4_BASE + 4], 0

	; PDPT[0] -> PD
	mov dword [PDPT_BASE + 0], PD_BASE + PAGE_PRESENT_RW
	mov dword [PDPT_BASE + 4], 0

	; PD entries: 512 x 2MiB identity map (first 1GiB).
	mov edi, PD_BASE
	xor edx, edx                    ; running physical base
	mov ecx, 512
.map_2m:
	mov eax, edx
	or  eax, PAGE_PRESENT_RW
	or  eax, PAGE_PS
	mov dword [edi + 0], eax
	mov dword [edi + 4], 0
	add edx, 0x200000
	add edi, 8
	loop .map_2m

	; Load tables + enable long mode.
	mov eax, PML4_BASE
	mov cr3, eax

	mov eax, cr4
	or  eax, 0x20                  ; CR4.PAE
	mov cr4, eax

	mov ecx, IA32_EFER_MSR
	rdmsr
	or  eax, 0x100                 ; EFER.LME
	wrmsr

	mov eax, cr0
	or  eax, 0x80000000            ; CR0.PG
	mov cr0, eax

	; Enter 64-bit submode.
	jmp LONG_CODE_SEL:long_mode_entry

; ---------------- 64-bit landing pad ----------------------------------------
use64
long_mode_entry:
	mov rsp, PM_STACK_TOP

	; SysV first arg = pointer to boot info.
	mov rdi, boot_info

	; 64-bit payload loaded at physical/virtual 0x00020000.
	mov rax, 0x0000000000020000
	jmp rax

.hang_pm:
	hlt
	jmp .hang_pm

msg_pmok db 'Initializing protected mode (PM): %g[OK]%', 0
