AS = fasm
LD = ld
QEMU = qemu-system-x86_64

BUILD_DIR = build
BOOT_SRC = stage_01.asm
KERNEL_SRC = stage_02.asm

STAGE_01_BIN = $(BUILD_DIR)/stage_01.bin
STAGE_02_BIN = $(BUILD_DIR)/stage_02.bin
DISK_IMG = $(BUILD_DIR)/disk.img

all: $(BUILD_DIR) $(DISK_IMG)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(STAGE_01_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	$(AS) $< $@

$(STAGE_02_BIN): $(KERNEL_SRC) | $(BUILD_DIR)
	$(AS) $< $@

$(DISK_IMG): $(STAGE_01_BIN) $(STAGE_02_BIN) | $(BUILD_DIR)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(STAGE_01_BIN) of=$@ seek=0 conv=notrunc
	stat --printf="Stage 1 size: %s bytes\n" $(STAGE_01_BIN) | grep -q 512 || (echo "Error: Stage 1 must be 512 bytes"; false)
	dd if=$(STAGE_02_BIN) of=$@ seek=1 conv=notrunc

run: $(DISK_IMG)
	$(QEMU) -d int -M smm=off -drive format=raw,file=$(DISK_IMG)

clean:
	rm -rf $(BUILD_DIR)
