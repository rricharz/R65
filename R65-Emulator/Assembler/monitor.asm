*                                15/8/79 RB
*
***********************************
* MONITOR FOR JOB COMPUTER SYSTEM *
***********************************
* EPROM VERSION         15/08/79 RB
* CC RRICHARZ RBAUMANN 1977-1982
*
* MODIFIED 2018 TO START DIRECTLY IN EXDOS
*
PSTART  EQU $F800       START OF PROGRAM
*
        TIT R65/JOB MONITOR
*
* THE MONITOR IS LINKED TO THE FOLLOWING
* CONTROLER-PROGRAMS:
* R65/JOB CRT CONTROLER    E000-E7FF
* R65/JOB I/O CONTROLER    E800-EFFF
* R65/JON DISK CONTROLER   F800-FFFF
*
* ERROR CODES
*************
* 01 READ ERROR
* 02 CHECKSUM ERROR
* 03 ESCAPE EXIT DURING READ/WRITE
* 04 RECORD NUMBER ERROR
* 05 FILE TYPE ERROR
* 06 FILE NOT FOUND
* 07 DISK NOT READY
* 08 DIRECTORY FULL, FILE NOT STORED
* 09 ILLEGAL IRQ
* 10 EXPRESSION MISSING
* 11 MEMORY CELL NOT GOOD
* 12 BREAK TABLE FULL, NOT INSERTED
* 13 ILLEGAL MEMORY CELL FOR BREAK
* 14 DOUBLE BRAK POINT SETTING
* 15 END OF LINE EXPECTED
* 16 SYNTAX WRONG IN REGISTER NAME OR =
* 17 BREAKPOINT NOT FOUND IN TABLE
* 18 SYNTAX FRONG IN STORE
* 19 FILE SUBTYPE WRONG OR MISSING
* 20 WRONG FILE TYPE NOT RUN
* 21 UNKNOWN MONITOR COMMAND
* 22 ILLEGAL OPCODE FOR STEP/TRACE
* 23 TOO MANY OPEN FILES, NOT OPENED
* 24 DIRECTION ERROR IN SEQUENTIAL R/W
* 25 WRONG FILE NUMBER, FILE NOT OPEN
* 26 DISK FULL, FILE NOT STORED
*
* PAGE ZERO TEMPORARY AREA
***************************
*
* USED FOR DISASSEMBLER AND TRACER
*
        ORG $DD
DFORM   BSS 1   FORMAT
LENGHT  BSS 1   OPERAND LENGHT
LMNEM   BSS 1   MNEMONIC
RMNEM   BSS 1
DISPC   BSS 2   PC
DISCNT  BSS 1   COUNTER
*
* USED FOR LOAD/STORE
        ORG $DA
FILFLG  BSS 1
FILERR  BSS 1
FILDRV  BSS 1   TAPE OR DISK DRIVE
*
* PAGE ZERO PERMANENT DATA AREA
*******************************
*
        ORG $E7
FETCH   BSS 2   REGISTER FOR DATA ROUT.
VIDPNT  BSS 2   VIDEO POINTER
VIPNT2  BSS 2   SECOND VIDEO POINTER
CURLIN  BSS 1   CURSOR LINE
CURPOS  BSS 1   CURSOR POSITION
SAVPC   BSS 2   PROCESSOR PC SAVE
SAVST   BSS 1   PROCESSOR STATUS SAVE
SAVSP   BSS 1   PROCESSOR STACK PN SAVE
SAVACC  BSS 1   PROCESSOR A SAVE
SAVYRG  BSS 1   PROCESSOR Y SAVE
SAVXRG  BSS 1   PROCESSOR X SAVE
CHKHI   BSS 1
CHKSUM  BSS 1
INL     BSS 2   MONITOR INPUT POINTER
POINT   BSS 2   OPEN CELL POINTER
TEMP    BSS 1
TEMPX   BSS 1
KCHAR   BSS 1
MODE    BSS 1
*
* PAGE 2/3 DATA AREA:
*********************
*
        ORG $200
        BSS 256 RESERVED FOR IO CONTR.
*
FILTYP  BSS 1
FILNAM  BSS 16
FILCYC  BSS 1
FILSTP  BSS 1
FILLOC  BSS 2
FILSIZ  BSS 2
FILDAT  BSS 3
FILSA   BSS 2
FILEA   BSS 2
FILLNK  BSS 2
*
FILNM1  BSS 16
FILCY1  BSS 1
FILSA1  BSS 2
*
* PAGE 17 DATA AREA:
********************
*
        ORG $1780
