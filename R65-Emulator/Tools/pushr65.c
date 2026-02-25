// pushr65
// push a text file to a R65
//
// tool for R65 system emulator
// can be called directly in linux
// also used by the EXDOS command EDIT
//
// usage: pushr65 filename diskfile
//
// file types which can be pushed:
// -------------------------------
// linux:                       type subtype subname
// .asm   assembler source file   S     A      :A
// .txt   general text file       S     B
// .pas   pascal source file      S     P      :P
// .pa2   pascal binary files     B     R      :R
// .pb1   pascal lib loader file  S     T      :T
// .lib   pascal library table    S     L      :L
// .help  pascal help files       S     H      :H
//
// (subnames are used to differentiate files for
// commands such as DELETE, RENAME etc. They are
// usually identical to the subtype
//
// 2018 rricharz (r77@bluewin.ch)
//

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "time.h"

struct DirEntries {
    uint8_t   filtyp;
    char      filnam[16];
    uint8_t   filcyc;
    uint8_t   filsubtype;
    uint8_t   filloc8[2];    // 16 bit number is not aligned to even address!
    uint8_t   filsiz8[2];    // 16 bit number is not aligned to even address!
    uint8_t   fildat[3];
    uint16_t  filsa;
    uint16_t  filea;
    uint16_t  fillnk;
} dirEntry;

uint8_t sector[256];

int debug = 0;

long int byteOutCounter;
long int byteInCounter;
int blankCounter;
int column;
int line;
int maxBytes;
int maxCharPerLine;
char type;

FILE *finput;
FILE *foutput;

/*****************/
void closeAndExit()
/*****************/
{
    if (finput != NULL)
        fclose(finput);
    if (foutput != NULL)
        fclose(foutput);
    printf("pushr65 exit with error\n");
    exit (-1);
}

/********************************/
int getDirEntry(FILE *f, int index)
/********************************/
{
    long int offset = index * sizeof(dirEntry);
    if (debug) printf("Seek to %d\n", offset);
    int res = fseek(f, offset, SEEK_SET);
    if (res != 0) {
        printf("***** Seek failed\n");
        closeAndExit();
    }    
    if (debug) printf("Reading %d bytes\n", sizeof(dirEntry));
    return ((fread(&dirEntry, sizeof(dirEntry), 1, f) == sizeof(dirEntry)));
}

/********************************/
int putDirEntry(FILE *f, int index)
/********************************/
{
    long int offset = index * sizeof(dirEntry);
    if (debug) printf("Seek to %d\n", offset);
    int res = fseek(f, offset, SEEK_SET);
    if (res != 0) {
        printf("***** Seek failed\n");
        closeAndExit();
    }    
    if (debug) printf("Writing %d bytes\n", sizeof(dirEntry));
    return ((fwrite(&dirEntry, sizeof(dirEntry), 1, f) == sizeof(dirEntry)));
}

/********************************/
int readSector(FILE *f, int index)
/********************************/
{
    long int offset = index * sizeof(sector);
    if (debug) printf("Seek to %d\n", offset);
    int res = fseek(f, offset, SEEK_SET);
    if (res != 0) {
        printf("*** Seek failed\n");
        closeAndExit();
    }    
    if (debug) printf("Reading %d bytes\n", sizeof(sector));
    return ((fread(&sector, sizeof(sector), 1, f) == sizeof(sector)));
}

/*******************/
int displayDirEntry()
/*******************/
{
    if (debug) printf("Directory entry: ");
    if (debug) printf("type=%02X ", dirEntry.filtyp);
    for (int i = 0;i<16; i++)
        if (debug) printf("%c",dirEntry.filnam[i]);
    if (debug) printf("\n");
} 

/************************/
uint8_t bcdbyte(int value)
/************************/
// convert byte to bcd
{
    return ((value % 10) + ((value / 10) % 10) * 16);
}

