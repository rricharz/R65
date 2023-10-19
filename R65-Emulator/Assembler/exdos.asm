*
**************************************
* R65 EXTENDED DISK OPERATING SYSTEM *
**************************************
*
* BASED ON VERSION 3.2 21/08/82
* RRICHARZ RBAUMANN 1978-1982
* VERSION 4.6 2018-2023
*   MODIFIED FOR R65 EMULATOR
*   AND LARGER DISK SIZE
*   BY RRICHARZ
*
*
* NEW COMMANDS FOR EMULATED SYSTEM:
*   EXPORT FILNAM.CY,DRIVE
*               EXPORT SEQUENTIAL FILE
*   IMPORT FILNAM.CY,DRIVE
*               IMPORT SEQUENTIAL FILE
*   EDIT FILNAM.CY,DRIVE
*               EDIT A SEQUENTIAL FILE
*               USING LEAFPAD
*   FLOPPY FILNAM,DRIVE
*               CHANGE FLOPPY DISK
*   NEW FILNAM.CY,DRIVE
*               NEW SEQUENTIAL FILE
*
* NEW GRAPHICS SUBROUTINES
*   PLOT(X,Y,MODE)      PLOT A DOT
*   PLOTCH(X,Y,CHR)     PLOT A 8x8 CHAR
*   BITMAP(X,Y,MAP)     PLOT A 4x4 MAP
*   DRAWX(X,Y,MODE,N)   DRAW N POINTS
*   DRAWY(X,Y,MODE,N)   DRAW N POINTS
*   DRAWXY(X,Y,MODE,N,XONC,YINC)
*
* WITH FAST PACK ROUTINE
* USES SCRATCH MEMORY $D700-$DEFF
* UPDATED FOR DUAL DISK DRIVE SYSTEMS
* WITH WILD CARD DIRECTORY
*
*   ERROR 61: WILD CARD NOT ALLOWED
*   ERROR 62: ONLY FOR DISK, NOT TAPE
*   ERROR 63: ILLEGAL COPY
*   ERROR 64: FILE TOO LARGE
*   ERROR 65: WRITE ERROR
*   ERROR 66: IMPORT ERROR
*   ERROR 67: UNKNOWN EMU COMMAND
*   ERROR 68: UNABLE TO RUN LEAFPAD
*
*
PSTART  EQU $C800       START OF PROGRAM
SPERTR  EQU 16          SECTORS PER TRACK
NTRACK  EQU 160         TRACKS
NRSEQ   EQU 2560        TOTAL SECTORS (16*160)
*
        TIT EXTENDED DISK OPERATING SYSTEM
*
*
* PAGE ZERO VARIABLES
*********************
*
        ORG $D8
*
COPYBN  BSS 2   POINTER FOR COPY SEQF
*
FILFLG  BSS 1   FILE ENTRY FLAGS
*               BIT 7=1: PROTECTED
*               BIT 6=1: NO PRINTED OUTPUT
*               BIT 5: DIRECTION (1=WRITE)
*
FILERR  BSS 1   FILE HANDLING ERROR
FILDRV  BSS 1   TAPE OR DISK DRIVE
*
* TAPE TEMPORARIES
*
TRECID  BSS 2   RECORD ID OF FIRST RECORD
TRECNO  BSS 1   RECORD NUMBER
TRECST  BSS 2   START ADDRESS POINTER
TRECSI  BSS 1   RECORD SIZE
*
* DISK TEMPORARIES
*
        ORG $DD
TRACK   BSS 1   CURRENT TRACK
SECTOR  BSS 1   CURRENT SECTOR
RESSAV  BSS 1   CURRENT FDC RESULT
DATA    BSS 2   DATA POINTER
DOSPNT  BSS 2   SECOND POINTER
FILCNT  BSS 1   DISK FILE POINTER
FILCN1  BSS 1
*
VIDPNT  EQU $E9 VIDEO MEMORY POINTER
POINT   EQU $FA USED AS SEQ FILE PNT
KCHAR   EQU $FE CHAR SAVE FOR WRITCH
*
* PAGE 3 DATA AREA
******************
*
        ORG $300
*
FILTYP  BSS 1   TYPE OF ACTIVE FILE
FILNAM  BSS 16  FILE NAME
FILCYC  BSS 1   CYCLUS NUMBER
FILSTP  BSS 1   FILE SUBTYPE
FILLOC  BSS 2   LOCATION OR SECTOR
FILSIZ  BSS 2   FILE SIZE
FILDAT  BSS 3   FILE GENERATION DATE
FILSA   BSS 2   START ADDRESS
FILEA   BSS 2   END ADDRESS
FILLNK  BSS 2   FILE LINK
*
FILNM1  BSS 16
FILCY1  BSS 1
FILSA1  BSS 2
SAVRST  BSS 2
*
CURSEQ  BSS 1   CURRENT SEQUENTIAL FILE
MAXSEQ  BSS 1   MAX NO OF SEQ FILE
MAXSIZ  BSS 1   MAX SIZE
FILBU1  BSS 1   START OF BUFFERS
*
* TABLE FOR 8 OPEN SEQUENTIAL FILES
*
FIDRTB  BSS 8   BIT 7 1=WRITE, 0=READ
*               BIT 5 1=FILE IS OPEN
FIDVTB  BSS 8   DRIVE NUMBER
FIBPTB  BSS 8   BUFFER POINTER LOW BYTE
FIRCTB  BSS 8   NO OF LAST RECORD
FIMAXT  BSS 8   MAXIMAL NO OF RECORDS
FITEMP  BSS 24  TAPE: RECORD ID SAVE (2)
*               DISK: FIRST SECTOR (2)
*               AND DIRECTORY ENTRY NO
*               (1)
EXITPN  BSS 1   DISK STACK POINTER SAVE
BUFSEC  BSS 1   CURRENT SECTOR
SCY     BSS 1   FOUND CYCLUS
SCYFC   BSS 1   FILE ENTRY OF CY
SLAST   BSS 1   END OF DIRECTORY MARK
DISFLG  BSS 1   DISK FLAG REGISTER
*               BIT 7 DRIVE 0 INITIALIZED
*               BIT 6 DRIVE 1 INITIALIZED
DISCNT  BSS 1   SPECIAL DISK COUNTER
*
        ORG $388
