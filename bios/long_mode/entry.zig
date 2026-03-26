
// Provided by linker.ld so we can zero .bss ourselves (objcopy strips it).
extern var __bss_start: u8;
extern var __bss_end: u8;

fn bss_clear() void {
	const start = @intFromPtr(&__bss_start);
	const end = @intFromPtr(&__bss_end);
	var p: usize = start;
	while (p < end) : (p += 1) {
		@as(*volatile u8, @ptrFromInt(p)).* = 0;
	}
}

const VGA_COLS: usize = 80;
const VGA_ROWS: usize = 25;
const VGA_TEXT: [*]volatile u16 = @ptrFromInt(0xB8000);

fn vga_clear(attr: u8) void {
	var i: usize = 0;
	while (i < VGA_COLS * VGA_ROWS) : (i += 1) {
		VGA_TEXT[i] = (@as(u16, attr) << 8) | @as(u16, ' ');
	}
}

fn vga_print(msg: []const u8, row: u8, col: u8, attr: u8) void {
	var i: usize = 0;
	var pos: usize = @as(usize, row) * VGA_COLS + @as(usize, col);
	while (i < msg.len and pos < VGA_COLS * VGA_ROWS) : ({
		i += 1;
		pos += 1;
	}) {
		VGA_TEXT[pos] = (@as(u16, attr) << 8) | @as(u16, msg[i]);
	}
}

pub export fn _start() linksection(".text.start") callconv(.c) noreturn {
	bss_clear();

	vga_clear(0x07);
	vga_print("long mode stage active", 0, 0, 0x0F);

	while (true) {
		asm volatile ("hlt");
	}
}