/**********************************/
void pushByte(FILE *f, uint8_t value)
/**********************************/
// push a byte to file
// handles r65 blank packing, tab and disk overflow
{
    char chr;
    char cr = 0x0D;
    
    byteInCounter++;                            // count input byte

    if (type == 'B') {                          // binary
        byteOutCounter++;
        if ((fwrite(&value, sizeof(chr), 1, f) != sizeof(chr))) { 
            printf("\n***** Write error, disk directory unchanged\n");
            printf("Maxbytes = %06X, byteOutCounter=%06X\n", maxBytes, byteOutCounter);
            closeAndExit();
        }
        return;        
    }
    
    if (value != EOF)
        chr = value & 0x7F;                     // mask bit 8 off
    else
        chr = EOF;                              // but keep EOF
    
    if (chr == 0x09) {                          // tab
        do
            pushByte(f, ' ');                   // this is a recursive call!
        while ((((column -1) & 0x07) != 0) && (column < maxCharPerLine));
        return;
    }
        
    if (chr == 0x0A) {                          // discard line feed
        blankCounter = 0;                       // ignore trailing blanks
        line++;
        column = 0;
        chr = 0x0D;
        // return;                              // send cr
    }
   
    if ((chr != ' ') && blankCounter > 0) {     // push blank counter
        if (byteOutCounter++ >= maxBytes) {
            printf("\n***** Disk full, disk directory unchanged\n");
            printf("Maxbytes = %06X, byteOutCounter=%06X\n", maxBytes, byteOutCounter);
            closeAndExit();
        }
        if (blankCounter == 1)      // only one blank
            blankCounter = 0x20;    // keep blank
        else
            blankCounter += 128;                    // set bit 8
        if ((fwrite(&blankCounter, sizeof(chr), 1, f) != sizeof(chr))) { 
            printf("\n***** Write error, disk directory unchanged\n");
            printf("Maxbytes = %06X, byteOutCounter=%06X\n", maxBytes, byteOutCounter);
            closeAndExit();
        }
        blankCounter = 0;
    }
    
    if (column > maxCharPerLine)  {            // ignore rest of line
        printf("\n***** Line %d too long\n", line);
        return;
    }
    
    if (chr == ' ') {                            // pack blanks
        blankCounter++;
        column++;
        return;
    }

    if (byteOutCounter++ >= maxBytes) {          // push the character
            printf("\n***** Disk full, disk directory unchanged\n");
            printf("Maxbytes = %06X, byteOutCounter=%06X\n", maxBytes, byteOutCounter);
            closeAndExit();
        }
        if ((fwrite(&chr, sizeof(chr), 1, f) != sizeof(chr))) { 
            printf("\n***** Write error, disk directory unchanged\n");
            printf("Maxbytes = %06X, byteOutCounter=%06X\n", maxBytes, byteOutCounter);
            closeAndExit();
        }
        column++;
}