*
OLDENT  BSS 1
OLDREC  BSS 2
NEWENT  BSS 1
NEWREC  BSS 2
COUNTER BSS 1
COUNT2  BSS 1
*
PFILENO BSS 1
PAGING  BSS 1
LINE    BSS 1
OLDDRV  BSS 1
NEWDRV  BSS 1
OLDFIL  BSS 1
NEWFIL  BSS 1
FULLFLG BSS 1
NAMEFLG BSS 1
DIRCNT  BSS 1
DELCNT  BSS 2
FILNM2  BSS 17
SUCCESS BSS 1   COUNT SUCCESS (COPY,DELETE)
GRX     BSS 1   X FOR GRAHICSS
GRY     BSS 1   Y FOR GRAPHICS
GRC     BSS 1   DRAW MODE FOR GRAPHICS
GRN     BSS 1   NUMBER OF POINTS TO DRAW
GRINDEX BSS 1   PLOT TEMPORARY
GRCNT   BSS 1   PLOT TEMPORARY
GRMASK  BSS 1   PLOT TEMPORARY
GRYCNT  BSS 1   PLOT TEMPORARY
GRMAP   BSS 2   PLOT MAP OR X INCREMENT
GRXINC  EQU GRMAP
GRXLOW  BSS 1
GRYLOW  BSS 1
GRYINC  BSS 2   PLOT Y INCREMENT
*
*
* BUFFERS
*********
*
        ORG $D600
DIRBUF  BSS 256         DISK DIRECTORY BUFFER
FILBUF  BSS $800        FILE BUFFER, 8
*                       OPEN FILES ALLOWED
*                       DEFAULT, CAN BE REMOVED
COPYBS  EQU $2000       COPY BUFFER
COPYBE  EQU $BFFF       END OF COPY BUFFER
*
*
* PAGE 17 DATA AREA
*******************
*
        ORG $1780
*
VFLAG   BSS 1
SFLAG   BSS 1
VMON    EQU $17D5
*
* INTERFACE ADDRESSES
*********************
*
PORTB1  EQU $1400       MEMORY WRITE DISABLE
EMUCOM  EQU $1430       EMULATOR COMMAND REG
EMURES  EQU $1431       EMULATOR RESULT REG
FDCOM   EQU $14C0       COMMAND REGISTER
FDSTAT  EQU $14C0       STATUS REGISTER
FDPARA  EQU $14C1       PARAMETER REGISTER
FDRES   EQU $14C1       RESULT REGISTER
FDTSTM  EQU $14C2       TEST MODE REGISTER
FDDAT   EQU $14C4       DACK ADDRESS
RSADAT  EQU $14C8       RS232 DATA REG
RSASTA  EQU $14CA       RS232 STATUS REG
RSACOM  EQU $14CA       RS232 COMMAND REG
MULTX   EQU $14E0       MULTIPLIER X-REGISTER
MULTY   EQU $14E1       MULTIPLIER Y-REGISTER
MULTR   EQU $14E2       MULTIPLIER DATA REGISTER
USPBD   EQU $1702       LED DISPLAY
PRIOTB  EQU $179C       PRIORITY IRQ TABLE
*
*
* VECTORS TO EPROMS OF OS
*************************
*
GETCHR  EQU $E003       GET CHAR
GETLIN  EQU $E006       GET LINE
PRTCHR  EQU $E009       PRINT A CHAR TO CRT
ENDLIN  EQU $E024       TEST END OF LINE
PRTINF  EQU $E027       PRINT A STRING
PRTHEX  EQU $E02A       PRINT HEX CHAR
PRTBYT  EQU $E02D       PRINT BYTE IN A
PRTAX   EQU $E030       PRINT TWO BYTES
RSIRQ   EQU $E92D       *** RS 232 IRQ, NORMAL
ESCTST  EQU $E806       TEST ESCAPE FLAG
TDIR    EQU $E809       TAPE DIRECTORY
DWRFIL  EQU $F000       WRITE DISK FILE
TPWAIT  EQU $E80F       READY MESSAGE FOR TAPE
TRDREC  EQU $E812       LOAD A RECORD FROM TAPE
TWRREC  EQU $E818       WRITE A RECORD TO TAPE
SETID   EQU $E82A       SET TAPE ID
SETFID  EQU $E81E       SET DATE TO FILE LABEL
TAPEON  EQU $E821       START TAPE DRIVE
TAPEOF  EQU $E824       STOP TAPE DRIVE
TDELAY  EQU $E827       WAIT 1 SEC
PRFLAB  EQU $E82D       PRINT FILE LABEL
TDRLBR  EQU $E830       READ LABEL RECORD
WRFILE  EQU $EB14       *** SPECIAL ENTRY
DELETE  EQU $F00C       DELETE ONE FILE
OPEN    EQU $F00F       OPENS EQUENTIAL FILE
CLOSE   EQU $F012       CLOSE SEQUENTIAL FILE
CLOSAL  EQU $F015       CLOSE ALL FILES
READCH  EQU $F018       READ ONE CHAR FROM FILE
WRITCH  EQU $F01B       WRITE ONE CHAR TO FILE
DRIVE   EQU $F364       *** COMPUTE DRIVE
SEEK    EQU $F36D       *** SEEK TRACK
WRCOMM  EQU $F3A4       *** WRITE COMMAND
WRPARA  EQU $F3AF       *** WRITE PARAMETER
RESULT  EQU $F3BC       *** GET RESULT
DATREAD EQU $F3F6       *** READ DATA
DATWRIT EQU $F3E1       *** WRITE DATA
WRITE   EQU $F425       *** WRITE RECORD
VERIFY  EQU $F44C       *** VERIFY RECORD
READ    EQU $F457       *** READRECORD
TRACK0  EQU $F4A0       *** SEEK TO TRACK 0
PREPDO  EQU $F4A7       *** PREPARE DISK OP
PREPDO1 EQU $F4CC       *** PREPARE DISK OP
GETFENT EQU $F4D2       *** GET FILE ENTRY
GETFREC EQU $F4ED       *** GET ENTRY RECORD
READDS  EQU $F502       *** READ DIR SECTOR
WRITDS  EQU $F52A       *** WRITE DIR SECTOR
PREPRW  EQU $F548       *** PREPARE WRITE
PREPRW1 EQU $F55E       *** PREPARE WRITE
PUTFENT EQU $F581       *** PUT FILE ENTRY
DISCERR EQU $F5F4       *** DISK ERROR
DISCER1 EQU $F5FD       *** DISK ERROR
ENDDO   EQU $F625       *** END DISK OPERATION
PREPRD  EQU $F62C       *** PREPARE READ
PREPWRA EQU $F651       *** PREPARE WRITE
DDIR2   EQU $F6B4       *** DISK DIRECTORY
DELETE4 EQU $F6F1       *** DELETE THIS ENTRY
DRDFIL2 EQU $F76E       *** READ FILE, WITHOUT
HEXPZE  EQU $F809       HEX EPRESSION, DEF=0
GETNAM  EQU $F815       GET FILE NAME
ENDLER  EQU $F9B5       *** ERROR, IF NOT EOL
ERROR   EQU $F932       *** ERROR
TEST    EQU $F94D       *** TEST STRING
INTCOM  EQU $FA06       *** INTERPRET MON COMM
BFLOAD0 EQU $FCCA       *** LOAD BLOCK FILE
BFSTOR0 EQU $FD60       *** STORE BLOCK FILE
HARGUM  EQU $FCF2       *** GET HEX ARGUMENT
*
*
        PAG
