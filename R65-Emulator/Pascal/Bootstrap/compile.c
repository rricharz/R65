/*

compile.c

Bootstrap Pascal Compiler for the R65 emulator

While the complete R65 Pascal source code is still
available, the object files were all lost. I decided
therefore to write this compiler in C to bootstrap
the process of reviving the Pascal environment

Once the environment is working, the original
Pascal Compiler written in Pascal can be used again

Currently work in progress, not working

*/

// debugging
#define debugFind    0      // display findid debug
#define debugLib     0      // display lib read debug
#define debugForw    0      // display forward debug

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#include "time.h"

#define IDLENGHT   32
#define RESWLENGHT 10
#define MAXRESW    64

#define MAXIDS    256       // max number of ids

#define SYMBSIZE  256       // symbol table entries

#define STACKSIZE 256       // stack size

#define P_LITB 32
#define P_INCB 33
#define P_LITW 34
#define P_INCW 35
#define P_JUMP 36

int numResw = 0;
char reswTb[MAXRESW][RESWLENGHT];
int  reswCd[MAXRESW];

FILE *fno = NULL;
FILE *ofno = NULL;
FILE *oprt = NULL;
FILE *libfno = NULL;

int ch, restype, vartype;
int token;

int value[2];
double rvalue = 0;
char ident[IDLENGHT];

char idTable[8 * MAXIDS];

int numerr = 0;
int tpos = 0;

int libflg = 0;
int icheck = 0;

int filstp = 0;

int dpnt, spnt, pc, stackpnt, spntmax, level, npara, stackmax, offset;

int t0[SYMBSIZE+1];      // type of symbol
int t1[SYMBSIZE+1];      // level
int t2[SYMBSIZE+1];      // val/dis/address
int t3[SYMBSIZE+1];      // stack pointer, size of array

int stack[STACKSIZE+1];

char prgname[IDLENGHT];
int lineno = 0;


/**************/
int low(int val)
/**************/
{
    return (val & 0xff);
}

/**************/
int high(int val)
/**************/
{
    return ((val >> 8) & 0xff);
}

/****************************/
int packed(char ch1, char ch2)
/****************************/
{
    int v = (ch1 << 8) | (ch2 & 0xFF);
    // printf("\n**packed(%c,%c): %04X\n", ch1, ch2, v);
    return(v);
}

/*************/
int pk(char *s)
/*************/
{
    return(packed(s[0], s[1]));
}

/*****************/
void closeAndExit()
/*****************/
{
    if (fno != NULL)
        fclose(fno);
    if (ofno != NULL)
        fclose(ofno);
    if (oprt != NULL)
        fclose(oprt);
    if (libfno != NULL)
        fclose(libfno);
    printf("Exiting compile with error\n");
    exit (1);
}


/******************/
void savebyte(int x)
/******************/
{
    
    if (ofno != NULL)
      fprintf(ofno, "%c%c", ((x & 255) >> 4)  + '0', (x & 15)  + '0');
}

/***********************/
void merror(int e, int x)
/***********************/
{
    printf("\n      ");
    numerr++;
    for (int i = 0; i < tpos+5; i++) printf(" ");
    printf("^\n###### Error: ");
    if (e == 1)
        printf("Illegal ident\n");
    else if (e == 2)
        printf("'%c%c' instead of '%c%c' expected\n",
            high(x), low(x), high(token), low(token));
    else if (e == 5)
        printf("%s undefined\n", ident+1);
    else if (e == 8)
        printf("Illegal declaration\n");
    else if (e == 11)
        printf("Stack overflow or underflow\n");
    else if (e == 13)
        printf("Forward reference %c%c\n", high(x), low(x));
    else if (e == 14)
        printf("type missmatch\n");
    else if (e == 15)
        printf("array size\n");    
    else if (e == 201)  // new code added 2018
        printf("Ident or string too long (n=%d)\n", x);
    else
        printf("%d %c%c\n", e, high(x), low(x));
    exit(1);
}

/***************/
void error(int e)
/***************/
{
    merror(e, pk("  "));
}

/**************/
void push(int x)
/**************/
{
    if (stackpnt >= STACKSIZE) error(8);
    else stackpnt++;
    if (stackpnt > stackmax) stackmax = stackpnt;
    stack[stackpnt] = x;
}

/*******/
int pop()
/*******/
{
    int x;
    if (stackpnt < 0) error(8);
    x = stack[stackpnt];
    stackpnt--;
    return(x);
}

/***********/
void getchr()
/***********/
{
    if (lineno == 0) {
        lineno++;
        printf("%04d (%05d) ", lineno, pc + 2);
        if (oprt !=NULL) {
            fprintf(oprt, "%04d (%05d) ", lineno, pc + 2);
        }
    }
    ch = getc(fno);
    if (ch == 0xA) {
      printf("\n");
      lineno++;
      printf("%04d (%05d) ", lineno, pc + 2);
      tpos = 0;
      ch = ' ';
      if (oprt !=NULL) {
          fprintf(oprt, "\n");
          fprintf(oprt, "%04d (%05d) ", lineno, pc + 2);
      }
    }
    else if (ch == 0xD)
        getchr();
    else {
      printf("%c", ch);
      if (oprt !=NULL)
            fprintf(oprt, "%c", ch);
      tpos++;
    }
}


/*********/
void init()
/*********/
{
    pc = 2; dpnt = 0; spnt=0; offset = 2;
    npara = 0; level=0;
    stackpnt = 0; libflg = 0;
    stackmax = 0; spntmax = 0; numerr = 0;
    t0[0] = pk("vi"); t1[0] = 0; t2[0] = 0; t3[0] = 0;
    
    icheck = 0;
}

/*********/
void scan()
/*********/
// scan input file for next token
// looks ahead one char
{
    int count = 1;
    
    void pack() // packs token and c to token
    {
        token = packed(low(token), ch);
        getchr();
    }
    
    int isLetter()  // is ch a letter?
    {
        return (((ch >= 'A') && (ch <= 'Z')) || ((ch >= 'a') && (ch <= 'z')));
    }
    
    int isNumber()  // is ch a number?
    {
        return ((ch >= '0') && (ch <= '9'));
    }

    int isHexDigit() // is ch a hex digit?
    {
        return (((ch >= 'a') && (ch <= 'f')) || isNumber());
    }
    
    void clear() // // clears identifier    
    {
        for (int i = 0; i < IDLENGHT; i++)
            ident[i] = ' ';
    }
    
    void setid()    //  sets one char to ident
    {
        if (count < IDLENGHT - 1) {
            ident[count++] = ch;
            ident[count] = 0;       // end of string mark
        }
        else {
            merror(201, count);
        }
        getchr();
    }
    
    void setval()   //  read a numeric value
    {
        double r = 0.0;
        do {
            r = 10.0 * r + ch - '0';
            getchr();
        }
        while (isNumber(ch));
        if (ch != '.') {   // integer
            token = pk("nu");
            if (r < 0.0)
                value[0] = (int)(r - 0.5);
            else
                value[0] = (int)(r + 0.5);
        }
        else { // real
            int n = 0;
            getchr();
            while (isNumber()) {
                r = 10.0 * r + ch - '0';
                n--;
                getchr();
            }
            if (ch == 'e') {  // exponent
                int ems = 0;
                getchr();
                switch (ch) {
                    case '+': getchr(); break;
                    case '-': ems = 1; getchr(); break;
                }
                if (!isNumber())
                    error(17);
                else {
                    int n1 = ch - '0';
                    getchr();
                    if (isNumber()) {
                        n1 = 10 * n1 + ch - '0';
                        getchr();
                    }
                    if (ems)
                        n = n - n1;
                    else
                        n = n + n1;
                }
            }
            while (n > 0) {r = 10.0 * r; n++;}
            while (n < 0) {r = 0.1 * r; n--;}
            rvalue = r;
            token = pk("ru");
        }
    }   
    
    // body of scan
    
    while (ch == ' ') {
        getchr();
    }
    if (!isLetter()) {  // is not letter
        if (!isNumber())   // is not number
        { // must be special symbol
            token = packed(' ',ch); getchr();
            switch (low(token)) {
                case '<':   if ((ch == '=') || (ch == '>')) pack(); break;
                case '>':   if (ch == '=') pack(); break;
                case ':':   if (ch == '=') pack(); break;
                case '{':   do getchr(); while (ch != '}');
                            getchr(); scan(); break;
                case '$':   token = pk("nu"); value[0] = 0;  // hex constant
                            while (isHexDigit()) {
                                if (!isNumber())
                                    value[0] = (value[0] << 4) + ch - 'a' + 10;
                                else
                                    value[0] = (value[0] << 4) + ch - '0';
                                getchr();
                            }
                            break;
                case '\'':  token = pk("st");   // string
                            do setid(); while (ch != '\'');
                            value[0] = count -1; getchr(); break;
            }
        }
        else setval(); // number
    }
    else { // must be ident
        clear();
        // printf("\ncalling ident at 379, count = %d\n",count);
        do setid();
        while (isNumber(ch) || isLetter(ch));
        
        // look up in table of reserved words
        // do not use a fast search algorith, time is not an issue for
        // the boostap compiler
        
        int index = 0;
        while ((strcmp(&reswTb[index][0],ident+1) != 0) && (index < numResw)) {
            // printf("\n##%s##%s##\n", &reswTb[index][0],ident+1);
            index++;
        }
        if (index < numResw) // found reserved word
            token = reswCd[index];
        else        
            token = pk("id");  // not a reserved word
    }
} // end of scan


