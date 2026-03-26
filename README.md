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
- `bios/handoff`: BIOS handoff loader that enters protected mode, enables IA-32e long mode, and jumps to 64-bit payload.
- `bios/long_mode`: Zig payload running in 64-bit long mode (framebuffer rendering demo).

## Cleaning
```sh
zig build clean
```

## Help
```sh
zig build what
```