VFLAG   BSS 1   VIDEO FLAG REGISTER
SFLAG   BSS 1   SYSTEM FLAG REGISTER
*
        BSS 23  RESERVED FOR CRT CONTR.
        BSS 28  RESERVED FOR IO CONTR.
NUMCHR  EQU $178A       CHARS PER LINE
NMI     EQU $179A       NMI VECTOR
BREAK   EQU $17AC       BREAK VECTOR
CNTL    EQU $17F2       TTY DELAY
CNTH    EQU $17F3       TTY DELAY
*
TIME    BSS 4   1/20 SEC,SEC,MIN,HOUR
DATE    BSS 3   DAY/MONTH/YEAR
*
TRACFL  BSS 1   TRACE FLAG/COUNTER
BREAKT  BSS 24  BREAK TABLE (8)
*
VMON    BSS 2   VECTOR FOR MONITOR
*
*
* VECTORS TO OTHER EPROMS:
**************************
*
GETKEY  EQU $E000       GET KEY FROM KB
GETLIN  EQU $E006       GET LINE
PRTCHR  EQU $E009       PRINT CHAR TO SCREEN
INITCR  EQU $E01B       INIT CRT CONTR.
ENDLIN  EQU $E024       TEST END OF LINE
PRTREG  EQU $E033       PRINT CPU REGISTER
RSTIOC  EQU $E803       RESET I/O CONTR.
PRTINF  EQU $E027       PRINT STRING
PRTBYT  EQU $E02D       PRINT HEX BYTE
PRTAX   EQU $E030       PRINT 2 BYTES
ESCTST  EQU $E806       ESCAPE TEST, DURING I=1
RDFILE  EQU $E815       READ BLOCK FILE
WRFILE  EQU $E81B       WRITE BLOCK FILE
TDIR    EQU $E809       PRINT TAPE DIRECTORY
RSTFLD  EQU $F006       RESET DISK CONTR.
DDIR    EQU $F009       PRINT DISK DIRECTORY
DELETE  EQU $F00C       DELETE FILE ON DISK
DECCPS  EQU $1CA0       GO TO KIM MONITOR
GOEXEC  EQU $1DC8       GO TO USER PROGRAM
INITS   EQU $1E88       INITIALIZE KIM
INCPT   EQU $1F63       INCREMENT POINT
PACK    EQU $1FAC       PACK INPUT (HEX)
OPEN    EQU $1FCC       INL TO POINT (2 BT)
IRQ     EQU $E833       IRQ PRIORITY HANDLER
EXDOS   EQU $C800       EXDOS
*
* OPCODE TABLE FOR DISASSEMBLER
*
DISMOD  EQU $E722
MODE2   EQU $E766
CHAR1   EQU $E774
CHAR2   EQU $E77A
MNEML   EQU $E780
MNEMR   EQU $E7C0
*
        PAG
*
* START OF PROGRAM
*
        ORG PSTART
*
* VECTORS TO SUBROUTINES
************************
*
        JMP RESET       RESET AND GOTO MONITOR
        JMP ILLIRQ      ILLEGAL INTERRUPT
        JMP HEXPDF      GET HEX EXPRESSION
        JMP HEXPZE
        JMP TEST        TEST INPUT
        JMP PRTDAT      PRINT DATE
        JMP PRTTIM      PRINT TIME
        JMP GETNAM      GET FILENAME FOR INPUT
        JMP ADAPT       ADAPT CHARS FOR OUTPUT
*
* SYSTEM RESET ROUTINE
**********************
* CALLED BY RESET AND ON STARTUP
*
RESET   LDX =$FF        RESET STACK POINTER
        TXS
        STX SAVSP
        JSR INITS
        LDX =0          CLEAR CPU FLAG
        STX SAVST
        CLD
*
        LDA =<STOP      SET NMI AND BREAK
        STA NMI
        STA BREAK
        LDA =>STOP
        STA NMI+1
        STA BREAK+1
*
        LDA =$80        SET DEFAULT BAUD RATE
        STA CNTL        (110 BAUD)
        LDA =2
        STA CNTH
*
        LDA =<GETCOM
        STA VMON
        LDA =>GETCOM
        STA VMON+1
*
        TXA             A=0
        LDX =24         CLEAR BREAK TABLE
        STA TRACFL,X    AND TRACE FLAG
        DEX
        BPL *-4
*
        JSR INITCR      INIT CRT-CONTROL
        JSR RSTIOC      INIT IO-CONTROL
        JSR RSTFLD      INIT DISK-CONTROL
