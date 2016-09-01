%{
#include "c.h"
#define NODEPTR_TYPE Node
#define OP_LABEL(p) ((p)->op)
#define LEFT_CHILD(p) ((p)->kids[0])
#define RIGHT_CHILD(p) ((p)->kids[1])
#define STATE_LABEL(p) ((p)->x.state)
extern int sametree(Node, Node);

static Symbol intreg[32], longreg[32];
static Symbol intregw, longregw;

static int cseg;
static int has_hidden_call;

static int is_cnst_short(unsigned u);
static int next_arg_offset;

extern void stabblock(int, int, Symbol*);
extern void stabend(Coordinate *, Symbol, Coordinate **, Symbol *, Symbol *);
extern void stabfend(Symbol, int);
extern void stabinit(char *, int, char *[]);
extern void stabline(Coordinate *);
extern void stabsym(Symbol);
extern void stabtype(Symbol);

#define hasargs(p) (p->syms[0] && p->syms[0]->u.c.v.i > 0 ? 0 : LBURG_MAX)
%}
%start stmt

%term ADDRGP1=1287 ADDRFP1=1303 ADDRLP1=1319
%term CNSTI1=1045 CNSTU1=1046 CNSTP1=1047 CNSTI2=2069 CNSTU2=2070
%term INDIRI1=1093 INDIRU1=1094 INDIRP1=1095 INDIRI2=2117 INDIRU2=2118
%term ASGNI1=1077 ASGNU1=1078 ASGNP1=1079 ASGNI2=2101 ASGNU2=2102
%term RETI1=1269 RETU1=1270 RETP1=1271 RETI2=2293 RETU2=2294
%term LOADI1=1253 LOADU1=1254 LOADP1=1255 LOADI2=2277 LOADU2=2278

%term ADDI1=1333 ADDU1=1334 ADDP1=1335 ADDI2=2357 ADDU2=2358
%term SUBI1=1349 SUBU1=1350 SUBP1=1351 SUBI2=2373 SUBU2=2374
%term DIVI1=1477 DIVU1=1478
%term MODI1=1381 MODU1=1382
%term BANDI1=1413 BANDU1=1414 BANDI2=2437 BANDU2=2438
%term BORI1=1445 BORU1=1446 BORI2=2469 BORU2=2470
%term BXORI1=1461 BXORU1=1462 BXORI2=2485 BXORU2=2486
%term BCOMI1=1429 BCOMU1=1430 BCOMI2=2453 BCOMU2=2454
%term NEGI1=1221 NEGI2=2045
%term LSHI1=1365 LSHU1=1366 LSHI2=2389 LSHU2=2390
%term RSHI1=1397 RSHU1=1398 RSHI2=2421 RSHU2=2422
%term MULI1=1493 MULU1=1494 MULI2=2517 MULU2=2518

%term EQI1=1509 EQU1=1510 EQI2=2533 EQU2=2534
%term NEI1=1589 NEU1=1590 NEI2=2613 NEU2=2614
%term GEI1=1525 GEU1=1526 GEI2=2549 GEU2=2550
%term GTI1=1541 GTU1=1542 GTI2=2565 GTU2=2566
%term LEI1=1557 LEU1=1558 LEI2=2581 LEU2=2582
%term LTI1=1573 LTU1=1574 LTI2=2597 LTU2=2598

%term CALLV=216 CALLI1=1237 CALLU1=1238 CALLP1=1239 CALLI2=2261 CALLU2=2262
%term ARGI1=1061 ARGU1=1062 ARGP1=1063 ARGI2=2085 ARGU2=2086

%term LABELV=600
%term JUMPV=584
%term VREGP=711
%term CVII2=2181 CVIU2=2182
%term CVUI2=2229 CVUU2=2230

%%

