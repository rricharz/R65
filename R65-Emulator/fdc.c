// fdc.c
//
// ******************************
// Emulate floppy disk controller
// ******************************
//
// Emulates the Intel 8271 memory mapped
// programmable floppy disk controller
//
// See fdc.h for the addresses of the registers
// in the R65 computer system
//
// Command register
// D7 D6 D5 D4 D3 D2 D1 D0
//        *  *              Drive
//              *  *  *  *  Opcode
// Parameter register
// D7 D6 D5 D4 D3 D2 D1 D0
//
// Result register
// D7 D6 D5 D4 D3 D2 D1 D0
//  0  0                 0
//        *                 Deleted data found
//           *  *           Completion type
//                 *  *     Completion code
//
// Status register
// D7 D6 D5 D4 D3 D2 D1 D0
//                    0  0
//  *                       Command busy
//     *                    Command register full
//        *                 Parameter register full
//           *              Result register full
//              *           Interrupt request
//                 *        Non DMA data request           
//
// cc 2018 rricharz
//
// FLOPPY CONFIGURATION:
//   2 drives
//   256 byte sectors
#define RPERTR 16  // number of sectors per track
#define NTRACKS 160 // number of tracks

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>

#include "time.h"
#include "main.h"
#include "R65.h"
#include "fake6502.h"
#include "crt.h"
#include "fdc.h"

#define KEEP_ON_CYCLES 200  // How many cycles of 10 msec the "motor" should stay on.
                            // After this time the disk file is closed and must be reopened.
                            // Do not make this too short, otherwise sequential r/w becomes
                            // extremely inefficient, and the SD card is wearing out!
                            // The high value is required for the Pascal compiler

int debug = 0;

struct Fdc {
    uint8_t fdstat;
    uint8_t drive;
    uint8_t command;
    uint8_t param;
    uint8_t fdres;
    uint8_t special;
    uint8_t parcounter;
    int bytecounter;
} FDC;

struct Ddrive floppy[2];


/*************/
void fdc_init()
/*************/
{
    FDC.fdstat = 0;
    FDC.drive = 0;
    for (int drv = 0; drv < 2; drv++) {
        floppy[drv].motor = 0;
        floppy[drv].track = 0;
        floppy[drv].sector = 0;
        floppy[drv].file = NULL;
    }
}

/*************************/
void closeDiskFile(int drv)
/*************************/
{
    if (floppy[drv].file != NULL) {
        fclose(floppy[drv].file);
        floppy[drv].file = NULL;
        if (debug) printf("FDC%d Closing disk file\n", drv);
    }
}

/*************/
void fdc_quit()
/*************/
{
    for (int i = 0; i < 1; i++) {
        closeDiskFile(i);
    }
}

/******************/
void convertFloppy()
/******************/
{
    char s[48];
    int i, sector;
    uint8_t buffer[256];
    printf("Converting disk to new format (32 directory sectors, 160*16 sectors total\n");
    // expand disk size from 800 sector to 2560 sectors
    // initialize buffer to 0
    for (i = 0; i < 256; i++)
        buffer[i] = 0;
    // enlarge file
    fseek(floppy[FDC.drive].file, 0, SEEK_END);
    for (i = 0; i < 2560-800; i++)
        fwrite(buffer, sizeof(buffer), 1, floppy[FDC.drive].file);
        
    // move data
    for (sector = 800; sector >= 11; sector--) {
        fseek(floppy[FDC.drive].file, (sector-1) * 256, SEEK_SET);
        fread(buffer, sizeof(buffer), 1, floppy[FDC.drive].file);
        fseek(floppy[FDC.drive].file, (sector -1 + 22) * 256, SEEK_SET);
        fwrite(buffer, sizeof(buffer), 1, floppy[FDC.drive].file);
    }
    // move last entry of directory
    int entry = 79;
    fseek(floppy[FDC.drive].file, entry * 32, SEEK_SET);
    fread(buffer, 32, 1, floppy[FDC.drive].file);
    entry = 255;
    fseek(floppy[FDC.drive].file, entry * 32, SEEK_SET);
    fwrite(buffer, 32, 1, floppy[FDC.drive].file);
    // clear new sectors of directory
    for (i = 0; i < 32; i++)
        buffer[i] = 0;
    for (entry = 80; entry < 32; entry++) {
        fseek(floppy[FDC.drive].file, entry * 32, SEEK_SET);
        fwrite(buffer, 32, 1, floppy[FDC.drive].file);
    }       
}


