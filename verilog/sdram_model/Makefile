all: sdr_parameters.vh sdr_module.v sdr.v

sdr_sdram.zip:
	wget https://www.micron.com/~/media/documents/products/sim-model/dram/sdram/sdr_sdram.zip

sdr_parameters.vh sdr_module.v sdr.v: sdr_sdram.zip
	unzip -o sdr_sdram.zip

.PHONY: clean
clean:
	rm -f readme.txt sdr_module.v sdr_parameters.vh sdr.v test.v sdr_sdram.zip
