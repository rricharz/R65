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
    floppy[FDC.drive].file = fopen(s,"r+");
    if (floppy[FDC.drive].file == NULL) {
        logmsg("FDC%d Cannot open disk %s\n",FDC.drive, s);
        floppy[FDC.drive].name[0]=0; // clear name, if floppy does not exist
        return;
    }
    fseek(floppy[FDC.drive].file, 0, SEEK_END);
    long size = ftell(floppy[FDC.drive].file);  // file size in bytes
    if (size < 205000) {
       logmsg("Disk has old format\n");
       convertFloppy();
    }
}

/************/
int doSector()
/************/
{
    int sectorNumber = floppy[FDC.drive].track * RPERTR + floppy[FDC.drive].sector;
    
    if (floppy[FDC.drive].file == NULL) {
        return 0x10;   // error, drive file not open
    }

    if (FDC.command == 0x13) {
        FDC.fdstat = 0x88;  // fdc ready to provide data
    }
    else if (FDC.command == 0x0B) {
        FDC.fdstat = 0x84;  // fdc ready to receive data

    }
    else if (FDC.command == 0x1F) {        
        FDC.fdstat = 0x10; 
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
    if (address == R8_FDSTAT) { 
        return FDC.fdstat;
    }
    else if (address == R8_FDRES) { 
        return FDC.fdres;
    }
    else if (address == R8_FDDAT) {
                        
        if (FDC.command != 0x13) {
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return 0xFF;
        }
        
        if (FDC.bytecounter == 255) {

            // seek
            unsigned int asector = RPERTR * floppy[FDC.drive].track + floppy[FDC.drive].sector;
            if (fseek(floppy[FDC.drive].file, 256 * (asector - 1), SEEK_SET)) {
                logmsg("****** seek error\n");
                FDC.fdstat = 0x10; 
                FDC.fdres = 0x10;
                return 0xFF;
            }
        }
        
        if (floppy[FDC.drive].file == NULL) {
            logmsg("****** data read error, file not open\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return 0xFF;
        }
        
        buffer = 0xFF;  // for testing
        if (fread(&buffer, 1, 1, floppy[FDC.drive].file) != 1) {
            logmsg("******* data read error\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x0C;
            return 0xFF;
        }
        
        if (FDC.bytecounter == 0) { // bytes read complete
            FDC.fdstat = 0x10; 
            FDC.fdres = 0;
        }
        
        FDC.bytecounter--;
        return buffer;
    }
    return 0xFF;
}

/******************************/
void checkMotorTurnoff(int tics)
/******************************/
{
    int drv;
    for (drv = 0; drv < 2; drv++) {
        if ((floppy[drv].motor > 0) && (floppy[drv].motor != 32000)) {
          floppy[drv].motor -= tics;
            if (floppy[drv].motor <= 0) {
                setLed(drv, 0);
                closeDiskFile(drv);
                floppy[drv].motor = 0;
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
        
    // command
    if (address == R8_FDCOM) {
        FDC.param = 0xFF;         // will be changed if parameter is set
        FDC.special = 0;
        if (value & 0x40)
            FDC.drive = 0;
        else if (value & 0x80)
            FDC.drive = 1;
        else
            if ((value & 0x3F) != 0x35)
              logmsg("FDC Drive not specified in command %02X\n", value & 0x3F);
        FDC.command = value & 0x3F;
        if (FDC.command == 0x2C) {
            FDC.fdstat = 0x10;
            if (floppy[FDC.drive].motor)
                FDC.fdres &= 0xFE;
            else
                FDC.fdres |= 0x01;
        }
        else if (FDC.command == 0x3D) {
            FDC.fdstat = 0;        
        }
        else if (FDC.command == 0x3A) {
            FDC.special = 0;
        }
        else if (FDC.command == 0x35) {
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x29) {
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x13) {
            FDC.parcounter = 0;
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x0B) {
            FDC.parcounter = 0;
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x1F) {
            FDC.parcounter = 0;
            FDC.fdstat = 0;
        }
    }
    
    // parameter
    else if (address == R8_FDPARA) {
        FDC.param = value;
        if (FDC.command == 0x3D) {
            if (FDC.param == 0x23) {
                FDC.fdstat = 0x10;
                FDC.fdres = 0;        
            }
        }
        else if (FDC.command == 0x3A) {
            if (FDC.special != 0 ) {
                if (FDC.special == 0x23) {
                    if (value & 0x20) {
                        if (floppy[FDC.drive].file == NULL) {
                            openDiskFile();
                        }
                        if (floppy[FDC.drive].file != NULL) {
                            floppy[FDC.drive].motor = 32000;          // means keep on
                            setLed(FDC.drive, 1);
                        }
                        else {
                            logmsg("*** disk file not opened\n");
                            floppy[FDC.drive].motor = 0;
                        }
                    }
                    else {
                        floppy[FDC.drive].motor = KEEP_ON_CYCLES;
                    }
                }
            }
            else if (FDC.param == 0x23) {
                FDC.special = FDC.param;
                FDC.fdstat = 0x10;
            }
        }
        else if (FDC.command == 0x35) {
            FDC.fdstat = 0;
        }
        else if (FDC.command == 0x29) {
            floppy[FDC.drive].track = FDC.param;
            FDC.fdstat = 0x10;
            // FDC.fdres = 16;      // disk not ready
            FDC.fdres = 0;          // OK
        }
        else if ((FDC.command == 0x13) || (FDC.command == 0x0B) || (FDC.command == 0x1F)) {
            if (FDC.parcounter == 0) {
                floppy[FDC.drive].track = FDC.param;
                FDC.fdres = 0;
                FDC.parcounter++;
            }
            else if (FDC.parcounter == 1) {
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
            logmsg("***** parameter for unknown command %02X\n", FDC.command);
        }
    }
    
    // data
    else if (address == R8_FDDAT) {
        
        if (FDC.command != 0x0B) {
            logmsg("******** writing to data register, but last command was %02X\n", FDC.command);
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return;
        }
        
        if (FDC.bytecounter == 255) {
            unsigned int asector = RPERTR * floppy[FDC.drive].track + floppy[FDC.drive].sector;
            
            // seek
            if (fseek(floppy[FDC.drive].file, 256 * (asector - 1), SEEK_SET)) {
                logmsg("****** seek error\n");
                FDC.fdstat = 0x10; 
                FDC.fdres = 0x10;
                return;
            }
        }
        
        if (floppy[FDC.drive].file == NULL) {
            logmsg("****** data write error, file not open\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x10;
            return;
        }
        
        buffer = value;
        if (fwrite(&buffer, 1, 1, floppy[FDC.drive].file) != 1) {
            logmsg("******* data write error\n");
            FDC.fdstat = 0x10; 
            FDC.fdres = 0x0A;
            return;
        }
        
        if (FDC.bytecounter == 0) { // bytes written complete
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
    int i, end, drive, filtyp, filstp, sectorPointer, size, chr, count;
    char buffer[256];
    char *extension;
    long int dataPnt;
    FILE *foutput;
    char s[32];
    char name[64];
    int pnt = 0;
        
    count = 0;
    
    // check whether directory "Files" exists
    DIR* dir = opendir("Files");
    if (dir)
        closedir(dir);
    else
        system("mkdir Files");
    
    drive = memory[M8_FILDRV];
    
    sectorPointer = memory[M16_FILLOC] + 256 * memory[M16_FILLOC + 1];    
    
    size = memory[M16_FILSIZ] + 256 * memory[M16_FILSIZ + 1] ;    
    
    i = 15;
    while ((memory[M8_FILNAM+i] == ' ') && (i > 0) )    // find end of file name
        i--;
    end = i + 1;
    
    for (i = 0; i < end; i++) {
        
        if (memory[M8_FILNAM+i] == ':') {               // remove :
            s[i]=' ';
            end = i;
            filstp = memory[M8_FILNAM+i+1];
        }
        else {
            s[i] = memory[M8_FILNAM+i];
            filstp = 'B';                               // generic text file
        }
            
        if ((s[i] >= 'A') && (s[i] <= 'Z'))             // convert to small letters
            s[i] = s[i] + 0x20;
    }
    
    s[end] = 0;                                         // add end of string mark
    
    filtyp = memory[M8_FILTYP];
    memory[M8_FILSTP] = filstp;
    
    if (filtyp=='S') {      // sequential file
        if (filstp == 'A')
            extension = ".asm";
        else if (filstp == 'P')
            extension = ".pas";
        else if (filstp == 'H')
            extension = ".help";
       else if (filstp == 'B')
            extension = ".txt";
       else if (filstp == 'N')
            extension = ".nroff";
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
    
    snprintf(name, sizeof(name), "Files/%s%s", s, extension);
    
    foutput = fopen(name, "w");         // open output file
    if (foutput == NULL) {
        logmsg("Export: Cannot open %s\n", name);
        return (0x65);
    }
    
    if (floppy[drive].file == NULL) {
        logmsg("Export: file not open\n");
        return (7);
    }
    
    dataPnt = 256 * (long int) (sectorPointer + 32);
    int res = fseek(floppy[drive].file, dataPnt, SEEK_SET);     // skip directory track and go to start of data
    if (res != 0) {
        logmsg("Export: Seek failed\n");
        return (0x65);
    }
    
 do {
    if ((fread(&buffer, sizeof(buffer), 1,
        floppy[drive].file) != 1)) {

        logmsg("Export: read error\n");
        fclose(foutput);
        return(0x65);
    }

    int i = 0;

    if (filtyp == 'S') {          // sequential file

        while (i < 256) {

            unsigned char ch =
                (unsigned char)buffer[i];

            // end of file

            if ((ch == 0x7F) || (ch == 0x1F)) {
                fclose(foutput);
                return 0;
            }

            // compressed blanks

            if ((ch >= 0x80) && (ch <= 0xFE)) {

                for (int ii = 0;
                     ii < (ch & 0x7F); ii++) {

                    fprintf(foutput, "%c", ' ');
                }
            }

            // carriage return

            else if (ch == 0x0D) {

                fprintf(foutput, "\n");
            }

            // normal character

            else {

                fprintf(foutput, "%c", ch);
                count++;
            }

            i++;
        }
    }

    else {

        for (i = 0; i < 256; i++) {

            if ((i & 15) == 0) {
                fprintf(foutput,
                        "\n(%04x) ", pnt);
            }

            fprintf(foutput,
                    "%02x ", buffer[i]);

            pnt++;
        }
    }

    size -= 256;

} while (size >= 0);

fclose(foutput);
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
        
    // check whether directory "Files" exists
    DIR* dir = opendir("Files");
    if (dir)
        closedir(dir);
    else
        system("mkdir Files");
    
    drive = memory[M8_FILDRV];
    
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
            else if (filstp == 'H')
              extension = ".help";
            else if (filstp == 'N')
              extension = ".nroff";
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
    int res = system(estring);
    setLed(drive, 0);
    res = res >> 8;
    if (res == 255)
        return 6;  // file not found
    else {
        // prepare data for PRFLAB
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
        
    drive = memory[M8_FILDRV];
    
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
        
    if (drive == 0)
        otherdrive = 1;
    else
        otherdrive = 0;
       
    if (strcmp(floppy[otherdrive].name, s) == 0) {
        return (7);
    }
    
    strcpy(floppy[drive].name, s);
    
    // check whether file exists
    
    sprintf(s,"Disks/%s.disk", floppy[drive].name);
    floppy[drive].file = fopen(s,"r+");
    if (floppy[drive].file == NULL) {
        logmsg("Cannot open disk %s\n",s);
        floppy[drive].name[0]=0; // clear name, if floppy does not exist
        return 7;
    }
    fclose(floppy[drive].file);
    floppy[drive].file=0;
    
    return 0;
    
}
