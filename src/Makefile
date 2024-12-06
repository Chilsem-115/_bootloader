# Kernel Makefile

KERNEL_DIR = .
BUILD_DIR = ../Build

NASM_FLAGS = -f elf32 -g
LD_FLAGS = -m elf_i386

# Output filenames
KERNEL_BIN = $(BUILD_DIR)/kernel.bin

# Collect all kernel source files
KERNEL_SOURCES = $(KERNEL_DIR)/kernel.asm \
                  $(wildcard $(KERNEL_DIR)/functions/*.asm) \
                  $(wildcard $(KERNEL_DIR)/syscalls/*.asm)

# Object files
KERNEL_OBJECTS = $(patsubst %.asm, $(BUILD_DIR)/%.o, $(notdir $(KERNEL_SOURCES)))

# Targets
all: $(KERNEL_BIN)

$(KERNEL_BIN): $(KERNEL_OBJECTS)
	@echo "Building Kernel..."
	# Link all object files into the kernel binary
	ld $(LD_FLAGS) -o $(KERNEL_BIN) $(KERNEL_OBJECTS)

$(BUILD_DIR)/%.o: $(KERNEL_DIR)/%.asm
	@echo "Assembling $<..."
	# Assemble the .asm file into an object file
	nasm $(NASM_FLAGS) $< -o $@

clean:
	@echo "Cleaning kernel..."
	rm -rf $(BUILD_DIR)/*.o $(KERNEL_BIN)

.PHONY: all clean