*
        ORG PSTART
*
* COLD START ENTRY POINT
*
        JMP START
*
* VECTOR TABLE FOR CALLING ROUTINES
*
FGETCOM JMP FGETCM0     GO TO EXDOS
        JMP FDIR0       PRINT DIRECTORY
        JMP PACK0       PACK DISK
        JMP DELETE1     DELETE FILE(S)
        JMP EDIT        EDIT FILE
        JMP NEW0        CREATE NEW FILE
        JMP PLOT        PLOT GRAPHICS DOT
        JMP PLOTCH      PLOT CHARACTER
        JMP BITMAP      PLOT 4x4 BITS
        JMP DRAWX       DRAW LINE IN X DIR
        JMP DRAWY       DRAW LINE IN Y DIR
        JMP DRAWXY      DRAW LINE IN BOTH DIR
        JMP FLOPPY      CHANGE FLOPPY
*
START   SEI
        LDA =<FGETCOM
        LDX =>FGETCOM
        STA VMON
        STX VMON+1
        JSR PRTINF
        BYT 'R65 EXDOS VERSION 4.6',$A0
        CLI
FGETCM0 JSR PRTINF      MAIN LOOP
        BYT $D,$A,'E*'+128
        JSR GETLIN
        JSR FINTCOM
        JMP FGETCOM
*
FINTCOM BCC *+3         RTS, IF ESC
        RTS
        JSR ENDLIN      OR EMPTY LINE
        BEQ *-4
*
        JSR ESCTST      CLEAR ESCAPE FLAG
*
        JSR TEST
        BYT 'DFORMAT'+128
        BCS FINTC1
*
        JSR NGETNE
        JSR HARGUM      *** DFORMAT ***
        STA FILDRV      (DISKNAME,FILDRV)
        JSR ENDLER
        JSR INITDIR
        BNE DERROR
        RTS
*
FINTC1  JSR TEST
        BYT 'EXPORT'+128
        BCS FINTC2
*
        JSR NGETNE      *** EXPORT ***
        JSR HARGUM      (FILNAM.CY,DRIVE)
        STA FILDRV
        JSR EXPORT
        BNE DERROR
        RTS
*
FINTC2  JSR TEST
        BYT 'IMPORT'+128
        BCS FINTC3
*
        JSR NGETNE      *** IMPORT ***
        JSR HARGUM      (FILNAM.CY,DRIVE)
        STA FILDRV
        JSR IMPORT
        BNE DERROR
        RTS
*
FINTC3  JSR TEST
        BYT 'EDIT'+128
        BCS FINTC4
*
        JSR NGETNE      *** EDIT ***
        JSR HARGUM      (FILNAM.CY,DRIVE)
        STA FILDRV
        JSR EDIT
        BNE DERROR
        RTS
*
FINTC4  JSR TEST
        BYT 'FLOPPY'+128
        BCS FINTC6
*
        JSR NGETNE      *** FLOPPY ***
        JSR HARGUM      (FILNAM.CY,DRIVE)
        STA FILDRV
        JSR FLOPPY
        BNE DERROR
        LDA =0          PRINT DIRECTORY
        STA FULLFLG
        JSR FDIR0
        BNE DERROR
        RTS
*
DERROR  JMP ERROR
*
FINTC6  JSR TEST
        BYT 'REVIVE'+128
        BCS FINTC7
        JSR REVIVE      *** REVIVE ***
        BNE DERROR      (ENTRY,DRIVE)
        RTS
*
FINTC7  JSR TEST
        BYT 'RENAME'+128
        BCS FINTC10
        JSR RENAME      *** RENAME ***
DERROR1 BNE DERROR      (FILNAM.CY,DRIVE)
        RTS
*
FINTC10 JSR TEST
        BYT 'FDIR'+128
        BCS FINTC25
        LDA =$FF
FINTC24 STA FULLFLG
        JSR FDIR        *** FDIR ***
DERROR2 BNE DERROR1     (DRIVE)
        RTS
*
FINTC25 JSR TEST
        BYT 'DIR'+128   *** DIR ***
        BCS FINTC11     (DRIVE)
        LDA =0
        JMP FINTC24
*
FINTC11 JSR TEST
        BYT 'PACK'+128  *** PACK ***
        BCS FINTC12     (DRIVE)
        JSR PACK
DERROR3 BNE DERROR2
        RTS
*
FINTC12 JSR TEST
        BYT 'PROTECT'+128
        BCS FINTC15
        JSR PROTECT     *** PROTECT ***
        BNE DERROR2     (FILNAM.CY,DRIVE)
        RTS
*
FINTC15 JSR TEST
        BYT 'COPY'+128
        BCS FINTC17     *** COPY ***
        JSR COPY        (FILNAM.CY,DRIVE,DRIVE)
        BNE DERROR3
        RTS
*
FINTC17 JSR TEST        *** LOAD ***
        BYT 'LOAD'+128
        BCS FINTC18
        JSR NGETNE
        JMP BFLOAD0
*
FINTC18 JSR TEST        *** STORE ***
        BYT 'STORE'+128
        BCS FINTC19
        JSR NGETNE
        JMP BFSTOR0
*
FINTC19 JSR TEST        *** DELETE ***
        BYT 'DELETE'+128
        BCS FINTC20
        JSR DELETE0
        BNE DERROR3
        RTS
*
FINTC20 JSR TEST        *** VOLUME ***
        BYT 'VOLUME'+128  (DRIVE)
        BCS FINTC21
        JSR HARGUM
        STA FILDRV
        JSR ENDLER
        JMP VOLUME
*
FINTC21 JSR TEST        *** NEW ***
        BYT 'NEW'+128     (FILNAM.CY,DRIVE)
        BCS FINTC22
        JSR NEW
        BNE DERROR3
        RTS
*
FINTC22 JMP INTCOM+8    MUST BE MONITOR COMM
*
*
* SUBROUTINES FOLLOW
* ******************
*
* INITDIR: INITIALIZE DISK DIRECTORY
************************************
*
INITDIR JSR DSKONLY
        JSR PREPDO
        JSR PRTINF
        BYT $D,$A,'FORMAT (DATA LOST)? '+128
        JSR GETCHR
        AND =$5F
        CMP ='Y'
        BEQ INITD1
        LDA =3          ESCAPE
        JMP DISCER1
