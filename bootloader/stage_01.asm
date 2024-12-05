[bits 16]
[org 0x7c00]

section .text
jmp short _start
nop

%include "bootloader_defs.asm"

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

    ; print hello world message
    mov si, msg_hello
    call puts

    ; Search for stage_02.asm in the FAT12 directory
    mov si, msg_searching
    call puts

    ; Find the stage_02.asm file
    mov ax, 0x0000               ; start searching from the first cluster
    call search_file

    ; If file found, load it
    mov si, msg_stage_02
    call puts

    ; Read stage_02.asm
    mov ax, 0x8000               ; Load it to address 0x8000
    call disk_read_stage_02

    ; Jump to the stage_02.asm entry point
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

; Disk routines (same as before)
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
    ; Read sectors as before
    ; [existing code remains unchanged]

disk_reset:
    ; Reset disk on failure
    ; [existing code remains unchanged]

search_file:
    ; Search through the FAT12 root directory for "stage_02.asm"
    ; Directory entry starts at 0x0020 and has a maximum of 224 entries (since there are 2880 sectors on the disk)
    mov cx, 0x0020  ; Start of directory entries
    mov dx, 0x00FF  ; Maximum directory entry count (224 entries)

.next_entry:
    ; Check for "stage_02.asm" filename in directory entries
    ; If found, return the starting cluster of the file
    ; [Implement FAT12 directory entry parsing here]
    ; Once found, return the starting cluster of the file to `ax`
    ; and jump to disk_read_stage_02

    ; If end of directory, return to main or handle error
    test dx, dx
    jz .done
    inc cx
    dec dx
    jmp .next_entry

.done:
    ret

disk_read_stage_02:
    ; Read the file `stage_02.asm` from the FAT12 disk and load it at the specified address (0x8000)
    ; Read the clusters chained together by the FAT12 table
    ; [Implement cluster reading logic here]
    ret

msg_hello:        db 'booting...!', ENDL, 0
msg_read_failed:  db 'Read from disk failed!', ENDL, 0
msg_searching:    db 'Searching for stage_02.asm...', ENDL, 0
msg_stage_02:     db 'Found stage_02.asm, loading...', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
