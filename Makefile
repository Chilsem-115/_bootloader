# ==================== tools ====================
FASM        ?= fasm
QEMU        ?= qemu-system-i386

ZIG         ?= zig
OBJCOPY     ?= objcopy
ZIG_TARGET  ?= x86-freestanding
ZIG_OFLAGS  ?= -O ReleaseSmall -fstrip -fno-stack-protector -fno-PIE -fno-PIC

# ==================== build dirs / outputs ====================
BUILD_BIOS  := build/bios
BUILD_ST3   := build/stage3

IMG         := $(BUILD_BIOS)/disk.img

# ==================== sources ====================
# stage1
MBR_SRC     := bios/stage1/mbr.asm

# stage2
ST2_SRC     := bios/stage2/stage2.asm
ST2_PARTS   := bios/stage2/a20.asm \
               bios/stage2/config.inc \
               bios/stage2/e820.asm \
               bios/stage2/load_s3.asm \
               bios/stage2/pm32.asm \
               bios/stage2/print_vga.asm \
               bios/shared.inc

# stage3
ST3_SRC     := bios/stage3/s3_entry.zig
ST3_LD      := bios/stage3/linker.ld

# ==================== build artifacts ====================
MBR_BIN     := $(BUILD_BIOS)/mbr.bin
ST2_BIN     := $(BUILD_BIOS)/stage2.bin
ST3_ELF     := $(BUILD_ST3)/stage3.elf
ST3_BIN     := $(BUILD_ST3)/stage3.bin

.PHONY: bios bios-image bios-run bios-clean re

# default: build full BIOS boot path
bios: $(MBR_BIN) $(ST2_BIN) $(ST3_BIN)

# make sure build dirs exist
$(BUILD_BIOS):
	mkdir -p $(BUILD_BIOS)

$(BUILD_ST3):
	mkdir -p $(BUILD_ST3)

# ==================== Stage3 (Zig -> bin) ====================
# 1. Zig -> ELF
$(ST3_ELF): $(ST3_SRC) $(ST3_LD) | $(BUILD_ST3)
	$(ZIG) build-exe \
		$(ST3_SRC) \
		-target $(ZIG_TARGET) \
		$(ZIG_OFLAGS) \
		-T $(ST3_LD) \
		-femit-bin=$(ST3_ELF)

# 2. ELF -> flat binary
$(ST3_BIN): $(ST3_ELF) | $(BUILD_ST3)
	$(OBJCOPY) -O binary $< $@

# ==================== Stage2 (2-pass FASM) ====================
# Pass1: assemble stage2.bin -> measure its size and stage3 size
# Pass2: reassemble with correct STAGE3_LBA / STAGE3_SECTORS baked in.
#
# Disk layout:
#   LBA0: mbr.bin
#   LBA1..: stage2.bin
#   next..: stage3.bin
#
# So:
#   S2_LBA       = 1
#   S2_SECT      = ceil(len(stage2.bin)/512)
#   STAGE3_LBA   = S2_LBA + S2_SECT
#   STAGE3_SECT  = ceil(len(stage3.bin)/512)
#

ST2_TMP := $(BUILD_BIOS)/stage2.tmp.bin

$(ST2_BIN): $(ST2_SRC) $(ST2_PARTS) $(ST3_BIN) | $(BUILD_BIOS)
	@set -euo pipefail; \
	echo "[stage2 pass1] assembling stage2.tmp.bin"; \
	$(FASM) -d STAGE3_LBA=0 -d STAGE3_SECTORS=0 $(ST2_SRC) $(ST2_TMP); \
	\
	S2_SIZE=$$(wc -c < $(ST2_TMP)); \
	S3_SIZE=$$(wc -c < $(ST3_BIN)); \
	S2_SECT=$$(( (S2_SIZE + 511) / 512 )); \
	S3_SECT=$$(( (S3_SIZE + 511) / 512 )); \
	S2_LBA=1; \
	S3_LBA=$$(( S2_LBA + S2_SECT )); \
	echo "stage2.tmp.bin: $$S2_SIZE bytes => $$S2_SECT sectors @ LBA $$S2_LBA"; \
	echo "stage3.bin:     $$S3_SIZE bytes => $$S3_SECT sectors @ LBA $$S3_LBA"; \
	\
	echo "[stage2 pass2] assembling FINAL stage2.bin with stage3 layout"; \
	$(FASM) \
		-d STAGE3_LBA=$$S3_LBA \
		-d STAGE3_SECTORS=$$S3_SECT \
		$(ST2_SRC) $(ST2_BIN)

# ==================== Stage1 / MBR ====================
# Stage1 now:
#   - loads stage2 to 0000:8000
#   - jumps to it
#   - does NOT load stage3 anymore
#
# It only needs STAGE2_LBA baked in (always 1).
#
$(MBR_BIN): $(MBR_SRC) bios/shared.inc $(ST2_BIN) | $(BUILD_BIOS)
	@S2_SIZE=$$(stat -c%s $(ST2_BIN) 2>/dev/null || stat -f%z $(ST2_BIN)); \
	S2_SECT=$$(( ( $$S2_SIZE + 511 ) / 512 )); \
	S2_LBA=1; \
	echo "MBR pack info:"; \
	echo "  stage2.bin: $$S2_SIZE bytes => $$S2_SECT sectors @ LBA $$S2_LBA"; \
	$(FASM) \
		-d STAGE2_LBA=$$S2_LBA \
		$(MBR_SRC) $(MBR_BIN)

# ==================== disk image ====================
# disk.img layout:
#   LBA0: mbr.bin
#   LBA1..: stage2.bin
#   next..: stage3.bin
bios-image: bios
	@S2_SIZE=$$(stat -c%s $(ST2_BIN) 2>/dev/null || stat -f%z $(ST2_BIN)); \
	S2_SECT=$$(( ( $$S2_SIZE + 511 ) / 512 )); \
	S3_LBA=$$(( 1 + $$S2_SECT )); \
	\
	echo "disk.img layout:"; \
	echo "  mbr.bin     -> LBA0"; \
	echo "  stage2.bin  -> LBA1.. (sectors=$$S2_SECT)"; \
	echo "  stage3.bin  -> LBA$$S3_LBA.."; \
	\
	truncate -s 2M $(IMG); \
	dd if=$(MBR_BIN) of=$(IMG) bs=512 count=1 conv=notrunc status=none; \
	dd if=$(ST2_BIN) of=$(IMG) bs=512 seek=1 conv=notrunc status=none; \
	dd if=$(ST3_BIN) of=$(IMG) bs=512 seek=$$S3_LBA conv=notrunc status=none

bios-run: bios-image
	$(QEMU) -drive file=$(IMG),format=raw,if=ide -boot c -monitor stdio

# ==================== clean / rebuild ====================
bios-clean:
	rm -rf build

re: bios-clean bios
