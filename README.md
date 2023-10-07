# R65 - A late seventies computer built with a KIM-1
Assembler and Pascal code of my home built R65 computer, built 1977-1979.

This repository includes the original source files of the programs for
the system. There is also an emulator for the Raspberry Pi in the R65-Emulator
folder. The source files for the R65 programs have been tested on the
emulator.

I have built a fully functional replica 2018 based on a Raspberry Pi.

![Alt text](replica.jpg?raw=true "R65 replica built 2018")

The original program listings are in the folder Original-Program-Listings.

Original Job computer built 1977-1979:
![Alt text](job.jpg?raw=true "job system")

The only picture of the original R65 computer available, made early 1978:
I (left) am demonstrating the R65 computer to Toni Weber (right) from the Swiss toy
store chain Franz Carl Weber. The keyboard (bottom) and the TV screen (in the back)
are visible. The very early reaction time test game played used the led's on the front panel.
 ![Alt text](original.jpg?raw=true "original")

Running pong written in Tiny Pascal:
![Alt text](screen-1.jpg?raw=true "screen-1")

The graphic basic interpreter has just been started:
![Alt text](screen-2.jpg?raw=true "screen-2")

The R65 computer has been built 1977-1979 by myself together with
Rudolf Baumann, who has built his own JOB computer at the same time with similar
hardware. The picture above shows the open JOB computer. The original
R65 computer has not survived. The floppy disks have also not survived.

Hardware specifications of the original R65 Computer:
- 6502 8-bit microprocessor
- 1 MHz clock speed
- 17 kByte, 33 kByte, 49 kByte RAM (expanded 2 times between 1977 an 1979)
- 2 kByte graphics RAM
- 10 kByte ROM
- 40 x 16 char monochrome display
- 224 x 118 dot monochrome graphics display (switchable with char display)
- 2 floppy disk drives. Formatted capacity 199680 bytes each.
- Interfaces: Teletype, RS232, parallel printer, audio tape, golf-ball typewriter, tv

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
which has been modified substantially. A number of commands have been added
to the emulator version
of the extended disk operating system module. They allow to import and
export serial data files to and from the Linux operating system and to
"change floppy disks". The emulator emulates 2 floppy drives as in the
original system, but can handle an unlimited number of floppy disks.

The original text editor has not been implemented, because it must be
considered very user unfriendly given todays standards. Instead,
using the "edit" command of EXDOS, the file to edit is automatically
exported to the Linux file system, and the Linux text editor "mousepad"
is called. Once mousepad is quit, the edited file is imported automatically
back into the R65 file system. This happens automatically and very quickly.

Please note that even so the emulator includes the original KIM-1 ROM, it is NOT
a KIM-1 emulator. Only the KIM-1 hardware required for the operation of the
R65 computer system is emulated in the emulator.

The emulator uses a very nice 6502 emulation module written 2011 by
Mike Chambers (miker00lz@gmail.com). The look and feel and
speed of the emulated system is very similar to the original. Floppy
disk access is much faster

While the original system used a 8x7 matrix for the character display, I have
decided to use a high resolution font in the emulation to improve readability.

The original R65 computer included a basic interpreter, and an improved Tiny
Pascal compiler. The R65 Pascal system, which was quite powerfull for
a 8-bit microprocessor at that time, and the Basic interpreter have been reconstructed.

The basic floating point subroutines of the R65 Pascal system were published in Dr. Dobbs
Journal, Volume 1, Number 7, August 1976, page 17 by Steve Wozniak.

The original manuals had been written in German only, but the most important part has
been translated to English and is available in the Manuals folder. You should
find everything you need to install and use the emulator on a Raspberry Pi.

The installation instructions are in the manual.

The following Pascal games have currently been reconstructed:
- Reversi
- Pong
- Alien Invasion
- Starship (using an external tek4010 terminal emulator)

No Basic games have survived, but I imported a few Basic games from
http://vintage-basic.net/games.html to test the Basic interpreter.

The contributions in this repository are distributed in the hope that they will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
Please report any problems or suggestions for improvements to r77@bluewin.ch
