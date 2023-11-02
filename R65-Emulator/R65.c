// R65 - Emulator
//
// rricharz 2018-2023
//
// Emulates the hardware of the R65 computer
// system built 1977 - 1982
// by R. Richarz and R. Baumann
//
// It is based on a KIM-1 board with 6502 Microprocessor
// a home built CRT controller board
// a home built floppy disk controller board
// A total of 64K memory
//
// This is not a KIM-1 emulator!
// Even so the KIM-1 ROM is used, the emulator only
// supports the hardware of the KIM-1 board, which
// is used by the R65 disk operating system
// Specifically, the KIM-1 timers, display and
// hex keyboard are currently NOT emulated
//
// Copyright 2018 rricharz <rricharz77@gmail.com>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
// MA 02110-1301, USA.


#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "time.h"
#include "main.h"
#include "R65.h"
#include "fake6502.h"
#include "crt.h"
#include "fdc.h"
#include "exdisp.h"

int pendingNMI              = 0;
int pendingIRQ              = 0;
int keyboardIrqEnabled      = 0;

const char *mnemonic[] = {           // p-codes
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

uint8_t memory[65536];
int timeOfSpMin;
int timeOfPascalMin;

int spMin;              // minimum value of sp during execution
int pascalMinFree;      // minimal value of pascalFreeStack

int rawPrint = 0;       // for Tektronix plotter

// source input file
FILE *sourceFile;
#define M_INBUFF 0x0000 // assembler input line
#define M_INBFPN 0x64   // input end pointer

// printout file
FILE *printFile;
int colNumber               = 0;   // count characters in a line
int lastPrintedCharacter    = 0;
int savedCrtAdr             = 0;
int curLocLow               = 0;

int dotrace = 0;        // pascal user program tracer

int checkEventCounter = 0;
clock_t lastCrtSync = 0;


/********************/
void checkMinTimeout()
/********************/
{
    // keep displayed figures for 5 seconds, then reset
    int now = time(NULL) % 86400;
    if ((now - timeOfSpMin) > 5) {
        spMin = sp;
        timeOfSpMin = now;
        global_pendingCrtUpdate = 1;
    }
    if ((now - timeOfPascalMin) > 3) {
        if (memory[M8_SFLAG] & 1) {
            int pascalSp = memory[0x0a] + (memory[0x0b] << 8);
            int pascalEndstk = memory[0x0e] + (memory[0x0f] << 8);
            pascalMinFree = pascalEndstk - pascalSp;
            timeOfPascalMin = time(NULL) % 86400;
        }
        else {
            pascalMinFree = 0xFFFF;
            timeOfPascalMin = time(NULL) % 86400; 
        }
    }
}


/**********************************/
uint8_t read6502_8(uint16_t address)
/**********************************/
// read a 8 bit number from memory. No handling of memory mapped io
{
    return memory[address];
}

/************************************/
uint16_t read6502_16(uint16_t address)
/************************************/
// read a 16 bit number from memory. No handling of memory mapped io
{
    return (memory[address] | (memory[address + 1] << 8));
}

/***********************/
int translateKey(int key)
/***********************/
// keyboard key code translation linux to R65
{
    int chr;
    switch (key) {
        case 0xFF08: chr = 0x5F; break;     // backspace key
        case 0xFF09: chr = 0x08; break;     // tab key
        case 0xFF51: chr = 0x03; break;     // cursor left key
        case 0xFF53: chr = 0x16; break;     // cursor right key
        case 0xFF52: chr = 0x1A; break;     // cursor up key
        case 0xFF54: chr = 0x18; break;     // cursor down key
        case 0xFFFF: chr = 0x19; break;     // del key
        case 0xFEFF: chr = 0x15; break;     // shift del key: insert
        case 0xFF0D: chr = 0x0D; break;     // return key
        case 0xFF1B: chr = 0x91; break;     // escape key
        case 0xFF50: chr = 0x01; break;     // home key
        case 0xFF55: chr = 0x08; break;     // page up key: roll up
        case 0xFF56: chr = 0x02; break;     // page down key: roll down
        case 0xFF57: chr = 0x10; break;     // end key
        default: {
            if (key & 0xFF00)                           // ignore all other special keys
                chr = 0;
            else if ((key >= 0x61) && (key <= 0x7A)) {  // translate all chars to upper case
                if (NUMCHAR==48) chr = (key - 0x20);
                else chr = key;
                }
            else
                chr = key;
        }
    }
    // printf("translate %04X > %04X\n", key, chr);
    return chr;
}

/************************/
uint8_t bcd(uint8_t value)
/************************/
// convert to bcd
{
    int dig0 = value % 10;
    int dig1 = (value / 10) % 10;
    return (16 * dig1 + dig0);
}

/*******************/
void setDateAndTime()
/*******************/
{
    // get system date and time
    time_t sysTime = time(NULL);
    struct tm systm = *localtime(&sysTime);
    int year = systm.tm_year % 100;
    int month = systm.tm_mon + 1;
    int day = systm.tm_mday;
    int hours = systm.tm_hour;
    int minutes = systm.tm_min;
    int seconds = systm.tm_sec;
    // make it available
    memory[M8_DATE] = bcd(day);
    memory[M8_DATE + 1] = bcd(month);
    memory[M8_DATE + 2] = bcd(year);
    memory[M8_TIME] = 0;
    memory[M8_TIME + 1] = bcd(seconds);
    memory[M8_TIME + 2] = bcd(minutes);
    memory[M8_TIME + 3] = bcd(hours);
}

/********************************/
uint8_t read6502(uint16_t address)
/********************************/
// read a byte from memory
// handles memory mapped io

{
    // pascal user program tracer (slow!)
    /*
    if (address == 0x29b9) {  // EXCODE ADDRESS
        int ipc = memory[0xa] + (memory[0xb] << 8);
        int pcode = memory[ipc];
        if (pcode == 0x41) {      // pcode RUNP turns tracer on
            dotrace = 1;
            printf("Starting Pascal user program\n");
        }
        else if (pcode == 0) {    // pcode STOP turns tracer off
            dotrace = 0;
            printf("Stopping Pascal user program\n");
        }
        else if (dotrace) {
            int stprog = memory[0x11] + (memory[0x12] << 8);
            printf("%05d PCODE=%02d(0x%02x) ", ipc - stprog + 2,pcode, pcode);
            if ((pcode >=0) && (pcode < sizeof(mnemonic) / sizeof(mnemonic[0])))
                printf("%s ", mnemonic[pcode]);
            int x;
            switch (pcode) {
                case 0x24:  x = (memory[ipc+2] << 8) + memory[ipc+1] + ipc - stprog + 3;
                            if (x > 32768) x -= 65536;
                            printf("%05d", x);
                            break;
            }
            
            printf("\n            ");
            printf("ACCU=%02x%02x, SP=%02x%02x, PC=%02x%02x, ABASE=%02x%02x, BASE=%02x%02x\n",
                memory[0x1],memory[0x0],memory[0x9],memory[0x8],memory[0xb],memory[0xa],
                memory[0x1a],memory[0x19],memory[0x18],memory[0x17]);
        }
    } */
    
    // optimization for speed, only check addresses in the io area
    // otherwise return right away
    
    if (address < 0x1400)
        return memory[address];
    else if (address >= 0x1800)
        return memory[address];
        
    // Update date and time.
    // Important, read memory[M8_DATE] first to update
    // date and time!
    
    if (address == M8_DATE)
        setDateAndTime();
    
    // floppy disk controller
    
   if ((address >= R8_FDSTAT) && (address <= R8_FDDAT))
        return fdc_read(address);    
    
    // Hardware multiplier
    
    else if (address == R16_MULTR) {
        memory[R16_MULTR] = (memory[0x14E0] * memory[0x14E1]) & 0xFF;
    }
    else if (address == R16_MULTR + 1) {
        memory[R16_MULTR + 1] = (memory[0x14E0] * memory[0x14E1]) >> 8;
    }
    
    // Hardware timer 1, count down miliseconds

    else if (address == R8_TMSEC) {
        if (memory[R8_TMSEC] >= 0) {
            usleep(1000);                   // this is not an exact implementation
            memory[R8_TMSEC]--;
        }
    }
    
    // Keyboard
    
    else if (address == M8_CHAR) {
        if (memory[address] == 0) {         // no char there, wait
            if (pendingNMI || pendingIRQ)   // do not wait for key if nmi or irq pending
                return(0);
            crtUpdate();                    // update screen bevore waiting for events
            checkPendingEvents();
            usleep(10000);                  // avoid 100% cpu usage during waiting for key
            checkMotorTurnoff(1);
            checkMinTimeout();
        }
    }
        
    else if ((address >= 0x1440) && (address <= 0x177F)) {
        if (address == KIM_PORTA2) {
            memory[address] = translateKey(global_char);
            global_char = 0;
            memory[KIM_IFR2] = 0x00;    // clear level 2 interrupt from KIM 6522-2, keyboard interrupt
            // printf ("Reading from KIM-1 PORTA2 register, pc=%04X, value=%02X\n",pc-3, memory[address]);
        }
        else if (address == EMU_RAND) {
            int rnd = (rand() & 255);
            return(rnd);
        }
        /*
        else if (address == KIM_IFR1) {
            printf ("Reading from KIM-1 IFR1 register, pc=%04X, value=%02X\n", pc - 3, memory[address]);
        }
        else if (address == KIM_IER1) {
            printf ("Reading from KIM-1 IER1 register, pc=%04X, value=%02X\n", pc - 3, memory[address]);
        }
        else if (address == KIM_IFR2) {
            printf ("Reading from KIM-1 IFR2 register, pc=%04X, value=%02X\n", pc - 3, memory[address]);
        }
        else if (address == KIM_IER2) {
            printf ("Reading from KIM-1 IER2 register, pc=%04X, value=%02X\n", pc - 3, memory[address]);
        }
        else if (address == KIM_IFR3) {
             printf ("Reading from KIM-1 IFR3 register, pc=%04X, value=%02X\n", pc - 3, memory[address]);
        }
        else if (address == KIM_IER3) {
            printf ("Reading from KIM-1 IER3 register, pc=%04X, value=%02X\n", pc - 3, memory[address]);
        }
        */
    }
    
    return memory[address];
}

/***********************************************/
void write6502_8(uint16_t address, uint8_t value)
/***********************************************/
// write 8 bits to memory. No handling of memory mapped io
{
    memory[address] = value;
}

/************/
int mousepad()
/************/
{
int i, end, filtyp, filstp;
    char *extension;
    char s[24];
    char name[80];
    char estring[80];
    
    // printf("Edit called\n");
    
    filtyp = memory[M8_FILTYP];
    // printf("Filtyp = %c\n", filtyp);
    if (filtyp != 'S')
        return (5);         // must be sequential file
        
    filstp = memory[M8_FILSTP];
    // printf("Filstp = %c\n", filstp);
    if (filstp == 'A')
        extension = ".asm";
    else if (filstp == 'P')
        extension = ".pas";
    else
        extension = ".txt";
    
    i = 15;
    while ((memory[M8_FILNAM+i] == ' ') && (i > 0) )    // find end of file name
        i--;
    end = i + 1;
    
    for (i = 0; i < end; i++) {
        
        if (memory[M8_FILNAM+i] == ':') {               // remove :
            s[i]=' ';
            end = i;
        }
        else
            s[i] = memory[M8_FILNAM+i];
            
        if ((s[i] >= 'A') && (s[i] <= 'Z'))             // convert to small letters
            s[i] = s[i] + 0x20;
    }
    
    s[end] = 0;                                         // add end of string mark
    sprintf(name, "Files/%s%s", s, extension);
    // printf("Editing %s\n", name);
    
    // execute mousepad command
    sprintf(estring, "mousepad Files/%s%s", s, extension);
    printf("Running %s, waiting for completion\n", estring);   
    int res = system(estring);
    // printf("result =%d\n", res);
    if (res)
        return (0X68);
    else
        return 0;
}

/*********************************************/
void write6502(uint16_t address, uint8_t value)
/*********************************************/
// write a byte to memory
// handles memory mapped io
{
    
    if (address < 0x400) {
        memory[address] = value;
        return;
    }
    else if (address>=0x2000) {
        if (address>=0xe000) {
            printf("writing into EPROM address space not allowed\n");
            return;
        }
        //else if ((address>=0xc800) && (address<=0xd5ff)) {
        //    printf("writing into EXDOS address space not allowed\n");
        //    printf("pc=%04x, address=%04x\n",pc,address);
        //    return;
        // }
        else {
            memory[address] = value;
            return;
        }
    }
    
    else if (address>=0x1800) {
            printf("writing into KIM ROM address space not allowed\n");
            return;
        }
    
    // video memory updated
    
    if ((address >= 0x0400) && (address <= 0x13FF)) {
        memory[address] = value;
        global_pendingCrtUpdate = 1;
        return;
    }
    
    // video memory offset updated
    
    else if (address == M8_OFFSET) {
        memory[address] = value;
        global_videoBaseAddress = M_CRTMEM + (value * NUMCHAR);
        global_pendingCrtUpdate = 1;
        return;
    }

    // floppy disk controller
    
    else if ((address >= R8_FDCOM) && (address <= R8_FDDAT)) {
        memory[address] = value;
        fdc_write(address, value);
        return;
    }
    
    // 7 segment led display register
    
    else if ((address >= RS8_LED) && (address <= (RS8_LED+8))) {
        memory[address] = value;
        global_pendingCrtUpdate = 1;
        return;
    }
    
    // emulator command register
    
    if (address == R8_EMUCOM) {
        if (value == 1) {
            memory[R8_EMURES] = export_file();  // export and set result
            memory[R8_EMUCOM] = 0;          // and clear command
        }
        else if (value == 2) {
            memory[R8_EMURES] = import_file();  // import and set result
            // printf("EMURES=%d\n",memory[R8_EMURES]);
            memory[R8_EMUCOM] = 0;          // and clear command
        }
        else if (value == 3) {
            memory[R8_EMURES] = mousepad();  // execute mousepad
            memory[R8_EMUCOM] = 0;          // and clear command
        }
        else if (value == 4) {
            memory[R8_EMURES] = change_floppy(); // execute change floppy
            memory[R8_EMUCOM] = 0;          // and clear command
        }
        else if (value == 5) {
            int pascalSp = memory[0x0a] + (memory[0x0b] << 8);
            int pascalEndstk = memory[0x0e] + (memory[0x0f] << 8);
            int now = time(NULL) % 86400;
            if ((pascalMinFree > pascalEndstk - pascalSp)
                || ((now - timeOfPascalMin) > 5)){
                pascalMinFree = pascalEndstk - pascalSp;
                timeOfPascalMin = time(NULL) % 86400;
            }
        }
        else if (value == 6) {              // wait 10 msec
            if (global_pendingCrtUpdate)
               crtUpdate();                 // update screen if necessary
            checkPendingEvents();
            usleep(10000);              // avoid 100% cpu usage during wait
            checkMotorTurnoff(2);
            checkMinTimeout();
            memory[R8_EMURES] = 0;
            memory[R8_EMUCOM] = 0;
        }
        else if (value == 7) {              // sync screen and wait 30 msec
                                            // since last call
            int sleepmicros = lastCrtSync - clock() + 30000;
            if ((sleepmicros > 0) && (sleepmicros < 30000))
                usleep(sleepmicros);
            else
                sleepmicros = 0;
            lastCrtSync = clock();
            checkEventCounter = -20000;
            crtUpdate();
            memory[R8_EMURES] = sleepmicros / 1000;
            memory[R8_EMUCOM] = 0;
        }
        else if (value == 8) {              // start listing
            int i,end;
            char s[32],name[32];
            if (printFile)
                fclose(printFile);                
            i = 15;
            while ((memory[M8_FILNAM+i] == ' ') && (i > 0) )    // find end of file name
                i--;
            end = i + 1;    
            for (i = 0; i < end; i++) {        
                if (memory[M8_FILNAM+i] == ':') {               // remove :
                s[i]=' ';
                end = i;               
                }
                else
                    s[i] = memory[M8_FILNAM+i];
            
            if ((s[i] >= 'A') && (s[i] <= 'Z'))             // convert to small letters
                s[i] = s[i] + 0x20;
            }    
            s[end] = 0;                                         // add end of string mark
            sprintf(name, "Listings/%s.txt", s);
            printf("Writing listing to %s\n", name);
            printFile = fopen(name,"w");
            if (printFile == NULL)
                printf("Cannot open %s\n",s);
        }
        else if (value == 9) {              // end listing
            printf("Closing listing\n");
            if (printFile)
                fclose(printFile);
            char *s = "printout.txt";
            printFile = fopen(s,"w");
            if (printFile == NULL)
                printf("Cannot open %s\n",s);            
        }
        else {
            printf("Unknown emulator command %02X, pc=%04X\n", value, pc-3);
        memory[R8_EMURES] = 0X67;           // set result to 0
        memory[R8_EMUCOM] = 0;              // and clear command
        }
        return;
    }
        
    // video controller registers
    
    else if (address == R8_CRTADR) {
        memory[address] = value;
        savedCrtAdr = value;
    }
    else if (address == R8_CRTDAT) {
        memory[address] = value;
        // printf("Writing to CRTDAT, CRTADR=%02X, CRTDAT=%02X\n", savedCrtAdr, value);
        if (savedCrtAdr == 1) {
            // printf("Setting chars per line to %2d, pc=%04X (not implemented)\n", value, pc-3);
        }
        else if (savedCrtAdr == 0xA) {
            // printf("Disabling/enabling cursor %02X, pc=%04X (not implemented)\n", value, pc-3);
        }
        else if (savedCrtAdr == 0xF) {
            // printf("curloc %02X, pc=%04X (not yet implemented)\n", value, pc-3);
            curLocLow = value;
        }
        else if (savedCrtAdr == 0xE) {
            global_curloc = (256 * value) + curLocLow;
            // printf("Setting curloc %04X, pc=%04X\n", global_curloc, pc-3);
            global_pendingCrtUpdate = 1;
        }
        else if (savedCrtAdr == 0x6) {
            if (value == 118) {             // graphics mode
                if (global_graphicsFlag == 0) global_pendingCrtUpdate = 1;
                global_graphicsFlag = 1;
           }
            else {                          // alpha mode
                if (global_graphicsFlag != 0) global_pendingCrtUpdate = 1;
                global_graphicsFlag = 0;
           }
        }
    }
        
    // KIM-1 registers
    
    else if ((address >= 0x1440) && (address <= 0x177F)) {
        memory[address] = value;
        if (address == KIM_IER2) {
            if (value & 0x82) {
                // printf("*** keyboard interrupt enabled, pc=%04X\n", pc - 3);
                keyboardIrqEnabled = 1;
            }
            else {
                // printf("*** keyboard interrupt disabled pc=%04X\n", pc - 3);
                keyboardIrqEnabled = 0;
            }
        }
        /*
        if (address == KIM_IFR1) {
            printf ("writing to KIM-1 IFR1 register, pc=%04X, value=%02X\n", pc - 3, value);
        }
        else if (address == KIM_IER1) {
            printf ("writing to KIM-1 IER1 register, pc=%04X, value=%02X\n", pc - 3, value);
        }
        else if (address == KIM_IFR2) {
            printf ("writing to KIM-1 IFR2 register, pc=%04X, value=%02X\n", pc - 3, value);
        }
        else if (address == KIM_IFR3) {
            printf ("writing to KIM-1 IFR3 register, pc=%04X, value=%02X\n", pc - 3, value);
        }
        else if (address == KIM_IER3) {
            printf ("writing to KIM-1 IER3 register, pc=%04X, value=%02X\n", pc - 3, value);
        }
        */
    }
    
    else
        memory[address] = value;
}

/*******************/
void printRegisters()
/*******************/
{
    printf("6502 registers: pc=%04X sp=%02X a=%02X, x=%02X, y=%02X, status=%2X\n", pc, sp, a, x, y, status);
}

/*************************/
void setKeyboardInterrupt()
/*************************/
{
    pendingIRQ = 1;
    memory[KIM_IFR2] = 0x82;    // set level 2 interrupt from KIM 6522-2, keyboard interrupt
    // printf("Keyboard interrupt set, global_char =%04X\n", global_char);
}

/******************************/
int catchSubroutine(uint16_t ea)
/******************************/
{
    if (ea == 0xE95E) {
        // printf("******** IO: PRTRSA (print to rs232) called, currently implemented in emulator\n");
        if ((a == 0x12) && rawPrint) {         // device control 2, switch to normal mode
                printf("Printer switched to normal mode\n");
                rawPrint = 0;
                return 1;
            }
        if ((lastPrintedCharacter == 0x1B) && (!rawPrint)) {   
            // ignore printer control characted
            lastPrintedCharacter = 0;
            return 1;
        }
        if ((a < 0x20) && (!rawPrint)) {       // produce a linux style text file
            if (a == 0x0D) {                   // linux text files have no cr, change for windows
                return 1;
            }
            if (a == 0x11) {                   // device control 1, switch to raw mode
                printf("Printer switched to raw mode\n");
                rawPrint = 1;
                return 1;
            }
            if (a == 0x14) {                   // ignore printer control character
                return 1;
            }
            if (a == 0x1B) {                   // ignore printer control character, also next one
                lastPrintedCharacter = 0x1B;
                return 1;
            }
            if (a == 0x12) {                   // bell, ignore
                return 1;
            }
            if (a == 0x09) {                   // tab8
                while (colNumber & 0x07) {
                    fprintf(printFile," ");
                    colNumber++;
                }
                return 1;
            }
            if ((a == 0x0e) || (a == 0x0b)) {  // invvid,norvid, do nothing
                return 1;
            }
            if (a == 0x0C) {                   // new page: simulate page break
                fprintf(printFile, "\n-----------------------------------");
                fprintf(printFile, "-----------------------------------\n");
                return 1;
            }
            if (a == 0x0A) {                   // new line
                fprintf(printFile, "%c", a);
                fflush(printFile);             // required if emulator is not properly terminated
                colNumber = 0;
                return 1;
            }
            fprintf(printFile, ">%02X<", a);
        }
        else {
            fprintf(printFile, "%c", a);
            if (rawPrint /*&& (a < 0x20)*/) fflush(printFile);
            colNumber++;
        }
        return 1;
    }
    else if (ea == 0xE827) {    // TDELAY set to 0 in emulator
        // printf("******** IO: TDELAY currently not implemented, should it?\n");
        return 1;
    }  
    return 0;
}

/*********************************************/
void store(int address, int data, int storeFlag)
/**********************************************/
{
    if (storeFlag) {
        memory[address] = data;
    }
    else {
        if (memory[address] == 0)  // do not check empty memory
            return;
        if (memory[address] != data)
            printf("Difference: memory[%04X] = %02X, new data = %02X\n", address, memory[address], data);
    }
}

/*********************************************/
int loadCodeFromListing(char* s, int storeFlag)
/*********************************************/
{
    // open the listing file
    
    FILE *codeFile;
    codeFile = fopen(s,"r");
    if (codeFile == NULL) {
	printf("Cannot open %s\n",s);
        exit(1);
	}
    
    printf("Extracting code from %s\n", s);
    
    // store the codes in memory
    
    int     address;
    int     data;
    
    char *lineBuffer;
    size_t bufSize = 32;
    size_t numChars;
    
    lineBuffer = (char *) malloc(bufSize * sizeof(char));
    
    if (lineBuffer == NULL) {
        printf("unable to allocate line buffer\n");
        exit(1);
    }
     
    while (!feof(codeFile)) {
        numChars = getline(&lineBuffer, &bufSize, codeFile);
        if (numChars > 0) {                             // line not empty
            if ((lineBuffer[0] >= '0') && (lineBuffer[0] <= '9')) {         // first char is number
                if (((lineBuffer[6] >= '0') && (lineBuffer[6] <= '9')
                            || (lineBuffer[6] >= 'A') && (lineBuffer[6] <= 'F'))
                            && (lineBuffer[10] == '-')) {       // line with address
                    // printf("%s",lineBuffer);
                    lineBuffer[20] = 0;                                     // ignore anything after 20
                    sscanf(lineBuffer + 6,"%4x", &address);
                    // printf("%04X ", address);
                    if ((lineBuffer[12] != ' ') && (numChars > 13)) {
                        sscanf(lineBuffer + 12,"%2x", &data);
                        // printf("%02X", data);
                        store(address, data, storeFlag);
                    }
                    if ((lineBuffer[15] != ' ') && (numChars > 16)) {
                        sscanf(lineBuffer + 15,"%2x", &data);
                           // printf(" %02X", data);
                        store(address+1, data, storeFlag);
                    }
                     if ((lineBuffer[18] != ' ') && (numChars > 19)) {
                        sscanf(lineBuffer + 18,"%2x", &data);
                        // printf(" %02X", data);
                        store(address+2, data, storeFlag);
                    }                    
                }
                // printf("\n");
            }
        }
    }
    // printf("\n");
    
    free(lineBuffer);
    fclose(codeFile);
    codeFile = NULL;
}

/************/
int r65Setup()
/************/
{
    FILE *confFile;
    char name[24];
    
    printf("R65 6502 emulator\n");
    
    void reset6502();
    memset(memory, 0, 65536);
    if (exDisplay)
        init_exdisp();
    crt_init();
    
    // loadCodeFromListing("Assembler/assembler.txt", 1);
    
    loadCodeFromListing("Listings/kim1.txt", 1);
    loadCodeFromListing("Listings/monitor.txt", 1);
    loadCodeFromListing("Listings/disk.txt", 1);    
    loadCodeFromListing("Listings/iocontrol.txt", 1);
    loadCodeFromListing("Listings/crt.txt", 1);
    loadCodeFromListing("Listings/exdos.txt", 1);
    
    char *s = "printout.txt";
    printFile = fopen(s,"w");
    if (printFile == NULL)
        printf("Cannot open %s\n",s);
        
    s = "r65.conf";           // read configuration file
    confFile = fopen(s,"r");
    if (confFile == NULL) {
        printf("Cannot read configuration in %s\n", s);
        strcpy(floppy[0].name,"PASCAL");
        strcpy(floppy[1].name,"WORK");
    }
    else {
        for (int drive = 0; drive < 2; drive++) {
            if (fscanf(confFile, "disk=%16s\n", &name) != 1) {
                if (drive == 0)
                    strcpy(name,"PASCAL");
                else
                    strcpy(name,"WORK");
            }
            // printf("disk%d=%s\n", drive+1, name);
            strcpy(floppy[drive].name, name);
        }
        fclose(confFile);
    }
    fdc_init();
    
    setDateAndTime();
    
    // initialize random number generator (rand)
    srand((unsigned)time(NULL));
}

/***********/
int r65Loop()
/***********/
{
    printf("\nStart executing 6502 code:\n");
    
    clearClicks();
    
    
    pc = 0xF800;            // initialize the program counter, start R65 Monitor
    spMin = 255;
    pascalMinFree = 0xFFFF;
    sp = 255;
    time_t seconds;
    do {
        if (pendingNMI) {
            memory[M8_SFLAG] = memory[M8_SFLAG] & 0xfe; // clear pascal bit in sflag
            memory[M8_VFLAG] = memory[M8_VFLAG] & 0x7f; // clear inverse bit in vflag
            nmi6502();
            pendingNMI = 0;
        }
        else if (pendingIRQ) {
            if ((status & FLAG_INTERRUPT) == 0) { // execute only if irq not disabled
                irq6502();
                pendingIRQ = 0;
            }
        }
        step6502();
        if (sp<spMin) {
            spMin = sp;           // capture lowest sp value for display
            global_pendingCrtUpdate = 1;
            timeOfSpMin = time(NULL) % 86400;
            global_pendingCrtUpdate = 1;
        }
        if (checkEventCounter++ > 200000) {
            checkPendingEvents();
            checkMotorTurnoff(1);
            crtUpdate();
            checkEventCounter = 0;
            checkMinTimeout();
        }
    }
    while (1);
}
    
/***********/
int r65Quit()
/***********/
{
    FILE *confFile;
    
    printf("Quitting R65 emulator and closing all open files\n");
    if (sourceFile)
        fclose(sourceFile);
    if (printFile)
        fclose(printFile);

    char *s = "r65.conf";           // update configuration file
    confFile = fopen(s,"w");
    if (printFile == NULL)
        printf("Cannot save configuration in %s\n",s);
    else {
        for (int drive = 0; drive < 2; drive++)
            fprintf(confFile, "disk=%s\n", floppy[drive].name);
        fclose(confFile);
    }
    if (exDisplay)
        quit_exdisp();
    fdc_quit();
}
