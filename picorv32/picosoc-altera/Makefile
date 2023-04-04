
#CROSS=riscv32-unknown-elf-
CROSS=riscv-none-embed-
CFLAGS=

# ---- MCY112 Board ----

mcy112sim: picorv32soc_tb.vvp mcy112demo_fw.hex
	vvp -N $< +firmware=mcy112demo_fw.hex

mcy112synsim: mcy112demo_syn_tb.vvp mcy112demo_fw.hex
	vvp -N $< +firmware=mcy112demo_fw.hex

picorv32soc_tb.vvp: picorv32soc_tb.v picorv32soc.v spimemio.v simpleuart.v picosoc.v ../picorv32.v spiflash.v seg4x7.v
	iverilog -s testbench -DIVERILOG=1 -o $@ $^

mcy112demo_syn_tb.vvp: picorv32soc_tb.v mcy112demo_syn.v spiflash.v
	iverilog -s testbench -DIVERILOG=1 -o $@ $^

mcy112demo_sections.lds: sections.lds
	$(CROSS)cpp -P -DMCY112DEMO -o $@ $^

mcy112demo_fw.elf: mcy112demo_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DMCY112DEMO -mabi=ilp32 -march=rv32imc -Wl,--build-id=none,-Bstatic,-T,mcy112demo_sections.lds,--strip-debug -ffreestanding -nostdlib -o mcy112demo_fw.elf start.s firmware.c

mcy112demo_fw.hex: mcy112demo_fw.elf
	$(CROSS)objcopy -O verilog mcy112demo_fw.elf mcy112demo_fw.hex

mcy112demo_fw.bin: mcy112demo_fw.elf
	$(CROSS)objcopy -O binary mcy112demo_fw.elf mcy112demo_fw.bin

# ---- Testbench for SPI Flash Model ----

spiflash_tb: spiflash_tb.vvp icebreaker_fw.hex
	vvp -N $< +firmware=icebreaker_fw.hex

spiflash_tb.vvp: spiflash.v spiflash_tb.v
	iverilog -s testbench -o $@ $^

# ---- Clean ----

clean:
	rm -f testbench.vvp testbench.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f mcy112demo_fw.elf mcy112demo_fw.hex mcy112demo_fw.bin cmos.log
	rm -f mcy112demo.blif mcy112demo.log mcy112demo.asc mcy112demo.rpt mcy112demo.bin
	rm -f mcy112demo_syn.v mcy112demo_syn_tb.vvp picorv32soc_tb.vvp

.PHONY: spiflash_tb clean
.PHONY: mcy112prog mcy112prog_fw mcy112sim mcy112synsim