*
        CLI             ALLOW NOW INTERRUPTS
*
        JSR PRTINF
        BYT 'R65 MONITOR '
        BYT '1978-1982 VERSION 3.01',$D,$8A
        JMP EXDOS
*
*
* GETCOM: GET MONITOR COMMAND, MAIN LOOP
****************************************
*
GETCOM  JSR PRTINF
        BYT $D,$A,$AA
        JSR GETLIN      GET A LINE
        JSR INTCOM
        JMP GETCOM
*
* STOP: NMI AND BREAK ROUTINE
*****************************
*
STOP    STA SAVACC
        PLA
        STA SAVST
        PLA
        STA SAVPC
        PLA
        STA SAVPC+1
        STY SAVYRG
        STX SAVXRG
        CLD
        CLI
        TSX
        STX SAVSP
        LDA SAVST       TEST FOR BREAK
        AND =$10
        BNE EXBRK
        JSR PRTREG
        JSR PRTINF
        BYT 'NM',128+'I'
        JMP (VMON)
*
EXBRK   SEC
        LDA SAVPC
        SBC =2
        STA SAVPC
        STA INL
        BCS *+4
        DEC SAVPC+1
        LDA SAVPC+1
        STA INL+1
        JSR PRTREG
        JSR PRTINF
        BYT 'BR',128+'K'
        JSR CLRB1       CLEAR THIS BREAKPOINT
        LDA TRACFL
        BEQ EXBRK-3     JUMP TO (VMON)
        JMP TRACEM      CONTINUE TRACING
*
*
* HEXP: GET HEX EXPRESSION
**************************
*
* HEXPPC: DEFAULT PC
* HEXPDF: DEFAULT IN A,X
* HEXPZE: DEFAULT =0
* HEXPER: ERROR, IF NOT HEX DIGIT
*
HEXPPC  LDA SAVPC
        LDX SAVPC+1
*
HEXPDF  STA INL
        STX INL+1
        JSR ENDLIN
        JSR PACKTS
        BNE HEXP3
*
HEXPZE  LDA =0
        STA INL
        STA INL+1
        JSR ENDLIN
HEXP1   JSR PACKTS
        BNE HEXP3
HEXP2   INY
        CPY NUMCHR
        BNE HEXP1
HEXP3   LDA INL
        LDX INL+1
        RTS
*
HEXPER  JSR ENDLIN
        JSR PACKTS
        BEQ HEXPZE
        LDA =$10        ERROR 10
        JMP ERROR
*
PACKTS  LDA (VIDPNT),Y
        JSR ADAPT
        STY TEMP
        CMP =$3A
        BMI PACKT1
        CMP =$41
        BMI PACKT1+3
PACKT1  JSR PACK
        LDY TEMP
        CMP =0
        RTS
*
* ERROR ROUTINE:
****************
*
ILLIRQ  LDA =$09        ERROR 9
*
ERROR   TAY
        LDX =$FF
        TXS
        JSR PRTINF
        BYT $0D,$0A,$7,'*** ERROR',$A0
        TYA
        JSR PRTBYT
        JMP (VMON)
*
* TEST: COMPARE INPUT BUFFER WITH ARG
*************************************
* ARG FOLLOWS SUBROUTINE CALL, LAST CHAR
* HAS BIT 7 SET, RETURN C=0 IF EQUAL, ELSE C=1.
* INPUT BUFFER IS ADDRESSED BY (VIDPNT),Y.
* Y IS SAVED IF NOT EQUAL, ELSE Y IS INCREASED
* TO FIRST BYTE AFTER MATCHING
* STRING IN INPUT BUFFER
*
TEST    JSR ENDLIN
        PLA             GET DATA POINTER
        STA FETCH
        PLA
        STA FETCH+1
        TYA             SAVE Y
        PHA
        TXA             SAVE X
        PHA
        LDX =0
TEST1   JSR INCFET
        LDA (FETCH,X)
        BMI TEST4       LAST CHAR FOUND
        LDA (VIDPNT),Y
        JSR ADAPT
        CMP (FETCH,X)
        BNE TEST2       DIFFERENCE FOUND
        CPY NUMCHR
        BEQ TEST2
        INY
        BNE TEST1       ALLWAYS TAKEN
*
TEST2   LDA (FETCH,X)
        BMI TEST3
        JSR INCFET
        JMP TEST2
*
TEST3   PLA
        TAX
        SEC
        PLA
        TAY
        JSR INCFET
        JMP (FETCH)