zero: CNSTI1 "%a" a->syms[0]->u.c.v.u==0 ? 0 : LBURG_MAX
zero: CNSTU1 "%a" a->syms[0]->u.c.v.u==0 ? 0 : LBURG_MAX
one: CNSTI1 "%a" a->syms[0]->u.c.v.u==1 ? 0 : LBURG_MAX
cnst8: CNSTI1 "%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
cnst8: CNSTU1 "%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
cnst8: CNSTP1 "%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
cnst7: CNSTI1 "%a" a->syms[0]->u.c.v.u<7 ? 0 : LBURG_MAX
cnst7: CNSTU1 "%a" a->syms[0]->u.c.v.u<7 ? 0 : LBURG_MAX
cnst7: CNSTP1 "%a" a->syms[0]->u.c.v.u<7 ? 0 : LBURG_MAX
cnst128: CNSTI1 "%a" a->syms[0]->u.c.v.u<128 ? 0 : LBURG_MAX
cnst128: CNSTU1 "%a" a->syms[0]->u.c.v.u<128 ? 0 : LBURG_MAX
cnst128: CNSTP1 "%a" a->syms[0]->u.c.v.u<128 ? 0 : LBURG_MAX
cnst_short: CNSTI1 "%a" is_cnst_short(a->syms[0]->u.c.v.u) ? 0 : LBURG_MAX
cnst_short: CNSTU1 "%a" is_cnst_short(a->syms[0]->u.c.v.u) ? 0 : LBURG_MAX
cnst_short2: CNSTI2 "%a" is_cnst_short(a->syms[0]->u.c.v.u&0xffff)&&is_cnst_short(a->syms[0]->u.c.v.u>>16) ? 0 : LBURG_MAX
cnst_short2: CNSTU2 "%a" is_cnst_short(a->syms[0]->u.c.v.u&0xffff)&&is_cnst_short(a->syms[0]->u.c.v.u>>16) ? 0 : LBURG_MAX
cnst_short: CNSTP1 "%a" is_cnst_short(a->syms[0]->u.c.v.u) ? 0 : LBURG_MAX
cnst: CNSTI1 "%a"
cnst: CNSTU1 "%a"
cnst: CNSTI2 "%a"
cnst: CNSTU2 "%a"
cnst: CNSTP1 "%a"
cnst: ADDRGP1 "%a"

stmt: LABELV "%a:\n"
stmt: JUMPV(cnst) "DJ %0\n"
stmt: ARGI1(reg) "# arg\n" 1
stmt: ARGU1(reg) "# arg\n" 1
stmt: ARGI2(reg2) "# arg\n" 1
stmt: ARGU2(reg2) "# arg\n" 1
stmt: ARGP1(reg) "# arg\n" 1
stmt: ARGI1(CNSTI1) "# arg\n"
stmt: ARGU1(CNSTU1) "# arg\n"
stmt: ARGI2(CNSTI2) "# arg\n"
stmt: ARGU2(CNSTU2) "# arg\n"
stmt: ARGP1(CNSTP1) "# arg\n"
stmt: ARGP1(ADDRGP1) "# arg\n"

stmt: CALLV(ADDRGP1) "# call %a\n"
reg: CALLI1(ADDRGP1) "# call %a\n"
reg: CALLU1(ADDRGP1) "# call %a\n"
reg2: CALLI2(ADDRGP1) "# call %a\n"
reg2: CALLU2(ADDRGP1) "# call %a\n"
reg: CALLP1(ADDRGP1) "# call %a\n"

stmt: RETI1(creg) "# RETI1 %0\n"
stmt: RETU1(creg) "# RETU1 %0\n"
stmt: RETI2(creg2) "# RETI1 %0\n"
stmt: RETU2(creg2) "# RETU1 %0\n"
stmt: RETP1(creg) "# RETP1 %0\n"
stmt: RETI1(reg) "MOV %c, %0\n" 1
stmt: RETU1(reg) "MOV %c, %0\n" 1
stmt: RETI2(reg2) "MOV %c, %0\nMOV HI(%c), HI(%0)\n" 1
stmt: RETU2(reg2) "MOV %c, %0\nMOV HI(%c), HI(%0)\n" 1
stmt: RETP1(reg) "MOV %c, %0\n" 1