/****************/
void testto(int x)
/****************/
{
    if (token != x) merror(2, x);
}


/***************/
void parse(int x)
/***************/
// parse  source for specified token, else error
{
    scan(); testto(x);
}


/***********/
void getlib()
/***********/
// get library      (page  10)
{
    int base, nent, size, i, j, num, x;
    int ch1, ltype2;
       
        int getint(int ii)
        // get a byte from input stream
        {
            int value, sign;
            
            int isNumber1()  // is ch a number?
            {
                return ((ch1 >= '0') && (ch1 <= '9'));
            }
            
            // body of getint
            do
                ch1 = fgetc(libfno);
            while (ch1 == ' ');
            
            if (ch1  == '-') { sign = -1; ch1 = fgetc(libfno); }
            else sign = 1;
            
            if (!isNumber1()) {
                printf("Getint(%d) Reading illegal digit char: 0x%02x\n", ii, ch1);
                closeAndExit();
            }
            value = 0;
            while (isNumber1()) {
                value = (10*value) + ch1 - '0';
                ch1 = fgetc(libfno);
            }
            return value*sign;
        }
   
    scan(); if (token == pk(" ,")) scan();
    testto(pk("id"));

    base = pc - 2;
    if (ofno != NULL) {
        fprintf(ofno,"L");
    }
    fprintf(ofno,"%s\n",ident+1);
    
    // opening library table
    char s2[IDLENGHT+4];
    sprintf(s2,"%s.lib", ident+1);
    // printf("\nOpening %s\n",s2);
    libfno = fopen(s2, "r");
    if (libfno == NULL) {
        printf("Cannot open %s\n",s2);
        closeAndExit();
    }
    
    nent = getint(1); size = getint(2);
    
    for (i = 0; i < nent; i++) {
        if (spnt > SYMBSIZE) error(7);
        spnt++;
        int first = 1;
        ch1 = fgetc(libfno); // next line
        for (j = 1; j <= 8; j++) {
            if ((ch1 == ' ') && first) {
                ch1 = 0; first = 0;
            }
            idTable[8 * spnt + j] = ch1;
            ch1 = fgetc(libfno);
        }
        if (debugLib) printf("\nId from library: >%s< ", idTable + 8 * spnt + 1);
        
        int ch2 = fgetc(libfno);
        int ch3 = fgetc(libfno);
        int ch1 = fgetc(libfno);
        if (debugLib) printf(" >%c%c<,", ch2,ch3);
        t0[spnt] = packed(ch2,ch3);
        t1[spnt] = getint(4);
        t2[spnt] = getint(5);
        t3[spnt] = getint(6);        
        if (debugLib) printf(" %5d, %5d, %5d", t1[spnt], t2[spnt], t3[spnt]);
        t1[spnt] = t1[spnt] + level;
        ltype2 = high(t0[spnt]);
        if (debugLib) printf(" ltype2=%c\n",ltype2);
        if ((ltype2 == 'p') | (ltype2 == 'f') | (ltype2 == 'g')) {
            t2[spnt] = t2[spnt] + base;
            if (t3[spnt] != 0) { // get data for stack
                num = getint(7);
                if (debugLib) printf("num=%d",num);
                push(num); t3[spnt] = stackpnt;
                for (j = 1; j <= num; j++) {
                    x = getint(8);
                    if (debugLib) printf(",x=%d,0x%04x",x,x);
                    push(x);
                }
                if (debugLib) printf("\n");                                
            }
        }
    }
    level++;
    pc = pc + size;
    offset = pc;
    if (spnt > spntmax) spntmax = spnt;
    if (stackpnt > stackmax) stackmax = stackpnt;
    if (libfno != NULL) {
        fclose(libfno); libfno = NULL;
    }
}