*
INITD1  JSR PRTINF
        BYT $D,$8A
        JSR CLOSAL
        SEI
*
INITD2  LDY =0
        TYA             CLEAR BUFFER FIRST
        STA DIRBUF,Y
        DEY
        BNE *-4
        LDX =1          STORE SECTORS 1-31
        STX BUFSEC
INITD3  JSR WRITDS
        INC BUFSEC
        LDX BUFSEC
        CPX =32
        BCC INITD3
        LDX =16         LOAD DISK NAME AND NO
INITD4  LDA FILNM1,X
        STA DIRBUF+$E1,X
        DEX
        BPL INITD4
        JSR WRITDS      STORE SECTOR 32
        RTS
*
*
SETEND1 JSR HEXPZE
        TAX
        DEX
        STX NEWENT      SAVE ENTRY NO
        JSR HARGUM
        STA FILDRV
        JSR ENDLER
        JSR PREPDO1
        LDX NEWENT
        JSR GETFENT
        LDX FILCNT
*
DSKONLY LDA FILDRV
        AND =$FC
        BNE *+3
        RTS
*
        LDA =$62
        JMP ERROR
*
* REVIVE: REVIVE DELETED FILE
*****************************
*
REVIVE  JSR SETEND1
        LDA FILLNK      CLEAR THE DELETED FLAG
        AND =$7F
        STA FILLNK
        JSR PUTFENT
        JMP ENDDO
*
* RENAME: RENAME FILE
*********************
*
RENAME  JSR NGETNE
        JSR HARGUM
        STA FILDRV
        JSR DSKONLY
        JSR ENDLER
        JSR PREPRD
        JSR PRFLAB
        JSR PRTINF
        BYT $D,$A,'FILNAM.CY,SUBTYPE? '+128
        JSR GETLIN
        JSR ENDLIN
        BNE *+5
        JMP INITD1-5    ESCAPE
*
        LDX FILCNT
        STX NEWENT
        JSR NGETNE
        JSR ENDLIN
        BEQ RENAME1
        JSR TEST
        BYT ','+128
        BCS SYNERR
        JSR TEST
        BYT '!'+128     PROTECTED?
        LDA FILTYP
        AND =$7F
        BCS *+4
        ORA =$80
        STA FILTYP
        LDA (VIDPNT),Y
        INY
        CMP =$41
        BCC SYNERR
        CMP =$5C
        BCS SYNERR
        STA FILSTP
        JSR ENDLIN
        BEQ RENAME1
        LDA =$15        END OF LINE EXPECTED
        JMP DISCER1
*
RENAME1 JSR PREPWRA+3
        STX FILCYC
        LDX =15
        LDA FILNM1,X
        STA FILNAM,X
        DEX
        BPL *-7
        LDX NEWENT
        JSR GETFREC
        JSR PUTFENT+2
        JMP ENDDO
*
SYNERR  LDA =$18
        JMP DISCERR
*
* PROTECT: PROTECT DISK FILE
* **************************
*
PROTECT JSR NGETNE
        JSR HARGUM
        STA FILDRV
        JSR DSKONLY
        JSR ENDLER
        JSR PREPRD
        LDA FILTYP
        ORA =$80
        STA FILTYP
        LDX FILCN1
        JSR PUTFENT
        JMP ENDDO
*
* IFNAME: READ FILE NAME, IF THERE
**********************************
*
IFNAME  LDA =0
        STA NAMEFLG
        JSR ENDLIN      SKIP BLANKS
        BEQ IFNAME1
        LDA (VIDPNT),Y
        AND =$7F
        CMP ='@'
        BCC IFNAME1
        CMP ='['
        BCS IFNAME1
        JSR NGETNAM
        LDA =$FF
        STA NAMEFLG
        LDA (VIDPNT),Y
        CMP =','
        BNE IFNAME1
        INY
IFNAME1 RTS
*
* FDIR: PRINT DIRECTORY
***********************
*
FDIR    JSR IFNAME
        JSR HEXPZE
        STA FILDRV
        JSR DSKONLY
        JSR ENDLER
FDIR0   LDA FILDRV      ENTRY FOR VECTOR CALL
        AND =$FC
        BEQ *+5
        JMP TDIR
*
        JSR PREPDO
        LDX =255
        JSR GETFENT
        JSR PRTINF
        BYT $D,$A,'      DIRECTORY '
        BYT 'DISK '+128
        LDA FILCYC
        JSR PRTBYT
        JSR PRTINF
        BYT ': '+128
        LDX =0
FDIR0A  LDA FILNAM,X
        JSR PRTCHR
        INX
        CPX =16
        BCC FDIR0A
*
        LDX =2
        STX DIRCNT
        LDX =0
        STX DELCNT
        STX DELCNT+1
FDIR1   LDA NAMEFLG
        BNE *+8
        JSR GETFENT
        JMP FDIR1A
        JSR NEXTENT
        LDX SCYFC
        STX FILCNT
FDIR1A  LDA FILTYP      0 MEANS END MARK
        BEQ FDIR2
        JSR ESCTST
        BCS FDIR2
        LDA DIRCNT      EVERY 14 LINES
        AND =$0E
        BNE FDIR4
        INC DIRCNT
        INC DIRCNT
        JSR GETCHR
        JSR ESCTST      ESCAPE?
        BCC FDIR4
        RTS             RETURN TO COMMAND LINE
*
FDIR4   LDA FILLNK
        BPL FDIR8
        LDA DELCNT      COUNT DELETED SECTORS
        CLC
        ADC FILSIZ+1
        STA DELCNT
        BCC FDIR8
        INC DELCNT+1
*
FDIR8   LDA FULLFLG
        BEQ FDIR5
        JSR PRTINF      PRINT FULL DIRECTORY
        BYT $D,$A,'***** '+128
        LDX FILCNT
        INX
        TXA
        JSR PRTBYT
        JSR PRTINF
        BYT '.  SIZE='+128
        LDA FILSIZ+1
        JSR PRTBYT
        LDA FILLNK
        BPL FDIR3-3
*
        JSR PRTINF
        BYT ' (DELETED)'+128
        INC DIRCNT      COUNT FIRST LINE
FDIR3   JSR PRFLAB
        BCS FDIR2       ESCAPE?
        INC DIRCNT      COUNT SECOND LINE
FDIR6   LDX FILCNT
        INX
        JMP FDIR1
*
FDIR2   JSR DDIR2
        JSR PRTINF
        BYT 'DELETED:     '+128
        LDX DELCNT
        LDA DELCNT+1
        JSR PRTAX
        JSR PRTINF
        BYT $D,$8A
        LDA =0
        RTS
*
FDIR5   LDA FILLNK
        BMI FDIR6
        BPL FDIR3
