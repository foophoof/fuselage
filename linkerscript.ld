ENTRY(start)

KERNEL_BASE = 0xFFFFC00000000000;

SECTIONS {
	. = 1M;

	.boot : {
		header_start = .;

		LONG(0xe85250d6)
		LONG(0)
		LONG(header_end - header_start)
		LONG(0x100000000 - (0xe85250d6 + 0 + (header_end - header_start)))

		SHORT(0)
		SHORT(0)
		LONG(8)

		header_end = .;
	}

	.bootstrap : {
		*(.bootstrap .bootstrap.*)
	}

	. += KERNEL_BASE;

	.text : AT(ADDR(.text) - KERNEL_BASE) {
		*(.text .text.*)
	}

	.bss : AT(ADDR(.bss) - KERNEL_BASE) {
		*(.bss .bss.*)
	}

	.rodata : AT(ADDR(.rodata) - KERNEL_BASE) {
		*(.rodata .rodata.*)
	}
}