/********************/
void block(int bottom)
/********************/
{
    int l, f9,i, n, stackpn1, forwpn, find, cproc,
        spnt1, dpnt1, parlevel;
    int fortab[9];


    void testtype(char ttype)   // pascal type test (function of block)
    {
        if (restype != ttype)
            if ((restype != 'u') && (ttype != 'u'))
                error(14);
    }
    
    int findid()                // search in table for id (function of block)
    {
        int k, i, id1;
        
        i = 1; k = 9 + 8 * spnt; id1 = ident[1];
        do {
            k = k - 8;
            while ((idTable[k] != id1) & (k > 0))
                k = k - 8;
            if (k > 0) {
                i = 1;
                do {
                    i++;
                }
                while ((i <= 8) && (idTable[k + i - 1] == ident[i]));
            }
        }
        while ((i <= 8) && (k > 0));
        if (k <= 0) {
            if (debugFind) {
                printf("\nfindid, id %s not found, spnt=%d\nidTable:\n", ident, spnt);
                for (int jj = 1; jj < spnt; jj++)
                    printf("%2d: %s\n", jj,idTable + 8 * jj + 1);
            }
            return 0;
        }
        if (debugFind) {
            printf("\n****findid, id=%s found, spnt=%d, index = %d", ident, spnt, (k - 1) >> 3);
            printf(", t0[index] = %04x (%c,%c)\nidTable:\n", t0[(k - 1) >> 3],
                high(t0[(k - 1) >> 3]), low(t0[(k - 1) >> 3]));
            for (int jj = 1; jj < spnt; jj++)
                printf("%2d: %s\n", jj,idTable + 8 * jj + 1);
        }
        return ((k - 1) >> 3);
    }

    
    void code1(int x)           // set one byte p-code (function of block)
    {
        savebyte(x); pc++;
    }
 
    
    void code2(int x, int y)    // set 2 byte p-code (function of block)
    {
        code1(x); code1(y);
    }

 
    void code3(int x, int y1)    // set 3 byte p-code (function of block)
    {
        int y;
        y = y1;
        if ((x == 34) && (y < 256) && (y >= 0))
            code2(P_LITB, y);
        else {
            if ((x == 35) && (y > -128) && (y <= 127)) {
                if (y < 0) y = y + 256;
                code2(P_INCB, y);
            }
            else {
                if ((x >= P_JUMP) && (x  <= 38)) y = y - pc - 1;
                code1(x); code1(y & 255); code1(y >> 8);
            }
        }
    }
    
    
    void putsym(int ltyp1, int ltyp2) // (function of block)
    {
        int i, addr;
        if (spnt >= SYMBSIZE) error(7);
        else spnt++;
        if (spnt > spntmax) spntmax = spnt;
        t0[spnt] = packed(ltyp1, ltyp2);
        t3[spnt] = 0;
        if (debugFind) {
            printf("\n*****putsym: id = %s, spnt=%d, t0 = %04x %c %c\n",
            ident, spnt, t0[spnt], ltyp1, ltyp2);
        }
        addr = 8 * spnt;
        for (i = 1; i <=8; i++)
            idTable[addr + i] = ident[i];
        if (ltyp1 == 'v') {
            t2[spnt] = dpnt; dpnt++;            
        }
        t1[spnt] = level;
    }
    
   
    void checkindex(int lowlim,  int highlim) // (function of block)
    {
        if (icheck) {
            code3(0x40,lowlim-1);
            code2(highlim & 255, highlim >> 8);
        }
    }
    
    
    int getcon()               // get constant (function of block)
    {
        int idpnt, val;
        // double rval;
        char sign;
        
        restype = 'i';
        if (token == pk(" -")) {
            sign = '-'; scan();
        }
        else {
            sign = '='; if (token == pk(" +")) scan();
        }
        if (token == pk("nu"))
            val = value[0];
        else if (token == pk("ru")) {
            val = value[0]; restype = 'r';
        }
        else if (token == pk("st")) {
            if (value[0] == 1) {
                restype = 'c'; val = ident[1];
            }
            else {
                val = (ident[1] << 8) + ident[2];
                if (value[0] != 2) error(12);
                restype = 'p';
            }
        }
        else if (token == pk("cr")) {       // chr
            parse(pk(" (")); scan(); val = getcon();
            if ((val > 127) || (val < 0)) error(12);
            testtype('i');
            restype = 'c'; parse(pk(" )"));
        }
        else if (token == pk("tr")) {
            val = 1; restype = 'b';
        }
        else if (token == pk("fa")) {
            val = 0; restype = 'b';
        }
        else if (token == pk(" @")) {
            scan(); val = getcon();
            testtype('i'); restype = 'f';
        }
        else {
            testto(pk("id")); idpnt = findid();
            if ((idpnt > 0) && (high(t0[idpnt]) == 'c')) {
                val = t2[idpnt];
                restype = low(t0[idpnt]);
                if (restype == 'r')
                    value[1] = t3[idpnt];
            }
            else {
                error(4); val = 0; restype = 'i';
            }
        }
        if (sign == '-') {
            if (restype == 'i')
                return (- val);
            else if (restype == 'r') {    
                // splitconv(value, rval);
                printf("######negative reals not yet implemented\n");                
                // splitconv(-rval,value);
                return(value[0]);
            }
            else error(12);
        }
        return(val);
    }
    
    
    void deccon()               // declare constant (function of block)
    {
        if (token == pk(" ;")) scan();
        testto(pk("id"));
        putsym('c', 'i');
        parse(pk(" =")); scan();
        t2[spnt] = getcon();
        if (restype == 'r') t3[spnt] = value[1];
        if (restype != 'i') {
            t0[spnt] = packed('c',restype);
            if (debugFind) {
                printf("\n*****deccon: t0 = %04x %c %c\n",
                t0[spnt], 'c', restype);
            }
        }
        scan();
    }


    void decvar(char typ1, char typ2)    // declare variable (function of block)
    {   
        if (token == pk(" ,")) scan();
        testto(pk("id"));
        putsym(typ1, typ2);
        scan();
    }
    
    
    void gettype(int *typ2, int *aflag, int *uflag, int *n)
    {                                   // gettype (function of block)
        *aflag = 0; *n = 0; *uflag = 0;
        scan();
        if (token == pk("ar")) {
            parse(pk(" [")); scan();
            *n = getcon(); testtype('i');
            if (*n < 1) {
                error(15); *n = 1;
            }
            parse(pk(" ]")); parse(pk("of")); scan();
            *aflag = 1;
        }
        if (token == pk(" %")) {
            scan();*uflag = 1;
        }
        if (token == pk("in"))
            *typ2 = 'i';
        else if (token == pk("ch"))
            *typ2 = 'c';
        else if (token == pk("pa")) {
            parse(pk("ch")); *typ2 = 'p';
        }
        else if (token == pk("bo"))
            *typ2 = 'b';
        else if (token == pk("rl")) {
            *typ2 = 'r'; *aflag = 1;
            *n = 2 * (*n + 1) - 1;        
        }
        else if (token == pk("fl")) {
            *typ2 = 'f';
            // printf("\nGettype, typ2=%c\n",*typ2);
        }
        else {
            error(11); *typ2 = 'i';
        }
    }
        
    
    void variable()    // handle variable (function of block)
    {   
        int typ1, typ2;
        int i, l;
        int aflag, uflag;
        scan();
        do { // main loop variable
            l = 0;
            do {
                decvar('v','i'); l++;  // declare first as integer, change later
            }
            while (token == pk(" ,"));
            testto(pk(" :"));
            gettype(&typ2, &aflag, &uflag, &n);
            if (uflag) error(11);
            if (aflag) typ1 = 'a';
            else typ1 ='v';
            if (typ1 == 'a') { // array
                dpnt = dpnt - l; // variable has been assumed
                for (i = spnt - l + 1; i <= spnt; i++) {
                    t2[i] = dpnt; t3[i] = n;
                    dpnt = dpnt + n + 1;
                }
            }
            for (i = spnt - l + 1; i <= spnt; i++) {
                t0[i] = packed(typ1, typ2);
                if (debugFind) printf("\n*****variable: fix type to %c\n", typ2);
            }
            parse(pk(" ;")); scan();
        }
        while (token == pk("id"));
    }


    void fixup(int x)    // resolve forward reference (page 16)
    {   
        if (ofno != NULL) {
            fprintf(ofno,"%c",'F');
            savebyte(low(x - offset + 1));
            savebyte(high(x - offset + 1));
            savebyte(low(pc - x - 1));
            savebyte(high(pc - x -1));
        }
    }
    
    
    void function()    // handle function (function of block)
    {   
        int n;
        int typ1,typ2;
        int aflag,uflag;
                
        if (token != pk(" :")) {
            aflag = 0; uflag = 0; typ2 = 'i';
            // printf("######## function 1\n");
        }
        else {
            gettype(&typ2,&aflag,&uflag,&n);
            scan();
            // printf("######## function 2, typ1=%c, typ2=%c\n",typ1,typ2);
        }
        if (aflag) {
            typ1 = 's'; t3[cproc+1] = n;
            t2[cproc+1] = t2[cproc+1] - n;
            // printf("######## function 3\n");
        }
        else {
            // printf("######## function 4\n");
            typ1 = 'r';
        }
        t0[cproc+1] = packed(typ1,typ2);
        if (uflag) typ2='u';
        if (aflag) typ1='g'; else typ1='f';
        t0[cproc] = packed(typ1,typ2);
    }
    
    void parameter()    // handle parameter (function of block) page 17
    {
        int counter1, counter2, i, n, bs;
        int aflag, uflag;
        int vtype1, vtype2;
        int vtype;
        push(0); // dummy size, fixed later
        if (find == 0) t3[spnt-npara] = stackpnt;
        else bs = stackpnt;
        counter1 = 0;
        do { // main loop of parameter
            counter2 = 0;
            vtype1 = 'd'; vtype2 = 'i';
            scan();
            if (token == pk("co")) scan();
            else {
                if (token == pk("va")) {
                    scan(); vtype1 = 'w';
                }
            }
            do {  // inner loop of parameter
                decvar(vtype1, vtype2);
                t2[spnt] = parlevel; parlevel++;
                npara++; counter2++;
            }
            while (token == pk(" ,"));
            uflag = 0; aflag = 0; n = 0;
            if (token != pk(" :")) vtype2 = 'i'; // assume integer
            else {
                gettype(&vtype2, &aflag, &uflag, &n);
                if (n > 63) error(15);
                scan();
            }
            if (aflag) {
                vtype1++;
                parlevel = parlevel - counter2;
            }
            vtype = packed(vtype1, vtype2);
            for (i = 1; i <= counter2; i++) {
                if (uflag) push(packed(vtype1, 'u'));
                else push(vtype);
                if (aflag) {
                    push(n); t3[spnt - counter2 + i] = n;
                    t2[spnt - counter2 + i] = parlevel;
                    parlevel = parlevel + n + 1;
                }
                t0[spnt - counter2 + i] = vtype;
                if (debugFind) {
                    printf("\n*****parameter: t0 = %04x\n",
                    vtype);
                }
            }
            if (aflag) counter2 = 2 * counter2;
            counter1 = counter1 + counter2;
        }
        while (token == pk(" ;"));
        testto(pk(" )")); scan();
        if (find == 0) {
          stack[t3[spnt - npara]] = counter1;
        }
        else {
            stack[bs] = counter1;
            n = t3[fortab[find]];       // existing stack data
            // printf("\n*****parameter: find=%d, fortab[find]=%d, n=%d, spnt=%d\n",
            //    find, fortab[find], n, spnt);
            for (i = 0; i <= (stackpnt - bs); i++)
                if (stack[bs + i] != stack[n + i])
                    merror(13, pk("pa"));
            stackpnt = bs - 1;
        } // end find= 0
    } // end of parameter
    
    void memory()    // handle memory (function of block)
    {   
        int typ1, typ2;
        int i, l, n;
        int aflag, uflag;
        scan();
        do {// main loop of memory
            l = 0;
            do {
                decvar('m','i');
                l++; testto(pk(" =")); scan();
                n = getcon(); testtype('i');
                scan(); t2[spnt] = n;                
            }
            while (token == pk(" ,"));
            testto(pk(" :"));
            gettype(&typ2, &aflag, &uflag, &n);
            if (uflag) error(11);
            scan();
            if (token == pk(" &")) {
                typ1 = 'h'; scan();
            }
            else typ1 = 'm';
            if (aflag) typ1++;
            for (i = spnt - l + 1; i <= spnt; i++) {
                t0[i] = packed(typ1, typ2);
                if (debugFind) {
                    printf("\n*****memory: t0 = %04x %c %c\n",
                    t0[i], typ1, typ2);
                }
                t3[i] = n;
            }
            testto(pk(" ;")); scan();
        }
        while (token == pk("id"));
    } // end of memory
    
    void statement()    // handle statement (function of block)
    {   
        int idpnt, relad, k2, savpc, bottom1;
        int device;
        char savtp1, vartyp2;
        int wln;
            
        void code4(int x, int y1, int z1)   // set a 4 byte code
        {  
            int y, z;
            y = y1; z = z1;
            if (y < 0) y += 256;
            if (x == 43) z = z - pc - 2;
            code1(x); code1(y); code1(low(z)); code1(high(z));
        }
    
        void testferror()       //  (function of statement) page 19
        {   
            code1(0x4f);
        }
        
        void gpval(int idpnt, int dir, int typ)  // (function of statement)
        {
            int d;
            
            if (dir) d = 1; else d = 0;
            if (typ == 'h') {
                code3(0x22, t2[idpnt]);
                if (dir) code1 (0x3F);
                code1(0x17 + d);
            }
            else if (typ == 'm') {
                code3(0x22, t2[idpnt]);
                code1(0x3d + d);
            }
            else if (typ == 'i') {
                if (dir) code1(0x3f);
                code3(0x22, t2[idpnt]);
                code1(0x03);
                if (dir) code1(0x3f);
                code1(0x17+d);
            }
            else if (typ == 'n') {
                if  (dir) code1(0x3f);
                code3(0x22, 1); code1(0x12);
                code3(0x22, t2[idpnt]);
                code1(0x03); code1(0x3d+d);
            }
            else
                code4(0x27 + 2 * d + relad, level - t1[idpnt], 2 * t2[idpnt]);
        }
        
        auto void mainexp(char reqtype, int *arsize); // forward reference to nested function
    
        void express()                              // express (function of statement)
        {
            int resultsize;
            // request a normal 16-bit result
            mainexp('n', &resultsize);
            if (resultsize != 0) error(15);
        }
        
        void arrayexp(int size, int eltype) 
        {
            int resultsize;
            mainexp(eltype, &resultsize);
            if (resultsize != size) error(15);
            testtype(eltype);
        }
        
        void getvar()                               // getvar (function of statement) 
        {
            vartyp2 = high(t0[idpnt]);
            vartype = low(t0[idpnt]);
            if (debugFind) printf("\n getvar, vartype =%c\n",vartype);
            switch (vartyp2) {
                case 'a':
                case 'x':
                case 's':
                case 'i':
                case 'n': scan();
                          if (token == pk(" [")) {
                              scan(); express(); relad = 1;
                              if (vartype == 'r') {
                                  relad = 3;
                                 code3(0x22,1); code1(0x12);
                              }
                              checkindex(0, t3[idpnt]);
                              testtype('i');
                              testto(pk(" ]")); scan();
                                                 
                          }
                          else relad = 2;
                          break;
                case 'v':
                case 'w':
                case 'r':
                case 'h':
                case 'm': relad = 0; scan(); break;
                case 'c':
                case 'd':
                case 'e':
                case 't':
                case 'u': error(6); break;
                default: error(1); break;
            }
        }
        
        void prcall(int idpn1)                     // procedure call (page 21)
        {
            int bstack, numpar, i, n, n2;
            
            void prcall1()
            {
            
                void prcall3()                          //  prcall3 (function of prcall1)
                {
                    testto(pk("id"));
                    idpnt = findid();
                    if (idpnt == 0) error(5);
                    getvar();
                    if (low(stack[i]) != vartype) {
                        if (low(stack[i]) != 'u')
                            error(14);
                    }
                    push(idpnt);
                }
            
                // body of prcall1
                switch (high(stack[i])) {
                    case 'd':   express();
                                if (low(stack[i]) != 'u')
                                testtype(low(stack[i]));
                                break;
                    case 'e':   arrayexp(stack[i+1], stack[i]);
                                i++; break;
                    case 'w':   prcall3();
                                if (relad != 0) error(14);
                                gpval(idpnt, 0, vartyp2);
                                break;
                    case 'x':   prcall3();
                                if (relad != 2) error(14);
                                if (vartyp2 == 'i') error(16);
                                i++;
                                if (stack[i] != t3[idpnt]) {
                                    error(15);
                                }
                                if (vartyp2 == 'n') {
                                    code3(P_LITW, t2[idpnt]);
                                    code1(0x3e);
                                }
                                else
                                    code4(0x27, level-t1[idpnt], 2*t2[idpnt]);
                                code2(0x3b, stack[i]);
                                break;
                    default:    error(14); break;
                }  // end switch
                
            } // end prcall1
            
            void prcall2()                                      // prcall2
            {
                if (n > 0) code3(P_INCW, -2*n);
                n = 0;
            }  // end prcall2
            
            // body of prcall
            if (t3[idpn1] != 0) {
                bstack = t3[idpn1];
                numpar = stack[bstack];
                parse(pk(" (")); scan();
                for (i = bstack+1; i <= bstack + numpar; i++) {
                    prcall1();
                    if (i < bstack + numpar) {
                        testto(pk(" ,")); scan();
                    }
                }
                testto(pk(" )"));
            }
            code4(43, level-t1[idpn1], t2[idpn1]);
            if (t3[idpn1] != 0) {
                n = 0; i = bstack + numpar;
                do {
                    switch (high(stack[i])) {
                        case 'd':   n++; break;
                        case 'w':   prcall2(); idpnt = pop();
                                    gpval(idpnt, 1, high(t0[idpnt]));
                                    break;
                        case 0:     n2 = stack[i];
                                    i--;
                                    switch (high(stack[i])) {
                                        case 'e':   n = n+n2+1; break;;
                                        case 'x':   prcall2();
                                                    idpnt = pop();
                                                    if (high(t0[idpnt]) == 'n') {
                                                        code3(0x22,
                                                            t2[idpnt]+2*t3[idpnt]);
                                                        code1(0x3e);                                                    
                                                    }
                                                    else {
                                                        code4(41, level-t1[idpnt],
                                                            2*(t2[idpnt]+t3[idpnt]));
                                                        code2(0x3c, t3[idpnt]);
                                                    }
                                                    break;
                                    } // end switch
                                    break;
                    } // end switch
                    i--;
                }
                while (i != bstack);
                prcall2();
            } // end if t3...
        } // end prcall
    
        void mainexp(char reqtype, int *arsize)
        {
            int opcode, roff;
            char savtype;
            
            void argument(char rtype) {             // argument (function of mainexp)
                parse(pk(" (")); scan(); express();
                testtype(rtype);
                testto(pk(" )")); scan();
            }
            
            void simexp(int *arsize1) {             // simpex (function of mainexp)
                int opcode;                         // page 23
                char sign;
                
                void term(int *arsize2) {            // term (function of simexp)
                    int opcode;
                    
                    void factor(int *arsize3) {      // factor (function of term)
                        int i, idpnt;
                        
                        int index(int chk) {        // index (function of factor)
                            char savtype;
                            int max;
                            if (chk) max = t3[idpnt];
                            scan(); savtype = restype;
                            express(); testtype('i'); testto(pk(" ]"));
                            if (savtype == 'r') {
                                code3(0x22, 1); code1(0x12);
                            }
                            if (chk) checkindex(0, max);
                            restype = savtype; scan();
                        } // end index

                        // body of factor (page 24)
                        *arsize3 = 0;
                        if (token == pk("id")) {    // identifier
                            idpnt = findid();
                            if (idpnt == 0) error(5);
                            restype = low(t0[idpnt]);
                            switch (high(t0[idpnt])) {
                                case 'v':   
                                case 'w':   
                                case 'd':   code4(39 , level - t1[idpnt],
                                                2 * t2[idpnt]);
                                            scan(); break;
                                case 'h':   code3(0x22, t2[idpnt]);
                                            code1(0x17); scan(); break;
                                case 'i':   code3(0x22, t2[idpnt]);
                                            scan();
                                            if (token == pk(" [")) {
                                                index(1); code1(3);
                                                code1(0x17);
                                            }
                                            else error(16);
                                            break;
                                case 'm':   code3(0x22, t2[idpnt]);
                                            code1(0x3d); scan(); break;
                                case 'n':   code3(0x22, t2[idpnt]);
                                            scan();
                                            if (token == pk(" [")) {
                                                index(1);
                                                // printf("\n**** line 1242\n");
                                                code3(0x22, 1);
                                                code1(0x12);
                                                code1(0x03); code1(0x3d);
                                                if (restype =='r') {
                                                    code2(0x3b, 1);
                                                    *arsize3 = 2;
                                                }
                                            }
                                            else {
                                                code1(0x3d);
                                                code2(0x3b,t3[idpnt]);
                                                *arsize3=t3[idpnt];
                                            }
                                            break;
                                case 'r':   
                                case 't':   code3(35, 2);
                                            idpnt = idpnt - 1;
                                            prcall(idpnt); scan();
                                            restype = low(t0[idpnt]);
                                            break;
                                case 'c':   if (low(t0[idpnt] != 'r')) {
                                                code3(34, t2[idpnt]); scan();
                                            }
                                            else {
                                                code2(0x3a, 2);
                                                code2(low(t3[idpnt]),
                                                    high(t3[idpnt]));
                                                *arsize3 = 1; scan();
                                            }
                                            break;
                                case 'a':   
                                case 'e':   
                                case 'x':   scan();
                                            if (token == pk(" [")) {
                                                index(1);
                                                code4(0x28, level - t1[idpnt],
                                                        2*t2[idpnt]);
                                                if (restype == 'r') {
                                                    code2(0x3b, 1);
                                                    *arsize3 = 1;
                                                }
                                            }
                                            else {
                                                code4(0x27, level - t1[idpnt],
                                                        2 * t2[idpnt]);
                                                code2(0x3b, t3[idpnt]);
                                                *arsize3 = t3[idpnt];
                                            } break;
                                case 's':
                                case 'u':   code3(35, 2 * t3[idpnt] + 2);
                                            idpnt--;
                                            prcall(idpnt);
                                            scan();
                                            idpnt++;
                                            *arsize3 = t3[idpnt];
                                            break;
                                default:    printf("\nfactor: illegal ident: %02x\n",
                                                    high(t0[idpnt]));
                                            printf("idpnt =%d\n", idpnt);
                                            printf("t0[idpnt]=%04x\n",t0[idpnt]);
                                            error(1); break;
                            } // end switch
                        } // end identifier
                        else if (token == pk("nu")) {       // number (page 26)
                            code3(34, value[0]); scan();
                            restype = 'i';
                        }
                        else if (token == pk("ru")) {       // real number
                            code2(low(value[0]), high(value[0]));
                            code2(low(value[1]), high(value[1]));
                            scan(); restype = 'r';
                            *arsize3 = 1;
                        }
                        else if (token == pk("st")) {       // string
                            if ((reqtype == 'n') && (value[0] < 3)) {
                                if (value[0] < 2) {
                                    code3(34, ident[1]);
                                    restype = 'c';
                                }
                                else {
                                    code3(34, packed(ident[1], ident[2]));
                                    restype = 'p';
                                }
                            }
                            else {
                                switch (reqtype) {
                                    case 'c':
                                    case 'u':
                                    case 'n':   *arsize3 = value[0] - 1;
                                                restype = 'c';
                                                code2(0x39, value[0]);
                                                for (i=1; i<= value[0]; i++)
                                                    code1(ident[i]);
                                                break;
                                    case'p':    if ((value[0] % 2) == 1)
                                                    error(15);
                                                value[0] = value[0] >> 1;
                                                *arsize3 = value[0] - 1;
                                                restype = 'p';
                                                code2(0x3a, value[0]);
                                                for (i=1; i<=value[0]; i++) {
                                                    code1(ident[2*i]);
                                                    code1(ident[2*i-1]);
                                                }
                                                break;
                                    default: error(14);
                                }
                            }
                            scan();                            
                        }
                        else if (token == pk("od")) {           // odd
                            argument('i'); code1(7);
                            restype = 'b';
                        }
                        else if (token == pk("me")) {           // mem
                            parse(pk(" [")); index(0);
                            code1(23); restype='i';
                        }
                        else if (token == pk(" (")) {           // ()
                            scan();
                            mainexp(reqtype,arsize3);
                            testto(pk(" )")); scan(); // no type change
                        }
                        else if (token == pk("no")) {           // not
                            scan(); factor(arsize3);
                            if (*arsize3 != 0) error(15);
                            code1(0x11);
                            if (restype != 'i') restype='b';
                        }
                        else if (token == pk("cr")) {           // chr
                            argument('i'); code1(52);
                            restype='c';
                        }   
                        else if (token == pk("hi")) {           // high
                            argument('p'); code1(51);
                            restype='c';
                        }
                        else if (token == pk("lo")) {           // low
                            argument('p'); code1(52);
                            restype='c';
                        }
                        else if (token == pk("su")) {           // succ
                            argument('u'); code1(0x14);
                        }
                        else if (token == pk("pc")) {           // prec
                            argument('u'); code1(0x15);
                        }
                        else if (token == pk("ox")) {           // ord
                            argument('u'); restype='i';
                        }
                        else if (token == pk(" @")) {           // @
                            scan(); factor(arsize3);
                            if (*arsize3 != 0) error(15);
                            testtype('i'); restype='f';
                        }
                        else if (token == pk("tr")) {           // true
                            code3(34,1); scan();
                            restype='b'; 
                        }
                        else if (token == pk("fa")) {           // false
                            code3(34,0); scan();
                            restype='b'; 
                        }
                        else if (token == pk("tc")) {           // trunc
                            parse(pk(" (")); scan();
                            arrayexp(1,'r');
                            testto(pk(" )")); scan();
                            code1(0x47); restype = 'i';
                        }
                        else if (token == pk("cv")) {           // conv (int to real)
                            argument('i'); code1(0x46);
                            *arsize3=1; restype='r';
                        }
                        else if (token == pk("pa")) {           // packed
                            parse(pk(" (")); scan(); express();
                            testtype('c');
                            if (token == pk(" ,")) {
                                scan(); express(); testtype('c');
                                code1(53); }
                            testto(pk(" )")); scan(); restype='p';
                            
                        }
                        else {
                            error(1);
                        }
                    } // end factor
                    
                    // body of term  (page 28)
                    factor(arsize2);
                    do {
                        if      (token == pk(" *")) opcode =  5;
                        else if (token == pk("di")) opcode =  6;
                        else if (token == pk("an")) opcode = 15;
                        else if (token == pk("sh")) opcode = 18;
                        else if (token == pk("sr")) opcode = 19;
                        else if (token == pk(" /")) opcode = 0x45;
                        else opcode = 0;
                        if (opcode > 0) {
                            if ((restype == 'r') & (*arsize2 == 1)) {
                                scan(); factor(arsize2);
                                if ((restype != 'r') | (*arsize2 != 1))
                                    error(14);
                                if      (opcode == 0x05) code1(0x44);
                                else if (opcode == 0x45) code1(0x45);
                                else error(17);
                            }
                            else {
                                if (opcode == 0x45) error(9);
                                if (*arsize2 != 0) error(15);
                                if ((restype == 'b') & (opcode == 15)) {
                                    scan(); factor(arsize2);
                                    if (*arsize2 != 0) error(15);
                                    testtype('b'); code1(opcode);
                                }
                                else {
                                    testtype('i'); scan();
                                    factor(arsize2);
                                    if (*arsize2 != 0) error(15);
                                    testtype('i'); code1(opcode);
                                }
                            }
                        }                        
                    }
                    while (opcode != 0);
                } // end term
            
                // body of simexp (page 29)
                sign = ' ';
                if (token == pk(" +")) {
                    sign ='+'; scan();
                }
                else if (token == pk(" -")) {
                    sign = '-'; scan();
                }
                term(arsize1);
                if (sign != ' ') {
                    if ((restype =='r') && (*arsize == 1)) {
                        if (sign == '-') code1(0x4e);
                    }
                    else {
                        testtype('i');
                        if (*arsize1 != 0) error(15);
                        if (sign == '-') code1(2);
                    }
                }
                do {
                    if      (token == pk(" &")) opcode = 1;
                    else if (token == pk(" +")) opcode = 3;
                    else if (token == pk(" -")) opcode = 4;
                    else if (token == pk("or")) opcode = 14;
                    else if (token == pk("xo")) opcode = 16;
                    else opcode = 0;
                    if (opcode > 1) {
                        if ((restype == 'r') && (*arsize == 1)
                                && (opcode != 1)) {
                            scan(); term(arsize1);
                            if ((restype != 'r') | (*arsize != 1))
                                error(17);
                            if (opcode == 3) code1(0x42);
                            else if (opcode == 4) code1(0x43);
                            else error(17);
                        }
                        else {
                            if (*arsize != 0) error(15);
                            if ((restype == 'b') && (opcode >= 14)) {
                                scan(); term(arsize1);
                                if (*arsize1 != 0) error(15);
                                testtype('b');
                                code1(opcode);
                            }
                            else {
                                testtype('i'); scan();
                                term(arsize1);
                                if (*arsize1 != 0) error(15);
                                testtype('i'); code1(opcode);
                            }
                        }
                    }
                    else {
                        if (opcode == 1) {
                            sign = restype;
                            scan(); term(&opcode);
                            *arsize1 = *arsize1 + opcode + 1;
                            testtype(sign);
                        }
                    }
                }
                while (opcode != 0);
            } // end simexp

            // body of mainexp (page 30)
            roff = 0;
            simexp(arsize);
            if ((restype != 'r') && (*arsize == 1))
                roff = 0x40;
            if      (token == pk(" =")) opcode = 8;
            else if (token == pk(" <")) opcode = 10;
            else if (token == pk(" >")) opcode = 12;
            else if (token == pk("<>")) opcode = 9;
            else if (token == pk("<=")) opcode = 13;
            else if (token == pk(">=")) opcode = 11;
            else opcode = 0;
            if (opcode > 0) {
                if ((*arsize != 0) && (roff == 0))
                    error(15);
                scan(); savtype = restype; simexp(arsize);
                if (((roff == 0) & (*arsize != 0))
                        | ((roff != 0) & (*arsize != 1)))
                    error(15);
                testtype(savtype); code1(opcode + roff);
                *arsize = 0; restype = 'b';
            }
        } // end mainexp
    
        void assign()                               // assign (function of statement)
        {                                           // page 30
            int savetype;
            
            void assign1()                          // assign1 (function of assign)
            {
                testto(pk(":=")); scan(); express();
                gpval(idpnt, 1, vartyp2);
            }
        
            // body of assign
            idpnt = findid();
            if (idpnt == 0) error(5);
            if (t0[idpnt] == pk("pr")) {
                prcall(idpnt); scan();
            }
            else {
                getvar(); savetype = vartype;
                if (relad < 2) {
                    assign1(); testtype(vartype);
                }
                else {
                    if (vartyp2 =='i') error(16);
                    testto(pk(":=")); scan();
                    if (relad == 3) {
                        arrayexp(1, vartype); relad = 1;
                        code1(0x53);
                        if (vartyp2 == 'n') {
                            code1(0x3f);
                            code3(0x22,1); code1(0x12);
                            code3(0x22,t2[idpnt] + 2);
                            code1(0x03);  code1(0x3E);
                        }
                        else {
                            code4(0xa2, level - t1[idpnt],
                                2 * t2[idpnt] + 2);
                            code2(0x3c,1);
                        }
                    }
                    else {
                        arrayexp(t3[idpnt], vartype);
                        if (vartyp2 == 'n') {
                            code3(0x22, t2[idpnt] + 2 * t3[idpnt]);
                            code1(0x3e);
                        }
                        else code4(0x29,level-t1[idpnt],
                            2*(t2[idpnt]+t3[idpnt]));
                        code2(0x3c,t3[idpnt]);
                    }
                }
            }
        }
        
        void case1()
        {
            int i1, i2, casave;
            int savetype;
            
            void case2()
            {
                void case3()
                {
                    scan(); code1(22); code3(34,getcon());
                    testtype(savetype);
                    code1(8); scan();
                }
                
                // body of case2
                i1 = 0; case3();
                while (token == pk(" ,")) {
                    push(pc); code3(38,0); i1++;
                    case3();
                }
                testto(pk(" :")); savpc = pc; code3(37,0);
                for (k2 = 1; k2 <= i1; k2++) fixup(pop());
                push(savpc); scan(); statement();
            } // end case2
            
            // body of case1
            scan(); express(); testto(pk("of"));
            savetype = restype; i2 = 1; case2();
            while (token == pk(" ;")) {
                casave= pc; code3(36,0); fixup(pop());
                push(casave); i2++; case2();
            }
            if (token == pk("el")) {
                casave = pc; code3(36,0); fixup(pop());
                push(casave); scan(); statement();
            }
            testto(pk("en"));
            for (k2 = 1; k2 <= i2; k2++) fixup(pop());
            code3(35, -2); scan();
        }
        
        void openrw(int x)      // openrw, page 32
        {
            parse(pk(" (")); parse(pk("id"));
            idpnt=findid();
            if (idpnt==0) error(5);
            getvar(); code1(x);
            testferror();
            if (relad == 2) error(15);
            if (vartype != 'f') error(14);
            gpval(idpnt,1,vartyp2);
            testto(pk(" )"));
            scan();            
        }
        
        // body of statement (original page 33)
        if (token == pk(" ;")) scan();
        
        if (token == pk("id")) assign();
        else if (token == pk("if")) {             // if
            scan(); express(); testtype('b');
            testto(pk("th")); scan(); savpc = pc;
            code3(37, 0); statement();
            if (token == pk("el")) {
                k2 = pc; code3(36,0);
                fixup(savpc); scan(); statement();
                fixup(k2);
            }
            else
                fixup(savpc);
        } // end if
        else if (token == pk("be")) {           // begin (page 33)
            do {
                scan(); statement();
            }
            while (token == pk(" ;"));
            testto(pk("en")); scan();
        }
        else if (token == pk("rp")) {           // repeat
            savpc = pc;
            do {
                scan(); statement();
            }
            while (token != pk("un"));
            scan(); express(); testtype('b');
            code3(37, savpc);
        }  // end repeat
        else if (token == pk("re")) {           // read
            parse(pk(" (")); scan();
            if (token == pk(" @")) {
                scan(); express(); testtype('f');
                device = 1;
                code1(44); testto(pk(" ,"));
            }
            else {
                device = 0;
                code1(26);
            }
            do { // main loop of read
                if (token == pk(" ,")) scan();
                testto(pk("id")); idpnt = findid();
                if (idpnt == 0) error(5);
                getvar();
                if (relad >= 2) error(15);
                if (vartype == 'i')
                    code1(28);
                else if (vartype == 'c')
                    code1(27);
                else if (vartype == 'p') {
                    code1(27); code1(27); code1(53);
                }
                else
                    error(114);
                gpval(idpnt, 1, vartyp2);
            }
            while (token == pk(" ,"));
            testto(pk(" )")); scan();
            if (device) code1(45);
        } // end read
        else if ((token == pk("wr")) || (token == pk("wl"))){    // write (page 34)
            if (token == pk("wl")) wln=1; else wln=0;
            scan();
            if (token == pk(" (")) {
                scan();
                if (token == pk(" @")) {
                    scan(); express(); testtype('f');
                    device = 1; code1(44);
                    testto(pk(" ,"));
                }
                else
                    device = 0;
                do { // main loop for write
                    if (token == pk(" ,")) scan();
                    if (token == pk("st")) {
                        code1(50); // prti
                        for (k2 = 1; k2 <= (value[0] - 1); k2++)
                            code1(ident[k2] & 127);
                        code1(ident[value[0]] | 128);
                        scan();
                    }
                    else {
                        express();
                        if (restype == 'i')
                            code1(30);
                        else if(restype == 'c')
                            code1(29);
                        else if (restype  == 'p') {
                            code1(22); code1(51);
                            code1(29); code1(52);
                            code1(29);
                        }
                        else error(14);
                    }
                }
                while (token == pk(" ,"));
                if (wln) {      // writeln: print cr,lf
                    // printf("*****writeln1\n");
                    code2(32,13); code1(29); code2(32,10); code1(29);
                }
                if (device) code1(45);
                testto(pk(" )")); scan();
            }  // end (
            else if (wln) {      // writeln: print cr,lf
                // printf("*****writeln2\n");
                code2(32,13); code1(29); code2(32,10); code1(29);
            }
        } // end write
        else if (token == pk("cs")) {            // case
            case1();
        }
        else if (token == pk("wh")) {           // while
            scan(); savpc = pc; express();
            testtype('b');
            k2 = pc; code3(37,0);
            testto(pk("do"));
            scan(); statement();
            code3(36, savpc); fixup(k2);
        } // end while
        else if (token == pk("fo")) {           // for
           parse(pk("id")); assign();
           if (t0[idpnt] == pk("pr")) error(1);
           savtp1 = low(t0[idpnt]);
           if (token == pk("to")) k2 = 1;
           else if (token == pk("dw")) k2 = 0;
           else merror(2, pk("to"));
           scan(); express(); testtype(savtp1);
           bottom1 = pc; code1(22);
           gpval(idpnt, 0, vartyp2);
           code1(13-k2-k2);
           savpc = pc; code3(37,0);
           testto(pk("do")); scan(); statement();
           gpval(idpnt, 0, vartyp2);
           code1(21-k2);
           gpval(idpnt, 1, vartyp2);
           code3(36, bottom1); fixup(savpc);
           code3(35, -2);
        } // end for
        else if (token == pk("me")) {           // mem
            parse(pk(" [")); scan(); express();
            testtype('i');
            testto(pk(" ]")); parse(pk(":="));
            scan(); express(); code1(24);
            testtype('i');
        }  // end mem
        else if (token == pk("ca")) {           // call
            parse(pk(" (")); scan(); express();
            testtype('i');
            testto(pk(" )")); code1(25); scan();
        }  // end call
        else if (token == pk("op")) openrw(47);     // openr
        else if (token == pk("ow")) openrw(48);     // openw
        else if (token == pk("ob")) openrw(0x50);   // openb
        else if (token == pk("gp")) {               // gb        #######
            printf("\n*** gb not yet implemented\n");
            exit(1);
        }
        else if (token == pk("gp")) {               // pb        #######
            printf("\n*** pb not yet implemented\n");
            exit(1);
        }        
        else if (token == pk("ru")) {              // run
            code1(0x41); scan();
        }
        else if (token == pk("fi")) {               // fi (filnam) #######
            printf("\n*** fi not yet implemented\n");
            exit(1);
        }
        else if (token == pk("ge")) {               // ge (getsector) ######
            printf("\n*** ge not yet implemented\n");
            exit(1);
        }
        else if (token == pk("pu")) {               // pu (putsector) ######
            printf("\n*** pu not yet implemented\n");
            exit(1);
        }        
        else if (token == pk("cl")) {              // close
            parse(pk(" ("));
            do {
                scan(); express(); code1(49);
                testtype('f');
                testferror();
            } while (token == pk(" ,"));
            testto(pk(" )")); scan();
        }
        
        else {
            if ((token != pk("en")) && (token != pk(" ;"))
                    && (token != pk("un"))) {
                error(10);
                scan();
            }
        }  // case of statements
    }  // end statement
    
    int findforw()              // (function of block, page 37)
    {
        int i0, j, sav1, result;
        
        int compare(char *s1, char *s2)
        {
            int ii = 0;
            if (debugForw) {
                printf("\n***** Compare, i0=%d, s1=", i0);
                for (int i9 = 0; i9 < 8; i9++)
                    printf("%c",s1[i9]);
                printf(", s2=");
                for (int i9 = 0; i9 < 8; i9++)
                    printf("%c",s2[i9]);
            }
            do {ii++;
            }
            while ((ii < 8) && (s1[ii] == s2[ii]));
            if (debugForw)
                printf(", ii = %d, returns %d\n", ii, ii < 8);
            return (ii < 8);
        }
        
        i0 = forwpn + 1;
        do i0--;
        while ((i0 > 0 ) && (compare(&ident[0],&idTable[8*fortab[i0]]) != 0));
        if (debugForw) printf("***** Findforw1, i0=%d, forwp=%d\n", i0, forwpn);
        result = i0;
        if (i0 > 0) {
            if (i0 == forwpn) forwpn--;
            else {
                sav1 = fortab[i0];
                for (j = i0; j < forwpn; j++)
                    fortab[i0] = fortab[i0] + 1;
                fortab[forwpn] = sav1;
                result = forwpn;
                forwpn--;
            }
        }
        if (debugForw) printf("***** Findforw2, forwp=%d, spnt=%d, returns %d\n",
          forwpn, spnt, result);
        return(result);
    }
        
    
    // body of block (page 37)
    
    // printf("###### Start of block, token = %c%c\n", high(token), low(token));
    
    dpnt = 3;
    t2[bottom] = pc;
    code3(36,0);
    stackpn1 = stackpnt; forwpn = 0;
    
    if (token == pk("co")) {             // *** const ***
        scan();
        do {
            deccon(); testto(pk(" ;")); scan();
        }
        while (token == pk("id"));
    }
    
    if (token == pk("me")) memory();    // *** mem ***
    
    if (token == pk("va")) variable();  // *** var ***
    
    while ((token == pk("pr")) || (token == pk("fu"))) {
        parlevel = 0;
        if (token == pk("pr")) {        // *** proc ***
            parse(pk("id")); npara = 0;
            putsym('p','r'); cproc=spnt;
            level++;
        }
        else if (token == pk("fu")) {   // ***func ***
            parse(pk("id")); npara = 1;
            putsym('f','i');
            cproc = spnt; level++;
            putsym('f','i');
            t2[spnt] = parlevel;
            parlevel++;
        }
        if (forwpn == 0) find = 0;
        else find =findforw();
        if (find != 0) {
            if (debugForw)
                printf("\n*****block1: spnt=%d, find=%d\n", spnt, find);
            spnt = spnt - npara - 1;
            if (debugForw)
                printf("\n*****block2: spnt=%d\n", spnt);
            cproc = fortab[find];
            fixup(t2[cproc]);
        }
        scan(); spnt1 = spnt;
        dpnt1 = dpnt;
        if (token == pk(" (")) parameter();
        if (t0[cproc] == pk("fi")) function();
        testto(pk(" ;"));
        for (i = 1; i <= npara; i++)
            t2[spnt - i + 1] -= parlevel;
        scan();
        if (token == pk("fw")) {
            if (forwpn == 8) merror(13, pk("ov"));
            forwpn++;
            fortab[forwpn] = cproc;
            t2[cproc] = pc;
            code3(P_JUMP, 0);
            scan();
        }
        else block(cproc);
        level--;
        dpnt = dpnt1; spnt = spnt1;
        if (high(t0[spnt]) == 'r') t0[spnt] = packed('t', low(t0[spnt]));
        else if (high(t0[spnt]) == 's') t0[spnt] = packed('u', low(t0[spnt]));
        testto(pk(" ;")); scan();
    }  // end procedure or function
    testto(pk("be"));                        // ***program***
    if (forwpn != 0) merror(13,pk("ur"));
    scan(); fixup(t2[bottom]);
    t2[bottom] =pc;
    code3(P_INCW, 2 * dpnt);
    do statement();
    while (token != pk("en"));
    scan();
    
    if (level > 0)
        code1(1);
    else
        code1(0);
    stackpnt = stackpn1;
} // end of block


