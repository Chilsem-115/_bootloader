ASM=nasm
CC=gcc

TOOLS_DIR=tools
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always tools_fat

all: floppy_image tools_fat

#
# Floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/stgtwo.bin "::stgtwo.bin"  # Changed kernel name here

#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	$(ASM) stage_01.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#
# Kernel
#
kernel: $(BUILD_DIR)/stgtwo.bin  # Changed to match new kernel name

$(BUILD_DIR)/stgtwo.bin: always
	$(ASM) stage_02.asm -f bin -o $(BUILD_DIR)/stgtwo.bin  # Changed output name to stgtwo.bin

#
# Always
#
always:
	mkdir -p $(BUILD_DIR)

#
# Clean
#
run: all
	qemu-system-i386  -d int -M smm=off -fda build/main_floppy.img
	
clean:
	rm -rf $(BUILD_DIR)/*
