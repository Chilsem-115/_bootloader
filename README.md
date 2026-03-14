# 1337 Bootloader (BIOS path)

Minimal BIOS boot path with an MBR, a protected-mode handoff loader, and a Zig long-mode stage payload.

## Build
Requires `fasm`, `zig`, `objcopy`, and `qemu-system-x86_64` on PATH.

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
- `bios/long_mode`: Zig long-mode stage running in 32-bit protected mode (CPUID checks + PAE enable path).

## Cleaning
```sh
zig build clean
```

## Help
```sh
zig build what
```