*
PACK9   JMP ENDDO
*
* PACK: PACK FLOPPY DISK
************************
*
PACK    JSR HEXPZE
        STA FILDRV
        JSR ENDLER
        JSR DSKONLY
        JSR CLOSAL
        JSR PRTINF
        BYT $D,$A
        BYT 'PACK (DELETED FILES LOST)? '+128
        JSR GETCHR
        AND =$5F
        CMP ='Y'
        BEQ *+5
        JMP INITD1-5    ESCAPE
*
        JSR PRTINF
        BYT $D,$8A
PACK0   JSR PREPDO
        LDX =0
PACK1   JSR GETFENT     LOOP UNTIL FIRST
        LDA FILTYP      EMPTY RECORD FOUND
        BEQ PACK9       NO PACK NEEDED
        LDA FILLNK
        BMI PACK2       SKIP, IF DELETED
        LDX FILCNT      ELSE NEXT ENTRY
        INX
        BNE PACK1       ALLWAYS TAKEN
*
PACK2   LDX FILCNT      DELETED FILE FOUND
        STX NEWENT
        LDA FILLOC
        LDX FILLOC+1
        STA NEWREC
        STX NEWREC+1
        LDX FILCNT
        INX
PACK3   JSR GETFENT
        LDA FILTYP
        BNE *+5
        JMP PACK8       SKIP, IF END OF DIR.
        LDA FILLNK
        BPL PACK4       SKIP, IF NOT DELETED
        LDX FILCNT
        INX
        BNE PACK3
*
PACK4   LDA FILLOC
        LDX FILLOC+1
        STA OLDREC
        STX OLDREC+1
        LDA FILCNT
        STA OLDENT
        LDA NEWREC
        LDX NEWREC+1
        STA FILLOC
        STX FILLOC+1
        LDX NEWENT
        JSR GETFREC
        JSR PUTFENT+2   MOVE ENTRY
        LDA FILSIZ+1
        STA COUNTER
*
PACK5   LDA =5
        CMP COUNTER
        BCC *+5
        LDA COUNTER
        STA COUNT2
*
        LDA =<FILBUF    MOVE FILE
        LDX =>FILBUF
        STA DATA
        STX DATA+1
PACK5A  LDA OLDREC
        LDX OLDREC+1
        STA SECTOR
        STX TRACK
        JSR PREPRW1-2
        JSR READ
        INC OLDREC
        BNE *+5
        INC OLDREC+1
        INC DATA+1
        DEC COUNT2
        BNE PACK5A
*
        LDA =>FILBUF
        STA DATA+1
        LDA =5
        CMP COUNTER
        BCC *+5
        LDA COUNTER
        STA COUNT2
PACK5B  LDA NEWREC
        LDX NEWREC+1
        STA SECTOR
        STX TRACK
        JSR PREPRW1-2
        JSR WRITE
        INC NEWREC
        BNE *+5
        INC NEWREC+1
        INC DATA+1
        DEC COUNTER
        DEC COUNT2
        BNE PACK5B
*
        LDA COUNTER
        BNE PACK5
*
        INC NEWENT
        INC OLDENT
        LDX OLDENT
        JMP PACK3
*
PACK8   LDA =0          SET END MARK
        STA FILTYP
        LDA NEWREC
        LDX NEWREC+1
        STA FILLOC
        STX FILLOC+1
        LDX NEWENT
        JSR GETFREC
        JSR PUTFENT+2
        JSR PRTINF
        BYT 'PACKING COMPLETE',' '+128
*
PACK7   JMP ENDDO
*
* NGETNAM: GET FILE NAME AND CYCLUS
***********************************
*
NGETNAM JSR GETNAM
        LDX =0
*
NGETN6  LDX =0
NGETN7  LDA FILNM1,X
        CMP ='@'
        BNE NGETN9
        INX
NGETN8  LDA FILNM1,X
        CMP =' '
        BNE NGETN7
        LDA ='@'
        STA FILNM1,X
        INX
        CPX =16
        BCC NGETN8
*
NGETN9  INX
        CPX =15
        BCC NGETN7
NGETN10 RTS
*
* NGETNE: GET FILE NAME, NO WILDCARDS
*************************************
*
NGETNE  JSR NGETNAM
        LDX =16
NGETNE1 LDA FILNM1+1,X
        CMP ='@'
        BEQ NGETNE2
        DEX
        BNE NGETNE1
        RTS
*
NGETNE2 LDA =$61        NO WILD CARD
        JMP ERROR
*
* NEXTENTRY
***********
* INPUT: X=FIRST ENTRY TO CHECK
* OUTPUT: SCYFC: FOUND ENTRY,Z=1 IF END MARK
*
NEXTENT STX SCYFC
NEXTE5  JSR GETFENT
        LDA FILTYP
        BNE *+3         END MARK?
        RTS
*
        LDA FILCY1      IF FILCYC=0
        BEQ NEXTE10     DO NOT CHECK
        CMP FILCYC
        BNE NEXTE30
*
NEXTE10 LDX =15
        LDA FILNM1,X
        CMP ='@'
        BEQ NEXTE20
        CMP FILNAM,X
        BNE NEXTE30
*
NEXTE20 DEX
        BPL NEXTE10+2
        RTS             FOUND
*
NEXTE30 INC SCYFC
        LDX SCYFC
        JMP NEXTE5
*
* VOLUME: CHANGE VOLUME NAME
****************************
*
VOLUME  JSR DSKONLY
        JSR PREPDO
        LDX =255
        JSR GETFENT
        JSR PRTINF
        BYT $D,$A,'OLD VOLUME: '+128
        LDX =0
VOL10   LDA FILNAM,X
        JSR PRTCHR
        INX
        CPX =16
        BCC VOL10
        JSR PRTINF
        BYT '.'+128
        LDA FILCYC
        JSR PRTBYT
        JSR PRTINF
        BYT $D,$A,'NEW VOLUME: '+128
        JSR GETLIN
        JSR ENDLIN
        BNE *+3
        RTS             NO CHANGE, RETURN
        JSR NGETNE
        LDX =16
VOL20   LDA FILNM1,X
        STA DIRBUF+$E1,X
        DEX
        BPL VOL20
        LDA =$20        Last directory entry
        STA BUFSEC
        JMP WRITDS
*
* DELETE: DELETE ONE OR SEVERAL FILES
*************************************
*
DELETE0 JSR NGETNAM
        JSR HARGUM
        STA FILDRV
        JSR DSKONLY
DELETE1 LDX =16         WILD CARDS?
DEL1    LDA FILNM1-1,X
        CMP ='@'
        BEQ DEL2        SKIP, IF YES
        DEX
        BNE DEL1
        JMP DELETE      DELETE ONE FILE
