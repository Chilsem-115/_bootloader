AS = nasm
LD = ld
QEMU = qemu-system-i386

BUILD_DIR = build

BOOT_SRC = stage_01.asm
KERNEL_SRC = stage_02.asm

STAGE_01_BIN = $(BUILD_DIR)/stage_01.bin
STAGE_02_BIN = $(BUILD_DIR)/stage_02.bin
FLOPPY_IMG = $(BUILD_DIR)/floppy.img

all: $(BUILD_DIR) $(FLOPPY_IMG)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(STAGE_01_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	$(AS) -f bin -o $@ $<

$(STAGE_02_BIN): $(KERNEL_SRC) | $(BUILD_DIR)
	$(AS) -f bin -o $@ $<

$(FLOPPY_IMG): $(STAGE_01_BIN) $(STAGE_02_BIN) | $(BUILD_DIR)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(STAGE_01_BIN) of=$@ seek=0 conv=notrunc
	dd if=$(STAGE_02_BIN) of=$@ seek=1 conv=notrunc

run: $(FLOPPY_IMG)
	$(QEMU) -d int -M smm=off -drive format=raw,file=$<

clean:
	rm -rf $(BUILD_DIR)
