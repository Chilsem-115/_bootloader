
const CpuidLeaf = packed struct {
	eax: u32,
	ebx: u32,
	ecx: u32,
	edx: u32,
};

fn cpuid_supported() bool {
	const changed: u32 = asm volatile (
		\\ pushfd
		\\ pop %%eax
		\\ mov %%eax, %%ecx
		\\ xor $0x200000, %%eax
		\\ push %%eax
		\\ popfd
		\\ pushfd
		\\ pop %%eax
		\\ push %%ecx
		\\ popfd
		\\ xor %%ecx, %%eax
		\\ and $0x200000, %%eax
		: [_] "={eax}" (-> u32),
		:
		: .{ .ecx = true }
	);
	return changed != 0;
}

fn cpuid(leaf_id: u32, subleaf_id: u32) CpuidLeaf {
	var eax: u32 = undefined;
	var ebx: u32 = undefined;
	var ecx: u32 = undefined;
	var edx: u32 = undefined;

	asm volatile ("cpuid"
		: [_] "={eax}" (eax),
			[_] "={ebx}" (ebx),
			[_] "={ecx}" (ecx),
			[_] "={edx}" (edx),
		: [_] "{eax}" (leaf_id),
			[_] "{ecx}" (subleaf_id),
	);

	return .{ .eax = eax, .ebx = ebx, .ecx = ecx, .edx = edx };
}

pub fn can_64() bool {
	if (!cpuid_supported()) return false;

	const ext_max = cpuid(0x80000000, 0);
	if (ext_max.eax < 0x80000001) return false;

	const ext_features = cpuid(0x80000001, 0);
	return (ext_features.edx & (@as(u32, 1) << 29)) != 0;
}

pub fn supports_pae() bool {
	if (!cpuid_supported()) return false;
	const basic = cpuid(1, 0);
	return (basic.edx & (@as(u32, 1) << 6)) != 0;
}

pub fn supports_long_mode() bool {
	return can_64();
}
