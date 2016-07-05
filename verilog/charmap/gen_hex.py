#coding: utf-8
charlist = {}
char = []
into = False
enc = 0
for l in file('ter-u12n.bdf', 'r').readlines():
    l = l.strip()
    if into:
        if l == 'ENDCHAR':
            charlist[enc] = char
#            print char
            char = []
            into = False
        else:
            char += [int(l, 16)]
    elif l == 'BITMAP':
        into = True
    elif l.startswith('ENCODING'):
        enc = int(l[9:])

count = 128 # 127-32
bits = 18
bytes = (bits+7) // 8
for c in range(count):
    for l in range(4):
        if c>=32 and c in charlist:
            ch = charlist[c]
            v = 0
            for by in [2,1,0]:
                w = ch[l*3+by] >> 2
                for i in range(6):
                    v = v*2 + w%2
                    w = w >> 1
            #v = (ch[l*3+2] << 10) | (ch[l*3+1] << 4) | (ch[l*3] >> 2)
        else:
            v = 0
        data = ('%02X%04X00%0'+str(bytes*2)+'X') % (bytes, c*4+l, v)
        data += '%02X' % ((256 - sum([int(data[i:i+2],16) for i in range(0,len(data),2)])) % 256)
        print ':'+data
print ':00000001FF'

