# Bootloader Makefile

BOOTLOADER_DIR = .
BUILD_DIR = ../Build

# Correct flags for the bootloader (real mode)
NASM_FLAGS = -f bin

# Output filenames
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin

# Targets
all: $(BOOTLOADER_BIN)

$(BOOTLOADER_BIN): stage_01.asm stage_02.asm
	@echo "Building Bootloader..."
	nasm $(NASM_FLAGS) stage_01.asm -o $(BUILD_DIR)/stage_01.bin
	nasm $(NASM_FLAGS) stage_02.asm -o $(BUILD_DIR)/stage_02.bin
	cat $(BUILD_DIR)/stage_01.bin $(BUILD_DIR)/stage_02.bin > $(BOOTLOADER_BIN)

clean:
	@echo "Cleaning bootloader..."
	rm -rf $(BUILD_DIR)/*.bin $(BOOTLOADER_BIN)

.PHONY: all clean