stmt: ASGNI1(VREGP, creg) "# write reg\n"
stmt: ASGNU1(VREGP, creg) "# write reg\n"
stmt: ASGNI2(VREGP, creg2) "# write reg\n"
stmt: ASGNU2(VREGP, creg2) "# write reg\n"
stmt: ASGNP1(VREGP, creg) "# write_reg\n"
stmt: ASGNI1(ccmov_addr, cnst) "CCMOV __CACHE__[%0], %1\n"
stmt: ASGNU1(ccmov_addr, cnst) "CCMOV __CACHE__[%0], %1\n"
stmt: ASGNI2(ccmov_addr2, cnst) "CCMOV __CACHE__[%0], LO(%1)\nCCMOV __CACHE__HI([%0]), HI(%1)\n"
stmt: ASGNU2(ccmov_addr2, cnst) "CCMOV __CACHE__[%0], LO(%1)\nCCMOV __CACHE__HI([%0]), HI(%1)\n"
stmt: ASGNP1(ccmov_addr, cnst) "CCMOV __CACHE__[%0], %1\n"
stmt: ASGNI1(addr, reg) "MOV __CACHE__[%0], %1\n" 1
stmt: ASGNU1(addr, reg) "MOV __CACHE__[%0], %1\n" 1
stmt: ASGNI2(addr, reg2) "MOV __CACHE__[%0], %1\nMOV __CACHE__HI([%0]), HI(%1)\n" 1
stmt: ASGNU2(addr, reg2) "MOV __CACHE__[%0], %1\nMOV __CACHE__HI([%0]), HI(%1)\n" 1
stmt: ASGNP1(addr, reg) "MOV __CACHE__[%0], %1\n" 1

addr: reg "__ADDR__%0+0" 1
addr: ADDRLP1 "_rr+%a"
addr: ADDRFP1 "_rr+%a"
addr: ADDI1(reg, cnst128) "__ADDR__%0+%1"
addr: ADDU1(reg, cnst128) "__ADDR__%0+%1"
addr: ADDP1(reg, cnst128) "__ADDR__%0+%1"
ccmov_addr: ADDI1(reg, cnst8) "__ADDR__%0+%1"
ccmov_addr: ADDU1(reg, cnst8) "__ADDR__%0+%1"
ccmov_addr: ADDP1(reg, cnst8) "__ADDR__%0+%1"
ccmov_addr: ADDRLP1 "_rr+%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
ccmov_addr: ADDRFP1 "_rr+%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
ccmov_addr2: ADDI1(reg, cnst7) "__ADDR__%0+%1"
ccmov_addr2: ADDU1(reg, cnst7) "__ADDR__%0+%1"
ccmov_addr2: ADDP1(reg, cnst7) "__ADDR__%0+%1"
ccmov_addr2: ADDRLP1 "_rr+%a" a->syms[0]->u.c.v.u<7 ? 0 : LBURG_MAX
ccmov_addr2: ADDRFP1 "_rr+%a" a->syms[0]->u.c.v.u<7 ? 0 : LBURG_MAX
ccmov_addr: reg "__ADDR__%0+0"
ccmov_addr2: reg "__ADDR__%0+0"

op: cnst_short "%0"
op: INDIRI1(addr) "[%0]"
op: INDIRU1(addr) "[%0]"
op: INDIRP1(addr) "[%0]"
op: reg "__SWAP__%0" 1
op: BCOMI1(reg) "NOT __NSWAP__%0"
op: BCOMU1(reg) "NOT __NSWAP__%0"
op2: cnst_short2 "%0"
op2: INDIRI2(addr) "[%0]"
op2: INDIRU2(addr) "[%0]"
op2: reg2 "%0"
op2: BCOMI2(reg2) "NOT %0"
op2: BCOMU2(reg2) "NOT %0"

reg: creg "%0" 1
reg2: creg2 "%0" 1
reg: LOADI1(reg) "%0"
reg: LOADU1(reg) "%0"
reg: LOADP1(reg) "%0"
reg: LOADI1(reg2) "%0" 1
reg: LOADU1(reg2) "%0" 1
reg: LOADP1(reg2) "%0" 1
reg2: LOADI2(reg2) "%0"
reg2: LOADU2(reg2) "%0"
reg: CVUI2(reg) "%0"
reg: INDIRI1(VREGP) "# read reg\n"
reg: INDIRU1(VREGP) "# read reg\n"
reg2: INDIRI2(VREGP) "# read reg\n"
reg2: INDIRU2(VREGP) "# read reg\n"
reg: INDIRP1(VREGP) "# read reg\n"

creg2: CVII2(reg) "MOVS %c, %0\nMOVPL HI(%c), 0\nMOVMI HI(%c), 0xffff\n"
creg2: CVUI2(reg) "MOV %c, %0\nMOV HI(%c), 0\n"
creg2: CVIU2(reg) "MOV %c, %0\nMOV HI(%c), 0\n"
creg2: CVUU2(reg) "MOV %c, %0\nMOV HI(%c), 0\n"

