#!/bin/bash
stty -F /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0 9600 -icrnl -ixon -ixoff -opost -isig -icanon -echo cstopb -crtscts -parenb
setserial /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0 spd_cust
setserial /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0 divisor 10
stty -F /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0 38400 2> /dev/null
