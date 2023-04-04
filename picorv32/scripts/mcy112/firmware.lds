SECTIONS {
	.memory : {
		. = 0x0;
		*(.init);
		*(.text);
		*(*);
		. = ALIGN(4);
		end = .;
	}
}

