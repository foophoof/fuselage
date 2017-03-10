.PHONY: cargo iso run

grub-mkrescue = grub-mkrescue

cargo:
	xargo build --release --verbose --target x86_64-unknown-fuselage-gnu

iso: cargo grub.cfg
	mkdir -p target/isofiles/boot/grub
	cp grub.cfg target/isofiles/boot/grub
	cp target/x86_64-unknown-fuselage-gnu/release/fuselage target/isofiles/boot
	$(grub-mkrescue) -o target/fuselage.iso target/isofiles

run: iso
	qemu-system-x86_64 -cdrom target/fuselage.iso
