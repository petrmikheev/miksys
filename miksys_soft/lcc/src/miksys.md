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
%term CNSTI1=1045 CNSTU1=1046 CNSTP1=1047
%term INDIRI1=1093 INDIRU1=1094 INDIRP1=1095
%term ASGNI1=1077 ASGNU1=1078 ASGNP1=1079
%term RETI1=1269 RETU1=1270 RETP1=1271
%term LOADI1=1253 LOADU1=1254 LOADP1=1255

%term ADDI1=1333 ADDU1=1334 ADDP1=1335
%term SUBI1=1349 SUBU1=1350 SUBP1=1351
%term DIVI1=1477 DIVU1=1478
%term MODI1=1381 MODU1=1382
%term BANDI1=1413 BANDU1=1414
%term BORI1=1445 BORU1=1446
%term BXORI1=1461 BXORU1=1462
%term BCOMI1=1429 BCOMU1=1430
%term NEGI1=1221
%term LSHI1=1365 LSHU1=1366
%term RSHI1=1397 RSHU1=1398
%term MULI1=1493 MULU1=1494

%term EQI1=1509 EQU1=1510
%term NEI1=1589 NEU1=1590
%term GEI1=1525 GEU1=1526
%term GTI1=1541 GTU1=1542
%term LEI1=1557 LEU1=1558
%term LTI1=1573 LTU1=1574

%term CALLV=216 CALLI1=1237 CALLU1=1238 CALLP1=1239
%term ARGI1=1061 ARGU1=1062 ARGP1=1063

%term LABELV=600
%term JUMPV=584
%term VREGP=711
%term CVUI2=2229

%%

zero: CNSTI1 "%a" a->syms[0]->u.c.v.u==0 ? 0 : LBURG_MAX
zero: CNSTU1 "%a" a->syms[0]->u.c.v.u==0 ? 0 : LBURG_MAX
one: CNSTI1 "%a" a->syms[0]->u.c.v.u==1 ? 0 : LBURG_MAX
cnst8: CNSTI1 "%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
cnst8: CNSTU1 "%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
cnst8: CNSTP1 "%a" a->syms[0]->u.c.v.u<8 ? 0 : LBURG_MAX
cnst128: CNSTI1 "%a" a->syms[0]->u.c.v.u<128 ? 0 : LBURG_MAX
cnst128: CNSTU1 "%a" a->syms[0]->u.c.v.u<128 ? 0 : LBURG_MAX
cnst128: CNSTP1 "%a" a->syms[0]->u.c.v.u<128 ? 0 : LBURG_MAX
cnst_short: CNSTI1 "%a" is_cnst_short(a->syms[0]->u.c.v.u) ? 0 : LBURG_MAX
cnst_short: CNSTU1 "%a" is_cnst_short(a->syms[0]->u.c.v.u) ? 0 : LBURG_MAX
cnst_short: CNSTP1 "%a" is_cnst_short(a->syms[0]->u.c.v.u) ? 0 : LBURG_MAX
cnst: CNSTI1 "%a"
cnst: CNSTU1 "%a"
cnst: CNSTP1 "%a"
cnst: ADDRGP1 "%a"

stmt: LABELV "%a:\n"
stmt: JUMPV(cnst) "DJ %0\n"
stmt: ARGI1(reg) "# arg\n" 1
stmt: ARGU1(reg) "# arg\n" 1
stmt: ARGP1(reg) "# arg\n" 1
stmt: CALLV(ADDRGP1) "# call\n"
reg: CALLI1(ADDRGP1) "# call\n"
reg: CALLU1(ADDRGP1) "# call\n"
reg: CALLP1(ADDRGP1) "# call\n"

stmt: RETI1(creg) "# RETI1 %0\n"
stmt: RETU1(creg) "# RETU1 %0\n"
stmt: RETP1(creg) "# RETP1 %0\n"
stmt: RETI1(reg) "MOV %c, %0\n" 1
stmt: RETU1(reg) "MOV %c, %0\n" 1
stmt: RETP1(reg) "MOV %c, %0\n" 1

stmt: ASGNI1(VREGP, creg) "# write reg\n"
stmt: ASGNU1(VREGP, creg) "# write reg\n"
stmt: ASGNP1(VREGP, creg) "# write_reg\n"
stmt: ASGNI1(ccmov_addr, cnst) "CCMOV __CACHE__[%0], %1\n"
stmt: ASGNU1(ccmov_addr, cnst) "CCMOV __CACHE__[%0], %1\n"
stmt: ASGNP1(ccmov_addr, cnst) "CCMOV __CACHE__[%0], %1\n"
stmt: ASGNI1(addr, reg) "MOV __CACHE__[%0], %1\n" 1
stmt: ASGNU1(addr, reg) "MOV __CACHE__[%0], %1\n" 1
stmt: ASGNP1(addr, reg) "MOV __CACHE__[%0], %1\n" 1