reg: DIVI1(creg, creg) "XOR r4, r0, r1\nCALL divide_func\nCMP r0, 0\nRSBLT r0, r0, 0\nCMP r1, 0\nRSBLT r1, r1, 0\n__:\nCMP r4, 0\nRSBLT r1, r1, 0\n"
reg: DIVU1(creg, creg) "DCALL divide_func\n"
reg: MODI1(creg, creg) "MOV r4, r0\nCALL divide_func\nCMP r0, 0\nRSBLT r0, r0, 0\nCMP r1, 0\nRSBLT r1, r1, 0\n__:\nCMP r4, 0\nRSBLT r0, r0, 0\n"
reg: MODU1(creg, creg) "DCALL divide_func\n"

creg: ADDRLP1 "ADDS %c, _rr, %a\n"
creg: ADDRFP1 "ADDS %c, _rr, %a\n"
creg: ADDRGP1 "CMOV %c, %a\n"
creg: CNSTI1 "CMOV %c, %a\n"
creg: CNSTU1 "CMOV %c, %a\n"
creg2: CNSTI2 "CMOV %c, LO(%a)\nCMOV HI(%c), HI(%a)\n"
creg2: CNSTU2 "CMOV %c, LO(%a)\nCMOV HI(%c), HI(%a)\n"
creg: CNSTP1 "CMOV %c, %a\n"

creg: INDIRI1(addr) "MOVS %c, [%0]\n"
creg: INDIRU1(addr) "MOVS %c, [%0]\n"
creg2: INDIRI2(addr) "MOV %c, [%0]\nMOV HI(%c), HI([%0])\n"
creg2: INDIRU2(addr) "MOV %c, [%0]\nMOV HI(%c), HI([%0])\n"
creg: INDIRP1(addr) "MOVS %c, [%0]\n"

creg: LOADI1(reg) "MOVS %c, %0\n" 1
creg: LOADU1(reg) "MOVS %c, %0\n" 1
creg2: LOADI2(reg2) "MOV %c, %0\nMOV HI(%c), HI(%0)\n" 1
creg2: LOADU2(reg2) "MOV %c, %0\nMOV HI(%c), HI(%0)\n" 1
creg: LOADP1(reg) "MOVS %c, %0\n" 1

creg: ADDI1(reg, op) "ADDS %c, %0, %1\n"
creg: ADDU1(reg, op) "ADDS %c, %0, %1\n"
creg: ADDP1(reg, op) "ADDS %c, %0, %1\n"
creg: ADDI1(op, reg) "ADDS %c, %1, %0\n"
creg: ADDU1(op, reg) "ADDS %c, %1, %0\n"
creg: ADDP1(op, reg) "ADDS %c, %1, %0\n"
creg: SUBI1(reg, op) "SUBS %c, %0, %1\n"
creg: SUBU1(reg, op) "SUBS %c, %0, %1\n"
creg: SUBP1(reg, op) "SUBS %c, %0, %1\n"
creg: SUBI1(op, reg) "RSBS %c, %1, %0\n" 1
creg: SUBU1(op, reg) "RSBS %c, %1, %0\n" 1
creg: SUBP1(op, reg) "RSBS %c, %1, %0\n" 1

creg2: ADDI2(reg2, op2) "ADD %c, %0, LO(%1)\nADC HI(%c), HI(%0), HI(%1)\n"
creg2: ADDU2(reg2, op2) "ADD %c, %0, LO(%1)\nADC HI(%c), HI(%0), HI(%1)\n"
creg2: SUBI2(reg2, op2) "SUB %c, %0, LO(%1)\nSBC HI(%c), HI(%0), HI(%1)\n"
creg2: SUBU2(reg2, op2) "SUB %c, %0, LO(%1)\nSBC HI(%c), HI(%0), HI(%1)\n"
creg2: BANDI2(reg2, op2) "AND %c, %0, LO(%1)\nAND HI(%c), HI(%0), HI(%1)\n"
creg2: BANDU2(reg2, op2) "AND %c, %0, LO(%1)\nAND HI(%c), HI(%0), HI(%1)\n"
creg2: BORI2(reg2, op2) "OR %c, %0, LO(%1)\nOR HI(%c), HI(%0), HI(%1)\n"
creg2: BORU2(reg2, op2) "OR %c, %0, LO(%1)\nOR HI(%c), HI(%0), HI(%1)\n"
creg2: BXORI2(reg2, op2) "XOR %c, %0, LO(%1)\nXOR HI(%c), HI(%0), HI(%1)\n"
creg2: BXORU2(reg2, op2) "XOR %c, %0, LO(%1)\nXOR HI(%c), HI(%0), HI(%1)\n"

