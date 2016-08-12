all: demo3d.packed demo3d.usb_packed

demo3d.bin: *.S *.H ../include/*.H
	../miksys_asm.py main.S demo3d.bin
	cat textures/brick.bin textures/roof.bin textures/wood.bin textures/window.bin >> demo3d.bin

demo3d.packed: demo3d.bin
	../pack.py demo3d.bin demo3d.packed

demo3d.usb_packed: demo3d.bin
	../pack_usb.py demo3d.bin demo3d.usb_packed

.PHONY: clean
clean:
	rm -f demo3d.bin demo3d.packed demo3d.usb_packed