/*****************/
void loadResWords()
/*****************/
{
    char resw[RESWLENGHT];
    char rescod[3];

    FILE *fresw;
    char *s = "reswords.txt";
    fresw = fopen(s, "r");
    if (fno == NULL) {
        printf("Cannot open %s\n",s);
        closeAndExit();
    }
    numResw = 0;
    while ((!feof(fresw)) && (numResw < MAXRESW)) {
        fscanf(fresw, "%2s %9s\n", rescod, resw);    // RESWLENGHT - 1!
        strcpy(&reswTb[numResw][0], resw);
        reswCd[numResw] = packed(rescod[0], rescod[1]);
        numResw++;
    }
    // for (int i = 0; i < numResw; i++)
    //    printf("%c%c - %s\n", high(reswCd[i]), low(reswCd[i]),reswTb[i]);
}


/*************/
void savtable()
/*************/
// save library address table
{
    int i, j,addr, num;
    char vt, chr;
    
    fprintf(ofno, "%d,%d\n", spnt, pc + 2);
    for (i = 1; i <= spnt; i++) {
        for (j = 1; j <= 8; j++) {
            chr = idTable[8 * i + j];
            if (chr == 0) chr = ' ';            // this needs probably to be changed
            fprintf(ofno, "%c", chr);
        }
        fprintf(ofno, " %c%c,%d,%d,%d", high(t0[i]), low(t0[i]), t1[i], t2[i], t3[i]);
        vt = high(t0[i]);
        if ((vt=='p') || (vt=='f') || ((vt=='g') && (t3[i]!=0))) {
            num = stack[t3[i]];
            if (t3[i] > 0) {
                fprintf(ofno, ",%x", num);
                for (j = 1; j <= num; j++)
                    fprintf(ofno, ",%d", stack[t3[i] + j]);
            }
        }
        fprintf(ofno, "\n");
    }
}

