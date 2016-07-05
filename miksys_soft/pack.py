#!/usr/bin/python
#coding: utf8

import sys, struct

if len(sys.argv) != 3:
    print 'Using: ./pack.py input.bin output.bin'
    sys.exit(0)
fin = file(sys.argv[1], 'rb')

data = fin.read()
print 'Size: %d bytes' % len(data)
if len(data) % 2 == 1:
    print 'Error: odd size'
    sys.exit(0)
fout = file(sys.argv[-1], 'wb')
fout.write(struct.pack('<I', len(data)/2))
fout.write(data)
checksum = sum([struct.unpack('<H', data[i:i+2])[0] for i in range(0, len(data), 2)]) % 0x10000
print 'Checksum: 0x%04x' % checksum
fout.write(struct.pack('<H', checksum))
fout.close()

