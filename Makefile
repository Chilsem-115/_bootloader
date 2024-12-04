# Root Makefile

# Directories
BOOTLOADER_DIR = bootloader
KERNEL_DIR = src
BUILD_DIR = Build

# Output filenames
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
BOOT_IMAGE = $(BUILD_DIR)/ascension_os.img

# Linker script
LINKER_SCRIPT = $(KERNEL_DIR)/linker.ld

# Flags
NASM_FLAGS = -f elf32 -g
LD_FLAGS = -m elf_i386 -T $(LINKER_SCRIPT)

# Default target
all: $(BOOTLOADER_BIN) $(KERNEL_BIN) $(BOOT_IMAGE)

# Build Bootloader
$(BOOTLOADER_BIN): $(BOOTLOADER_DIR)/stage_01.asm $(BOOTLOADER_DIR)/stage_02.asm
	@echo "Building Bootloader..."
	# Assemble the bootloader code in raw binary format (not ELF)
	nasm -f bin $(BOOTLOADER_DIR)/stage_01.asm -o $(BUILD_DIR)/stage_01.bin
	nasm -f bin $(BOOTLOADER_DIR)/stage_02.asm -o $(BUILD_DIR)/stage_02.bin
	# Concatenate the two binary stages into one bootloader binary
	cat $(BUILD_DIR)/stage_01.bin $(BUILD_DIR)/stage_02.bin > $(BOOTLOADER_BIN)

# Build Kernel
$(KERNEL_BIN): $(KERNEL_DIR)/kernel.asm $(KERNEL_DIR)/functions/*.asm $(KERNEL_DIR)/syscalls/*.asm $(LINKER_SCRIPT)
	@echo "Building Kernel..."
	nasm $(NASM_FLAGS) $(KERNEL_DIR)/kernel.asm -o $(BUILD_DIR)/kernel.o
	ld $(LD_FLAGS) -o $(KERNEL_BIN) $(BUILD_DIR)/kernel.o

# Create Bootable Image
$(BOOT_IMAGE): $(BOOTLOADER_BIN) $(KERNEL_BIN)
	@echo "Creating Bootable Image..."
	# Write the bootloader at the start of the image
	dd if=$(BOOTLOADER_BIN) of=$(BOOT_IMAGE) bs=512 seek=4
	# Write the kernel starting at the appropriate position
	dd if=$(KERNEL_BIN) of=$(BOOT_IMAGE) bs=512 seek=100

# Clean the build directory
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)/*

# Run in QEMU
run: $(BOOT_IMAGE)
	qemu-system-i386 -drive format=raw,file=$(BOOT_IMAGE)

.PHONY: all clean run
