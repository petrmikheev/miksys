#!/usr/bin/python
#coding: utf8

import sys, struct

data_size = 2*1024*1024

if len(sys.argv) != 3:
    print 'Using: ./pack_usb.py input.bin output.bin'
    sys.exit(0)
fin = file(sys.argv[1], 'rb')

data = fin.read()
print 'Size: %d bytes' % len(data)
if len(data) > data_size-2:
    print 'Error: too big'
    sys.exit(0)
data += b'\xa5'*(data_size-2-len(data))
fout = file(sys.argv[-1], 'wb')
fout.write(data)
checksum = sum([struct.unpack('<H', data[i:i+2])[0] for i in range(0, len(data), 2)]) % 0x10000
#fout.write(b'\0'*(data_size-2-len(data)))
print 'Checksum: 0x%04x' % checksum
fout.write(struct.pack('<H', (0x1aa55-checksum)%0x10000))
fout.close()

