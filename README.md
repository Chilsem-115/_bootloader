# 1337 Bootloader (BIOS path)

Minimal multi-stage BIOS boot path with Zig stage3.

## Build
Requires `fasm`, `zig`, `objcopy`, and `qemu-system-i386` on PATH.

```sh
make bios
```

## Run in QEMU
```sh
make bios-run
```

## Layout
- Stage1 (MBR): loads Stage2 to `0000:8000`, jumps.
- Stage2 (real mode): loads Stage3 to 0x00002000, collects E820, enables A20, switches to protected mode.
- Stage3 (Zig): currently just clears screen and prints; zeroes `.bss` manually.

## Cleaning
```sh
make bios-clean
```
