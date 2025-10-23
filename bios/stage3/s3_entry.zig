
pub const BootInfo = extern struct {
    boot_drive: u8,
    _pad: [3]u8,
    e820_ptr: u32,
    e820_count: u32,
    stage3_base: u32,
    stage3_size: u32,
    res0: u32,
    res1: u32,
};

export fn _main_entry_(bi: *const BootInfo) callconv(.C) noreturn {
    vgaPrint("Stage3 (Zig) up\n");
    // TODO: dump E820, build GDT/IDT, paging, LM, stivale2
    while (true) {}
}
