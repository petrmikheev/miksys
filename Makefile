VERILOG_OUTPUT = verilog/output_files
QTSIM = qt_sim/qt_sim

.PHONY: all soft write write_epcs4 demo3d demoIO
all: \
	$(QTSIM) \
	verilog/miksys.svf verilog/miksys_epcs4.svf \
	lcc demo3d demoIO

verilog/startup/startup.hex miksys_soft/ustartup/startup.bin: miksys_soft/ustartup/*.S miksys_soft/include/*.H
	$(MAKE) -C miksys_soft/ustartup

verilog/charmap/charmap.hex:
	$(MAKE) -C verilog/charmap

SDRAM_MODEL_FILES = verilog/sdram_model/sdr_module.v \
	verilog/sdram_model/sdr_parameters.vh \
	verilog/sdram_model/sdr.v

$(SDRAM_MODEL_FILES):
	$(MAKE) -C verilog/sdram_model

$(VERILOG_OUTPUT)/miksys.sof: verilog/startup/startup.hex verilog/charmap/charmap.hex $(SDRAM_MODEL_FILES) verilog/*.sv verilog/*.v
	cd verilog && quartus_sh --flow compile miksys.qpf

verilog/miksys.svf: $(VERILOG_OUTPUT)/miksys.sof
	quartus_cpf -c -q 10MHz -g 3.3 -n v $< $@

$(VERILOG_OUTPUT)/miksys.jic: $(VERILOG_OUTPUT)/miksys.sof
	quartus_cpf -c -d EPCS4 -s EP3C10 $< $@

verilog/miksys_epcs4.svf: $(VERILOG_OUTPUT)/miksys.jic
	quartus_cpf -c -q 10MHz -g 3.3 -n pb $< $@

write: verilog/miksys.svf
	sudo rmmod ftdi_sio
	sudo ./mbftdi verilog/miksys.svf
	sudo modprobe ftdi_sio

write_epcs4: verilog/miksys_epcs4.svf verilog/epcs4_tunnel.svf
	sudo rmmod ftdi_sio
	sudo ./mbftdi verilog/epcs4_tunnel.svf
	sudo ./mbftdi verilog/miksys_epcs4.svf
	sudo modprobe ftdi_sio

$(QTSIM):
	cd qt_sim && qmake
	$(MAKE) -C qt_sim

demo3d: miksys_soft/ustartup/startup.bin
	$(MAKE) -C miksys_soft/demo3d

demoIO: miksys_soft/ustartup/startup.bin
	$(MAKE) -C miksys_soft/demoIO

sim_demo3d: $(QTSIM) miksys_soft/ustartup/startup.bin miksys_soft/demo3d/demo3d.packed demo3d
	./qt_sim/qt_sim miksys_soft/demo3d/demo3d.packed

sim_demoIO: $(QTSIM) miksys_soft/ustartup/startup.bin miksys_soft/demoIO/demo.packed demoIO
	./qt_sim/qt_sim miksys_soft/demoIO/demo.packed

.PHONY: lcc
lcc:
	mkdir -p miksys_soft/lcc/build
	$(MAKE) -C miksys_soft/lcc rcc cpp

.PHONY: clean
clean:
	rm -rf verilog/db verilog/incremental_db verilog/simulation $(VERILOG_OUTPUT)
	$(MAKE) -C verilog/sdram_model clean
	$(MAKE) -C miksys_soft/ustartup clean
	$(MAKE) -C miksys_soft/demo3d clean
	$(MAKE) -C miksys_soft/demoIO clean
	$(MAKE) -C miksys_soft/lcc clean
