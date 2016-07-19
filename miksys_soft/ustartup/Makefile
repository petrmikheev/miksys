startup.bin: startup.S usb_read.S
	./rebuild_startup.sh
	python2 ../../verilog/startup/gen_hex.py startup.bin > ../../verilog/startup/startup.hex

clean:
	rm startup.bin
