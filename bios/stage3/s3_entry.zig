const VGA = @as(*volatile [80 * 25]u16, @ptrFromInt(0xB8000));

fn vga_clear(attr: u8) void {
	var i: usize = 0;
	while (i < 80 * 25) : (i += 1) {
		// high byte = attr, low byte = ' '
		VGA[i] = (@as(u16, attr) << 8) | ' ';
	}
}

fn vga_print(msg: []const u8, row: u8, col: u8, attr: u8) void {
	var i: usize = 0;
	var pos: usize = (@as(usize, row) * 80 + @as(usize, col));
	while (i < msg.len and pos < 80 * 25) : ({
		i += 1;
		pos += 1;
	}) {
		const ch: u8 = msg[i];
		VGA[pos] = (@as(u16, attr) << 8) | ch;
	}
}

pub export fn _start() linksection(".text.start") callconv(.C) noreturn {
	// We're already in 32-bit protected mode, with a valid stack (ESP set by stage2).
	// Segments must already be flat, paging off.

	// clear to gray-on-black
	vga_clear(0x07);

	// print in bright white
	vga_print("hello from 32-bit protected mode", 0, 0, 0x0F);
	vga_print("suka", 1, 0, 0x1D);

	// hang forever (hlt in a loop)
	while (true) {
		asm volatile ("hlt");
	}
}
