build_all: build qt_sim miksys.svf

build:
	$(MAKE) -C verilog/charmap
	$(MAKE) -C verilog/sdram_model
	$(MAKE) -C miksys_soft/ustartup
	$(MAKE) -C miksys_soft/demo3d
	$(MAKE) -C miksys_soft/demoIO
	$(MAKE) -C verilog

miksys.svf: build
	quartus_cpf -c -q 25MHz -g 3.3 -n v verilog/output_files/miksys.sof miksys.svf

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
