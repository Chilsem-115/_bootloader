; ===== bios/stage2/a20.asm =====
use16

KBD_STAT = 64h
KBD_DATA = 60h

; Tiny I/O delay (legacy-safe)
_a20_io_delay:
	in   al, 80h
	ret

; Wait until input buffer empty (IBF=0), with bounded timeout
; Outer DX loop * Inner CX loop (each 0FFFFh)
wait_ibf_clear:
	push dx
	push cx
	mov  dx, 10                ; outer tries (tune as needed)
.outer_ibf:
	mov  cx, 0FFFFh
.inner_ibf:
	in   al, KBD_STAT
	test al, 02h               ; bit1 = IBF
	jz   .ok
	loop .inner_ibf
	dec  dx
	jnz  .outer_ibf
	stc                          ; timeout -> CF=1
	pop  cx
	pop  dx
	ret
.ok:
	clc                          ; CF=0
	pop  cx
	pop  dx
	ret

; Wait until output buffer full (OBF=1), with bounded timeout
wait_obf_set:
	push dx
	push cx
	mov  dx, 10
.outer_obf:
	mov  cx, 0FFFFh
.inner_obf:
	in   al, KBD_STAT
	test al, 01h               ; bit0 = OBF
	jnz  .ok
	loop .inner_obf
	dec  dx
	jnz  .outer_obf
	stc
	pop  cx
	pop  dx
	ret
.ok:
	clc
	pop  cx
	pop  dx
	ret

; (Optional) quick heuristic: CF=0 if A20 looks enabled
a20_check_enabled:
	push ax bx ds es si di
	xor  ax, ax
	mov  ds, ax                ; DS=0000
	mov  ax, 0FFFFh
	mov  es, ax                ; ES=FFFF
	xor  si, si
	mov  di, 0010h
	mov  al, [ds:si]
	mov  bl, [es:di]
	cmp  al, bl
	jne  .on
	stc                        ; equal => likely off (or inconclusive)
	jmp  .out
.on:
	clc
.out:
	pop  di si es ds bx ax
	ret

; ---- Enable A20 via 8042 output port (0xD0/0xD1 sequence) ----
; Read output port -> set bit1 (A20) and keep bit0=1 (no reset) -> write back
enable_a20:
	push ax

	; Skip if already on
	call a20_check_enabled
	jnc  .ok

	; 1) Read current output port
	call wait_ibf_clear
	jc   .fail
	mov  al, 0D0h              ; "Read Output Port" command
	out  KBD_STAT, al          ; OUT uses AL; port is immediate 64h
	call _a20_io_delay

	call wait_obf_set
	jc   .fail
	in   al, KBD_DATA          ; AL = output port byte

	; 2) Modify: ensure reset is deasserted (bit0=1) and A20 enabled (bit1=1)
	; Some firmwares expect bit0 set; OR 03h keeps both bits = 1.
	or   al, 03h

	; 3) Write back via 0xD1
	call wait_ibf_clear
	jc   .fail
	mov  ah, 0D1h
	mov  al, ah                ; OUT requires AL
	out  KBD_STAT, al
	call _a20_io_delay

	call wait_ibf_clear
	jc   .fail
	out  KBD_DATA, al          ; write modified byte
	call _a20_io_delay

	; 4) Optional verify
	call a20_check_enabled
	jc   .fail

.ok:
	clc                         ; CF=0 success
	pop  ax
	ret

.fail:
	stc                         ; CF=1 failure
	pop  ax
	ret