*
TEST4   LDA (VIDPNT),Y
        JSR ADAPT
        ORA =$80
        CMP (FETCH,X)
        BNE TEST2
        CPY NUMCHR      END OF LINE?
        BEQ *+3
        INY
        PLA
        TAX
        PLA
        CLC
        JMP TEST4-6
*
ADAPT   AND =$7F        IGNORE INVERSE VIDEO
        CMP =$61        AND CAPITALIZE
        BCC ADAPT1
        CMP =$7B
        BCS ADAPT1
        AND =$DF
ADAPT1  RTS
*
INCFET  INC FETCH
        BNE *+4
        INC FETCH+1
        RTS
*
* ENDER: ERROR, IF NOT EOL
**************************
*
ENDLER  JSR ENDLIN
        BEQ ENDLER-1    RTS, IF EOL
        LDA =$15        ERROR 15
        JMP ERROR
*
* GETDAT: GET DATE
******************
*
GETDAT  JSR GETLIN
        JSR ENDLIN
        BEQ ENDLER-1    RTS IF EOL
        JSR HEXPZE      GET DAY
        STA DATE
        JSR GETDA1      GET MONTH
        STA DATE+1
        JSR GETDA1      GET YEAR
        STA DATE+2
        JMP ENDLER
*
GETDA1  JSR TEST
        BYT 128+'/'
        JMP HEXPZE
*
* GETTIM: GET TIME
******************
*
GETTIM  JSR GETLIN
        JSR ENDLIN
        BEQ ENDLER-1    RTS IF EOL
        JSR HEXPZE      GET HOURS
        STA TIME+3
        JSR TEST
        BYT 128+':'
        JSR HEXPZE      GET MINUTES
        STA TIME+2
        LDA =0
        STA TIME
        STA TIME+1
        JMP ENDLER
*
* INTCOM: INTERPRET MONITOR COMMANDS
************************************
* CAN BE CALLED FROM OTHER PROGRAMS, TRACE
* COMMANDS AND BREAKPOINTS RETURN TO MONITOR
* MAIN LOOP, INTERPRETATION STARTS AT
* (VIDPNT),Y
*
INTCOM  BCC *+3
        RTS             RETURN, IF ESCAPE
*
        JSR ENDLIN
        BEQ *-4         RTS, IF EOL
        JSR TEST
        BYT 'G',128+'O' *** GO ***
        BCS INTC1
GO      JSR HEXPPC
        JSR OPEN
        JSR TEST
        BYT 128+','
        BCS *+5
        JSR REG1        SET REGISTERS
*
        JMP GOEXEC
*
*
INTC1   JSR TEST
        BYT 128+'/'     *** /(OPEN MEMORY)***
        BCS INTC2
OPM0    JSR HEXPZE
        JSR ENDLER      ERROR, IF NOT EOL
        JSR OPEN
*
OPM1    JSR PRTINF
        BYT $D,$A,$A8
        LDA POINT+1
        LDX POINT
        JSR PRTAX
        JSR PRTINF
        BYT $29,$20,$A0
        LDY =0
        LDA (POINT),Y
        JSR PRTBYT
        JSR PRTINF
        BYT $20,$A0
        JSR GETLIN
        BCC *+3
        RTS             RETURN, IF ESCAPE
*
        JSR ENDLIN
        BNE OPM2
*
OPM1A   JSR INCPT       RETURN, NEXT CELL
        JMP OPM1
*
OPM2    JSR ADAPT
        CMP ='L'        LAST CELL
        BNE OPM3
        LDA POINT
        BNE *+4
        DEC POINT+1
        DEC POINT
        JMP OPM1
