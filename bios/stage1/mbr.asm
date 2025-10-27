; ===== stage1/mbr.asm (FASM) =====
format  binary
use16
org     7C00h

; ---- layout ----
LOAD_SEG        = 0000h
LOAD_OFS        = 8000h          ; Stage2 entry at 0000:8000
LOAD_LIN        = (LOAD_SEG shl 4) + LOAD_OFS

USE_CLEAR_SCREEN = 1


include '../shared.inc'
;include 'load_s3.asm'

start:
    cli

    ; ---- set up a safe stack high in low memory ----
    mov ax, 0x7000
    mov ss, ax
    mov sp, 0xFFFE

    ; ---- set DS/ES = our code segment so we can access our data labels ----
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; ---- save BIOS boot drive from DL ----
    mov [BootDrive], dl

    ; ---- (optional) clear screen to text mode 80x25 ----
	if USE_CLEAR_SCREEN
		mov ax, 0003h
		int 10h
	end if

    ; ---- read Stage2 header (LBA STAGE2_LBA -> 0000:8000) ----
    call read_stage2_header

    ; ---- read the rest of Stage2 after the first sector ----
    call read_stage2_rest

	; ---- read stage3 entirely (LBA STAGE3_LBA -> 0000:2000) ----
	;call load_stage3

    ; ---- jump into Stage2 ----
    xor ax, ax
    mov ds, ax                 ; DS = 0000 to read Stage2 header words at 0000:8000

    mov bx, [LOAD_OFS + 12]    ; ST_ENTRY_OFS (low16)
    add bx, LOAD_OFS           ; BX = 0x8000 + entry_ofs -> final IP

    push LOAD_SEG              ; target CS = 0000
    push bx                    ; target IP = BX
    retf                       ; far jump into Stage2


; ---------------------- INT 13h Extensions (AH=42h) helpers ----------------------

; Read first sector (header) into 0000:8000
read_stage2_header:
	push ds
	push si

	; build DAP
	mov  word  [DAP_COUNT], 1
	mov  word  [DAP_OFF],   LOAD_OFS
	mov  word  [DAP_SEG],   LOAD_SEG
	mov  dword [DAP_LBA],   STAGE2_LBA
	mov  dword [DAP_LBA+4], 0

	; DS:SI -> DAP
	push cs
	pop  ds
	mov  si, DAP

	; DL = boot drive we saved
	mov  dl, [BootDrive]

	mov  ah, 42h
	int  13h
	jc   disk_fail

	pop  si
	pop  ds
	ret


; Read remaining sectors of Stage2 into memory after the first 512 bytes
read_stage2_rest:
    push ds
    push si
    push ax
    push bx
    push cx
    push dx
    push di
    push bp

    ; EAX = current linear dest (start right after header sector)
    mov   eax, LOAD_LIN + 512

    ; ECX = remaining sectors = total - 1
    mov   cx,  word [LOAD_OFS + 4]    ; low 16 of ST2_TOTAL_SECT
    mov   bx,  word [LOAD_OFS + 6]    ; high 16 if you ever go >65535 sectors
    dec   cx
    jz    .done

    ; EDI = current LBA (start at second sector of Stage2)
    mov   edi, STAGE2_LBA + 1

.next:
    test  cx, cx
    jz    .done

    ; derive seg:ofs from linear EAX
    mov   ebx, eax
    mov   dx,  bx
    and   dx,  0x000F              ; DX = offset within 64K window
    shr   ebx, 4                   ; EBX>>4 = segment (we'll reuse below)

    ; figure how many sectors fit before 64K boundary
    push  cx                        ; save remaining
    mov   bx, dx
    neg   bx                        ; BX = (0x10000 - DX) mod 65536
    mov   si, bx                    ; SI = window bytes
    shr   si, 9                     ; SI >>= 9 gives max sectors in this 64K window
    jnz   .win_ok2
    mov   si, 128                   ; exact boundary → full 64K = 128 sectors
.win_ok2:

    ; chunk = min(remaining CX, window SI, 127)
    mov   bx, si
    cmp   bx, 127
    jbe   .cap1
    mov   bx, 127
.cap1:
    cmp   bx, cx
    jbe   .chunk_ok
    mov   bx, cx
.chunk_ok:
    pop   cx                        ; restore remaining count into CX

    ; Fill DAP
    mov   [DAP_COUNT], bx
    mov   [DAP_OFF],   dx
    mov   ebx, eax
    shr   ebx, 4
    mov   [DAP_SEG],   bx
    mov   dword [DAP_LBA],   edi
    mov   dword [DAP_LBA+4], 0

    ; BIOS read
    push  cs
    pop   ds
    mov   si, DAP
    mov   dl, [BootDrive]
    mov   ah, 42h
    int   13h
    jc    disk_fail

    ; advance pointers
    mov   bp, [DAP_COUNT]
    mov   bx, bp
    shl   bx, 9              ; sectors * 512
    movzx edx, bx
    add   eax, edx           ; linear += bytes

    movzx ebp, bp
    add   edi, ebp           ; LBA += sectors

    sub   cx,  bp            ; remaining -= chunk
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


; pad + signature
times 510-($-$$) db 0
dw 0AA55h
