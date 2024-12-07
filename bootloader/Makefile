ASM=nasm
CC=gcc

TOOLS_DIR=tools
BUILD_DIR=build

.PHONY: all floppy_image stage_02 stage_01 clean always tools_fat

all: floppy_image tools_fat

#
# Floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: stage_01 stage_02
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/stage_01.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/stgtwo.bin "::stgtwo.bin"  # Changed stage_02 name here

#
# Stage_01
#
stage_01: $(BUILD_DIR)/stage_01.bin

$(BUILD_DIR)/stage_01.bin: always
	$(ASM) stage_01.asm -f bin -o $(BUILD_DIR)/stage_01.bin

#
# stage_02
#
stage_02: $(BUILD_DIR)/stgtwo.bin  # Changed to match new stage_02 name

$(BUILD_DIR)/stgtwo.bin: always
	$(ASM) stage_02.asm -f bin -o $(BUILD_DIR)/stgtwo.bin  # Changed output name to stgtwo.bin

#
# Always
#
always:
	mkdir -p $(BUILD_DIR)

#
# Run
# 
# for debugging, use these :
# -no-reboot to make it shutdown instead of reboot
# -no-shutdown to make it pause instead of shutdown
# -d int -M smm=off to print some info about interrupt that cause the triple fault
run: all
	qemu-system-i386 -fda build/main_floppy.img
	
#
# Clean
#
clean:
	rm -rf $(BUILD_DIR)/*