*
OPM3    CMP ='''        ASCII?
        BNE OPM4
        INY
        LDA (VIDPNT),Y
OPM3A   LDY =0
        STA (POINT),Y
        CMP (POINT),Y
        BEQ OPM1A
        LDA =$11        ERROR 11
        JMP ERROR
*
OPM4    CMP ='/'        NEW CELL
        BNE OPM5
        INY
        JMP OPM0
*
OPM5    JSR HEXPER
        JSR ENDLER
        LDA INL
        JMP OPM3A
*
*
INTC2   JSR TEST
        BYT 'GS',128+'B'  *** GSB ***
        BCS INTC3
        TSX
        STX SAVSP       SET STACK POINTER
        JMP GO
*
*
INTC3   JSR TEST
        BYT 'SET',128+'B'   *** SETBR ***
        BCS INTC4
        JSR HEXPER
        JSR ENDLER
SETB1   LDX =7
        LDA BREAKT,X    CHECK IN TABLE
        BEQ SETB3
        DEX
        BPL SETB1+2
        LDA =$12        ERROR 12
        JSR ERROR
*
SETB3   LDA INL
        STA BREAKT+8,X
        LDA INL+1
        STA BREAKT+16,X
        LDY =0
        LDA (INL),Y
        BEQ SETB4
        STA BREAKT,X
        TYA
        STA (INL),Y
        CMP (INL),Y
        BNE *+3
        RTS
        STA BREAKT,X
        LDA =$13        ERROR 13
        JMP ERROR
*
SETB4   LDA =$14
        JMP ERROR       ERROR 14
*
*
INTC4   JSR TEST
        BYT 'CLR',128+'B'   *** CLRB ***
        BCS INTC5
        JSR HEXPER
        JSR ENDLER
CLRB1   LDX =7
        LDA BREAKT+8,X
        CMP INL
        BNE CLRB3
        LDA BREAKT+16,X
        CMP INL+1
        BEQ CLRB4
CLRB3   DEX
        BPL CLRB1+2
        LDA =$17        ERROR 17
        JMP ERROR
CLRB4   LDA BREAKT,X
        BEQ CLRB3
        LDY =0
        STA (INL),Y
        TYA
        STA BREAKT,X
        RTS
*
*
INTC5   JSR TEST
        BYT 'RESET',128+'B'   *** RESETB ***
        BCS INTC6
        JSR ENDLER
*
RESB1   LDX =7
        LDA BREAKT,X
        BEQ RESB3
        LDA BREAKT+8,X
        STA INL
        LDA BREAKT+16,X
        STA INL+1
        JSR CLRB4
RESB3   DEX
        BPL RESB1+2
        RTS
*
INTC6   JSR TEST
        BYT 'PRT',128+'B'   *** PRTB ***
        BCS INTC7
        JSR ENDLER
        LDX =7
PRTB2   LDA BREAKT,X
        BEQ PRTB3
        JSR PRTINF
        BYT $89         TAB
        LDA BREAKT+16,X
        JSR PRTBYT
        LDA BREAKT+8,X
        JSR PRTBYT
PRTB3   DEX
        BPL PRTB2
        RTS
*
*
INTC7   JSR TEST
        BYT 'RE',128+'G'  *** REG ***
        BCS INTC8
        JSR ENDLIN
        BNE REG1
        JSR PRTREG
        JSR PRTINF
        BYT $D,$A,'R',128+'*'
        JSR GETLIN
        LDY =2
        JSR ENDLIN
        BNE REG1
        RTS
*
REG1    JSR ENDLIN
        LDA (VIDPNT),Y
        JSR ADAPT
        LDX =6
REG2    CMP REG6-1,X
        BEQ REG4
        DEX
        BNE REG2
REG3    LDA =$16        ERROR 16
        JMP ERROR
*
REG4    INY
        JSR TEST
        BYT 128+'='
        BCS REG3
        TXA
        PHA
        JSR HEXPZE
        PLA
        TAX
        LDA INL
        STA SAVPC,X
        CPX =1
        BNE REG5
        STA SAVPC
        LDA INL+1
        STA SAVPC+1
REG5    JSR TEST
        BYT 128+','
        BCC REG1
        JMP ENDLER
*
REG6    BYT 'PFSAYX'
*
*
INTC8   JSR TEST
        BYT 'DAT',128+'E'   *** DATE ***
        BCS INTC9
        JSR ENDLER
        JSR PRTINF
        BYT $D,$8A
        JSR PRTDAT
        JMP GETDAT
*
PRTDAT  LDX =0
        LDA DATE,X
        JSR PRTBYT
        INX
        CPX =3
        BEQ PRTDA1
        JSR PRTINF
        BYT 128+'/'
        JMP PRTDAT+2
*
PRTDA1  JSR PRTINF
        BYT $A0
        RTS
*
PRTTIM  LDX =3
        LDA TIME,X
        JSR PRTBYT
        DEX
        BEQ PRTDA1
        JSR PRTINF
        BYT 128+':'
        JMP PRTTIM+2
*
INTC9   JSR TEST
        BYT 'TIM',128+'E'   *** TIME ***
        BCS INTC10
        JSR ENDLER
        JSR PRTINF
        BYT $0D,$8A
        JSR PRTTIM
        JMP GETTIM
*
*
INTC10  JSR TEST
        BYT 'DI',128+'S'   *** DIS ***
        BCS INTC11
        LDA DISPC
        LDX DISPC+1
        JSR HEXPDF
        STA DISPC
        STX DISPC+1
        JSR TEST
        BYT 128+','
        LDA =11
        JSR HEXPDF
        JSR DSMBL+2
DIS1    JSR GETKEY
        BEQ DIS2
        CMP =$D
        BNE DIS2
        JSR DSMBL
        JMP DIS1
*
DIS2    RTS             RETURN AFTER ESCAPE
*
*
INTC11  JSR TEST
        BYT 'STE',128+'P'   *** STEP ***
        BCS INTC12
        JSR HEXPPC
        JSR ENDLER
        LDA INL
        STA SAVPC
        LDA INL+1
        STA SAVPC+1
        LDA =$80
        STA TRACFL      STEPPING
        JMP STEP
*
*
INTC12  JSR TEST
        BYT 'TRAC',128+'E'   *** TRACE ***
        BCS INTC13
        JSR HEXPPC
        STA SAVPC
        STX SAVPC+1
        JSR TEST
        BYT 128+','
        LDA =6
        JSR HEXPDF
        AND =$7F        MAX 127 STEPS
        BNE *+4
        LDA =1
        STA TRACFL
TRACEM  BPL TRACE3
TRACE2  JSR GETKEY
        BNE TRACE4
        LDA =0
        STA TRACFL
        JMP (VMON)
*
TRACE4  CMP =$D
        BNE TRACE2+5
        BEQ TRACE3+3    STEP
*
TRACE3  DEC TRACFL
        JMP STEP
*
*
INTC13  JSR TEST
        BYT 'LOA',128+'D'   *** LOAD ***
        BCS INTC14
*
BFLOAD  JSR GETNAM      GET FILE NAME
        JSR HARGUM      GET DRIVE, DEFAULT=0
        STA FILDRV
        JSR HARGUM      GET START ADDRESS
        STA FILSA1
        STX FILSA1+1
        JSR ENDLER
        LDA =0
        STA FILFLG
        JSR RDFILE
        BNE LOADER
        LDA FILSA
        STA SAVPC
        LDA FILSA+1
        STA SAVPC+1
        RTS
*
LOADER  JMP ERROR
*
* HARGUM: GET ARGUMENT (, OR HEXPZE)
************************************
*
HARGUM  JSR TEST
        BYT 128+','
        JMP HEXPZE
*
*
INTC14  JSR TEST
        BYT 'RU',128+'N'   *** RUN ***
        BCS INTC15
        JSR BFLOAD
        LDA FILSTP
        CMP ='M'        MUST BE ML PROGRAM
        BEQ RUN1
        LDA =$20        ERROR 20
        JMP ERROR
*
RUN1    LDA SAVPC       GET START ADDRESS
        LDX SAVPC+1
        STA INL
        STX INL+1
        JMP GO+3
*
*
INTC15  JSR TEST
        BYT 'DI',128+'R'   *** DIR ***
        BCS INTC16
*
        JSR HEXPZE      GET DRIVE NUMBER
        STA FILDRV
        AND =2
        BNE *+5
        JMP DDIR        DISK DIRECTORY
        JMP TDIR        TAPE DIRECTORY
*
*
INTC16  JSR TEST
        BYT 'DELET',128+'E'   *** DELETE ***
        BCS INTC17
*
        JSR GETNAM      GET FILE NAME
        JSR HARGUM      GET DISK DRIVE
        STA FILDRV
        JSR DELETE
        BEQ *+5
        JMP ERROR
        RTS
*
*
INTC17  JSR TEST
        BYT 'STOR',128+'E'   *** STORE ***
        BCC *+7
        LDA =$21        ERROR 21
        JMP ERROR
        JSR GETNAM
        LDX =16
        LDA FILNM1,X    TRANSFER
        STA FILNAM,X
        DEX
        BPL *-7
        JSR HARGUM      GET DRIVE
        STA FILDRV
        JSR TEST
        BYT 128+','
        BCS STORE1      SYNTAX ERROR?
        JSR HEXPER
        STA FILSA
        STX FILSA+1
        JSR TEST
        BYT 128+'-'
        BCS STORE1
        JSR HEXPER
        STA FILEA
        STX FILEA+1
        JSR TEST
        BYT 128+','     SYNTAX ERROR?
        BCS STORE1
        JSR TEST
        BYT 128+'P'     PROTECTED FLAG?
        LDA =0
        BCS *+4
        LDA =$80
        STA FILFLG      PROTECTED FLAG
        LDA (VIDPNT),Y
        INY
        JSR ADAPT
        CMP =$41
        BCC STORE2      MUST BE LETTER
        CMP =$5C
        BCS STORE2
        STA FILSTP
        JSR HARGUM
        STA FILLOC
        STX FILLOC+1
        JSR ENDLER
        JSR WRFILE
        BNE STORE1+2
        RTS
*
STORE1  LDA =$18        ERROR 18
        JMP ERROR
*
STORE2  LDA =$19        ERROR 19
        BNE STORE1+2
*
*
* GETNAM: GET FILE NAME
***********************
*
GETNAM  JSR ENDLIN
        LDA =$20
        LDX =16
        STA FILNM1-1,X
        DEX
        BNE *-4
        STX FILCY1      IS 0
GETNM0  LDA (VIDPNT),Y
        AND =$7F
        CMP =','
        BEQ GETNM2      END OF NAME
        CMP ='.'
        BEQ GETNM1
        CPX =16
        BCS *+5
        STA FILNM1,X
        INY
        CPY NUMCHR
        BCS GETNM3
        INX
        BNE GETNM0      ALLWAYS TAKEN
*
GETNM1  INY
        JSR HEXPZE
        STA FILCY1
        RTS
*
GETNM2  CPX =0
        BNE GETNM3
        STX FILNM1      READ NEXT FILE ON TAPE
GETNM3  RTS
*
*
* TRACE AND STEP ROUTINE
************************
* ESCAPE TEST IS MADE AFTER EVERY STEP,EVERY
* LINE IS DISASSEMBLED AND A BREAKPOINT SET
* AT THE FOLLOWING INSTRUCTION CODE. RTS,RTI
* AND BRK GIVE AN ERROR STOP. SUBROUTINES
* ARE EXECUTED IN REAL TIME
*
STEP    LDA SAVPC
        STA DISPC
        LDA SAVPC+1
        STA DISPC+1
        JSR INTDS       DISASSEMBLE ONE CODE
        LDA SAVPC
        STA INL
        LDA SAVPC+1
        STA INL+1
        JSR OPEN
        LDY =0
COMPST  LDA (DISPC),Y   GET OPCODE
        CMP =$4C        IF JMP
        CLC
        BEQ COMPS1
        CMP =$6C        OR JMP (IND)
        SEC
        BNE COMPS3
*
COMPS1  INY             COMPUTE TARGET
        LDA (DISPC),Y
        STA INL
        INY
        LDA (DISPC),Y
        STA INL+1
        BCC COMPS2      SKIP, IF DIRECT
*
        LDA (INL),Y
        TAX
        DEY
        LDA (INL),Y
        STA INL
        STX INL+1
*
COMPS2  JMP COMPS4
*
COMPS3  TAY             SAVE CODE
        AND =$F
        BNE CODE
        TYA
        AND =$10
        BEQ TSTBRK
        TYA
        LSR A
        LSR A
        LSR A
        LSR A
        LSR A
        LSR A
        TAX
        LDA MASK,X
        BIT SAVST
        BCS BITSET
NOTSET  BNE CODE
        JMP DOBRA
BITSET  BNE *-3
*
TSTBRK  TYA
        BEQ ENDST       BRK
        CMP =$60
        BEQ ENDST       RST
        CMP =$40
        BNE CODE        RTI
*
ENDST   LDA =$22        ERROR 22
        JMP ERROR
*
CODE    LDA LMNEM
        BNE ENDST       SKIP, IF ILLEGAL CODE
        JSR PCADJ
COMS4A  STA INL
        STY INL+1
COMPS4  JSR SETB1       SET BREAKPOINT
        JMP GOEXEC      DO THE INSTRUCTION
*
DOBRA   SEC             COMPUTE BRANCH
        LDY =1
        LDA (DISPC),Y
        JSR PCADJ3
        TAX
        INX
        BNE *+3
        INY
        TXA
        JMP COMS4A
*
MASK    BYT $80,$40,$01,$02
*
*
* DISASSEMBLER ROUTINES:
************************
* DISASSEMBLE ONE OR SEVERAL LINES FROM MEMORY.
* INVALID OPCODES ARE ASSUMED TO BE ONE BYTE
*
DSMBL   LDA =12         12 INSTRUCTIONS
        STA DISCNT
DSMBL2  JSR INTDS
        JSR PCADJ
        STA DISPC
        STY DISPC+1
        DEC DISCNT
        BNE DSMBL2
        RTS
*
INTDS   JSR ESCTST      ESCAPE?
        BCC *+5
        JMP TRACE2+5
*
        JSR PRPC        PRINT PC
        LDA (DISPC,X)   GET OPCODE, X IS 0
        TAY
        LSR A           ODD,EVEN TEST
        BCC IEVEN
        LSR A
        BCS ERR         XXXXXX11 INVALID
        CMP =$22
        BEQ ERR         10001001 INVALID
        AND =7
        ORA =$80        ADD INDEXING OFFSET
*
IEVEN   LSR A
        TAX
        LDA DISMOD,X    INDEXING INTO ADDRESS
        BCS RTMODE      MODE TABLE
        LSR A
        LSR A
        LSR A
        LSR A
*
RTMODE  AND =$F         MASK FOR 4 BIT INDEX
        BNE GETFMT
*
ERR     LDY =$80        SUBSTITUTE 80 FOR INVAL
        LDA =0          VALID CODE
GETFMT  TAX
        LDA MODE2,X
        STA DFORM
        AND =3
        STA LENGHT
        TYA
        AND =$8F
        TAX
        TYA
        LDY =3
        CPX =$8A
        BEQ MNNDX3
MNNDX1  LSR A
        BCC MNNDX3
        LSR A
MNNDX2  LSR A
        ORA =$20
        DEY
        BNE MNNDX2
        INY
MNNDX3  DEY
        BNE MNNDX1
        PHA
*
PROP    LDA (DISPC),Y
        JSR PRTBYT
        LDX =1
PROPBL  JSR PRBL2
        CPY LENGHT
        INY
        BCC PROP
        LDX =3
        CPY =4
        BCC PROPBL
        PLA
        TAY
        LDA MNEML,Y
        STA LMNEM
        LDA MNEMR,Y
        STA RMNEM
PRMN1   LDA =0
        LDY =5
PRMN2   ASL RMNEM
        ROL LMNEM
        ROL A
        DEY
        BNE PRMN2
        ADC =$3F
        JSR PRTCHR
        DEX
        BNE PRMN1
        JSR PRBLNK
        LDX =6
PRADR1  CPX =3
        BNE PRADR3
        LDY LENGHT
        BEQ PRADR3
PRADR2  LDA DFORM
        CMP =$E8
        LDA (DISPC),Y
        BCS RELADR
        JSR PRTBYT
        DEY
        BNE PRADR2
PRADR3  ASL DFORM
        BCC PRADR4
        LDA CHAR1-1,X
        JSR PRTCHR
        LDA CHAR2-1,X
        BEQ PRADR4
        JSR PRTCHR
PRADR4  DEX
        BNE PRADR1
        RTS
*
RELADR  JSR PCADJ3
        TAX
        INX
        BNE PRNTYX
        INY
PRNTYX  TYA
        JMP PRTAX
*
PRPC    JSR PRTINF
        BYT $0D,$8A
        LDA DISPC+1
        LDX DISPC
        JSR PRTAX
        JSR PRTINF
        BYT $AD
PRBLNK  LDX =3
PRBL2   LDA =$20
PRBL3   JSR PRTCHR
        DEX
        BNE PRBL2
        RTS
*
PCADJ   LDY =0
        LDA (DISPC),Y
        CMP =$20
        BNE PCADJ0
        LDX =2
PCADJ6  LDY =1
        LDA (DISPC),Y
        CMP SUBTBL,X
        BNE PCADJ7
        INY
        LDA (DISPC),Y
        CMP SUBTBL+1,X
        BEQ PCADJ8
PCADJ7  DEX
        DEX
        BPL PCADJ6
        JMP PCADJ0
        INY
PCADJ8  JSR PRTINF
        BYT $D,$A,9,9,'    BYT ',$A0
        LDX =6
CALCL1  DEX
        BEQ PCADJ8
        INY
        LDA (DISPC),Y
        PHA
        JSR PRTBYT
        JSR PRTINF
        BYT $AC
        PLA
        BPL CALCL1
        TYA
        JMP PCADJ2
PCADJ0  LDA LENGHT
PCADJ2  SEC
PCADJ3  LDY DISPC+1
        TAX
        BPL PCADJ4
        DEY
PCADJ4  ADC DISPC
        BCC RTS1
        INY
RTS1    RTS
*
SUBTBL  WRD PRTINF,PSTART+12
*
*
* SYSTEM VECTORS FOR CPU RESET, NMI AND IRQ
*******************************************
*
        ORG $FFF7
*
EXSNMI  JMP (NMI)
*
SYSNMI  WRD EXSNMI
SYSRST  WRD RESET
SYSIRQ  WRD IRQ
*
        END


