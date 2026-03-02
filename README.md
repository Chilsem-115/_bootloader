# 1337 Bootloader (BIOS path)

Minimal BIOS boot path with an MBR, a protected-mode handoff loader, and a Zig checkup payload.

## Build
Requires `fasm`, `zig`, `objcopy`, and `qemu-system-i386` on PATH.

```sh
zig build bios
```

## Run in QEMU
```sh
zig build bios-run
```

## Layout
- `bios/mbr`: loads the handoff image to `0000:8000`, then jumps.
- `bios/pm-handoff`: BIOS real-mode handoff loader (INT13/E820/A20) that enters 32-bit protected mode.
- `bios/checkup`: Zig checkup payload running in 32-bit protected mode (currently clears screen + prints; zeroes `.bss`).

## Cleaning
```sh
zig build clean
```

## Help
```sh
zig build what
```
