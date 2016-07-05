#!/usr/bin/python
#coding: utf-8

import struct, sys

bytes = file(sys.argv[1], 'rb').read()

count = len(bytes) / 4
bytes_per_word = 4
for c in range(count):
    v = struct.unpack('<I', bytes[c*4:c*4+4])[0]
    data = ('%02X%04X00%0'+str(bytes_per_word*2)+'X') % (bytes_per_word, c, v)
    data += '%02X' % ((256 - sum([int(data[i:i+2],16) for i in range(0,len(data),2)])) % 256)
    print ':'+data
print ':00000001FF'

