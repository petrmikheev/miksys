#!/bin/bash
sudo rmmod ftdi_sio
sudo ./mbftdi verilog/miksys.svf
sudo modprobe ftdi_sio
