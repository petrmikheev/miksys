build_all: build qt_sim verilog/miksys.svf verilog/miksys_epcs4.svf

build:
	$(MAKE) -C verilog/charmap
	$(MAKE) -C verilog/sdram_model
	$(MAKE) -C miksys_soft/ustartup
	$(MAKE) -C miksys_soft/demo3d
	$(MAKE) -C miksys_soft/demoIO
	$(MAKE) -C verilog

verilog/miksys.svf: build
	quartus_cpf -c -q 10MHz -g 3.3 -n v verilog/output_files/miksys.sof verilog/miksys.svf

verilog/miksys_epcs4.svf: build
	quartus_cpf -c -d EPCS4 -s EP3C10 verilog/output_files/miksys.sof verilog/output_files/miksys.jic
	quartus_cpf -c -q 10MHz -g 3.3 -n v verilog/output_files/miksys.jic verilog/miksys_epcs4.svf

write: verilog/miksys.svf
	sudo rmmod ftdi_sio
	sudo ./mbftdi verilog/miksys.svf
	sudo modprobe ftdi_sio

write_epcs4: verilog/miksys_epcs4.svf
	sudo rmmod ftdi_sio
	sudo ./mbftdi verilog/epcs4_tunnel.svf
	sudo ./mbftdi verilog/miksys_epcs4.svf
	sudo modprobe ftdi_sio

qt_sim:
	cd qt_sim && qmake
	$(MAKE) -C qt_sim

sim_demo3d:
	cp miksys_soft/demo3d/demo3d.packed miksys_soft/serial_in
	cd qt_sim && ./qt_sim

sim_demoIO:
	cp miksys_soft/demoIO/demo.packed miksys_soft/serial_in
	cd qt_sim && ./qt_sim

clean:
	rm -rf verilog/db verilog/incremental_db verilog/simulation output_files
