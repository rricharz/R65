// runtime.c
// pascal runtime

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#include "time.h"
#include "load.h"
#include "runtime.h"

// p-code runtime

#define SIZE    1200
#define SIZE1   1180
#define MNEMOTB 0x1300
#define NUMCODES 84             // was 56 in original debug version

uint16_t p0;
int i, j, k, stopflg, ll, ff;
int device;
char cmd;
int s[SIZE+1];  // data stack

int p;          // program counter
int b;          // base pointer
int t;          // stack pointer
int k;          // instruction counter
int z;          // start address of pcodes

int xbase;      // stored base for lodn and ston

const char *mnemonic[] = {
    "stop","retn","nega","adda","suba","mula",
    "diva","lowb","tequ","tneq","tles","tgre",
    "tgrt","tlee","orac","anda","eora","nota",
    "left","righ","inca","deca","copy","peek",
    "poke","cala","rlin","getc","getn","prtc",
    "prtn","prts","litb","incb","litw","incw",
    "jump","jmpz","jmpo","load","lodx","stor",
    "stox","call","sdev","rdev","fnam","opnr",
    "opnw","clos","prti","ghgh","glow","phgh",
    "plow","gsec","psec","nbyt","nwrd","lodn",
    "ston","lodi","stoi","exst","tind","runp",
    "addf","subf","mulf","divf","flof","fixf",
    "fequ","fneq","fles","fgre","fgrt","flee",
    "fcom","tfer","opra","getr","putr","swa2",
};

/***************/
int base(int leu)
/***************/
{
    int b1, leu1;
    b1 = b;
    leu1 = leu;
    while (leu1 > 0) {
        b1 = s[b1]; leu1 = leu1 - 1;
    }
    return b1;
}

/*********************/
int error(int x, int y)
/*********************/
{
    printf("\n");
    if (x < 100)
        printf("file error %02X\n", x);
    else {
        switch (x) {
           case 101: printf("Error: program too long\n"); break;
           case 102: printf("Illegal p-code %d at %d\n", y, p); break;
           case 103: printf("Interpreter stack overflow\n"); break;
           case 104: printf("p-code not yet implemented %02d at %d\n", y, p);
                            mem[p + 2]; break;
           default: printf("Unknown error %d\n", x);
        }
    }
    stopflg = 1;
}


/**********/
void init()
/**********/
{   
    
    t = 0; b = 1; p = 2; stopflg = 0;       // bug fixed in bootstrap version, was t=0
    s[1] = 0; s[2] = 0; s[3] = -1;
    p0 = 2; k = 0; z = SBLOCK;
}


/**************/
int type(int pc)
/**************/
{
    if ((pc < 0) || (pc > NUMCODES)) return 0;
    else if (pc <= 15) return 1;
    else if (pc <= 31) return 2;
    else if (pc <= 33) return 3;
    else if (pc <= 38) return 4;
    else if (pc <= 43) return 5;
    else return 6;

}

