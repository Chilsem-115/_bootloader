BOOTLOADER_DIR = .
BUILD_DIR = ../Build
LINKER_SCRIPT = $(BOOTLOADER_DIR)/bootlinker.ld

# Flags for NASM and linking
NASM_FLAGS = -f elf32
LD_FLAGS = -m elf_i386 -T $(LINKER_SCRIPT)

# Output filenames
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin

# Targets
all: $(BOOTLOADER_BIN)

$(BOOTLOADER_BIN): stage_01.asm stage_02.asm $(LINKER_SCRIPT)
	@echo "Building Bootloader..."
	# Assemble stage 1 and stage 2 into ELF object files
	nasm $(NASM_FLAGS) stage_01.asm -o $(BUILD_DIR)/stage_01.o
	nasm $(NASM_FLAGS) stage_02.asm -o $(BUILD_DIR)/stage_02.o
	# Link both stages into a single binary using the linker script
	ld $(LD_FLAGS) -o $(BOOTLOADER_BIN) $(BUILD_DIR)/stage_01.o $(BUILD_DIR)/stage_02.o

clean:
	@echo "Cleaning bootloader..."
	rm -rf $(BUILD_DIR)/*.o $(BOOTLOADER_BIN)

.PHONY: all clean
