
const check_cpuid = @import("check_cpuid.zig");

pub const Result = enum {
	enabled,
	already_enabled,
	not_supported,
	failed,
};

const CR4_PAE_MASK: u32 = @as(u32, 1) << 5;

fn read_cr4() u32 {
	return asm volatile (
		\\ mov %%cr4, %%eax
		: [_] "={eax}" (-> u32),
	);
}

fn write_cr4(value: u32) void {
	asm volatile (
		\\ mov %%eax, %%cr4
		:
		: [_] "{eax}" (value),
	);
}

pub fn enable() Result {
	if (!check_cpuid.supports_pae()) return .not_supported;

	const before = read_cr4();
	if ((before & CR4_PAE_MASK) != 0) return .already_enabled;

	write_cr4(before | CR4_PAE_MASK);

	const after = read_cr4();
	if ((after & CR4_PAE_MASK) == 0) return .failed;

	return .enabled;
}

pub fn prepare_long_mode_paging() void {
	// Keep all capability checks and paging setup logic inside paging/.
	if (!check_cpuid.supports_long_mode()) return;
	_ = enable();
}
