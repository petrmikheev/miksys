startup.bin: startup.S usb_read.S ../include/math.H ../include/string.H ../include/usb.H
	./rebuild_startup.sh
	python2 ../../verilog/startup/gen_hex.py startup.bin > ../../verilog/startup/startup.hex

.PHONY: clean
clean:
	rm -f startup.bin
