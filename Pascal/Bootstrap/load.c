// load.c

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

uint8_t mem[EBLOCK + 1];

FILE *fno = NULL;
FILE *ofno = NULL;
FILE *libfno = NULL;

uint16_t maxsize, pointer, offset, address;
uint16_t endprog;
int exitFlag;
int ch;


/*****************/
void closeAndExit()
/*****************/
{
    if (fno != NULL)
        fclose(fno);
    if (ofno != NULL)
        fclose(ofno);
    if (libfno != NULL)
        fclose(libfno);
    printf("Exiting load with error\n");
    exit (1);
}


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


/************/
int isNumber()  // is ch a number?
/************/
{
    return ((ch >= '0') && (ch <= '9'));
}


/**************/
int isHexDigit() // is ch a hex digit?
/**************/
{
    return (((ch >= 'a') && (ch <= 'f')) || isNumber());
}


/************/
int getbyte1()
/************/
// get a byte from input stream
{
    int byte;
    if ((ch < '0') | (ch > '@')) {
        printf("Reading illegal char from input file: %02x\n", ch);
        closeAndExit();
    }
    byte = (ch & 15) << 4;
    ch = fgetc(fno);
    if ((ch < '0') | (ch > '@')) {
        printf("Reading illegal char from input file: %02x\n", ch);
        closeAndExit();
    }
    byte = byte + (ch & 15);
    return byte;
}


/************/
int getbyte2()
/************/
{
    ch = fgetc(fno);
    // printf("%c",ch);
    return(getbyte1());
}


/*********************/
void getblock(int base)
/*********************/
{
    void libcall()          // libcall, not yet implemented
    {
        int i, ch1;
        
        char libName[8];
        char s3[16];
        
        FILE *tmpfno;
        
        i = 0;
        do {
            ch1 = fgetc(fno);
            libName[i] = ch1;
            i++;
        }
        while ((ch1 != 0xd) && (ch1 != 0xa) && (i < 8));
        libName[i -1] = 0;
        // printf("libcall: library name = %s\n", libName);
        
        sprintf(s3, "%s.li1", libName);
        libfno = fopen(s3, "r");
        if (libfno == NULL) {
            printf("Cannot open %s\n", s3);
            closeAndExit();
        }
        
        tmpfno = fno;       // swap file handles, so that they get closed in case of error
        fno = libfno;       // reading now from library file
        libfno = tmpfno;
        
        getblock(offset - 2);       // load the library
        
        tmpfno = fno;       // swap files back
        fno = libfno;       // reading now again from source file
        libfno = tmpfno;
        
        if (libfno != NULL) {
            fclose(libfno);
            libfno = NULL;
        }
        
        // printf("pointer = %d\n", pointer);
        
        mem[pointer-1] = 43;
        mem[pointer]   = 0;
        mem[pointer+1] = 3;
        mem[pointer+2] = 0;
        mem[pointer+3] = 0;
        pointer += 4;
        if ((pointer - SBLOCK) > maxsize) {
            printf("library too large\n");
            closeAndExit();
        }
        offset = pointer - SBLOCK;
        printf("Library %s loaded\n", libName);
        exitFlag = 0;  // keep going
    }  // end libcall
    
    exitFlag = 0;
    do {
        ch = fgetc(fno);
        // printf("%c",ch);
        if (ch == 'F') {
            // printf("Fixup:\n");
            address = getbyte2() + (getbyte2() << 8) + offset;
            if ((address < offset) | (address > maxsize)) {
                printf("Fixup: illegal address=%04x, offset=%04x\n",
                    address, offset);
                closeAndExit();
            }
            mem[address + SBLOCK] = getbyte2();
            mem[address + SBLOCK +1] = getbyte2();
        }
        else if (ch == 'L') libcall();
        else if (ch == 'E') exitFlag = 1;
        else if (feof(fno)) {
            printf("Unexpected end of file\n");
            closeAndExit();
        }
        else {
            mem[pointer] = getbyte1();
            // printf("mem[%04x]=%02x\n", pointer, mem[pointer]);
            pointer++;
            if ((pointer - SBLOCK) > maxsize) {
                printf("Maximal size of code exceeded\n");
                closeAndExit();
            }            
        }
    }
    while (exitFlag == 0);
    mem[SBLOCK] = low(pointer - SBLOCK);
    mem[SBLOCK + 1] = high(pointer - SBLOCK);
    address = getbyte2() + (getbyte2() << 8) + base;
    if (address != (pointer - SBLOCK)) {
        printf("Wrong size, stored size=%d, bytes read=%d ???\n",
            address, pointer - SBLOCK);
    }
    endprog = pointer - SBLOCK;       
}


/*************************************/
int blocksave(int lowlim, int highlim)
/*************************************/
{
    return (fwrite(&mem[lowlim], 1, highlim - lowlim, ofno) != (highlim - lowlim));
}

/******************************/
int main(int argc, char *argv[])
/******************************/
{
    char s[64];

    printf("load version 1.0\n");
    
    if (argc != 2) {
        printf("Usage: load filename\n");
        closeAndExit();
    }
    
    sprintf(s,"%s.pa1", argv[1]);
    fno = fopen(s, "r");
    if (fno == NULL) {
        printf("Cannot open %s\n",s);
        closeAndExit();
    }
    
    sprintf(s,"%s.pa2", argv[1]);
    ofno = fopen(s, "w");
    if (ofno == NULL) {
        printf("Cannot open %s\n",s);
        closeAndExit();
    }
    
    maxsize = EBLOCK - SBLOCK;
    pointer = SBLOCK + 2;
    offset = 2;
    
    getblock(0);
    printf("Program loaded\n");
    
    if (blocksave(SBLOCK, pointer)) {
        printf("Error while saving in %s\n", s);
    }

    if (fno != NULL) {
        fclose(fno);
        fno = NULL;
    }
    if (ofno != NULL) {
        fclose(ofno);
        ofno = NULL;
    }
    if (libfno != NULL) {
        fclose(libfno);
        libfno = NULL;
    }
    
    runtime();
    
    exit(0);
}
