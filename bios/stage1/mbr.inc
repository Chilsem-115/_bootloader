
; ===== stage1/mbr.inc =====

; Compile-time assert (no runtime bytes)
macro ASSERT cond, msg&
{
  if ~ (cond)
    ; show the message, then hard-stop assembly
    display 'ASSERT FAILED: ', `msg, 13, 10
    err
  end if
}

; Print zero-terminated string at DS:SI (expands to a few bytes)
macro PRINT_Z si_reg
{
  local .loop, .done
  .loop:
    lodsb
    test  al, al
    jz    .done
    mov   ah, 0Eh
    mov   bh, 0
    mov   bl, 7
    int   10h
    jmp   .loop
  .done:
}

; Disk Address Packet builder (16 bytes) for INT 13h AH=42h
macro MAKE_DAP name, count, seg, ofs, lba
{
  name:
    db 10h
    db 0
    dw count
    dw ofs
    dw seg
    dq lba
}
