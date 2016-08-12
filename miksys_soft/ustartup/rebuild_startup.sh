#!/bin/bash
../miksys_asm.py -v startup.S startup.bin > tmp
for func in divide_func set_number_base_func printf_func usb_request_func ; do
	addr=`grep "$func = " tmp | cut -d ' ' -f 3`
	echo $func : $addr
	sed -i "s/#define $func .*$/#define $func $addr/g" ../include/std.H
done
rm tmp
