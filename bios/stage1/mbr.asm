
; ===== stage1/mbr.asm (FASM) =====
format  binary
use16
org     7C00h

include 'mbr.inc'          ; keep your macros/asserts if any

; ---- layout ----
LOAD_SEG		= 0000h
LOAD_OFS		= 8000h                      ; Stage2 entry at 0000:8000
LOAD_LIN		= (LOAD_SEG shl 4) + LOAD_OFS
STAGE2_LBA		= 1                          ; Stage2 starts at LBA 1

USE_CLEAR_SCREEN = 1

start:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 7C00h

    ; save BIOS boot drive
    mov [BootDrive], dl

    ; optional: clear to text mode
	if USE_CLEAR_SCREEN
		mov ax, 0003h
		int 10h
	end if

    ; 1) Read Stage2 header (1 sector @ LBA 1) to 0000:8000
    call read_stage2_header

    ; 2) Read the remaining Stage2 sectors with chunked AH=42h (≤127 sectors, no 64K crossing)
    call read_stage2_rest

    ; 3) Jump to Stage2 real entry (CS must be 0000 because org 0x8000)
    xor  ax, ax
    mov  ds, ax                 ; DS=0000 to read header

    mov  bx, [LOAD_OFS + 12]    ; low-16 of ST_ENTRY_OFS (enough here)
    add  bx, LOAD_OFS           ; BX = 0x8000 + entry_ofs  → final IP

    ; Correct order for RETF: push CS first, then IP
    push LOAD_SEG               ; CS = 0000
    push bx                     ; IP = 0x8000 + entry_ofs
    retf                        ; pops IP (top), then CS → jump

; ---------------------- INT 13h Extensions (AH=42h) helpers ----------------------

align 16
DAP:
    db 16, 0
	DAP_COUNT   dw 0
	DAP_OFF     dw 0
	DAP_SEG     dw 0
	DAP_LBA     dq 0

; Read first sector (header) into 0000:8000
read_stage2_header:
    push ds
    push si

    mov  word  [DAP_COUNT], 1
    mov  word  [DAP_OFF],   LOAD_OFS
    mov  word  [DAP_SEG],   LOAD_SEG
    mov  dword [DAP_LBA],   STAGE2_LBA
    mov  dword [DAP_LBA+4], 0

    push cs
    pop  ds
    mov  si, DAP

    mov  dl, [BootDrive]
    mov  ah, 42h
    int  13h
    jc   disk_fail

    pop  si
    pop  ds

    ret

; Read remaining sectors into 0000:8000+512 from LBA 2..end
; Stage2 header at LOAD_OFS:
;   [LOAD_OFS+0..3]  = 'ST2H'
;   [LOAD_OFS+4..7]  = ST2_TOTAL_SECT (u32)
read_stage2_rest:

    push ds
    push si
    push ax
    push bx
    push cx
    push dx
    push di
    push bp

    ; EAX = current linear destination (start right after header sector)
    mov   eax, LOAD_LIN + 512

    ; ECX = remaining sectors = total - 1  (handle up to 65535)
    mov   cx,  word [LOAD_OFS + 4]
    mov   bx,  word [LOAD_OFS + 6]     ; high 16 if ever needed later
    dec   cx
    jz    .done

    ; EDI = current LBA (start at 2)
    mov   edi, STAGE2_LBA + 1

.next:
    test  cx, cx
    jz    .done

    ; -- derive seg:ofs from linear EAX --
    mov   ebx, eax
    mov   dx,  bx
    and   dx,  0x000F              ; DX = offset within 64K window
    shr   ebx, 4                   ; BX = segment (not used further here)

    ; -- window sectors left before a 64K boundary (no 0x10000 literal) --
    ; window_bytes = (0x10000 - DX) mod 65536
    ; window_sectors = floor(window_bytes / 512), except when DX=0 we want 128.
    push  cx                        ; save remaining (CX)
    mov   bx, dx
    neg   bx                        ; BX = (0x10000 - DX) mod 65536
    mov   si, bx                    ; SI = window bytes (mod 64K)
    shr   si, 9                     ; SI = floor(window_bytes/512)
    jnz   .win_ok2
    mov   si, 128                   ; DX==0 → full 64K → 128 sectors
.win_ok2:

    ; chunk = min(remaining (CX), window (SI), 127)
    mov   bx, si
    cmp   bx, 127
    jbe   .cap1
    mov   bx, 127
.cap1:
    cmp   bx, cx
    jbe   .chunk_ok
    mov   bx, cx
.chunk_ok:
    pop   cx                        ; restore remaining

    ; ---- fill DAP for this chunk ----
    mov   [DAP_COUNT], bx
    mov   [DAP_OFF],   dx
    ; recompute segment for DAP (segment = linear >> 4)
    mov   ebx, eax
    shr   ebx, 4
    mov   [DAP_SEG],   bx
    mov   dword [DAP_LBA],   edi
    mov   dword [DAP_LBA+4], 0

    push  cs
    pop   ds
    mov   si, DAP
    mov   dl, [BootDrive]
    mov   ah, 42h
    int   13h
    jc    disk_fail

    ; ---- advance pointers ----
    ; bytes = sectors * 512  (≤127*512 = 65024 fits in 16-bit)
    mov   bp, [DAP_COUNT]
    mov   bx, bp
    shl   bx, 9
    movzx edx, bx                  ; zero-extend to 32 bits
    add   eax, edx                 ; linear += bytes

    movzx ebp, bp
    add   edi, ebp                 ; LBA += sectors (32-bit)

    sub   cx,  bp                  ; remaining -= sectors (16-bit counter)

    jmp   .next

.done:
    pop   bp
    pop   di
    pop   dx
    pop   cx
    pop   bx
    pop   ax
    pop   si
    pop   ds
    ret

disk_fail:
    cli
.hang:
    hlt
    jmp .hang

; ---- data ----
BootDrive   db 0

; pad + signature
times 510-($-$$) db 0
dw 0AA55h