creg2: BCOMI2(reg2) "MOV %c, NOT %0\nMOV HI(%c), NOT HI(%0)\n"
creg2: BCOMU2(reg2) "MOV %c, NOT %0\nMOV HI(%c), NOT HI(%0)\n"
creg2: NEGI2(reg2) "RSB %c, %0, 0\nRSC HI(%c), HI(%0), 0\n"

creg: BANDI1(reg, op) "ANDS %c, %0, %1\n"
creg: BANDU1(reg, op) "ANDS %c, %0, %1\n"
creg: BANDI1(op, reg) "ANDS %c, %1, %0\n"
creg: BANDU1(op, reg) "ANDS %c, %1, %0\n"
creg: BORI1(reg, op) "ORS %c, %0, %1\n"
creg: BORU1(reg, op) "ORS %c, %0, %1\n"
creg: BORI1(op, reg) "ORS %c, %1, %0\n"
creg: BORU1(op, reg) "ORS %c, %1, %0\n"
creg: BXORI1(reg, op) "XORS %c, %0, %1\n"
creg: BXORU1(reg, op) "XORS %c, %0, %1\n"
creg: BXORI1(op, reg) "XORS %c, %1, %0\n"
creg: BXORU1(op, reg) "XORS %c, %1, %0\n"
creg: BCOMI1(reg) "MOVS %c, NOT __NSWAP__%0\n"
creg: BCOMU1(reg) "MOVS %c, NOT __NSWAP__%0\n"
creg: NEGI1(reg) "RSBS %c, %0, 0\n"
creg: LSHI1(reg, one) "ADDS %c, %0, __NSWAP__%0\n"
creg: LSHU1(reg, one) "ADDS %c, %0, __NSWAP__%0\n"
creg: LSHI1(reg, op) "SHL %0, %1\nNOP\nMOVS %c, SHIFT_RESULT\n"
creg: LSHU1(reg, op) "SHL %0, %1\nNOP\nMOVS %c, SHIFT_RESULT\n"
reg: RSHI1(creg, op) "SHR %0, %1\nCMOV %c, 0xffff\nSHR %c, %1\nMOV %c, SHIFT_RESULT\nORMI %c, %c, NOT SHIFT_RESULT\n"
creg: RSHU1(reg, op) "SHR %0, %1\nNOP\nMOVS %c, SHIFT_RESULT\n"
creg: MULI1(reg, op) "SMUL %0, %1\nNOP\nNOP\nMOVS %c, MUL_RESULT_LO\n"
creg: MULU1(reg, op) "MUL %0, %1\nNOP\nNOP\nMOVS %c, MUL_RESULT_LO\n"
creg: MULI1(op, reg) "SMUL %1, %0\nNOP\nNOP\nMOVS %c, MUL_RESULT_LO\n"
creg: MULU1(op, reg) "MUL %1, %0\nNOP\nNOP\nMOVS %c, MUL_RESULT_LO\n"

stmt: EQI1(creg, zero) "DJEQ %a\n"
stmt: EQU1(creg, zero) "DJEQ %a\n"
stmt: NEI1(creg, zero) "DJNE %a\n"
stmt: NEU1(creg, zero) "DJNE %a\n"
stmt: EQI1(reg, op) "CMP %0, %1\nDJEQ %a\n" 1
stmt: EQU1(reg, op) "CMP %0, %1\nDJEQ %a\n" 1
stmt: NEI1(reg, op) "CMP %0, %1\nDJNE %a\n" 1
stmt: NEU1(reg, op) "CMP %0, %1\nDJNE %a\n" 1
stmt: GEI1(reg, op) "CMP %0, %1\nDJGE %a\n"
stmt: GEU1(reg, op) "CMP %0, %1\nDJCS %a\n"
stmt: GTI1(reg, op) "CMP %0, %1\nDJGT %a\n"
stmt: GTU1(reg, op) "CMP %0, %1\nDJHI %a\n"
stmt: LEI1(reg, op) "CMP %0, %1\nDJLE %a\n"
stmt: LEU1(reg, op) "CMP %0, %1\nDJLS %a\n"
stmt: LTI1(reg, op) "CMP %0, %1\nDJLT %a\n"
stmt: LTU1(reg, op) "CMP %0, %1\nDJCC %a\n"

