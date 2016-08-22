#!/usr/bin/python

import sys, os
base_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
output_file = 'a.out'

def print_help():
    print('miksys_cc - C compiler for miksys (based on lcc)')
    print('Using: miksys_cc [-o outfile] [-E|-T|-s] [-nostd] [-Dmacro=value] [-Iinclude_dir] [-pserial] [-pusb] file ...')
    print('    -E        Stop after preprocessing')
    print('    -T        Stop after compilation, before asm optimization')
    print('    -s        Stop after asm optimization')
    print('    -pserial  Generate outfile.packed to boot from serial port')
    print('    -pusb     Generate outfile.usb_packed to boot from usb flash')

targets = []

if len(sys.argv)<2:
    print_help()
    exit(0)
outname = False
E_opt = False
s_opt = False
T_opt = False
pserial = False
pusb = False
addstd = True
cpp_opts = ''
for opt in sys.argv[1:]:
    if outname:
        outname = False
        output_file = opt
        continue
    if opt == '-o':
        outname = True
        continue
    if opt == '-s':
        s_opt = True
        continue
    if opt == '-T':
        T_opt = True
        continue
    if opt == '-E':
        E_opt = True
        continue
    if opt == '-nostd':
        addstd = False
        continue
    if opt == '-pserial':
        pserial = True
        continue
    if opt == '-pusb':
        pusb = True
        continue
    if opt[:2] in ['-D', '-I']:
        cpp_opts += opt + ' '
        continue
    if opt == '-h' or opt == '-v':
        print_help()
        exit(0)
    targets.append(opt)
if outname:
    print('Output filename expected')
    exit(1)

link_list = []
elink_list = []
tmp_list = []
for t in targets:
    if t[-2:] in ['.c']:
        command = '%s/lcc/build/cpp %s -I%s/include/c %s.c %s.i' % (base_dir, cpp_opts, base_dir, t[:-2], t[:-2])
        print(command)
        if os.system(command) != 0: exit(1)
    if E_opt: continue
    if t[-2:] in ['.c', '.i']:
        for l in open(t[:-2]+'.i'):
            if l.startswith('#pragma link'):
                elink_list.append(base_dir + '/include/' + l[13:].strip())
        command = '%s/lcc/build/rcc %s -target=miksys %s.i %s.T' % (base_dir, cpp_opts, t[:-2], t[:-2])
        print(command)
        if os.system(command) != 0: exit(1)
        if t[-2:] in ['.c']: os.system('rm %s.i' % t[:-2])
    if T_opt: continue
    if t[-2:] in ['.c', '.i', '.T']:
        command = '%s/lcc/build/cpp -I%s/include %s.T %s.ss' % (base_dir, base_dir, t[:-2], t[:-2])
        print(command)
        if os.system(command) != 0: exit(1)
        command = '%s/miksys_optimizer.py %s %s.ss %s.s' % (base_dir, cpp_opts, t[:-2], t[:-2])
        print(command)
        if os.system(command) != 0: exit(1)
        os.system('rm %s.ss' % t[:-2])
        if t[-2:] in ['.c', '.i']: os.system('rm %s.T' % t[:-2])
        tmp_list.append('%s.s' % t[:-2])
    if s_opt: continue
    if t[-2:] in ['.S']:
        link_list.append('%s.S' % t[:-2])
    else:
        link_list.append('%s.s' % t[:-2])
if len(link_list) > 0:
    if addstd: link_list = ['%s/include/std.S' % base_dir] + link_list + elink_list + ['%s/include/std_end.S' % base_dir]
    command = '%s/miksys_asm.py %s %s' % (base_dir, ' '.join(link_list), output_file)
    print(command)
    if os.system(command) != 0: exit(1)
    if len(tmp_list)>0: os.system('rm %s' % ' '.join(tmp_list))
    if pserial:
        command = '%s/pack.py %s %s.packed' % (base_dir, output_file, output_file)
        print(command)
        if os.system(command) != 0: exit(1)
    if pusb:
        command = '%s/pack_usb.py %s %s.usb_packed' % (base_dir, output_file, output_file)
        print(command)
        if os.system(command) != 0: exit(1)