/*****************/
void openDiskFile()
/*****************/
{  
    char s[32];
    if (floppy[FDC.drive].file != NULL)
        fclose(floppy[FDC.drive].file);
    sprintf(s,"Disks/%s.disk", floppy[FDC.drive].name);
    if (debug) printf("FDC%d Opening disk %s\n", FDC.drive, s);
    floppy[FDC.drive].file = fopen(s,"r+");
    if (floppy[FDC.drive].file == NULL) {
        printf("FDC%d Cannot open disk %s\n",FDC.drive, s);
        floppy[FDC.drive].name[0]=0; // clear name, if floppy does not exist
        return;
    }
    else
        if (debug) printf("FDC%d (%s) opened\n", FDC.drive, s);
    fseek(floppy[FDC.drive].file, 0, SEEK_END);
    long size = ftell(floppy[FDC.drive].file);  // file size in bytes
    // printf("Disk opened, size = %ld\n", size);
    if (size < 205000) {
       printf("Old has old format\n", size);
       convertFloppy();
    }
}

/************/
int doSector()
/************/
{
    int sectorNumber = floppy[FDC.drive].track * RPERTR + floppy[FDC.drive].sector;
    
    if (floppy[FDC.drive].file == NULL) {
        printf("***** drive file not open\n");
        return 0x10;   // error, drive file not open
    }

    if (FDC.command == 0x13) {
        FDC.fdstat = 0x88;  // fdc ready to provide data
        if (debug) printf("FDC%d Read sector %2d, track %2d, loc %04X\n",
            FDC.drive, floppy[FDC.drive].sector, floppy[FDC.drive].track,
            RPERTR * floppy[FDC.drive].track + floppy[FDC.drive].sector - 1);
    }
    else if (FDC.command == 0x0B) {
        FDC.fdstat = 0x84;  // fdc ready to receive data
        if (debug) printf("FDC%d Write sector %2d, track %2d, loc %04X\n",
            FDC.drive, floppy[FDC.drive].sector, floppy[FDC.drive].track,
            RPERTR * floppy[FDC.drive].track + floppy[FDC.drive].sector - 1);
    }
    else if (FDC.command == 0x1F) {        
        FDC.fdstat = 0x10; 
        if (debug) if (debug) printf("FDC%d Verify sector %2d, track %2d, loc %04X\n",
            FDC.drive, floppy[FDC.drive].sector, floppy[FDC.drive].track,
            RPERTR * floppy[FDC.drive].track + floppy[FDC.drive].sector - 1);
    }
    FDC.bytecounter = 255;
    return(0);      // good completion
}