*
DEL2    JSR PREPDO
*
        LDX =0
        STX SUCCESS     RESET SUCCESS CNT
DEL3    JSR NEXTENT
        LDA FILTYP
        BNE DEL4
        LDX SUCCESS     ANYTHING DONE?
        BNE DEL6
*
NOSUCC  JSR PRTINF
        BYT $D,$A,'NO MATCH',$D,$8A
*
DEL6    JMP ENDDO       END MARKFOUND
*
DEL4    LDA FILLNK
        BMI DEL5
        JSR PRFLAB
        JSR DELETE4
        INC SUCCESS     COUNT SUCCESS
DEL5    INC SCYFC
        LDX SCYFC
        JMP DEL3
*
* COPY: COPY FILE(S) TO NEW DRIVE
*********************************
*
COPY    JSR IFNAME
        JSR CLOSAL
        JSR HEXPZE      GET OLD DRIVE
        STA OLDDRV
        JSR DSKONLY+2
        JSR HARGUM      GET NEW DRIVE
        STA NEWDRV
        JSR DSKONLY+2
COPY0   LDA NEWDRV      DIFFERENT DRIVE?
        CMP OLDDRV
        BNE COPY1
*
        LDA =$63        IDENTICAL DRIVE
        STA FILERR
        RTS
*
COPY1   LDX =16
COPYL   LDA FILNM1,X
        STA FILNM2,X
        DEX
        BPL COPYL
*
        LDX =0
        STX SUCCESS     RESET SUCCESS CNT
LOOP    STX OLDENT      LOOP THROUGH FILES
        LDA OLDDRV
        STA FILDRV
        LDA =0
        STA FILFLG
        JSR PREPDO
        LDX OLDENT
        LDA NAMEFLG
        BNE *+8
        JSR GETFENT
        JMP LOOP1
*
        JSR NEXTENT
        LDX SCYFC
        STX OLDENT
*
LOOP1   LDA FILTYP
        BNE NOTEND
        LDA SUCCESS     ANYTHING DONE?
        BNE *+5
        JMP NOSUCC
        JMP ENDDO       COMPLETE
*
NOTEND  LDA FILLNK      SKIP DELETED FILES
        BPL *+5
        JMP NEXTF
        LDX =16
NOTE1   LDA FILNAM,X
        STA FILNM1,X
        DEX
        BPL NOTE1
*
COPYF   JSR PRFLAB
        INC SUCCESS
        LDA =<COPYBS    PREPARE ADDRESS
        LDX =>COPYBS
        JSR PREPRW+6    AND POINTERS
*
        SEC
        LDA =>COPYBE    CHECK SIZE OF COPY
        SBC =>COPYBS    BUFFER
        SBC FILCN1
        BCS COPYF1
        LDA =$64        FILE TOO LARGE
        STA FILERR
        RTS
*
COPYF1  JSR DRDFIL2
        LDA NEWDRV
        STA FILDRV
        LDA =$60
        STA FILFLG
        LDA FILCYC
        STA FILCY1
        LDA =<COPYBS
        LDX =>COPYBS
        STA FILSA1
        STX FILSA1+1
        JSR WRFILE+24   DO NOT OVERWRITE
        BEQ NEXTF       FILTYP,DATE
        LDA =1
        STA FILERR      WRITE ERROR
        RTS
*
NEXTF   LDX =16
NEXTF1  LDA FILNM2,X    RESTORE FILNM1,FILCY1
        STA FILNM1,X
        DEX
        BPL NEXTF1
        LDX OLDENT
        INX
        JSR ESCTST
        BCS *+5
        JMP LOOP
*
        LDA SUCCESS     ANYTHING DONE?
        BNE *+5
        JMP NOSUCC
*
        JMP ENDDO       FINISHED
*
*
* EXPORT: EXPORT A SEQUENTIAL FILE
**********************************
*
EXPORT  JSR DSKONLY
        JSR ENDLER
        JSR PREPRD
        JSR PRFLAB
*
        LDA =1          COMMAND 1: EXPORT
        STA EMUCOM      EXECUTE LINUX CMD
        JSR ENDDO
        LDA EMURES      GET RESULT
        STA FILERR
        RTS
*
*
* IMPORT: IMPORT A SEQUENTIAL FILE
**********************************
*
IMPORT  JSR DSKONLY
        JSR ENDLER
*
IMPORT1 LDX =16
        LDA FILNM1,X
        STA FILNAM,X
        DEX
        BPL *-7
*
        LDA =2          COMMAND 2: IMPORT
        STA EMUCOM      EXECUTE LINUX CMD
        LDA EMURES      GET RESULT
        BNE IMPORTE
        JSR PRFLAB
        LDA =0          NO ERROR
IMPORTE STA FILERR
        RTS
*
* EDIT: EDIT USING LEAFPAD
**************************
*
EDIT    JSR EXPORT
        BNE EDITR
        JSR TDELAY      ALLOW SCREEN UPDATE
        JSR EDIT0
        BNE EDITR
        JSR IMPORT1
        BNE EDITR
        RTS
*
EDIT0   LDX =16
        LDA FILNM1,X
        STA FILNAM,X
        DEX
        BPL *-7
*
        LDA =3          COMMAND 3: EDIT
        STA EMUCOM      EXECUTE LINUX CMD
        LDA EMURES      GET RESULT
EDITR   STA FILERR
        RTS
*
* FLOPPY: CHANGE FLOPPY DISK
****************************
*
FLOPPY  JSR DSKONLY
        JSR ENDLER
*
        LDX =16
        LDA FILNM1,X
        STA FILNAM,X
        DEX
        BPL *-7
*
        LDA =4          COMMAND 4: FLOPPY
        STA EMUCOM      EXECUTE LINUX CMD
        LDA EMURES      GET RESULT
        STA FILERR
        RTS
*
* NEW: CREATE AN NEW SEQUENTIAL FILE
************************************
*
NEW     JSR NGETNE
        JSR HARGUM
        STA FILDRV
NEW0    LDA ='B'        DEFAULT SUBTYPE
        STA FILSTP
*
        LDX =14         FIND TYPE
NEW1    LDA FILNM1,X
        CMP =':'
        BEQ NEW2
        DEX
        BNE NEW1
        BEQ NEW3
*
NEW2    LDA FILNM1+1,X
        STA FILSTP      STORE SUBTYPE
*
NEW3    LDA =$20        WRITE
        STA FILFLG
        LDA =1
        STA MAXSIZ      SIZE 1 SECTOR
        JSR OPEN
        BEQ NEW4
