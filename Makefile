# Root Makefile

# Directories
BOOTLOADER_DIR = bootloader
KERNEL_DIR = src
BUILD_DIR = Build

# Output filenames
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
BOOT_IMAGE = $(BUILD_DIR)/ascension_os.img

# Linker script for the kernel (no bootloader linker script needed)
KERNEL_LINKER_SCRIPT = $(KERNEL_DIR)/linker.ld

# Flags
NASM_FLAGS = -f elf32 -g
LD_FLAGS = -m elf_i386 -T $(KERNEL_LINKER_SCRIPT)

# Collect all kernel source files
KERNEL_SOURCES = $(KERNEL_DIR)/kernel.asm $(wildcard $(KERNEL_DIR)/functions/*.asm) $(wildcard $(KERNEL_DIR)/syscalls/*.asm)

# Collect all bootloader source files (no bootlinker.ld required now)
BOOTLOADER_SOURCES = $(BOOTLOADER_DIR)/stage_01.asm $(BOOTLOADER_DIR)/stage_02.asm $(BOOTLOADER_DIR)/bootloader_defs.asm

# Object files for the kernel
KERNEL_OBJECTS = $(patsubst %.asm, $(BUILD_DIR)/%.o, $(notdir $(KERNEL_SOURCES)))

# Object files for the bootloader
BOOTLOADER_OBJECTS = $(patsubst %.asm, $(BUILD_DIR)/%.o, $(notdir $(BOOTLOADER_SOURCES)))

# Default target
all: $(BOOTLOADER_BIN) $(KERNEL_BIN) $(BOOT_IMAGE)

# Build Bootloader
$(BOOTLOADER_BIN): $(BOOTLOADER_SOURCES)
	@echo "Building Bootloader..."
	# Assemble all bootloader source files
	mkdir -p $(BUILD_DIR)
	for src in $(BOOTLOADER_SOURCES); do \
		nasm $(NASM_FLAGS) $$src -o $(BUILD_DIR)/$$(basename $$src .asm).o; \
	done
	# Link all bootloader object files into one bootloader binary
	ld -m elf_i386 -o $(BOOTLOADER_BIN) $(BOOTLOADER_OBJECTS)

# Build Kernel
$(KERNEL_BIN): $(KERNEL_SOURCES) $(KERNEL_LINKER_SCRIPT)
	@echo "Building Kernel..."
	# Assemble all kernel source files
	mkdir -p $(BUILD_DIR)
	for src in $(KERNEL_SOURCES); do \
		nasm $(NASM_FLAGS) $$src -o $(BUILD_DIR)/$$(basename $$src .asm).o; \
	done
	# Link all object files into the kernel binary
	ld $(LD_FLAGS) -o $(KERNEL_BIN) $(KERNEL_OBJECTS)

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
	rm -rf $(BUILD_DIR)/*.o $(BUILD_DIR)/*.bin $(BUILD_DIR)/bootloader.bin $(BUILD_DIR)/kernel.bin $(BUILD_DIR)/ascension_os.img

# Run in QEMU
run: $(BOOT_IMAGE)
	qemu-system-i386 -drive format=raw,file=$(BOOT_IMAGE)

.PHONY: all clean run