/*********/
void exec()
/*********/
// execute one p-code instruction
{
    int x, l, f, idx, temp;
    int16_t a;
    char ch;
    
    f = mem[p+z];
    p0 = p; k = k+1;
    // compute type of operation
    ff = type(f); if (ff == 0) error(102,f);
    // if (mem[sflag] != 0) {               // R65 escape
    // stopflg = 1; mem[sflag] = 0;
    // }
    // printf("***Exec: p+z=%d, f=%d, ff=%d\n",p+z,f,ff);
    // printf("\n***Exec-1 %s: ", mnemonic[f]);
    // for (int iii=0; iii<8;iii++) printf("%4x ", s[iii]);
    switch (ff) {
        case 1: // type 1 instructions
                p = p+1;
                switch (f) {
                    case 0: stopflg = 1; break;                     // stop
                    case 1: t = b-1; b = s[t+2]; p = s[t+3]; break; // return
                    case 2: s[t] = - s[t]; break;                   // nega
                    case 3: t = t-1; s[t] = s[t] + s[t+1]; break;   // adda
                    case 4: t = t-1; s[t] = s[t] - s[t+1]; break;   // suba
                    case 5: t = t-1; s[t] = s[t] * s[t+1]; break;   // mula
                    case 6: t = t-1; s[t] = s[t] / s[t+1]; break;   // diva
                    case 7: s[t] = s[t] & 1;                        // lowb
                    case 8: t = t-1; s[t] = s[t] == s[t+1]; break;  // tequ
                    case 9: t = t-1; s[t] = s[t] != s[t+1]; break;  // tneq
                    case 10: t = t-1; s[t] = s[t] < s[t+1]; break;  // tles
                    case 11: t = t-1; s[t] = s[t] >= s[t+1]; break; // tgre
                    case 12: t = t-1; s[t] = s[t] > s[t+1]; break;  // tgrt
                    case 13: t = t-1; s[t] = s[t] <= s[t+1]; break; // tlee
                    case 14: t = t-1; s[t] = s[t] | s[t+1]; break;  // orac
                    case 15: t = t-1; s[t] = s[t] & s[t+1]; break;  // anda
                } break;
        case 2: // type 2 instructions
                p = p+1;
                switch (f) {
                    case 16: t = t-1; s[t] = s[t] ^ s[t+1]; break;  // eora
                    case 17: s[t] = ~s[t]; break;                   // nota
                    case 18: t = t-1; s[t] = s[t] << s[t+1]; break; // left
                    case 19: t = t-1; s[t] = s[t] >> s[t+1]; break; // righ
                    case 20: s[t]++; break;                         // inca
                    case 21: s[t]--; break;                         // deca
                    case 22: t = t+1; s[t] = s[t-1]; break;         // copy
                    case 23: s[t] = mem[s[t]]; break;               // peek
                    case 24: // printf("poke setting [$%04x] to %d\n",s[t-1],s[t]);
                             mem[s[t-1]] = s[t]; t = t-2; break;    // poke                    
                    case 25: error(104,f); break;                   // cala
                    case 26: rlin(); break;                         // rlin
                    case 27: s[t+1] = pgetc(); t++; break;          // getc
                    case 28: error(104,f); break;                   // getn
                    case 29: printf("%c",s[t]); t--; break;         // prtc
                    case 30: printf("%d",s[t]); t--; break;         // prtn
                    case 31: for (idx = t-s[t]; idx <= t-1; idx++)  // prts
                                printf("%c", s[idx]); break;                    
                } break;
        case 3: // type 3 instructions
                a = mem[p+z+1];
                p = p+2;
                // printf("\n***** type 3: %d %d\n", f, a);
                switch (f) {
                    case 32: s[t+1] = a; t=t+1; break;              // litb
                    case 33: if (a > 128) a = a - 256;              // incb
                             t = t+(a/2); break;  // 16 bit machine! 
                } break;
        case 4: // type 4 instructions
                a = mem[p+z+1] + (mem[p+z+2] << 8);
                p = p+3;
                // printf("***exec type 4: a=%d, p=%d\n", a, p);
                switch (f) {
                    case 34: s[t+1] = a; t = t+1; break;            // litw
                    case 35: t = t + a / 2; break;                  // incw
                    case 36: p += a - 2; break;                     // jump
                    case 37: if ((s[t] & 1) == 0) p = p + a - 2;    // jmpz
                             t = t-1;break;
                    case 38: if ((s[t] & 1) == 1) p = p + a - 2;    // jmpo
                             t = t-1;break;
                } 
                // printf("***exec type 4: t=%d, p=%d\n", t, p);
                break;
                
        case 5: // type 5 instructions
                l = mem[p+z+1];
                a = mem[p+z+2] + (mem[p+z+3] << 8);
                p = p+4;
                switch (f) {
                    case 39: xbase = base(l) + (a/2);               // load
                             t++; s[t] = s[xbase]; break;
                    case 40: xbase = base(l) + (a / 2) + s[t];      // lodx
                             s[t] = s[xbase]; break;
                    case 41: xbase = base(l)+(a/2);                 // stor
                             s[xbase] = s[t]; t--; break;
                    case 42: a = (a/2) + s[t-1];
                             xbase = base(l)+a;                     // stox
                             s[xbase] = s[t]; t -= 2; break;    
                    case 43: s[t+1] = base(l); s[t+2] = b;          // call
                             s[t+3] = p; b = t+1;p = p+a-2; break;
                } break;
        case 6: // type 6 instructions
                p = p+1;
                switch (f) {
                    case 44: device = s[t]; t--; break;             // sdev
                    case 45: device = 0; break;                     // rdev
                    case 46: error(104,f); break;                   // fnam
                    case 47: error(104,f); break;                   // opnr
                    case 48: error(104,f); break;                   // opnw
                    case 49: error(104,f); break;                   // clos
                    case 50: do {printf("%c", mem[p+z]&127); p=p+1;}// prti
                             while ((mem[p+z-1]&128) == 0); break;
                    case 51: s[t] = s[t] >> 8; break;               // ghgh
                    case 52: s[t] = s[t] & 255; break;              // glow
                    case 53: s[t-1] = (s[t-1]<<8)+(s[t]&255);       // phgh
                             t--; break;
                    case 54: s[t-1] = (s[t-1]&0xff)+(s[t]&255);     // plow
                             t--; break;
                    case 55: error(104,f); break;                   // gsec
                    case 56: error(104,f); break;                   // psec
                    
                    // codes added to original debug
                    case 59: a = mem[p+z]; p = p+1;                 // lodn
                             for (int ii=0; ii<a;ii++) {
                                t++; xbase++; s[t] = s[xbase]; }
                             break;
                    case 60: a = mem[p+z]; p = p+1;                 // ston
                             for (int ii=0; ii<a;ii++) {
                                xbase--; s[xbase] = s[t]; t--; }
                             break;
                    case 61: //printf("\nlodi loading $%04x from [$%04x]\n",
                             //       mem[s[t]]+(mem[s[t]+1] << 8),s[t]);
                             s[t]=mem[s[t]]+(mem[s[t]+1] << 8);     // lodi
                             break;
                    case 62: //printf("\nstoi setting [$%04x] to $%04x\n",
                             //               s[t],s[t-1]);
                             mem[s[t]]=s[t-1] & 255;                // stoi
                             mem[s[t]+1]=(s[t-1]) >> 8;
                             t=t-2; break;
                    case 63: x=s[t];                                // exst
                             s[t]=s[t-1]; s[t-1]=x; break;
                                                
                    default: error(104,f); break;
                } break;
    }  // end switch (ff)
    if (t > SIZE1)
        error(103,0);
    // printf("***exec: end of function\n");
}

