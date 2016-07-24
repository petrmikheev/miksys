#!/bin/bash
sudo rmmod ftdi_sio
sudo ./mbftdi miksys.svf
sudo modprobe ftdi_sio