NEWERR  RTS
*
NEW4    STY NEWFIL      SAVE FILE NO
        JSR PRFLAB
        LDA =' '
        LDX NEWFIL
        JSR WRITCH      WRITE ONE BLANK
        BNE NEWERR
        LDX NEWFIL
        JSR CLOSE       CLOSE FILE
        RTS
*
        TIT GRAPHICS SUBROUTINES
        PAG
*
* SUBROUTINES FOR GRAPHICS
**************************
*
* PLOT (GRX,GRY,GRC)
********************
* USER MUST CHECK VFOR VALID VALUES!
*
PLOT    LDA GRX
        LSR A
        LSR A
        LSR A
        TAX             X=GRX/8
        LDA =28
        SEI
        STA MULTX       MULTX=28
        LDA GRY
        STA MULTY       MULTY=GRY
        LDY MULTR+1     Y=HIGH(MULTR)
        CLI
        TXA             A=GRX/8
        CLC
        ADC MULTR
        BCC PLOT1
        INY
PLOT1   STA DATA        A,Y=GRX/8+28*GRY
        TYA
        CLC
        ADC =7
        STA DATA+1      DATA=GRX/8+28*GRY+$700
*
        LDA GRX
        AND =7          A=GRX AND 7
        TAY             Y=GRX AND Y
        LDA MASKTB,Y    A=MASKTB[GRX AND 7]
        LDY =0
        LDX GRC         X=GRC
        BEQ PLOR
        DEX
        BEQ PLEOR
*
PLAND   EOR =$FF        NOT MASK
        AND (DATA),Y    A=[DATA] AND NOT MASK
        STA (DATA),Y
        RTS
*
PLEOR   EOR (DATA),Y    A=[DATA] EOR MASK
        STA (DATA),Y
        RTS
*
PLOR    ORA (DATA),Y    A=[DATA] OR MASK
        STA (DATA),Y
        RTS
*
MASKTB  BYT $80,$40,$20,$10
        BYT $08,$04,$02,$01
*
*
* PLOTCH (GRX,GRY,GRC)
**********************
* USER MUST CHECK FOR VALID VALUES OF
* X AND Y
*
PLOTCH  LDA =8          8 BYTES OF MAP
        STA GRYCNT
        LDA =0          MEANS 8 BITS IN ROW
        STA GRYLOW
        LDA GRY
        CLC
        ADC =7
        STA GRY         START WITH TOP
        LDA GRC
        AND =$7F
        SEC
        SBC =$20        RETURN IF CTRL CHAR
        BPL PLOTCH1
        RTS
*
PLOTCH1 SEC
        CMP =$40        CONVERT TO UPPER CASE
        BCC PLOTCH2
        SBC =$20
*
PLOTCH2 LDX =>FONTTB
        STX DOSPNT+1    A=CODE NOW $00-$3F
        ASL A
        ASL A
        ASL A
        BCC *+4
        INC DOSPNT+1
        STA GRINDEX     8 * CODE
        LDX =0
        STX GRCNT       GRCNT COUNTS MAP BYTES
        CLC             DOSPNT=FONTTB+8*CODE
        ADC =<FONTTB
        STA DOSPNT
        BCC PLOTCH3
        INC DOSPNT+1
*
PLOTCH3 LDA =$80
        STA GRMASK
        LDA GRX
        STA GRXLOW      SAVE GRX FOR NEXT ROW
PLOTCH4 LDY GRCNT       COUNTS FROM 0 TO GRYCNT-
        LDA GRMASK
        AND (DOSPNT),Y  GET A CHARACTER BIT MAP
        BEQ PLOTCH5
        LDX =0          WHITE
        STX GRC
        JMP PLOTCH6
PLOTCH5 LDX =2          BLACK
        STX GRC
PLOTCH6 JSR PLOT        PLOT THE DOT
        INC GRX         INCREMENT X FOR NEXT DOT
        LDA GRMASK
        CMP =$01        LAST BIT DONE?
        BEQ PLOTCH8
        LSR A           SHIFT MASK
        STA GRMASK
        CMP GRYLOW      ONE ROW DONE?
        BNE PLOTCH4     NEXT BIT
PLOTCH7 LDA GRXLOW      RESTORE STARTING GRX
        STA GRX
        DEC GRY
        JMP PLOTCH4
*
PLOTCH8 INC GRCNT       NEXT MAP BYTE
        LDA GRCNT
        CMP GRYCNT
        BEQ PLOTCH9
        LDA GRXLOW      RESTORE STARTING GRX
        STA GRX
        DEC GRY
        JMP PLOTCH3
*
PLOTCH9 RTS             DONE
*
* BITMAP (GRX,GRY,GRMAP)
************************
* USER MUST CHECK FOR VALID VALUES OF
* X AND Y
*
BITMAP  LDA GRMAP       EXCHANGE BYTES
        LDX GRMAP+1
        STA GRMAP+1
        STX GRMAP
        LDA GRY         START ON TOP
        ADC =3
        STA GRY
        LDA =2          2 BYTES OF MAP
        STA GRYCNT
        LDA =8          MEANS 4 BITS IN ROW
        STA GRYLOW
        LDX =0
        STX GRCNT       COUNTS MAP BYTES
        LDA =>GRMAP     SET MAP ADDRESS
        STA DOSPNT+1
        LDA =<GRMAP
        STA DOSPNT
        JMP PLOTCH3
*
* DRAWX (GRX,GRY,GRC,GRN)
*************************
* USER MUST CHECK FOR VALID VALUES OF
* X AND Y AND N
*
DRAWX   JSR PLOT        PLOT A DOT
        INC GRX
        DEC GRN
        BNE DRAWX       KEEP DRAWING
        RTS
*
* DRAWY (GRX,GRY,GRC,GRN)
*************************
* USER MUST CHECK FOR VALID VALUES OF
* X AND Y AND N
*
DRAWY   JSR PLOT        PLOT A DOT
        INC GRY
        DEC GRN
        BNE DRAWY       KEEP DRAWING
        RTS
*
* DRAWXY (GRX,GRY,GRC,GRN,XINC,YINC)
************************************
* USER MUST CHECK FOR VALID VALUES
*
DRAWXY  LDA =0
        STA GRXLOW
        STA GRYLOW
DRAWXY1 JSR PLOT        PLOT A DOT
        CLC             CALCULATE NEXT GRX
        LDA GRXLOW
        ADC GRXINC
        STA GRXLOW
        LDA GRX
        ADC GRXINC+1
        STA GRX
*
        CLC             CALCULATE NEXT GRY
        LDA GRYLOW
        ADC GRYINC
        STA GRYLOW
        LDA GRY
        ADC GRYINC+1
        STA GRY
*
        DEC GRN
        BNE DRAWXY1     KEEP DRAWING
        RTS