stmt: EQI2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJEQ %a\n"
stmt: EQU2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJEQ %a\n"
stmt: NEI2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJNE %a\n"
stmt: NEU2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJNE %a\n"
stmt: GEI2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJGE %a\n"
stmt: GEU2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJCS %a\n"
stmt: GTI2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJGT %a\n"
stmt: GTU2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJHI %a\n"
stmt: LEI2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJLE %a\n"
stmt: LEU2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJLS %a\n"
stmt: LTI2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJLT %a\n"
stmt: LTU2(reg2, op2) "CMP HI(%0), HI(%1)\nCMPEQ LO(%0), LO(%1)\nDJCC %a\n"

stmt: reg "# stmt reg" 5
stmt: creg2 "# stmt creg2" 5

%%

static void progbeg(int argc, char *argv[]) {
        int i;
        {
                union { char c; int i; } u;
                u.i = 0;
                u.c = 1;
                swap = ((int)(u.i == 1)) != IR->little_endian;
        }
        parseflags(argc, argv);
        for (i = 0; i < 14; i++) intreg[i] = mkreg("r%d", i, 1, IREG);
        for (i = 0; i < 14; i+=2) longreg[i] = mkreg("r%d", i, 3, IREG);
        intregw = mkwildcard(intreg);
        longregw = mkwildcard(longreg);
        tmask[IREG] = 0x303e;
        vmask[IREG] = 0x0fc0;
        tmask[FREG] = 0;
        vmask[FREG] = 0;
        cseg = 0;
        print("#include <std.H>\n");
}

static int is_cnst_short(unsigned u) {
    return u<=0x1ff || ~u<=0x1ff || (u&0x7f)==0 || (u&0x7f)==0x7f;
}

static Symbol rmap(int opk) {
        return opsize(opk) == 2 ? longregw : intregw;
}

static void globalend(void) {}
static void progend(void) { globalend(); }

static void deep_target(Node p, int n, Symbol r) {
        if (generic(p->kids[n]->op) == LOAD)
                deep_target(p->kids[n], 0, r);
        else
                rtarget(p, n, r);
}

static void target(Node p) {
        assert(p);
        Symbol* regs = opsize(p->op) == 2 ? longreg : intreg;
        switch (generic(p->op)) {
        case RET:
                deep_target(p, 0, regs[0]);
                setreg(p, intreg[0]);
                break;
        case DIV: case MOD:
                deep_target(p, 0, intreg[0]);
                deep_target(p, 1, intreg[1]);
                if (generic(p->op)==MOD)
                        setreg(p, intreg[0]);
                else
                        setreg(p, intreg[1]);
                break;
        case CALL:
                setreg(p, regs[0]);
                break;
        }
}

static void clobber(Node p) {
        switch (specific(p->op)) {
        case DIV+I: case MOD+I:
                spill(16, IREG, p);
        case DIV+U: case MOD+U:
                spill(12, IREG, p);
                if (generic(p->op)==MOD)
                        spill(2, IREG, p);
                else
                        spill(1, IREG, p);
                break;
        case CALL+I: case CALL+U: case CALL+P: case CALL+V:
                spill(tmask[IREG]&(opsize(p->op) == 2 ? ~3 : ~1), IREG, p);
                break;
        case ARG+I: case ARG+U: case ARG+P:
                spill(1, IREG, p);
                break;
        }
}