/***************/
void code(int pc)
/***************/
// print code at pc
{
    int cd, y, i;
    int16_t x;
    y = pc+z; cd=mem[y];
    printf("%05d [%04x] %02d(tp%d) %s ", pc, y, cd, type(cd), mnemonic[cd]);
    ll=1;
    switch (type(cd)) {
        case 3: x = mem[y+1]; ll = 2;
                if ((cd == 33) && (x>127)) x-= 256;
                printf("%d", x);
                if ((cd == 32) && (x>31)) printf("(%c)",x); break;
        case 4: ll = 3;
                x = mem[y+1]+(mem[y+2]<<8);
                if (cd>35) x=pc+x+1;
                printf("%d", x); break;
        case 5: ll = 4;
                printf("%d ",mem[y+1]);
                x = mem[y+2]+(mem[y+3]<<8);
                if (cd == 43) x = pc+x+2;
                else x = x/2;
                printf("%d",x); break;
        case 6: if (cd == 50) {
                    printf("'");
                    do { printf("%c",mem[y+ll]&127); ll++;
                    }
                    while ((mem[y+ll-1]&128) == 0);
                    printf("'");
                }
                if ((cd == 59) || (cd == 60)) {
                    ll = 2;
                    printf("%d ", mem[y+1]);
                }
    }
}

/*****************/
void code1(int pc1)
/*****************/
{
    code(pc1);
    printf("  t=%d  s[t]=%d",t,s[t]);
}

/*********/
void ckbp()
/*********/
// check breakpoint
{
    int i;
    if (p < 0)
        stopflg = 1;
}

/************/
void runtime()
/************/
{
    int maxlines;
    
    printf("\nPascal runtime version 1.0\n");
    init();
    // code(p);
    // printf("Size of mnemonic table %d\n", sizeof(mnemonic) / sizeof(mnemonic[0]));
    do {
        printf("\n(c,s,r,g,l,q)?"); cmd = getkey();
        switch (cmd) {
            case 'c':   printf(" Continue...\n");
                        stopflg = 0;
                        do {
                            exec(); ckbp();
                        }
                        while (stopflg == 0); break;
            case 's':   exec();code1(p); break;
            case 'r':   printf(" p=%d, b=%d, t=%d, s[t]=%d, s[t-1]=%d",
                            p, b, t, s[t], s[t-1]); break;
            case 'g':   printf(" Go...\n\n");
                        init();
                        do {exec(); ckbp(); }
                        while (stopflg == 0); break;
            case 'l':   maxlines = 2000;
                        do {
                            printf("\n"); code(p0); p0 = p0+ll; maxlines--;
                        } while  ((p0 < endprog) && (maxlines > 0)); break;
            case 'q':   p = -1; break;
            case 0xa:   break;  // needed in bootstrap version (linux)
            default:    printf(" Unknown command %02x", cmd); break;                        
        }
    }
    while (p >= 0);
    printf("\n\n%d instructions executed\n", k); 
}
