#!/usr/bin/python
#coding: utf8

import sys, subprocess, struct, re

opcodes = {
    'NOP'   : 0x0,
    'J'     : 0x1,
    'CALL'  : 0x1,
    'RET'   : 0x1,
    'CMOV'  : 0x2,
    'CCMOV' : 0x3,

    'DJ'    : 0x5,
    'DCALL' : 0x5,
    'DRET'  : 0x5,

    'SHL'   : 0xc,
    'SHR'   : 0xd,
    'MUL'   : 0xe,
    'WMUL'  : 0xe,
    'SMUL'  : 0xe,
    'READ'  : 0xf,
    'WRITE' : 0xf,
    'OR'    : 0x10,
    'XOR'   : 0x11,
    'AND'   : 0x12,
    'TST'   : 0x13,
    'MOV'   : 0x14,
    'IN'    : 0x14,
    'OUT'   : 0x14,
    
    'RGBADD': 0x16,
    'RGBSHR': 0x17,
    'ADD'   : 0x18,
    'RSB'   : 0x19,
    'SUB'   : 0x1a,
    'CMP'   : 0x1b,
    'ADC'   : 0x1c,
    'RSC'   : 0x1d,
    'SBC'   : 0x1e
}
conditions = {
    'AL'    : 0x0,
    'EQ'    : 0x1,
    'NE'    : 0x2,
    'CS'    : 0x3,
    'CC'    : 0x4,
    'MI'    : 0x5,
    'PL'    : 0x6,
    'VS'    : 0x7,
    'VC'    : 0x8,
    'HI'    : 0x9,
    'LS'    : 0xa,
    'GE'    : 0xb,
    'LT'    : 0xc,
    'GT'    : 0xd,
    'LE'    : 0xe
}
special_registers = {
    'IN_FLAGS'        : 'r0',
    'IN_CLOCK'        : 'r3',
    'IN_TIME_MS4'     : 'r4',
    'MUL_RESULT_LO'   : 'r5',
    'MUL_RESULT_HI'   : 'r6',
    'SHIFT_RESULT'    : 'r5',
    #'FLOAT_RESULT'    : 'r7',
    'OUT_LEDS'        : 'r0',
    'MEM_ADDR_LO'     : 'r1',
    'MEM_ADDR_HI'     : 'r2'
}
consts = {
    'DEV_SERIAL' : 0,
    'DEV_SDRAM' : 1,
    'DEV_VGA' : 2,
    'DEV_SOUND' : 3,
    'DEV_PS2_0' : 4,
    'DEV_PS2_1' : 5,
    'DEV_USB' : 6,
    'N_FLAG' : 16,
    'Z_FLAG' : 32,
    'V_FLAG' : 64,
    'C_FLAG' : 128,
    'SOFTKEY_FLAG' : 4,
    'MEM_FLAG' : 8
}

macroses = {}
commands = []

def LO(v):
    if isinstance(v, int):
        p = struct.pack('i', v)
    elif isinstance(v, float):
        p = struct.pack('f', v)
    else: raise Exception('int or float expected')
    return struct.unpack('H', p[0:2])[0]

def HI(v):
    if isinstance(v, int):
        p = struct.pack('i', v)
    elif isinstance(v, float):
        p = struct.pack('f', v)
    else: raise Exception('int or float expected')
    return struct.unpack('H', p[2:4])[0]

def RGB(s):
    r,g,b = [int(x) for x in s.split()]
    return (r<<11) + (g<<6) + b

def parseConst(s):
    s = s.strip()
    #s = re.sub(r"'\\?.'", str(consts[w]), s)
    #if len(s) == 3 and s[0] == "'" and s[2] == "'":
    #    return ord(s[1])
    k = consts.keys()
    k.sort(key=len, reverse=True)
    for w in k:
        s = re.sub(r'\b%s\b' % w, str(consts[w]), s)
        #s = s.replace(w, str(consts[w]))
    for i in s.replace('LO', '').replace('HI', '').replace('RGB', ''):
        if i not in ' .abcdefABCDEF0123456789()+-*/&|^~<>x%"':
            raise Exception('const expression expected: "%s"' % i)
    try:
        return eval(s, {'LO' : LO, 'HI' : HI, 'RGB' : RGB})
    except Exception as e:
        raise Exception('const expression expected: ' + str(e) + '\n' + s)

