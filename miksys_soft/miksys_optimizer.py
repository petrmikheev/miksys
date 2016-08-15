#!/usr/bin/python

from miksys_asm import opcodes
import sys, re

link_calls = {}
class Command:
    def __init__(self, text):
        self.text = text
        self.is_link = text[-1]==':'
        if self.is_link:
            self.link = text[:-1]
            link_calls[self.link] = 0
            self.opcode = ''
            return
        c = text.split()[0].upper()
        cl = 0
        for k, v in opcodes.iteritems():
            if c.startswith(k):
                self.opcode = k
                cl = len(k)
        if cl == 0: raise Exception('Unknown opcode: ' + text)
        self.flagS = False
        if len(c) == cl + 3 or len(c) == cl + 1:
            if c[-1] != 'S': raise Exception('Unknown opcode: ' + l)
            self.flagS = True
        elif len(c) != cl and len(c) != cl+2:
            raise Exception('Unknown opcode: ' + l)
        if self.opcode in ['CMP', 'TST']: self.flagS = True
        if len(c) >= cl+2:
            self.cond = c[cl:cl+2]
        else:
            self.cond = ''
        self.params = [p.strip() for p in text[len(c):].split(',') if p.strip() != '']
        self.wr_reg = ''
        if (self.opcode in ['IN', 'OUT']): self.wr_reg = self.params[1]
        if self.opcode in ['MOV', 'CMOV', 'OR', 'XOR', 'AND', 'RGBADD', 'RGBSHR', 'ADD', 'RSB', 'SUB', 'ADC', 'RSC', 'SBC']:
            self.wr_reg = self.params[0]
        if '[' in self.wr_reg: self.wr_reg = ''
    def __str__(self):
        if self.is_link: return self.text
        c = self.opcode + self.cond
        if self.flagS and (self.opcode not in ['CMP', 'TST']): c += 'S'
        return (c + ' ' + ', '.join(self.params)).strip()

if len(sys.argv) != 3:
    print('Using: miksys_optimizer in.ss out.s')

cond_sign_invert = {
    ''      : '',
    'AL'    : '',
    'EQ'    : 'EQ',
    'NE'    : 'NE',
    'CS'    : 'LS',
    'CC'    : 'HI',
    'MI'    : False,
    'PL'    : False,
    'VS'    : False,
    'VC'    : False,
    'HI'    : 'CC',
    'LS'    : 'CS',
    'GE'    : 'LE',
    'LT'    : 'GT',
    'GT'    : 'LT',
    'LE'    : 'GE'
}

cond_invert = {
    'EQ'    : 'NE',
    'NE'    : 'EQ',
    'CS'    : 'CC',
    'CC'    : 'CS',
    'MI'    : 'PS',
    'PL'    : 'MI',
    'VS'    : 'VC',
    'VC'    : 'VS',
    'HI'    : 'LS',
    'LS'    : 'HI',
    'GE'    : 'LT',
    'LT'    : 'GE',
    'GT'    : 'LE',
    'LE'    : 'GT'
}

def cnst_short(s):
    try: x=int(s)
    except Exception: return False
    if x<0: x+=0x10000
    return x<=0x1ff or ~x<=0x1ff or (x&0x7f)==0 or (x&0x7f)==0x7f

fout = open(sys.argv[2], 'w')
def handle(code):
    for j in range(3):
        aregs = ['','']
        for i in range(len(code)-1, 0, -1):
            if code[i].is_link: continue
            drop = False
            if i<len(code)-1 and (code[i+1].opcode in ['ADC', 'SBC', 'RSC']): drop = True
            if code[i-1].is_link or (code[i-1].opcode in ['DJ', 'DCALL', 'DRET']): drop = True
            if len(code[i].params)>0:
                if re.search(r'\b(__ADDR__)?%s\b' % code[i].params[0], code[i-1].text): drop = True
                if code[i].params[0] not in aregs: drop = True
            if len(code[i].params)>1 and not code[i-1].is_link and len(code[i-1].params)>0:
                if code[i].opcode != 'CMOV' and (code[i].params[1] == code[i-1].params[0]): drop = True
            if len(code[i].params)==3 and re.search(r'\br\d+\b|\[', code[i].params[2]) is not None: drop = True
            if not drop and (code[i].opcode in ['CMOV','ADD','SUB']):
                code[i-1], code[i] = code[i], code[i-1]
            a = re.search(r'__ADDR__(r\d+)\b', code[i].text)
            if a is not None:
                aregs = [a.group(1), aregs[0]]
    global link_calls
    last_cond = ''
    next_link = ''
    link_dist = 0
    for i in range(len(code)-1, -1, -1):
        l = code[i]
        if l.is_link:
            next_link = l.link
            link_dist = 0
            continue
        if last_cond == '':
            if l.opcode not in ['CMP', 'TST']: l.flagS = False
        elif l.flagS == True: last_cond = ''
        if l.opcode=='MOV' and not l.flagS and l.params[0] == l.params[1]:
            del code[i]
            continue
        l.next_link = next_link
        l.link_dist = link_dist
        if l.flagS or l.cond != '': next_link = ''
        if l.opcode != 'DJ':
            l.next_link = next_link
            l.link_dist = link_dist
        link_dist += 1
        if l.cond != '': last_cond = l.cond
        if l.opcode in ['J', 'DJ', 'CALL', 'DCALL'] and l.params[0] in link_calls:
            link_calls[l.params[0]] += 1
    last_reg, last_reg2 = '', ''
    cache = [('','')]*3
    i = 0
    while i < len(code):
        l = code[i]
        if l.is_link:
            for j in range(3): cache[j] = (cache[j][0], '')
            i += 1
            continue
        if l.opcode == 'DJ' and l.params[0] == l.next_link and l.link_dist<8:
            link_calls[l.next_link] -= 1
            if l.cond == '': raise Exception('Inaccessible code')
            ncond = cond_invert[l.cond]
            for j in range(l.link_dist): code[i+j+1].cond = ncond
            if link_calls[l.next_link] == 0:
                if i+l.link_dist+2 < len(code) and code[i+l.link_dist+2].opcode != 'DJ' and not code[i+l.link_dist+2].is_link:
                    code[i+l.link_dist].next_link = code[i+l.link_dist+2].next_link
                    code[i+l.link_dist].link_dist = code[i+l.link_dist+2].link_dist+1
                del code[i+l.link_dist+1]
            del code[i]
            continue
        if l.opcode == 'DJ':
            last_reg, last_reg2 = '', ''
            cache = [('','')]*3