*
*
* 8x8 BIT CHARACTER TABLE
*************************
* FOR CHARACTER DISPLAY IN GRAPHICS MODE
*
*
        ORG $D400
*
FONTTB  BYT $00,$00,$00
        BYT $00,$00,$00
        BYT $00,$00
        BYT $04,$04,$04         !
        BYT $04,$04,$00
        BYT $04,$00
        BYT $0A,$0A,$0A         "
        BYT $00,$00,$00
        BYT $00,$00
        BYT $0A,$0A,$1F         #
        BYT $0A,$1F,$0A
        BYT $0A,$00
        BYT $04,$0F,$14         $
        BYT $0E,$05,$1E
        BYT $04,$00
        BYT $19,$19,$02         %
        BYT $04,$08,$13
        BYT $13,$00
        BYT $04,$0A,$0A         &
        BYT $0C,$15,$12
        BYT $0D,$00
        BYT $04,$08,$10         '
        BYT $00,$00,$00
        BYT $00,$00
        BYT $02,$04,$08         (
        BYT $08,$08,$04
        BYT $02,$00
        BYT $08,$04,$02         )
        BYT $02,$02,$04
        BYT $08,$00
        BYT $00,$04,$15         *
        BYT $0E,$15,$04
        BYT $00,$00
        BYT $00,$04,$04         +
        BYT $1F,$04,$04
        BYT $00,$00
        BYT $00,$00,$00         ,
        BYT $00,$00,$08
        BYT $08,$10
        BYT $00,$00,$00         -
        BYT $1F,$00,$00
        BYT $00,$00
        BYT $00,$00,$00         .
        BYT $00,$00,$00
        BYT $10,$00
        BYT $01,$01,$02         /
        BYT $04,$08,$10
        BYT $10,$00
        BYT $0E,$11,$13         0
        BYT $15,$19,$11
        BYT $0E,$00
        BYT $04,$0C,$14         1
        BYT $04,$04,$04
        BYT $0E,$00
        BYT $0E,$11,$01         2
        BYT $02,$0C,$10
        BYT $1F,$00
        BYT $1E,$01,$02         3
        BYT $04,$02,$01
        BYT $1E,$00
        BYT $02,$06,$0A         4
        BYT $12,$1F,$02
        BYT $02,$00
        BYT $1F,$10,$1E         5
        BYT $01,$01,$11
        BYT $0E,$00
        BYT $07,$08,$10         6
        BYT $1E,$11,$11
        BYT $0E,$00
        BYT $1F,$01,$02         7
        BYT $04,$08,$08
        BYT $08,$00
        BYT $0E,$11,$11         8
        BYT $0E,$11,$11
        BYT $0E,$00
        BYT $0E,$11,$11         9
        BYT $0F,$01,$02
        BYT $1C,$00
        BYT $00,$00,$00         10
        BYT $04,$00,$00
        BYT $04,$00
        BYT $00,$00,$00         :
        BYT $08,$00,$08
        BYT $08,$10
        BYT $03,$04,$08         <
        BYT $10,$08,$04
        BYT $03,$00
        BYT $00,$00,$1F         =
        BYT $00,$1F,$00
        BYT $00,$00
        BYT $18,$04,$02         >
        BYT $01,$02,$04
        BYT $18,$00
        BYT $1E,$11,$01         ?
        BYT $02,$04,$00
        BYT $04,$00
        BYT $0E,$11,$17         @
        BYT $15,$17,$10
        BYT $0E,$00
        BYT $0E,$11,$11         A
        BYT $1F,$11,$11
        BYT $11,$00
        BYT $1E,$11,$11         B
        BYT $1E,$11,$11
        BYT $1E,$00
        BYT $0E,$11,$10         C
        BYT $10,$10,$11
        BYT $0E,$00
        BYT $1C,$12,$11         D
        BYT $11,$11,$12
        BYT $1C,$00
        BYT $1F,$10,$10         E
        BYT $1E,$10,$10
        BYT $1F,$00
        BYT $1F,$10,$10         F
        BYT $1E,$10,$10
        BYT $10,$00
        BYT $0E,$11,$10         G
        BYT $13,$11,$11
        BYT $0F,$00
        BYT $11,$11,$11         H
        BYT $1F,$11,$11
        BYT $11,$00
        BYT $0E,$04,$04         I
        BYT $04,$04,$04
        BYT $0E,$00
        BYT $07,$02,$02         J
        BYT $02,$12,$12
        BYT $0C,$00
        BYT $11,$12,$14         K
        BYT $18,$14,$12
        BYT $11,$00
        BYT $10,$10,$10         L
        BYT $10,$10,$10
        BYT $1F,$00
        BYT $11,$1B,$15         M
        BYT $15,$11,$11
        BYT $11,$00
        BYT $11,$19,$19         N
        BYT $15,$13,$13
        BYT $11,$00
        BYT $0E,$11,$11         O
        BYT $11,$11,$11
        BYT $0E,$00
        BYT $1E,$11,$11         P
        BYT $1E,$10,$10
        BYT $10,$00
        BYT $0E,$11,$11         Q
        BYT $11,$15,$13
        BYT $0D,$00
        BYT $1E,$11,$11         R
        BYT $1E,$14,$12
        BYT $11,$00
        BYT $0F,$10,$10         S
        BYT $0E,$01,$01
        BYT $1E,$00
        BYT $1F,$04,$04         T
        BYT $04,$04,$04
        BYT $04,$00
        BYT $11,$11,$11         U
        BYT $11,$11,$11
        BYT $0E,$00
        BYT $11,$11,$11         V
        BYT $0A,$0A,$04
        BYT $04,$00
        BYT $11,$11,$11         W
        BYT $15,$15,$1B
        BYT $11,$00
        BYT $11,$11,$0A         X
        BYT $04,$0A,$11
        BYT $11,$00
        BYT $11,$11,$11         Y
        BYT $0E,$04,$04
        BYT $04,$00
        BYT $1F,$01,$02         Z
        BYT $04,$08,$10
        BYT $1F,$00
        BYT $1C,$10,$10         [
        BYT $10,$10,$10
        BYT $1C,$00
        BYT $FF,$FF,$FF
        BYT $FF,$FF,$FF
        BYT $FF,$FF
        BYT $07,$01,$01         ]
        BYT $01,$01,$01
        BYT $07,$00
        BYT $04,$0E,$15         ^
        BYT $04,$04,$04
        BYT $04,$00
        BYT $00,$00,$00         _
        BYT $00,$00,$00
        BYT $00,$1F
*
        TIT EXTENDED DISK OPERATING SYSTEM
*
* DISK AND EXDOS ARE USING BUFFER AREA
* AT $D600 - $DFFF. DO NOT USE OTHERWISE
*
        END
*