addr: reg "__ADDR__%0" 1
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

op: cnst_short "%0"
op: INDIRI1(addr) "[%0]"
op: INDIRU1(addr) "[%0]"
op: INDIRP1(addr) "[%0]"
op: reg "__SWAP__%0" 1
op: BCOMI1(reg) "NOT __NSWAP__%0"
op: BCOMU1(reg) "NOT __NSWAP__%0"

reg: creg "%0" 1
reg: LOADI1(reg) "%0"
reg: LOADU1(reg) "%0"
reg: LOADP1(reg) "%0"
reg: CVUI2(reg) "%0"
reg: INDIRI1(VREGP) "# read reg\n"
reg: INDIRU1(VREGP) "# read reg\n"
reg: INDIRP1(VREGP) "# read reg\n"

reg: DIVI1(creg, creg) "XOR r4, r0, r1\nCALL divide_func\nCMP r0, 0\nRSBMI r0, r0, 0\nCMP r1, 0\nRSBMI r1, r1, 0\n__:\nCMP r4, 0\nRSBMI r1, r1, 0\n"
reg: DIVU1(creg, creg) "DCALL divide_func\n"
reg: MODI1(creg, creg) "MOV r4, r0\nCALL divide_func\nCMP r0, 0\nRSBMI r0, r0, 0\nCMP r1, 0\nRSBMI r1, r1, 0\n__:\nCMP r4, 0\nRSBMI r0, r0, 0\n"
reg: MODU1(creg, creg) "DCALL divide_func\n"

creg: ADDRLP1 "ADDS %c, _rr, %a\n"
creg: ADDRFP1 "ADDS %c, _rr, %a\n"
creg: ADDRGP1 "CMOV %c, %a\n"
creg: CNSTI1 "CMOV %c, %a\n"
creg: CNSTU1 "CMOV %c, %a\n"
creg: CNSTP1 "CMOV %c, %a\n"

creg: INDIRI1(addr) "MOVS %c, [%0]\n"
creg: INDIRU1(addr) "MOVS %c, [%0]\n"
creg: INDIRP1(addr) "MOVS %c, [%0]\n"

creg: LOADI1(reg) "MOVS %c, %0\n" 1
creg: LOADU1(reg) "MOVS %c, %0\n" 1
creg: LOADP1(reg) "MOVS %c, %0\n" 1
creg: LOADI1(creg) "%0"
creg: LOADU1(creg) "%0"
creg: LOADP1(creg) "%0"

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
        tmask[IREG] = 0x3fff;
        vmask[IREG] = 0x00e0;
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
        switch (generic(p->op)) {
        case RET:
                deep_target(p, 0, intreg[0]);
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
                setreg(p, intreg[0]);
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
                spill(0x3f1e, IREG, p);
                break;
        }
}

static void emit2(Node p) {
        switch (generic(p->op)) {
        case ARG:
            print("MOV [_rr+%d], %s\n", next_arg_offset++, intreg[getregnum(p->x.kids[0])]->x.name);
            break;
        case CALL:
            next_arg_offset = framesize;
            print("DCALL %s\n", p->kids[0]->syms[0]->x.name);
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
        maxoffset += 3;
        print("MOV [r15+%d], r5\n", maxoffset-3);
        print("MOV [r15+%d], r6\n", maxoffset-2);
        print("MOV [r15+%d], r7\n", maxoffset-1);
        next_arg_offset = framesize = maxoffset;
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
        print("MOV r5, [r15+%d]\n", maxoffset-3);
        print("MOV r6, [r15+%d]\n", maxoffset-2);
        print("MOV r7, [r15+%d]\n", maxoffset-1);
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
                p->x.name = stringf("_LC%s.%d", p->name, genlabel(1));
        else if (p->generated)
                p->x.name = stringf("_LC%s", p->name);
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
                print(".const %d\n", v.u);
        else if ((suffix == I || suffix == U) && size == 2)
                print(".const LO(%d), HI(%d)\n", v.u);
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
        1/*2*/, 1, 1,  /* long */
        1/*2*/, 1, 1,  /* long long */
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

