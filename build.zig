
const std = @import("std");

// This repo builds a BIOS boot image out of multiple tools (FASM + Zig + objcopy + dd).
// Zig's build system is used as the top-level orchestrator.
pub fn build(b: *std.Build) void {

	const fasm = b.option([]const u8, "fasm", "Path to fasm") orelse "fasm";
	const objcopy = b.option([]const u8, "objcopy", "Path to objcopy") orelse "objcopy";
	const qemu = b.option([]const u8, "qemu", "Path to qemu-system-i386") orelse "qemu-system-i386";

	// Keep outputs in-repo for now to match the existing workflow.
	const build_bios_dir = "build/bios";
	const build_checkup_dir = "build/checkup";

	const mbr_bin = build_bios_dir ++ "/mbr.bin";
	const handoff_tmp_bin = build_bios_dir ++ "/handoff.tmp.bin";
	const handoff_bin = build_bios_dir ++ "/handoff.bin";
	const checkup_elf = build_checkup_dir ++ "/checkup.elf";
	const checkup_bin = build_checkup_dir ++ "/checkup.bin";
	const disk_img = build_bios_dir ++ "/disk.img";

	const zig_target = b.option([]const u8, "zig-target", "Zig target triple") orelse "x86-freestanding";
	const zig_oflags = b.option([]const u8, "zig-oflags", "Extra Zig flags") orelse "-O ReleaseSmall -fstrip -fno-stack-protector -fno-PIE -fno-PIC";

	const bios = b.step("bios", "Build BIOS artifacts (mbr + handoff loader + checkup payload)");
	const bios_image = b.step("bios-image", "Build a raw disk image for BIOS boot");
	const bios_run = b.step("bios-run", "Run the BIOS image in QEMU");
	const what = b.step("what", "Print common build commands");
	const clean = b.step("clean", "Remove in-repo build artifacts (build/)");

	// Default `zig build` does something useful for this repo.
	b.default_step = bios_image;

	// -------------------- checkup payload (zig -> elf -> flat bin) -----------
	const mk_checkup = b.addSystemCommand(&.{ "bash", "-ceu" });
	mk_checkup.setCwd(b.path("."));
	mk_checkup.addArg(b.fmt(
		\\mkdir -p {s}
		\\zig build-exe bios/checkup/main.zig -target {s} {s} -T bios/checkup/linker.ld -femit-bin={s}
		\\
	, .{ build_checkup_dir, zig_target, zig_oflags, checkup_elf }));

	const mk_checkup_bin = b.addSystemCommand(&.{ "bash", "-ceu" });
	mk_checkup_bin.setCwd(b.path("."));
	mk_checkup_bin.step.dependOn(&mk_checkup.step);
	mk_checkup_bin.addArg(b.fmt(
		\\{s} -O binary {s} {s}
		\\
	, .{ objcopy, checkup_elf, checkup_bin }));

	// -------------------- handoff loader (fasm, 2-pass with checkup layout) --
	const mk_handoff = b.addSystemCommand(&.{ "bash", "-ceu" });
	mk_handoff.setCwd(b.path("."));
	mk_handoff.step.dependOn(&mk_checkup_bin.step);
	mk_handoff.addArg(b.fmt(
		\\mkdir -p {s}
		\\echo "[handoff pass1] assembling {s}"
		\\{s} -d CHECKUP_LBA=0 -d CHECKUP_SECTORS=0 bios/pm-handoff/handoff.asm {s}
		\\
		\\HANDOFF_SIZE=$(wc -c < {s})
		\\CHECKUP_SIZE=$(wc -c < {s})
		\\HANDOFF_SECT=$(( (HANDOFF_SIZE + 511) / 512 ))
		\\CHECKUP_SECT=$(( (CHECKUP_SIZE + 511) / 512 ))
		\\HANDOFF_LBA=1
		\\CHECKUP_LBA=$(( HANDOFF_LBA + HANDOFF_SECT ))
		\\echo "handoff.tmp.bin: $HANDOFF_SIZE bytes => $HANDOFF_SECT sectors @ LBA $HANDOFF_LBA"
		\\echo "checkup.bin:     $CHECKUP_SIZE bytes => $CHECKUP_SECT sectors @ LBA $CHECKUP_LBA"
		\\
		\\echo "[handoff pass2] assembling FINAL {s}"
		\\{s} -d CHECKUP_LBA=$CHECKUP_LBA -d CHECKUP_SECTORS=$CHECKUP_SECT bios/pm-handoff/handoff.asm {s}
		\\
	, .{ build_bios_dir, handoff_tmp_bin, fasm, handoff_tmp_bin, handoff_tmp_bin, checkup_bin, handoff_bin, fasm, handoff_bin }));

	// -------------------- mbr (fasm) ----------------------------------------
	const mk_mbr = b.addSystemCommand(&.{ "bash", "-ceu" });
	mk_mbr.setCwd(b.path("."));
	mk_mbr.step.dependOn(&mk_handoff.step);
	mk_mbr.addArg(b.fmt(
		\\mkdir -p {s}
		\\HANDOFF_SIZE=$(stat -c%s {s} 2>/dev/null || stat -f%z {s})
		\\HANDOFF_SECT=$(( (HANDOFF_SIZE + 511) / 512 ))
		\\HANDOFF_LBA=1
		\\echo "MBR pack info:"
		\\echo "  handoff.bin: $HANDOFF_SIZE bytes => $HANDOFF_SECT sectors @ LBA $HANDOFF_LBA"
		\\{s} -d HANDOFF_LBA=$HANDOFF_LBA bios/mbr/mbr.asm {s}
		\\
	, .{ build_bios_dir, handoff_bin, handoff_bin, fasm, mbr_bin }));

	// -------------------- disk image packing --------------------------------
	const mk_img = b.addSystemCommand(&.{ "bash", "-ceu" });
	mk_img.setCwd(b.path("."));
	mk_img.step.dependOn(&mk_mbr.step);
	mk_img.addArg(b.fmt(
		\\mkdir -p {s}
		\\HANDOFF_SIZE=$(stat -c%s {s} 2>/dev/null || stat -f%z {s})
		\\HANDOFF_SECT=$(( (HANDOFF_SIZE + 511) / 512 ))
		\\CHECKUP_LBA=$(( 1 + HANDOFF_SECT ))
		\\echo "disk.img layout:"
		\\echo "  mbr.bin     -> LBA0"
		\\echo "  handoff.bin -> LBA1.. (sectors=$HANDOFF_SECT)"
		\\echo "  checkup.bin -> LBA$CHECKUP_LBA.."
		\\truncate -s 2M {s}
		\\dd if={s} of={s} bs=512 count=1 conv=notrunc status=none
		\\dd if={s} of={s} bs=512 seek=1 conv=notrunc status=none
		\\dd if={s} of={s} bs=512 seek=$CHECKUP_LBA conv=notrunc status=none
		\\
	, .{ build_bios_dir, handoff_bin, handoff_bin, disk_img, mbr_bin, disk_img, handoff_bin, disk_img, checkup_bin, disk_img }));

	// -------------------- top-level steps -----------------------------------
	bios.dependOn(&mk_mbr.step);
	bios_image.dependOn(&mk_img.step);

	const run_qemu = b.addSystemCommand(&.{ qemu });
	run_qemu.setCwd(b.path("."));
	run_qemu.step.dependOn(&mk_img.step);
	run_qemu.addArgs(&.{
		"-drive",
		b.fmt("file={s},format=raw,if=ide", .{disk_img}),
		"-boot",
		"c",
		"-monitor",
		"stdio",
	});
	bios_run.dependOn(&run_qemu.step);

	const what_run = b.addSystemCommand(&.{ "bash", "-ceu" });
	what_run.setCwd(b.path("."));
	what_run.addArg(
		\\printf '%s\n' \
		\\  'Common commands:' \
		\\  '  zig build bios' \
		\\  '  zig build bios-image        (default)' \
		\\  '  zig build bios-run' \
		\\  '  zig build clean' \
		\\  '' \
		\\  'Tool overrides:' \
		\\  '  zig build bios-image -Dfasm=fasm -Dobjcopy=objcopy -Dqemu=qemu-system-i386' \
		\\  '' \
		\\  'Tip: zig build -h will list all build steps.'
		\\
	);
	what.dependOn(&what_run.step);

	const rm_build = b.addRemoveDirTree(b.path("build"));
	clean.dependOn(&rm_build.step);
}
