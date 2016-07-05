#!/bin/bash

cat /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0 | hexdump -v -e '1/1 "0x%02X" "\n"'
