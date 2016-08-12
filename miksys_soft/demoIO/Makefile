all: demo.packed demo.usb_packed

demo.bin: demo.S ../include/*.H
	../miksys_asm.py demo.S demo.bin
	cat picture.img >> demo.bin

demo.packed: demo.bin
	../pack.py demo.bin demo.packed

demo.usb_packed: demo.bin
	../pack_usb.py demo.bin demo.usb_packed

.PHONY: clean
clean:
	rm -f demo.bin demo.packed demo.usb_packed