/****************************/
int fdc_read(uint16_t address)
/****************************/
// read from memory mapped fdc controller
{
    uint8_t buffer;
    if (debug) printf("Reading from FDC, pc = %04X, address = %04X\n", pc, address);
    if (address == R8_FDSTAT) { 
        if (debug) printf("  Reading FDC status = %02X\n", FDC.fdstat);
        return FDC.fdstat;
    }
    else if (address == R8_FDRES) { 
        if (FDC.fdres != 0) if (debug) printf("FDC%d Result = %02X\n", FDC.drive, FDC.fdres);
        return FDC.fdres;
    }
    else if (address == R8_FDDAT) {
                        
        if (FDC.command != 0x13) {
            printf("******** reading from data register, but last command was %02X\n", FDC.command);
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return 0xFF;
        }
        
        if (FDC.bytecounter == 255) {

            // seek
            long asector = RPERTR * floppy[FDC.drive].track + floppy[FDC.drive].sector;
            if (debug) printf("FDC%d Seek to block %04X\n", FDC.drive, asector);
            if (fseek(floppy[FDC.drive].file, 256 * (asector - 1), SEEK_SET)) {
                printf("****** seek error\n");
                FDC.fdstat = 0x10; 
                FDC.fdres = 0x10;
                return 0xFF;
            }
        }
        
        if (debug) printf("reading FDC data, i=%d\n", FDC.bytecounter);
        if (floppy[FDC.drive].file == NULL) {
            printf("****** data read error, file not open\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return 0xFF;
        }
        
        buffer = 0xFF;  // for testing
        if (fread(&buffer, 1, 1, floppy[FDC.drive].file) != 1) {
            printf("******* data read error\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x0C;
            return 0xFF;
        }
        
        if (debug) printf("  buffer[%02X]= %02X\n", 255 - FDC.bytecounter, buffer);
        if (FDC.bytecounter == 0) { // bytes read complete
            if (debug) printf("FDC%d Reading complete\n", FDC.drive);
            FDC.fdstat = 0x10; 
            FDC.fdres = 0;
        }
        
        FDC.bytecounter--;
        return buffer;
    }
    printf("  **** not implemented\n");
    return 0xFF;
}

/******************************/
void checkMotorTurnoff(int tics)
/******************************/
{
    int drv;
    for (drv = 0; drv < 2; drv++) {
        if ((floppy[drv].motor > 0) && (floppy[drv].motor != 32000)) {
            // if (debug) printf("FDC%d Motor turnoff countdown %d\n", drv, floppy[drv].motor);
            floppy[drv].motor -= tics;
            if (floppy[drv].motor <= 0) {
                setLed(drv, 0);
                if (debug) printf("FDC%d Turning motor off\n", drv);
                closeDiskFile(drv);
                floppy[drv].motor;
            }
        }
    }
}

/*********************************************/
void fdc_write(uint16_t address, uint8_t value)
/*********************************************/
// write to memory mapped fdc controller
{
    uint8_t buffer;
    
    if (debug) printf("Writing to FDC, pc =%04X, address = %04X\n", pc, address);
    
    // command
    if (address == R8_FDCOM) {
        FDC.param = 0xFF;         // will be changed if parameter is set
        FDC.special = 0;
        if (value & 0x40)
            FDC.drive = 0;
        else if (value & 0x80)
            FDC.drive = 1;
        else
            if ((value & 0x3F) != 0x35) printf("FDC Drive not specified in command %02X\n", value & 0x3F);
        FDC.command = value & 0x3F;
        if (debug) printf("  Command = %02X, drive = %d\n", FDC.command, FDC.drive);
        if (FDC.command == 0x2C) {
            FDC.fdstat = 0x10;
            if (floppy[FDC.drive].motor)
                FDC.fdres &= 0xFE;
            else
                FDC.fdres |= 0x01;
            if (debug) printf("  Get status of drive %d\n", FDC.drive);
        }
        else if (FDC.command == 0x3D) {
            if (debug) printf("  Get special register drive %d\n", FDC.drive);
            FDC.fdstat = 0;        
        }
        else if (FDC.command == 0x3A) {
            if (debug) printf("  Set special register drive %d\n", FDC.drive);
            FDC.special = 0;
        }
        else if (FDC.command == 0x35) {
            if (debug) printf("  Initialize FDC, ignoring, drive = %d\n", FDC.drive);
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x29) {
            if (debug) printf("  Seek, drive = %d\n", FDC.drive);
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x13) {
            if (debug) printf("Read sector command, drive = %d\n", FDC.drive);
            FDC.parcounter = 0;
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x0B) {
            if (debug) printf("Write sector command, drive = %d\n", FDC.drive);
            FDC.parcounter = 0;
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x1F) {
            if (debug) printf("Verify sector command, drive = %d\n", FDC.drive);
            FDC.parcounter = 0;
            FDC.fdstat = 0;
        }
        else {
            printf("  *** command not implemented\n");
        }
    }
    
    // parameter
    else if (address == R8_FDPARA) {
        if (debug) printf("  Parameter = %02X, command was %02X\n", value,FDC.command);
        FDC.param = value;
        if (FDC.command == 0x3D) {
            if (FDC.param == 0x23) {
                if (debug) printf("  read from special register %02X\n", FDC.param);
                FDC.fdstat = 0x10;
                FDC.fdres = 0;        
            }
        }
        else if (FDC.command == 0x3A) {
            if (FDC.special != 0 ) {
                if (FDC.special == 0x23) {
                    if (debug) printf("  write to special register %02X, value = %02X\n", FDC.special, value);
                    if (value & 0x20) {
                        if (floppy[FDC.drive].file == NULL) {
                            if (debug) printf("FDC%d Turning motor on\n", FDC.drive);
                            openDiskFile();
                        }
                        if (floppy[FDC.drive].file != NULL) {
                            floppy[FDC.drive].motor = 32000;          // means keep on
                            setLed(FDC.drive, 1);
                        }
                        else {
                            printf("*** disk file not opened\n");
                            floppy[FDC.drive].motor = 0;
                        }
                    }
                    else {
                        if (debug) printf("FDC%d Releasing motor\n", FDC.drive);
                        floppy[FDC.drive].motor = KEEP_ON_CYCLES;
                    }
                }
            }
            else if (FDC.param == 0x23) {
                if (debug) printf("  prepare write to special register %02X\n", FDC.param);
                FDC.special = FDC.param;
                FDC.fdstat = 0x10;
            }
        }
        else if (FDC.command == 0x35) {
            if (debug) printf("  ignoring parameter\n");
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x29) {
            if (debug) printf("Setting track to %02X\n", FDC.param);
            floppy[FDC.drive].track = FDC.param;
            FDC.fdstat = 0x10;
            // FDC.fdres = 16;      // disk not ready
            FDC.fdres = 0;          // OK
        }
        else if ((FDC.command == 0x13) || (FDC.command == 0x0B) || (FDC.command == 0x1F)) {
            if (FDC.parcounter == 0) {
                if (debug) printf("  setting track to %02X\n", FDC.param);
                floppy[FDC.drive].track = FDC.param;
                FDC.fdres = 0;
                FDC.parcounter++;
            }
            else if (FDC.parcounter == 1) {
                if (debug) printf("  setting sector to %02X\n", FDC.param);
                floppy[FDC.drive].sector = FDC.param;
                FDC.fdres = 0;
                FDC.parcounter++;
            }
            else if (FDC.parcounter == 2) {
                if (FDC.param == 0x21) {
                    FDC.fdstat = 0x10;
                    FDC.fdres = doSector();
                }
            }
        }
        else {
            printf("***** parameter for unknown command %02X\n", FDC.command);
        }
    }
    
    // data
    else if (address == R8_FDDAT) {
        
        if (FDC.command != 0x0B) {
            printf("******** writing to data register, but last command was %02X\n", FDC.command);
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return;
        }
        
        if (FDC.bytecounter == 255) {
            long asector = RPERTR * floppy[FDC.drive].track + floppy[FDC.drive].sector;
            
            // seek
            if (debug) printf("seek to start of sector %02X\n", asector);
            if (fseek(floppy[FDC.drive].file, 256 * (asector - 1), SEEK_SET)) {
                printf("****** seek error\n");
                FDC.fdstat = 0x10; 
                FDC.fdres = 0x10;
                return;
            }
        }
        
        if (debug) printf("writing FDC data, i=%d\n", FDC.bytecounter);
        if (floppy[FDC.drive].file == NULL) {
            printf("****** data write error, file not open\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return;
        }
        
        buffer = value;
        if (fwrite(&buffer, 1, 1, floppy[FDC.drive].file) != 1) {
            printf("******* data write error\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x0A;
            return;
        }
        
        if (debug) printf("  buffer[%02X]= %02X\n", 255 - FDC.bytecounter, buffer);
        if (FDC.bytecounter == 0) { // bytes written complete
            if (debug) printf("FDC%d Writing complete\n", FDC.drive);
            FDC.fdstat = 0x10; 
            FDC.fdres = 0;
        }
        
        FDC.bytecounter--;
    }
    return; 
}

/***************/
int export_file()
/***************/
{
    int i, end, drive, filtyp, filstp, sectorPointer, size, chr;
    char buffer[256];
    char *extension;
    long int dataPnt;
    FILE *foutput;
    char s[32];
    char name[32];
    int pnt = 0;
    
    // printf("Export called\n")
    
    // check whether directory "Files" exists
    DIR* dir = opendir("Files");
    if (dir)
        closedir(dir);
    else
        system("mkdir Files");
    
    filtyp = memory[M8_FILTYP];
    // printf("Filtyp = %c\n", filtyp);
        
    filstp = memory[M8_FILSTP];
    // printf("Filstp = %c\n", filstp);
    
    if (filtyp=='S') {      // sequential file
        if (filstp == 'A')
            extension = ".asm";
        else if (filstp == 'P')
            extension = ".pas";
        else
            extension = ".txt";
    }
    else {                  // block file
        if (filstp == 'R') {
           extension = ".pdump";
           pnt = 0x2000;
        }
        else {
           extension = ".bin";
           pnt =0;
        }
    }
    
    drive = memory[M8_FILDRV];
    // printf("Drive = %d\n", drive);
    
    sectorPointer = memory[M16_FILLOC] + 256 * memory[M16_FILLOC + 1];    
    // printf("Pointer = %04X\n", sectorPointer);
    
    size = memory[M16_FILSIZ] + 256 * memory[M16_FILSIZ + 1] ;    
    // printf("Size = %04X\n", size);
    
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
    printf("Exporting to %s\n", name);
    
    foutput = fopen(name, "w");         // open output file
    if (foutput == NULL) {
        printf("Export: Cannot open %s\n", name);
        return (0x65);
    }
    
    if (floppy[drive].file == NULL) {
        printf("Export: file not open\n");
        return (7);
    }
    
    dataPnt = 256 * (long int) (sectorPointer + 32);
    int res = fseek(floppy[drive].file, dataPnt, SEEK_SET);     // skip directory track and go to start of data
    if (res != 0) {
        printf("Export: Seek failed\n");
        return (0x65);
    }
    
    do {
        if ((fread(&buffer, sizeof(buffer), 1, floppy[drive].file) != 1)) { 
            printf("Export: write error\n");
            return(0x65);
        }
        else {
            // print buffer
            int i = 0;
            
            if (filtyp=='S') {  // sequential file
                while ((i < 256) && ((buffer[i] & 0x7F) != 0x7F)) {
                    if ((buffer[i] >= 0x80) && (buffer[i] <= 0xFe)) {
                        for (int ii = 0; ii < (buffer[i] & 0x7F); ii++)
                            fprintf(foutput, "%c", ' ');
                    }
                    else if (buffer[i] == 0x0D) {
                        fprintf(foutput, "\n");
                    }
                    else {
                        fprintf(foutput, "%c",buffer[i]);
                    }
                    i++;
                }
                if ((buffer[i] & 0x7F) == 0x7F) {
                    fclose(foutput);
                    printf("Export complete\n");
                    return 0;
                }
            }
            else {
                for (i = 0; i<256; i++) {
                    if ((i & 15) == 0) {
                       fprintf(foutput,"\n(%04x) ",pnt);
                    }
                    fprintf(foutput,"%02x ", buffer[i]);
                    pnt++;                    
                }
            }
        }
        size -= 256;
        
    }
    while (size >= 0);
    
    fclose(foutput);
    printf("Export complete\n");
    return 0;
}

/***************/
int import_file()
/***************/
{
    int  i, drive, end;
    char *extension;
    char s[24];
    char estring[80];
    char filstp;
    FILE *finput;
    
    // printf("Import called\n");
    
    // check whether directory "Files" exists
    DIR* dir = opendir("Files");
    if (dir)
        closedir(dir);
    else
        system("mkdir Files");
    
    drive = memory[M8_FILDRV];
    // printf("Drive = %d\n", drive);
    
    i = 15;
    while ((memory[M8_FILNAM+i] == ' ') && (i > 0) )    // find end of file name
        i--;
    end = i + 1;
    
    filstp = 'B';    // default: test file
    extension = ".txt";
    
    for (i = 0; i < end; i++) {
        if (memory[M8_FILNAM+i] == ':') {               // remove :
            s[i]=' ';
            filstp = memory[M8_FILNAM+i+1];
            if (filstp == 'A')
              extension = ".asm";
            else if (filstp == 'P')
              extension = ".pas";
            end = i;
        }
        
        s[i] = memory[M8_FILNAM+i];
        if ((s[i] >= 'A') && (s[i] <= 'Z'))     // convert to small letters
            s[i] = s[i] + 0x20;
    }
    
    s[end] = 0;                                 // add end of string mark
    
    closeDiskFile(drive);   // close file to avoid problems when pushr65 writes to it 
    
    setLed(drive, 1);
    
    // run pushr65
    sprintf(estring, "Tools/pushr65 Files/%s%s  Disks/%s.disk", s, extension, floppy[drive].name);
    printf("Running %s\n", estring);   
    int res = system(estring);
    // printf("Result=%d\n", res);
    setLed(drive, 0);
    res = res >> 8;
    if (res == 255)
        return 6;  // file not found
    else {
        // prepare data for PRFLAB
        // printf("Setting filcyc to %d\n",res);
        memory[M8_FILCYC] = res;
        return 0;
    }
}

/*****************/
int change_floppy()
/*****************/
{
    int   i, drive, end, otherdrive;
    char *extension;
    char s[32];
    
    // printf("Floppy called\n");
    
    drive = memory[M8_FILDRV];
    // printf("Drive = %d\n", drive);
    
    i = 11;
    while ((memory[M8_FILNAM+i] == ' ') && (i > 0) )    // find end of file name
        i--;
    end = i + 1;
    for (i = 0; i < end; i++) {
        s[i] = memory[M8_FILNAM+i];
    }
    s[end] = 0;                                 // add end of string mark
    
    closeDiskFile(drive);   // close file to avoid problems when pushr65 writes to it
    setLed(drive, 0);
    
    // printf("New file name = %s\n", s);
    
    if (drive == 0)
        otherdrive = 1;
    else
        otherdrive = 0;
       
    if (strcmp(floppy[otherdrive].name, s) == 0) {
        printf("Trying to load same floppy in both drives\n");
        return (7);
    }
    
    strcpy(floppy[drive].name, s);
    
    // check whether file exists
    
    sprintf(s,"Disks/%s.disk", floppy[drive].name);
    if (debug) printf("Checking for disk %s\n", s);
    floppy[drive].file = fopen(s,"r+");
    if (floppy[drive].file == NULL) {
        printf("Cannot open disk %s\n",s);
        floppy[drive].name[0]=0; // clear name, if floppy does not exist
        return 7;
    }
    fclose(floppy[drive].file);
    floppy[drive].file=0;
    
    return 0;
    
}
