#!/bin/bash
../compile.py demo.S demo.bin
cat picture.img >> demo.bin
../pack.py demo.bin serial_in
