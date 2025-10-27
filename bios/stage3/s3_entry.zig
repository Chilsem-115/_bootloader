// bios/stage3/s3_entry.zig

const StackTrace = extern struct {}; // minimal stub so we can define panic()

const VGA = struct {
    pub fn put(row: u8, col: u8, ch: u8, attr: u8) void {
        const buf: [*]volatile u16 = @ptrFromInt(0xB8000);
        const idx =
            @as(usize, @intCast(row)) * 80 +
            @as(usize, @intCast(col));
        buf[idx] = (@as(u16, attr) << 8) | ch;
    }
};

fn hang() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

// Entry point (matches linker.ld ENTRY(_start))
export fn _start() noreturn {
    // Clear first line
    var i: u8 = 0;
    while (i < 80) : (i += 1) VGA.put(0, i, ' ', 0x0F);

    // "ZIG3 OK"
    VGA.put(0, 0, 'Z', 0x0F);
    VGA.put(0, 1, 'I', 0x0F);
    VGA.put(0, 2, 'G', 0x0F);
    VGA.put(0, 3, '3', 0x0F);
    VGA.put(0, 5, 'O', 0x0A);
    VGA.put(0, 6, 'K', 0x0A);

    hang();
}

// Minimal panic stub for freestanding (avoid pulling in std)
pub fn panic(
    msg: []const u8,
    trace: ?*StackTrace,
    ret_addr: ?usize,
) noreturn {
    _ = msg;
    _ = trace;
    _ = ret_addr;
    hang();
}
