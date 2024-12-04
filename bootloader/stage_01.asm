[bits 16]
org 0x7c00

section .text
jmp short _start
nop

%include "bootloader_defs.asm"

; Code goes here
_start:
    jmp main

puts:
    ; save registers we will modify
    push si
    push ax
    push bx

.loop:
    lodsb                        ; loads next character in al
    or al, al                    ; verify if next character is null?
    jz .done

    mov ah, 0x0E                 ; call bios interrupt
    mov bh, 0                    ; set page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret

main:
    ; setup data segments
    mov ax, 0                    ; can't set ds/es directly
    mov ds, ax
    mov es, ax
    
    ; setup stack
    mov ss, ax
    mov sp, 0x7C00                ; stack grows downwards from where we are loaded in memory

    ; read kernel from floppy (LBA 2 for kernel sector)
    mov ax, 2                    ; LBA=2, second sector from disk (kernel starts here)
    mov cl, 1                    ; 1 sector to read
    mov bx, 0x8000               ; kernel will be loaded at 0x8000
    call disk_read

    ; print hello world message
    mov si, msg_hello
    call puts

    ; jump to kernel's entry point (address 0x8000)
    jmp 0x8000

; Error handlers
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                       ; wait for keypress
    jmp 0FFFFh:0                  ; jump to beginning of BIOS, should reboot

.halt:
    cli            ; Disable interrupts
    jmp .halt      ; Jump to the halt label, creating an infinite loop

; Disk routines
lba_to_chs:
    push ax
    push dx

    xor dx, dx                        ; dx = 0
    div word [bdb_sectors_per_track]    ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack

    inc dx                             ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                         ; cx = sector

    xor dx, dx                         ; dx = 0
    div word [bdb_heads]                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        ; dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl                         ; dh = head
    mov ch, al                         ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                         ; restore DL
    pop ax
    ret

disk_read:
    push ax                             ; save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; temporarily save CL (number of sectors to read)
    call lba_to_chs                    ; compute CHS
    pop ax                             ; AL = number of sectors to read
    
    mov ah, 02h
    mov di, 3                             ; retry count

.retry:
    pusha                                   ; save all registers, we don't know what bios modifies
    stc                                      ; set carry flag, some BIOS'es don't set it
    int 13h                                  ; carry flag cleared = success
    jnc .done                                ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             ; restore registers modified
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_hello:                db 'booting...!', ENDL, 0
msg_read_failed:        db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