def parseReg(s):
    if len(s) == 0 or s[0] not in ['r', 'R']: raise Exception('register expected: ' + s)
    return int(s[1:])

class Param:
    def __init__(self, s):
        self.type = ''
        self.value = 0
        self.special = False
        self.all = False
        s = s.strip()
        if s == '': return
        try:
            self.value = parseConst(s)
            self.type = 'const'
            return
        except Exception: pass
        if s[0] == '[':
            if s[-1] != ']': raise Exception('Incorrect param: ' + s)
            self.type = 'mem'
            s = s[1:-1].strip()
            if s.startswith('ALL '):
                s = s[4:].strip()
                self.all = True
            pl = s.find('+')
            if pl == -1:
                self.reg = parseReg(s.strip())
                self.value = 0
            else:
                self.reg = parseReg(s[:pl].strip())
                self.value = parseConst(s[pl+1:])
                if self.value < 0 or self.value >= 128: raise Exception('Incorrect offset: ' + s)
            return
        self.type = 'register'
        self.inv = False
        if s.upper().startswith('NOT '):
            self.inv = True
            s = s[4:].strip()
        if s in special_registers.keys():
            self.special = True
            s = special_registers[s]
        self.reg = parseReg(s)
                
    def __repr__(self):
        if self.type == 'mem':
            return '[r%d + %d]' % (self.reg, self.value)
        if self.type == 'const':
            return 'const %d' % self.value
        if self.type == 'register':
            v = str(self.reg)
            if self.special: v = 'SPECIAL ' + v
            if self.inv: v = 'NOT ' + v
            return v
        return 'UNKNOWN'

class Macro:
    def __init__(self, l):
        l = l.replace(',', ' ').split()
        self.title = l[1]
        self.params = l[2:]
        self.params.append('$(m)')
        self.body = ''
        macroses[self.title] = self
    def use(self, l):
        global addr
        l = l.strip()
        if len(self.body) == 0: return
        params = [v.strip() for v in l[len(self.title):].split(',') if v.strip() != '']
        params.append('m_%d_' % addr)
        if len(params) != len(self.params):
            print l, ':', params
            print self.params
            raise Exception('Incorrect parameters number')
        s = self.body
        i = 0
        for p in self.params:
            s = s.replace(p, params[i])
            i += 1
        for q in s.split('\n'):
            if q != '': stage1_handle_line(q)

def addLink(l):
    consts[l] = addr
    print '%s = 0x%06X' % (l, addr)

addr = 0
def stage1_handle_line(l):
    global addr
    if not l.startswith('.ascii '):
        l = l.replace("'\"'", str(ord('"')))
        l = re.sub(r"'(\\?.)'", lambda x: eval('str(ord("%s"))' % x.group(1)), l)
    w = l.split()
    if w[0][-1] == ':':
        addLink(w[0][:-1])
        l = l[len(w[0]):].strip()
        w = w[1:]
    if len(w) == 0: return
    for k, v in macroses.iteritems():
        if w[0] == k:
            v.use(l)
            return
    if not virtual:
        commands.append(l)
    if w[0] == '.words':
        addr += parseConst(l[7:])
    elif w[0] == '.ascii':
        s = l[7:].strip()[1:-1].replace('\\n', '\n')
        addr += (len(s)+3) // 2
    elif w[0] == '.const':
        for c in l[7:].split(','):
            if '.' in str(parseConst(c)):
                addr += 2
            else:
                addr += 1
    else:
        addr += 2

virtual = False
in_macro = False
if len(sys.argv) != 3:
    print 'Using: ./compile input.S output.bin'
    sys.exit(0)
fout = file(sys.argv[-1], 'wb')
#consts_str = ' '.join(['-D%s=%d' % (k, v) for k, v in consts.iteritems()])
m = None
for l in subprocess.check_output('gcc -w -E %s -undef -nostdinc' % sys.argv[1], shell = True).split('\n'):
    l = l.strip()
    if len(l) == 0 or l[0] == '#': continue
    if in_macro:
        if l == '.endmacro':
            in_macro = False
        else:
            m.body += l+'\n'
        continue
    if l.startswith('.macro '):
        in_macro = True
        m = Macro(l)
        continue
    if l.startswith('.virtual '): # .data .virtual_data .virtual_code
        addr = parseConst(l.split()[1])
        virtual = True
        continue
    if l.startswith('.code ') or l.startswith('.data '):
        addr = parseConst(l.split()[1])
        virtual = False
        commands.append(l)
        continue
    stage1_handle_line(l)