/******************************/
int main(int argc, char *argv[])
/******************************/
{
    char s[64];

    printf("compile version 1.0\n");
    
    if (argc != 2) {
        printf("Usage: compile filename\n");
        closeAndExit();
    }
    
    sprintf(s,"%s.pas", argv[1]);
    fno = fopen(s, "r");
    if (fno == NULL) {
        printf("Cannot open %s\n",s);
        closeAndExit();
    }
    
    sprintf(s,"%s.print", argv[1]);
    oprt = fopen(s, "w");
    if (oprt == NULL) {
        printf("Cannot open %s\n",s);
        closeAndExit();
    }
    
    loadResWords();
    
    init();
    
    getchr();
    
    scan();
    
    if (token == pk("pg")) {   // must be program or library
        libflg = 0;
        sprintf(s,"%s.pa1", argv[1]);
    }
    else if (token == pk("li")) {
        libflg = 1; filstp = 'R';
        sprintf(s,"%s.li1", argv[1]);
    }
    else merror(2, pk("pg"));
    
    ofno = fopen(s, "w");       // open output file (.pa1 or .lb1)
    if (ofno == NULL) {
        printf("Cannot open %s\n",s);
        closeAndExit();
    }    
    
    parse(pk("id"));     // name of program or library
    parse(pk(" ;"));
    strcpy(prgname, ident+1);
    scan();

    // library
    
    if ((token == pk("us")) && (libflg == 0)) {   // uses library
        do {
            getlib(); scan();
        }
        while (token == pk(" ,"));
        testto(pk(" ;")); scan();
    }
    
    block(0); testto(pk(" ."));
    
    if (ofno != NULL) {
        fprintf(ofno, "%c", 'E');
        savebyte(low(pc));
        savebyte(high(pc));
        fclose(ofno); ofno = NULL;

        if (libflg) {
            char s1[IDLENGHT+4];
            // printf("\n\nWriting library ident list of %s\n", prgname);
            sprintf(s1,"%s.lib", prgname);
            ofno = fopen(s1, "w");
            if (ofno == NULL) {
                printf("Cannot open %s\n",s1);
                closeAndExit();
            }
            savtable();
            if (ofno != NULL)
                fclose(ofno); ofno = NULL;           
        }
    }
    
    printf("\n\nEnd compile\n");
    printf("Code length:         %5d bytes\n", pc);
    printf("Compiler stack size   %4d words\n", stackmax);
    printf("Ident stack size      %4d idents\n", spntmax);
    printf("Pascal errors         %4d\n",numerr);
    
    if (oprt != 0) {
        fprintf(oprt, "\n\nEnd compile\n");
        fprintf(oprt, "Code length          %5d bytes\n", pc);
        fprintf(oprt, "Compiler stack size   %4d words\n", stackmax);
        fprintf(oprt, "Ident stack size      %4d idents\n", spntmax);
        fprintf(oprt, "Pascal errors         %4d\n",numerr);
    }

    if (fno != NULL)
        fclose(fno);
    if (ofno != NULL)
        fclose(ofno);
    if (oprt != NULL)
        fclose(oprt);
    if (libfno != NULL)
        fclose(libfno);
    exit (0);
    
}
