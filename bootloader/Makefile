# Compiler and tools
AS = nasm
LD = ld
QEMU = qemu-system-i386

# Source files
BOOT_SRC = stage_01.asm   # Bootloader code
KERNEL_SRC = stage_02.asm # Kernel code (if applicable)

# Build directory
BUILD_DIR = build

# Output files
BOOT_BIN = $(BUILD_DIR)/boot.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
FLOPPY_IMG = $(BUILD_DIR)/floppy.img
ISO = $(BUILD_DIR)/AscensionOS.iso

# All target
all: $(BUILD_DIR) $(FLOPPY_IMG)

# Create the build directory if it doesn't exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Bootloader binary (16-bit)
$(BOOT_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	$(AS) -f bin -o $@ $<  # Compile boot.asm to boot.bin in raw binary format

# Kernel binary (32-bit) - Optional, you can adjust based on your setup
$(KERNEL_BIN): $(KERNEL_SRC) | $(BUILD_DIR)
	$(AS) -f bin -o $@ $<  # Compile kernel.asm to kernel.bin in raw binary format

# Create the floppy image
$(FLOPPY_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880  # Create empty floppy disk image
	dd if=$(BOOT_BIN) of=$@ conv=notrunc  # Copy the bootloader into the image
	dd if=$(KERNEL_BIN) of=$@ seek=1 conv=notrunc  # Copy the kernel into the image

# Clean up generated files
clean:
	rm -rf $(BUILD_DIR)

# Run the operating system in QEMU
run: $(FLOPPY_IMG)
	$(QEMU) -drive format=raw,file=$<

# Create the ISO image (optional)
$(ISO): $(FLOPPY_IMG)
	genisoimage -o $@ -b $(FLOPPY_IMG) -no-emul-boot -boot-load-size 4 -boot-info-table
