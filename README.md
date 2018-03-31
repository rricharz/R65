# R65 - A late seventies computer built with a KIM-1
Assembler and Pascal code of my home built R65 computer, built 1977-1979.

This repository includes the original source files of the programs for
the system. There is also an emulator for the Raspberry Pi in the R65-Emulator
folder. The source files for the R65 programs have been tested on the
emulator.

The original program listings are in the folder Original-Program-Listings.

![Alt text](job.jpg?raw=true "job system") ![Alt text](emulator.jpg?raw=true "emulator")

The R65 computer has been built 1977-1979 by myself together with
Rudolf Baumann, who has built his own JOB computer at the same time with similar
hardware. The picture above shows the opened JOB computer. The original
R65 computer has not survived. The floppy disks have also not survived.

Most of the original 6502 assembler programs have been written by myself
1977 - 1980, some of them based on code snippets found in publications.
They have been modified and improved up to 1982 by Rudolf Baumann
for his hardware. Thanks to him for keeping his hardware (not
functional anymore) and printed program listings up to today. The program
listings have been scanned and digitized 2018 by myself.

The main software includes the original KIM-1 ROM and 4 modules,
which were burned on EPROMS at that time. These modules are:

- A system monitor module, which is executed at startup
- A disk controller module, which handles the access to the floppy drives
- A IO controller module, which handles other IO
- A crt controller module, which handles the display

These 4 modules run in their original version, with the exception of
a few minor bug fixes.

The software also includes an extended disk operating system module (EXDOS),
which has been modified substantially. In this module, the commands allowing
to manipulate the data on the inherently unreliable floppy disks have been removed.
They were available in
the original R65 systems to allow to recover data from broken floppy disks.
Because the floppy disk emulation of the emulator is reliable, they are not
required anymore. A number of commands have been added to the emulator version
of the extended disk operating system module. They allow to import and
export serial data files to and from the Linux operating system and to
"change floppy disks". The emulator emulates 2 floppy drives as in the
original system, but can handle an unlimited number of floppy disks.

The original text editor has not been implemented, because it must be
considered extremly user unfriendly given todays standards. Instead,
using the "edit" command of EXDOS, the file to edit is automatically
exported to the Linux file system, and the Linux text editor "leafpad"
is called. Once leafpad is quit, the edited file is imported automatically
back into the R65 file system. This happens automatically and very quickly.

Please note that even so the emulator includes the original KIM-1 ROM, it is NOT
a KIM-1 emulator. Only the KIM-1 hardware required for the operation of the
R65 computer system is emulated in the emulator.

The emulator uses a very nice 6502 emulation module written 2011 by
Mike Chambers (miker00lz@gmail.com). The execution of the 6502 code
is time accurate, but the emulation of the R65 hardware might cause
some slight slowdown under certain circumstances. The look and feel and
speed of the emulated systems is very similar to the original.

The original R65 computer also included a basic interpreter, and a "tiny"
pascal compiler. The R65 Pascal system, which was quite powerfull for
a 8-bit microprocessor at that time, has now been reconstructed. I'm
currently working on the reconstruction of the Basic interpreter.

The manuals had been written in German only, but the OS manual has already
been translated to English and is available in the Manuals folder.

The installation instructions are in the manual.

The following Pascal games have currently been reconstructed:
- Reversi
- Pong
- Alien Invasion

Basic games will be made available once the Basic interpreter is ready.

The contributions in this repository are distributed in the hope that they will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
Please report any problems or suggestions for improvements to r77@bluewin.ch
