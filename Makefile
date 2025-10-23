# ---- BIOS-only quick build & run ----
FASM	?= fasm
QEMU	?= qemu-system-i386

BUILD	:= build/bios
IMG		:= $(BUILD)/disk.img

MBR_SRC		:= bios/stage1/mbr.asm
MBR_INC		:= bios/stage1/mbr.inc

ST2_DIR		:= bios/stage2
ST2_SRC		:= $(ST2_DIR)/stage2.asm
ST2_PARTS	:= $(ST2_DIR)/config.inc \
			   $(ST2_DIR)/a20.asm \
			   $(ST2_DIR)/e820.asm \
			   $(ST2_DIR)/pm32.asm

MBR_BIN		:= $(BUILD)/mbr.bin
ST2_BIN		:= $(BUILD)/stage2.bin

.PHONY: bios bios-image bios-run bios-clean

bios: $(MBR_BIN) $(ST2_BIN)

$(BUILD):
	@mkdir -p $(BUILD)

$(MBR_BIN): $(MBR_SRC) $(MBR_INC) | $(BUILD)
	$(FASM) $(MBR_SRC) $(MBR_BIN)

$(ST2_BIN): $(ST2_SRC) $(ST2_PARTS) | $(BUILD)
	$(FASM) $(ST2_SRC) $(ST2_BIN)

bios-image: bios
	truncate -s 2M $(IMG)
	dd if=$(MBR_BIN) of=$(IMG) bs=512 count=1 conv=notrunc status=none
	dd if=$(ST2_BIN) of=$(IMG) bs=512 seek=1 conv=notrunc status=none

bios-run: bios-image
	$(QEMU) -drive file=$(IMG),format=raw,if=ide -boot c

bios-clean:
	rm -rf $(BUILD)