addr = 0
real_addr = 0
for l in commands:
    if l.startswith('.code ') or l.startswith('.data '):
        addr = parseConst(l.split()[1])
        new_real_addr = parseConst(l.split()[2])
        if new_real_addr < real_addr: raise Exception('Incorrect segment address: 0x%06X -> 0x%06X' % (real_addr, new_real_addr))
        if new_real_addr > real_addr:
            fout.write(b'\0\0' * (new_real_addr - real_addr))
            print '0x%06X:  ***  ZEROS %5d         %s' % (real_addr, new_real_addr - real_addr, l)
            real_addr = new_real_addr
        continue
    if l.startswith('.words '):
        wc = parseConst(l[7:])
        addr += wc
        fout.write(b'\0\0' * wc)
        print '0x%06X:  ***  ZEROS %5d       %s' % (real_addr, wc, l)
        real_addr += wc
        continue
    if l.startswith('.ascii '):
        s = l[7:].strip()[1:-1].replace('\\n', '\n')
        fout.write(s)
        fout.write(b'\0' * (2 + len(s) % 2))
        wc = (len(s) + 3) // 2
        print '0x%06X:  ***  ASCII %5d         %s' % (real_addr, wc, l)
        addr += wc
        real_addr += wc
        continue
    if l.startswith('.const '):
        for c in l[7:].split(','):
            c = str(parseConst(c))
            if '.' in c:
                d = struct.pack('<f', float(c))
                fout.write(d)
                res = struct.unpack('<I', d)[0]
                print '0x%06X:       %02X %02X %02X %02X         .const %s' % (real_addr, (res>>24)&255, (res>>16)&255, (res>>8)&255, res&255, c)
                addr += 2
                real_addr += 2
            else:
                res = parseConst(c)
                if res<0: res += 65536
                fout.write(struct.pack('<H', res))
                print '0x%06X:       %02X %02X               .const %s' % (real_addr, (res>>8)&255, res&255, c)
                addr += 1
                real_addr += 1
        continue
    c = l.split()[0].upper()
    cl = 0
    for k, v in opcodes.iteritems():
        if c.startswith(k):
            opcode = v
            cl = len(k)
    if cl == 0: raise Exception('Unknown opcode: ' + l)
    flagS = False
    if len(c) == cl + 3 or len(c) == cl + 1:
        if c[-1] != 'S': raise Exception('Unknown opcode: ' + l)
        flagS = True
    elif len(c) != cl and len(c) != cl+2:
        raise Exception('Unknown opcode: ' + l)
    if len(c) >= cl+2:
        cond = conditions[c[cl:cl+2]]
    else:
        cond = conditions['AL']
    params = [Param(p.strip()) for p in l[len(c):].split(',') if p.strip() != '']
    c = c[:cl]
    if flagS and opcode in [opcodes[x] for x in ['NOP', 'J', 'DJ', 'CMOV', 'CCMOV', 'READ', 'CMP', 'TST', 'MUL', 'SHL', 'SHR']]:
        raise Exception('incorrect opcode: ' + l)
    res = cond << 28
    if c == 'SMUL': res |= 1 << 16
    if c == 'WMUL': res |= 1 << 17
    if flagS or opcode in [opcodes['CMP'], opcodes['TST']]:
        res |= 1 << 22
    if c == 'NOP':
        pass
    elif opcode == opcodes['J'] or opcode == opcodes['DJ']:
        if c == 'RET' or c == 'DRET':
            if len(params) > 0: raise Exception('unexpected parameter')
        else:
            if c == 'CALL' or c == 'DCALL':
                res |= 6 << 20
            else:
                res |= 2 << 20
            if len(params) != 1: raise Exception('address expected')
            a = params[0]
            if a.type != 'const': raise Exception('incorrect address')
            if opcode == opcodes['J']:
                res |= (a.value//2 - addr//2 + 0x200000 - 4) & 0x1fffff
            else:
                res |= (a.value//2 - addr//2 + 0x200000 - 1) & 0x1fffff
    elif opcode == opcodes['CMOV']:
        if len(params) != 2: raise Exception('2 args expected: ' + l)
        if params[1].type != 'const': raise Exception('const expected: ' + l)
        if params[0].type != 'register' or params[0].inv: raise Exception('register expected: ' + l)
        res |= params[0].reg << 16
        res |= params[1].value & 0xffff
        if params[0].special:
            res |= 1 << 20
    elif opcode == opcodes['CCMOV']:
        if len(params) != 2: raise Exception('2 args expected: ' + l)
        if params[1].type != 'const': raise Exception('const expected: ' + l)
        if params[0].type != 'mem': raise Exception('cache expr expected: ' + l)
        if params[0].value < 0 or params[0].value > 7: raise Exception('incorrect offset for CCMOV: ' + l)
        res |= params[0].reg << 8
        res |= params[0].value << 20
        res |= params[1].value & 0xff
        res |= (params[1].value & 0xff00) << 4
    else:
        if opcode == opcodes['MOV'] or opcode == opcodes['RGBSHR']:
            if len(params) != 2: raise Exception('2 args expected: ' + l)
            if c == 'IN' or c == 'OUT':
                if params[0].type != 'const': raise Exception('const expected: ' + l)
                params[0] = Param('r%d' % params[0].value)
                if cond != 0: raise Exception('Unexpected condition: ' + l)
            p1 = params[0]
            p3 = params[1]
            if c == 'IN':
                if params[1].type == 'const':
                    raise Exception('Unexpected const: ' + l)
                p3 = params[0]
                p1 = params[1]
                p2 = Param('r2')
            elif c == 'OUT':
                p2 = Param('r3')
            elif p1.special or (p3.special and p1.type != 'register'):
                p2 = Param('r1')
            else:
                p2 = Param('r0')
        elif len(params) == 2:
            if opcode not in [opcodes[x] for x in ['CMP', 'TST', 'MUL', 'SHL', 'SHR', 'READ']]:
                raise Exception('incorrect args count: ' + l)
            p1 = None
            p2 = params[0]
            p3 = params[1]
        elif len(params) == 3:
            if opcode in [opcodes[x] for x in ['CMP', 'TST', 'MUL', 'SHL', 'SHR', 'READ']]:
                raise Exception('incorrect args count: ' + l)
            p1 = params[0]
            p2 = params[1]
            p3 = params[2]
        else: raise Exception('incorrect args count: ' + l)
        if p2.type != 'register': raise Exception('arg2 should be register: ' + l)
        res |= p2.reg << 12
        if (p1 is not None) and p1.type == 'mem':
            p1, p3 = p3, p1
            tx = 0
        elif p3.type == 'mem': tx = 1
        elif p3.type == 'const': tx = 2
        else: tx = 3
        res |= tx << 20
        if opcode == opcodes['READ']:
            if c == 'WRITE': res |= 1 << 22
        if p1 is not None:
            if p1.type != 'register': raise Exception('register expected: ' + l)
            res |= p1.reg << 16
        if p2.special:
            if tx != 2: raise Exception('arg2 should be register: ' + l)
            res |= 1<<9
        if tx < 2:
            res |= p3.reg << 8
            res |= p3.value
            if p3.all: res |= 128
        elif tx == 2:
            v = p3.value % 0x10000
            if v >> 9 == 0:
                res |= v
            elif v >> 9 == 0x7f:
                res |= v&0x1ff
                res |= 1 << 11
            elif v & 0x7f == 0:
                res |= (v >> 7) & 0x1ff
                res |= 1 << 10
            elif v & 0x7f == 0x7f:
                res |= (v >> 7) & 0x3ff
                res |= 3 << 10
            else: raise Exception('incorrect const: ' + l)
        elif p3.type == 'register':
            res |= p3.reg << 8
            if p3.special: res |= 1 << 4
            if p3.inv: res |= 1 << 7
        else: raise Exception('Unknown p3 type: ' + l)
    res |= opcode << 23
    fout.write(struct.pack('<I', res))
    print '0x%06X:       %02X %02X %02X %02X         %s' % (real_addr, (res>>24)&255, (res>>16)&255, (res>>8)&255, res&255, l)
    addr += 2
    real_addr += 2
fout.close()