static void emit2(Node p) {
        switch (generic(p->op)) {
        case ARG:
            if (opsize(p->op)==1) {
                if (generic(p->kids[0]->op)==CNST || generic(p->kids[0]->op)==ADDRG) {
                    if (next_arg_offset < 8) {
                        if (generic(p->kids[0]->op)==CNST)
                            print("CCMOV [r15+%d], 0x%x\n", next_arg_offset++, p->kids[0]->syms[0]->u.c.v.u);
                        else
                            print("CCMOV [r15+%d], %s\n", next_arg_offset++, p->kids[0]->syms[0]->x.name);
                    } else {
                        if (generic(p->kids[0]->op)==CNST)
                            print("CMOV r0, 0x%x\nMOV [r15+%d], r0\n", p->kids[0]->syms[0]->u.c.v.u, next_arg_offset++);
                        else
                            print("CMOV r0, %s\nMOV [r15+%d], r0\n", p->kids[0]->syms[0]->x.name, next_arg_offset++);
                    }
                } else print("MOV [r15+%d], %s\n", next_arg_offset++, intreg[getregnum(p->x.kids[0])]->x.name);
            } else {
                if (generic(p->kids[0]->op)==CNST) {
                    if (next_arg_offset < 7) {
                        print("CCMOV [r15+%d], LO(0x%x)\n", next_arg_offset++, p->kids[0]->syms[0]->u.c.v.u);
                        print("CCMOV [r15+%d], HI(0x%x)\n", next_arg_offset++, p->kids[0]->syms[0]->u.c.v.u);
                    } else {
                        print("CMOV r0, LO(0x%x)\nMOV [r15+%d], r0\n", p->kids[0]->syms[0]->u.c.v.u, next_arg_offset++);
                        print("CMOV r0, HI(0x%x)\nMOV [r15+%d], r0\n", p->kids[0]->syms[0]->u.c.v.u, next_arg_offset++);
                    }
                } else {
                    print("MOV [r15+%d], %s\n", next_arg_offset++, intreg[getregnum(p->x.kids[0])]->x.name);
                    print("MOV [r15+%d], HI(%s)\n", next_arg_offset++, intreg[getregnum(p->x.kids[0])]->x.name);
                }
            }
            break;
        case CALL:
            next_arg_offset = 0;
            print("DCALL %s\n__:\n", p->kids[0]->syms[0]->x.name);
            break;
        }
}

static void function(Symbol f, Symbol caller[], Symbol callee[], int n) {
        int i;
        globalend();
        usedmask[0] = usedmask[1] = 0;
        freemask[0] = freemask[1] = ~0U;
        offset = 0;
        for (i = 0; callee[i]; i++) {
                Symbol p = callee[i];
                Symbol q = caller[i];
                assert(q);
                p->x.offset = q->x.offset = offset;
                p->x.name = q->x.name = stringf("%d", p->x.offset);
                p->sclass = q->sclass = AUTO;
                offset += q->type->size;
        }
        assert(caller[i] == 0);
        int params = offset;
        maxoffset = offset = offset + 3;
        has_hidden_call = 0;
        gencode(caller, callee);
        
        print("%s:\n", f->x.name);
        for (i = 0; i < 32; ++i) {
            if (usedmask[IREG] & vmask[IREG] & (1<<i))
                print("MOV [r15+%d], r%d\n", maxoffset++, i);
        }
        next_arg_offset = 0;
        framesize = maxoffset;
        if (n>0) {
                print("#define _rr r14\n");
                print("MOV [r15+%d], r14\n", params);
                print("MOV r14, r15\n");
                print("ADD r15, r15, %d\n", maxoffset);
        } else print("#define _rr r15\n");
        if (n>0 || has_hidden_call) {
                print("MOV [r15+%d], MEM_ADDR_LO\n", params+1);
                print("MOV [r15+%d], MEM_ADDR_HI\n", params+2);
        }
        emitcode();
        for (i = 31; i >= 0; --i) {
            if (usedmask[IREG] & vmask[IREG] & (1<<i))
                print("MOV r%d, [_rr+%d]\n", i, --maxoffset);
        }
        if (n>0 || has_hidden_call) {
                print("MOV MEM_ADDR_LO, [_rr+%d]\n", params+1);
                print("MOV MEM_ADDR_HI, [_rr+%d]\n", params+2);
        }
        if (n>0) {
                print("RET\n");
                print("MOV r15, r14\n");
                print("MOV r14, [r14+%d]\n", params);
                print("NOP\nNOP\n");
        } else print("DRET\n");
        print("#undef _rr\n");
}