#        if '__ARG__' in l.text:
#            l.params[0] = l.params[0].replace('__ARG__', '')
#            cnst, reg = re.match(r'MOV.*\[.*\+(.*)\],\s*(\w*)$', code[i+1].text).groups() 
#            if reg == l.params[0] and int(cnst)<8:
#                code[i] = Command('CCMOV %s, %s' % (code[i+1].params[0], l.params[1]))
#                del code[i+1]
#                continue
        if '__ADDR__' in l.text:
            r = re.search(r'__ADDR__(r\d+)', l.text).groups()[0]
            while r == last_reg or r == last_reg2:
                code.insert(i, Command('NOP'))
                cache = cache[1:]+[('', '')]
                last_reg2, last_reg = last_reg, ''
                i += 1
            for j in range(len(l.params)): l.params[j] = l.params[j].replace('__ADDR__', '')
        if '__SWAP__' in l.text:
            r = l.params[-1].split('_')[-1]
            if r == last_reg and l.opcode != 'MOV':
                if l.params[1] == last_reg:
                    l.params[-1] = l.params[-1].replace('__SWAP__', '__NSWAP__')
                else:
                    l.params[-1] = l.params[-1].replace('__SWAP__', '')
                    l.params[1], l.params[2] = l.params[2], l.params[1]
                    if l.opcode == 'SUB': l.opcode = 'RSB'
                    elif l.opcode == 'SBC': l.opcode = 'RSC'
                    elif l.opcode == 'CMP' and i < len(code)-1:
                        if cond_sign_invert[code[i+1].cond]==False: raise Exception('Strange condition for __SWAP__')
                        code[i+1].cond = cond_sign_invert[code[i+1].cond]
            else: l.params[-1] = l.params[-1].replace('__SWAP__', '')
        if '__NSWAP__' in l.text:
            r = l.params[-1].split('_')[-1]
            if r == last_reg and l.opcode != 'MOV':
                code.insert(i, Command('NOP'))
                cache = cache[1:]+[('', '')]
                last_reg = ''
                i += 1
            l.params[-1] = l.params[-1].replace('__NSWAP__', '')
        lp = len(l.params)-1
        for j in range(3):
            if cache[j][0]!='' and lp>=0 and cache[j][0] == l.params[lp]:
                if cache[j][1]!='': l.params[lp] = cache[j][1]
                else:
                    for nc in range(j+1):
                        code.insert(i, Command('NOP'))
                        cache = cache[1:]+[('', '')]
                        last_reg2, last_reg = last_reg, ''
                        i += 1
                break
        for j in range(1, 3):
            if l.wr_reg!='' and (l.wr_reg in cache[j][0]): cache[j]=(cache[j][0], '')
        last_reg2, last_reg = last_reg, l.wr_reg
        cache = cache[1:]+[('', '')]
        if '__CACHE__' in l.text:
            l.params[0] = l.params[0].replace('__CACHE__', '').strip()
            if l.opcode=='MOV' or (l.opcode=='CCMOV' and cnst_short(l.params[1])):
                cache[2] = (l.params[0], l.params[1])
            else:
                cache[2] = (l.params[0], '')
            if cache[0][0]==l.params[0]: cache[0]=('', '')
            if cache[1][0]==l.params[0]: cache[1]=('', '')
        i += 1
    for c in code:
        s = str(c)
        if s != '__:': fout.write(s+'\n')
    link_calls = {}

code = []
in_code = False

for l in open(sys.argv[1]).readlines():
    l = l.strip()
    if l == '' or l[:1] == '#': continue
    if not in_code:
        fout.write(l+'\n')
        if l == '.code': in_code = True
    else:
        if l[0] == '.':
            handle(code)
            fout.write(l+'\n')
            code = []
        else:
            l = re.sub(r"'(\\?.)'", lambda x: eval('str(ord("%s"))' % x.group(1)), l)
            l = re.sub(r'LO\(([^\)]*)\br(\d+)\s*\)', lambda x: '%sr%d' % (x.group(1), int(x.group(2))), l)
            l = re.sub(r'HI\(([^\)]*)\br(\d+)\s*\)', lambda x: '%sr%d' % (x.group(1), int(x.group(2))+1), l)
            l = re.sub(r'\[[^\]]*\]', lambda x: x.group(0).replace(' ', ''), l)
            l = re.sub(r'LO\(\s*(\[[^\]]*\])\s*\)', lambda x: x.group(1), l)
            l = re.sub(r'HI\(\s*\[((__ADDR__)?r\d+\+)(\d+)\]\s*\)', lambda x: '[%s%d]' % (x.group(1), int(x.group(3))+1), l)
            if ':' in l:
                code.append(Command(l[:l.find(':')+1]))
                c = l[l.find(':')+1:].strip()
                if len(c)>0: code.append(Command(c))
            else:
                code.append(Command(l))
if len(code) > 0: handle(code)
fout.close()