/******************************/
int main(int argc, char *argv[])
/******************************/
{
    int  i;
    char subtype, subname;
    int  chr;
    char *diskName;
    char *begin;
    char *end;
    
    byteOutCounter = 0;
    byteInCounter = 0;
    blankCounter = 0;
    column = 0;
    line = 1;
    
    printf("pushr65 version 1.3\n");
    
    if ((argc < 2) || (argc > 3)) {
        printf("Usage: pushr65 filename diskfile\n");
        closeAndExit();
    }
    
    if (argc == 3) {
        diskName = argv[2];
    }
    else
        diskName = "/home/rricharz/Projects/R65/R65-Emulator/Disks/WORK.disk";
        
    if (debug) printf("Disk file: %s\n", diskName);
    
    if (sizeof(dirEntry) != 32) {
        printf("Size of dirent is wrong (%d)!\n",sizeof(dirEntry));
        closeAndExit();
    }
    
    // prepare R65 file name
    
    int r65name[16];    
    for (i = 0;  i < 16; i++)
        r65name[i] = ' ';
        
    maxCharPerLine = 56;
        
    if ((end = strstr(argv[1],".asm")) != NULL) {
        type = 'S';
        subtype = 'A';       // Assembler source file
        subname = 'A';
    }
    else if ((end = strstr(argv[1],".txt")) != NULL) {
        type = 'S';
        subtype = 'B';      // Textfile
        maxCharPerLine = 56;
        subname = ' ';
    }
    else if ((end = strstr(argv[1],".pas")) != NULL) {
        type = 'S';
        subtype = 'P';      // Pascal source file
        subname = 'P';
    }
    else if ((end = strstr(argv[1],".pa2")) != NULL) {
        type = 'B';
        subtype = 'R';      // Pascal runtime file
        subname = 'R';
    }
    else if ((end = strstr(argv[1],".lib")) != NULL) {
        type = 'S';
        subtype = 'L';      // Pascal library table
        maxCharPerLine = 100;
        subname = 'L';
    }
    else if ((end = strstr(argv[1],".li1")) != NULL) {
        type = 'S';
        subtype = 'T';      // Pascal library file
        maxCharPerLine = 32767;
        subname = 'T';
    }
    else if ((end = strstr(argv[1],".help")) != NULL) {
        type = 'S';
        subtype = 'H';      // Pascal library file
        maxCharPerLine = 48;
        subname = 'H';
    }
    else {
        printf("Filename must end with .asm,.txt,.pas,.pa2,.lib,.li1\n");
        closeAndExit();
    }
    
    begin = strstr(argv[1], "/");
    if (begin == NULL)
        begin = argv[1];
    else
        begin = begin + 1;
        
    if ((end - begin) > 13) {
        printf("filename too long\n");
        closeAndExit();
    }
    
    int colon = 0;
    
    for (i = 0; begin+i < end; i++)
        if ((begin[i] >= 'A') && (begin[i] <= 'Z'))
            r65name[i] = begin[i];
        else if (((begin[i] >= '0') && (begin[i] <= '9')) && (i > 0))
            r65name[i] = begin[i];
        else if ((begin[i] >= 'a') && (begin[i] <= 'z'))            
            r65name[i] = begin[i] -'a' + 'A';
        else if ((begin[i] == ':')  && (i > 0)) {         
            r65name[i] = begin[i];
            colon = i;
        }
        else {
            printf("File name contains illegal character %c\n", begin[i]);
            closeAndExit();
        }
        
    if (colon>0)
        i = colon;      // overwrite existing name type
        
    if (subname != ' '){
        r65name[i] = ':';
        r65name[i+1] = subname;
    }
    if (debug) {
        printf("R65 file name: ");
        for (i=0; i < 16; i++)
            printf("%c",r65name[i]);
        printf("\n");
    }
       
    finput = fopen(argv[1], "r");         // open input file for read
    if (finput == NULL) {
        printf("Cannot open %s\n",argv[1]);
        closeAndExit();
    }
    
    foutput = fopen(diskName, "r+");      // open output file for read/write
    if (foutput == NULL) {
        printf("Cannot open %s\n",diskName);
        closeAndExit();
    }
    
    int cyclus = 1;
    int dirIndex = 0;
    int isSame = 0;
    do {
        if (getDirEntry(foutput,dirIndex) == 0) {
        }
        else {
            printf("Cannot read directory entry %d\n");
            closeAndExit();
        }
        if (dirEntry.filtyp != 0) {
            isSame = 1;
            for (i = 0; i < 16; i++)
                if (r65name[i] != dirEntry.filnam[i]) {
                    isSame = 0;
                }
            if ((isSame == 1) && (dirEntry.filcyc >= cyclus))
                cyclus = dirEntry.filcyc + 1;
            
        }
        if (debug) printf("%4d: ", dirIndex);
        displayDirEntry();
    }
    while ((dirEntry.filtyp != 0) && (dirIndex++ < 79));
    
    if (dirIndex >= 255) {
        printf("***** Directory full\n");
        closeAndExit();
    }
    
    if (debug) printf("New cyclus = %d\n", cyclus);
    
    int startSector = dirEntry.filloc8[0] + 256 * dirEntry.filloc8[1];
    
    if (debug) printf("New start sector = %04x\n", startSector);
    
        
    int numSectors = 1;
    
    // Store the data
    
    maxBytes = (((159 * 16) - startSector) * 256);
    if (debug) printf("Space for maximal %d bytes\n", maxBytes);
    if (debug) printf("Start of data sector %04X\n", startSector + 10);
    long int dataPnt = 256 * (long int) (startSector + 32);
    int res = fseek(foutput, dataPnt, SEEK_SET);     // skip directory tracks and go to start of data
    if (res != 0) {
        printf("***** Seek failed\n");
        closeAndExit();
    }
    do {
        chr =fgetc(finput);
        pushByte(foutput, chr);     // push characters
    }
    while (!feof(finput));
    pushByte(foutput, 0x1f);        // R65 system EOF character
    numSectors = (byteOutCounter / 256) + 1;
    printf("Bytes read %d\n", byteInCounter);
    printf("Bytes written %d\n", byteOutCounter);
    printf("Compression %d\%\n", (100 * byteOutCounter) / byteInCounter);
    if (debug) printf("Lines written %d\n", line);
    if (debug) printf("Sectors written %d\n", numSectors);

    
    // Prepare and save the new file entry
    
    if ((byteOutCounter & 0xFF) != 0) {      // round up byte counter to full sectors
        byteOutCounter = (byteOutCounter + 256) & 0xFF00;
    }
    struct tm *clock;
    struct stat attr;
    stat(argv[1], &attr);
    clock = gmtime(&(attr.st_mtime));
    if (debug) printf("File date %d/%d/%d\n", clock->tm_mday,  clock->tm_mon + 1,  clock->tm_year + 1900);

    dirEntry.filtyp = type;
    dirEntry.filsubtype = subtype;
    for (i = 0; i < 16; i++)
        dirEntry.filnam[i] = r65name[i];
    dirEntry.filcyc = cyclus;
    dirEntry.filloc8[0] = startSector & 0xFF;
    dirEntry.filloc8[1] = startSector / 256;
    dirEntry.filsiz8[0] = byteOutCounter & 0xFF;
    dirEntry.filsiz8[1] = byteOutCounter / 256;;
    dirEntry.fildat[0]  = bcdbyte(clock->tm_mday);
    dirEntry.fildat[1]  = bcdbyte(clock->tm_mon + 1);
    dirEntry.fildat[2]  = bcdbyte(clock->tm_year + 1900);
    if (type == 'B')
        dirEntry.filsa = 0x3000;    // a save address, so that LOAD does not crash
                                    // if used with a binary Pascal file
    else
        dirEntry.filsa = 0;
    dirEntry.filea = dirEntry.filsa + (256 * numSectors) - 1;
    dirEntry.fillnk = 0;
    if (debug) printf("%4d: ", dirIndex);
        displayDirEntry();
    if (putDirEntry(foutput,dirIndex) != 0) {
        printf("***** Cannot save directory entry\n");
        closeAndExit();
    }
    
    // Prepare and save the new end mark
    dirIndex++;
    dirEntry.filtyp = 0;
    dirEntry.filloc8[0] = (startSector + numSectors) & 0xFF;
    dirEntry.filloc8[1] = (startSector + numSectors) / 256;
    if (debug) printf("%4d: ", dirIndex);
        displayDirEntry();
    if (putDirEntry(foutput,dirIndex) != 0) {
        printf("***** Cannot save directory end mark\n");
        closeAndExit();
    }
    
    fclose(finput);
    fclose(foutput);
    // printf("pushr65 finished, new cyclus=%d\n",cyclus);
    exit(cyclus);
    
}