static void defsymbol(Symbol p) {
        if (p->scope >= LOCAL && p->sclass == STATIC)
                p->x.name = stringf("_LS_%s_%d", p->name, genlabel(1));
        else if (p->generated || (p->scope == GLOBAL && p->sclass == STATIC))
                p->x.name = stringf("_LC_%s", p->name);
        else if (p->scope == GLOBAL || p->sclass == EXTERN)
                p->x.name = stringf("C_%s", p->name);
        else
                p->x.name = p->name;
}

static void address(Symbol q, Symbol p, long n) {
        if (p->scope == GLOBAL || p->sclass == STATIC || p->sclass == EXTERN)
                q->x.name = stringf("%s%s%D", p->x.name, n >= 0 ? "+" : "", n);
        else {
                assert(n <= INT_MAX && n >= INT_MIN);
                q->x.offset = p->x.offset + n;
                q->x.name = stringd(q->x.offset);
        }
}

static void segment(int n) {
        if (n == cseg)
                return;
        cseg = n;
        if (cseg == CODE)
                print(".code\n");
        else if (cseg == BSS)
                print(".virtual\n");
        else if (cseg == DATA || cseg == LIT)
                print(".data\n");
}

static void defconst(int suffix, int size, Value v) {
        if ((suffix == I || suffix == U || suffix == P) && size == 1)
                print(".const %u\n", v.u);
        else if ((suffix == I || suffix == U) && size == 2)
                print(".const LO(%u), HI(%u)\n", v.u);
        else if (suffix == F && size == 2) {
                float f = v.d;
                unsigned short* s = (unsigned short*)&f;
                print(".const 0x%x, 0x%x\n", s[0], s[1]);
        }
        else assert(0);
}
static void defaddress(Symbol p) {
        print(".const %s\n", p->x.name);
}
static void defstring(int n, char *str) {
        char *s;
        print(".const ");
        for (s = str; s < str + n - 1; s+=2)
                print("0x%x, ", (((unsigned)s[1])<<8) + s[0]);
        if (n%2)
                print("0x%x\n", *s);
        else
                print("0\n");
}
static void doarg(Node p) {
        assert(p && p->syms[0]);
        argoffset = p->syms[0]->u.c.v.i;
}
static void blkfetch(int k, int off, int reg, int tmp) {}
static void blkstore(int k, int off, int reg, int tmp) {}
static void blkloop(int dreg, int doff, int sreg, int soff, int size, int tmps[]) {}
static void export(Symbol p) {}
static void import(Symbol p) {}
static void global(Symbol p) {
        print("%s:\n", p->x.name);
}
static void local(Symbol p) {
        if (askregvar(p, (*IR->x.rmap)(ttob(p->type))) == 0) {
                assert(p->sclass == AUTO);
                p->x.offset = offset;
                p->x.name = stringd(offset);
                offset += p->type->size;
        }
}
static void space(int n) {
        print(".words %d\n", n);
}
static Node mgen(Node forest) {
        Node p, r;
        r = gen(forest);
        for (p = r; p; p = p->x.next) {
                if (generic(p->op) == DIV || generic(p->op) == MOD) has_hidden_call = 1;
        }
        return r;
}

Interface miksysIR = {
        1, 1, 0,  /* char */
        1, 1, 0,  /* short */
        1, 1, 0,  /* int */
        2, 1, 0,  /* long */
        2, 1, 0,  /* long long */
        2, 1, 1,  /* float */
        2, 1, 1,  /* double */
        2, 1, 1,  /* long double */
        1, 1, 0,  /* T * */
        0, 1, 0,  /* struct */
        1,        /* little_endian */
        0,        /* mulops_calls */
        0,        /* wants_callb */
        0,        /* wants_argb */
        0,        /* left_to_right */
        0,        /* wants_dag */
        0,        /* unsigned_char */
        address,
        blockbeg,
        blockend,
        defaddress,
        defconst,
        defstring,
        defsymbol,
        emit,
        export,
        function,
        mgen,
        global,
        import,
        local,
        progbeg,
        progend,
        segment,
        space,
        stabblock, stabend, 0, stabinit, stabline, stabsym, stabtype,
        {1, rmap,
            blkfetch, blkstore, blkloop,
            _label,
            _rule,
            _nts,
            _kids,
            _string,
            _templates,
            _isinstruction,
            _ntname,
            emit2,
            doarg,
            target,
            clobber,
        }
};

