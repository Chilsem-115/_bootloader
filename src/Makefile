# Kernel Makefile

KERNEL_DIR = .
BUILD_DIR = ../Build

NASM_FLAGS = -f elf32 -g
LD_FLAGS = -m elf_i386

# Output filenames
KERNEL_BIN = $(BUILD_DIR)/kernel.bin

# Targets
all: $(KERNEL_BIN)

$(KERNEL_BIN): kernel.asm functions/*.asm syscalls/*.asm
	@echo "Building Kernel..."
	nasm $(NASM_FLAGS) kernel.asm -o $(BUILD_DIR)/kernel.o
	ld $(LD_FLAGS) -o $(KERNEL_BIN) $(BUILD_DIR)/kernel.o

clean:
	@echo "Cleaning kernel..."
	rm -rf $(BUILD_DIR)/*.o $(KERNEL_BIN)

.PHONY: all clean
