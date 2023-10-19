*
*   ********************************
*   * R65 DISK AND FILE CONTROLLER *
*   ********************************
*
* EPROM VERSION 1 REVISION 7 15/8/82 RB
*       - FOR 2 TEAC FD50-E DRIVES
* RRICHARZ RBAUMANN 1978 - 1982
* RRICHARZ 2023 MODIFIED FOR LARGER DISK SIZE
*
PSTART  EQU $F000       START OF PROGRAM
SPERTR  EQU 16          SECTORS PER TRACK
NRSEC   EQU 2560        TOTAL SECTORS (16*160)
*
        TIT R65 DISK IO - VARIABLES
*
* THE R65/JOB DISK CONTROLLER CONTROLS TWO
* FLOPPY DRIVES. THE DISK FILE HANDLING IS DONE
* WITH A DIRECTORY ON TRACK 0
* SEQUENTIAL FILE HANDLING ON DISK AND ON AUDIO
* TAPE IS ALLOWED. UP TO 8 FILES CAN BE OPEN
* AT THE SAME TIME
*
* IMPROVEMENTS OF REVISION 5:
*       - WRITE OVERFLOW BUG FIXED
*       - RANDOM ACCESS FILE COMPATIBILITY
*       - PROTECTED SEQUENTIAL FILES ALLOWED
*       - AUTOMATIC RESTORE AFTER DRFIL
*       - 2 DISK DRIVES
*       - I-FLAG ONLY SET DURING 1 SECTOR R/W
*       - FULL FILE NAME(16 CHARS) CHECK
*       - HEAD UNLOAD TIME 8 REVOLUTIONS
*       - RECOVERY AFTER DISK NOT READY
*       - LOADED MESSAGE OPTIONAL
*
* PAGE ZERO VARIABLES:
**********************
*
        ORG $DA
*
FILFLG  BSS 1   FILE ENTRY FLAGS
*               BIT 7 1=PROTECTED
*               BIT 6 1=NO PRINTING
*               BIT 5 1=WRITE, 0=READ
*
FILERR  BSS 1   FILE HANDLING ERROR
*               01 DISK OR TAPE READ ERROR
*               02 CHECKSUM ERROR
*               03 ESCAPE EXIT DURING R/W
*               04 RECORD NO ERROR ON TAPE
*               05 FILE TYPE ERROR
*               06 FILE NOT FOUND
*               07 DISK DRIVE NOT READY
*               08 DIRECTORY FULL, NOT STORED
*               23 TOO MANY OPEN FILES
*               24 DIRECTION OR WRITE PROTECT
*               25 WRONG FILE NUMBER, NOT OPEN
*               26 DISK FULL, NOT STORED
*               27 FILE TOO LONG
*
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
POINT   EQU $FA USED AS SEQ FILE PNT
KCHAR   EQU $FE CHAR SAVE FOR WRITCH
*
* PAGE 3 DATA REGISTERS
***********************
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
*               BIT 6 1=RANDOM ACCESS
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
*
* BUFFERS:
**********
*
        ORG $D600
DIRBUF  BSS $100        DISK DIRECTORY BUFFER
FILBUF  BSS $800        FILE BUFFER MAX 8
*                       FILES ALLOWED
*
* PAGE 17 DATA AREA
*******************
*
        ORG $1780
*
VFLAG   BSS 1
SFLAG   BSS 1
*
* INTERFACE ADDRESSES
*********************
*
FDCOM   EQU $14C0       COMMAND REGISTER
FDSTAT  EQU $14C0       STATUS REGISTER
FDPARA  EQU $14C1       PARAMETER REGISTER
FDRES   EQU $14C1       RESULT REGISTER
FDTSTM  EQU $14C2       TEST MODE REGISTER
FDDAT   EQU $14C4       DACK ADDRESS
USPBD   EQU $1702       LED DISPLAY
*
* VECTORS TO OTHER EPROMS OF OS
*******************************
*
GETCHR  EQU $E003       GET CHAR
PRTINF  EQU $E027       PRINT A STRING
PRTAX   EQU $E030       PRINT TWO BYTES
TWRFIL  EQU $E80C       WRITE TAPE FILE LABEL
TPWAIT  EQU $E80F       READY MESSAGE FOR TAPE
TRDREC  EQU $E812       LOAD A RECORD FROM TAPE
TWRREC  EQU $E818       WRITE A RECORD TO TAPE
SETID   EQU $E82A       SET SET TAPE ID
SETFID  EQU $E81E       SET DATE TO FILE LABEL
TAPEON  EQU $E821       START TAPE DRIVE
TAPEOF  EQU $E824       STOP TAPE DRIVE
TDELAY  EQU $E827       WAIT 1 SEC
PRFLAB  EQU $E82D       PRINT FILE LABEL
TRDLBR  EQU $E830       READ LABEL RECORD
*
        TIT R65 DISK IO - FILE HANDLER
        PAG
*
* START OF PROGRAM
*
        ORG PSTART
*
* VECTORS FOR SUBROUTINE CALLS
******************************
*
        JMP DWRFIL      WRITE BLOCK TO DISK
        JMP DRDFIL      READ BLOCK FROM DISK
        JMP RSTFLD      RESET DISK CONTROLLER
        JMP DDIR        PRINT DISK DIRECTORY
        JMP DELETE      DELETE FILE ON DISK
        JMP OPEN        OPEN SEQUENTIAL FILE
        JMP CLOSE       CLOSE SEQUENTIAL FILE
        JMP CLOSAL      CLOSE ALL FILES
        JMP READCH      READ A CHAR FROM FILE
        JMP WRITCH      WRITE A CHAR TO FILE
*
*
* OPEN SEQUENTIAL FILE
**********************
*
* ENTRY: FILNM1,FILCY1,FILDRV,FILFLG (R/W)
*   FOR WRITE ONLY: FILSTP, FILLOC (TAPE)
*                   MAXSIZ
* FILNAM AND FILCYC ARE COPIED FROM FILNM1
* AND FILCY1
*
* EXIT: NO OF OPEN FILE IN Y, STATUS IN A
*       AND FILERR, Y ONLY VALID IF A=0
*
OPEN    LDY MAXSEQ      SEARCH AN EMPTY ENTRY
        LDA FIDRTB,Y    BIT 6=1: ENTRY USED
        AND =$20
        BEQ OPEN1
        DEY
        BPL OPEN+3
*
        LDA =$23        ERROR 23
        STA FILERR
        RTS
*
OPEN1   STY CURSEQ      SAVE CURRENT ENTRY NO
        LDA FILFLG
        ASL A
        ASL A
        AND =$80        GET R/W DIRECTION FLAG
        STA FIDRTB,Y    BIT 7=1: WRITE
        BEQ OPEN2       SKIP, IF READ
*
        LDA ='S'        FOR WRITE ONLY:
        STA FILTYP      SET FILTYP TO S
        LDA =0
        LDX =3
        STA FILSA,X     CLEAR FILSA AND FILEA
        DEX
        BPL *-4
        STA FILSIZ      CLEAR FILSIZ
        STA FILSIZ+1
        JSR SETFID      SET FILE DATE
*
        LDX =16         SET FILNM1 AND
        LDA FILNM1,X    FILCY1
        STA FILNAM,X
        DEX
        BPL *-7
*
OPEN2   LDA =0
        STA FIBPTB,Y    BUFFER POINTER
        STA FIRCTB,Y    RECORD COUNTER
        LDA FILDRV
        STA FIDVTB,Y    SET DRIVE NUMBER
*
        AND =4          TEST DRIVE TYPE
        BEQ DOPEN       OPEN A DISK FILE
*
TOPEN   LDX MAXSEQ      TEST: ONLY ONE OPEN
TOPEN1  LDA FIDRTB,X    IS THIS ENTRY OPEN?
        AND =$20
        BEQ TOPEN2      SKIP, IF NOT
        LDA FIDVTB,X
        CMP FILDRV
        BEQ TOPEN5      SKIP, IF DOUBLE DRIVE
TOPEN2  DEX
        BPL TOPEN1
*
        JSR TPWAIT
*
        LDA FIDRTB,Y    TEST DIRECTION
        BMI TOPEN7
*
        JSR TRDLBR      GET LABEL RECORD
        JSR PRFLB1      PRINT LABEL, IF ALLOWED
*
        LDA FILTYP
        AND =$7F
        CMP ='S'        IS IT A SEQUENTIAL FILE
        BEQ *+7
        LDA =$05        ERROR 5
        STA FILERR
        RTS
*
        JSR CPOINT      COMPUTE BUFFER POINTER
        LDA =$FE        SET EOF MARK
        STA (POINT),Y
*
TOPEN4  JSR SETID       COMPUTE ID
        LDA TRECID
        LDY CURSEQ
        STA FITEMP,Y    SAVE ID FOR DATA REC
        LDA TRECID+1
        STA FITEMP+8,Y
*
OPEN3   LDA FIDRTB,Y    AND OPEN NOW FILE
        ORA =$20
        STA FIDRTB,Y
*
        LDA =0          NORMAL EXIT
        STA FILERR
        RTS
*
TOPEN5  LDA =$26        ERROR 26
        STA FILERR
        RTS
*
TOPEN7  JSR TWRFIL      WRITE LABEL RECORD
        BEQ TOPEN4      SKIP, IF OK
        STA FILERR      OR EXIT WITH ERROR
        RTS
*
DOPEN   LDA FIDRTB,Y    TEST DIRECTION
        BMI DOPEN2
*
        JSR PREPRD      DISK READ FILE
        JSR PRFLB1
        LDA FILTYP
        AND =$7F
        CMP ='S'        MUST BE SEQUENTIAL
        BEQ *+7
        LDA =5
        JMP DISCER1
*
        JSR ENDDO
        JSR DOPEN1
        JSR CPOINT
        LDA =$FE        SET EOR MARK
        STA (POINT),Y
        LDY CURSEQ
        JMP OPEN3       OPEN THE FILE
*
DOPEN1  LDY CURSEQ      SUBROUTINE
        LDA FILLOC+1    GET FIRST SECTOR
        STA FITEMP,Y
        LDA FILLOC
        STA FITEMP+8,Y
        LDA FILSIZ+1
        STA FIMAXT,Y    NO OF SECTORS
        LDA SCYFC       DIRECTORY ENTRY NO
        STA FITEMP+16,Y
        RTS
*
DOPEN2  JSR PREPWRA     DISK WRITE FILE
        STX FILCYC
        JSR PREPWRB
        LDA =$FF        COMPUTE FREE SPACE
        CPY =0          MAX 255 SECTORS
        BNE *+3
        TXA
        JSR DOPEN3      SET UP DIRECTORY
        LDY CURSEQ
        JMP OPEN3       OPEN NOW THE FILE
*
DOPEN3  STA FILSIZ+1    SET SIZE OF FILE
        STA FILEA+1
        LDA =0
        STA FILSA
        STA FILEA
        STA FILSA+1
DOPEN4  LDA SLAST
        STA SCYFC
        JSR DOPEN1
        JMP DWRFI6
*
* PRINT FILE LABEL, IF ALLOWED
******************************
*
PRFLB1  BIT FILFLG
        BVS *+5
        JMP PRFLAB
        RTS
*
* COMPUTE BUFFER POINTER (POINT),Y
**********************************
* CURSEQ IS USED AS FILE NUMBER
*
CPOINT  LDX CURSEQ
        LDY FIBPTB,X    GET LOW POINTER
        LDA =0
        STA POINT
        TXA
        CLC
        ADC FILBU1      AND START OF FILE
        STA POINT+1     BUFFERS, FULLPAGE
        RTS
*
* READCH: READ CHAR FROM FILE IN X
**********************************
* ENTRY: x,FILDRV
* EXIT: FILERR IN Y AND STATUS, CHAR IN A
* CHAR =$1F MEANS EOF, CHAR=$1D MEANS ERROR
*
READCH  LDA =0          MUST BE READ FILE
        JSR TESTFN
        STX CURSEQ
        JSR CPOINT
        LDA (POINT),Y   GET ONE CHAR FROM FILE
        BMI READC4      SKIP, IF BIT 7 SET
*
READC0  LDX CURSEQ
        INY             COUNT CHAR
        BNE READC2      SKIP, IF NOT EOR
*
READC1  PHA             SAV CHAR
        JSR RDSREC      GET NEXT RECORD
        BNE READC3      SKIP, IF ERROR
        PLA             IF OK, GET CHAR BACK
        LDY =0
*
READC2  PHA             SAVE CHAR AGAIN
        TYA             POINTER TO A
        LDX CURSEQ
        STA FIBPTB,X    STORE POINTER
        PLA
READC7  LDY =0          NORMAL EXIT
        STY FILERR
        RTS
*
READC3  TYA             READ ERROR
        PLA
        LDA =$1D
        BNE READC7+2    ALLWAYS TAKEN
*
READC4  CMP =$FE        EOR?
        BNE READC5
        JSR READC1      GET NEXT RECORD
        BEQ READCH      OK, GET CHAR
        RTS             ERROR, RETURN
*
READC5  CMP =$FF        END OF FILE?
        BNE READC6
        LDA =$1F        END OF FILE
        BNE READC7      ALLWAYS TAKEN, OK
*
READC6  SEC             COUNT ONE BLANK
        SBC =1
        STA (POINT),Y
        TAX
        LDA =$20
        CPX =$80
        BEQ READC0      IF LAST BLANK, INCREASE
        BNE READC7      ELSE SAME PNT AGAIN
*
* TESTFN: TEST FILE NUMBER IN X
*******************************
* A=00: MUST BE OPEN SEQUENTIAL READ FILE
* A=80: MUST BE OPEN SEQUENTIAL WRITE FILE
*
TESTFN  CPX MAXSEQ
        BCS TESTF1
*
TESTF0  EOR FIDRTB,X
        BMI TESTF2      DIRECTON ERROR, SKIP
        LDA FIDRTB,X
        AND =$60        TEST FOR NOT OPEN
        CMP =$20        OR RANDOM ACCESS FILE
        BNE TESTF3      SKIP, IF NOT OPEN
        RTS
*
TESTF1  BEQ TESTF0
TESTF3  LDY =$25        WRONG FILE TYPE
        PLA             NUMBER
        PLA
        STY FILERR
        LDA =$1E
        RTS
*
TESTF2  LDY =$24        DIRECTION ERROR
        BNE TESTF1+4    ALLWAYS TAKEN
*
* PREPSR: PREPARE SEQUENTIAL RECORD R/W
***************************************
*
PREPSR  JSR CPOINT
        LDA POINT
        LDY POINT+1
        STA TRECST
        STY TRECST+1
        LDA FIRCTB,X
        STA TRECNO
        INC TRECNO
        LDA FITEMP,X
        STA TRECID
        LDA FITEMP+8,X
        STA TRECID+1
        LDA FIDVTB,X
        STA FILDRV
        AND =4          TEST DISK OR TAPE
        RTS
*
* ENDSR: END OF SEQUENTIAL RECORD R/W
*************************************
*
ENDSRT  PHA             ENTRY FOR TAPE ROUTINES
        JSR TAPEOF
        CLI
        PLA
*
ENDSRD  BNE ENDSR1      ENTRY FOR DISK ROUTINES
        PHA
        LDX CURSEQ
        INC FIRCTB,X
        PLA
ENDSR1  RTS
*
* RDSREC: READ SEQUENTIAL RECORD
********************************
*
RDSREC  JSR PREPSR
        BEQ RDSRE1      SKIP,IFDISK
*
        JSR TAPEON
        JSR TRDREC
        JMP ENDSRT
*
RDSRE1  JSR PREPSR1
        JSR READ
        JMP ENDSR2
*
* WRITCH: WRITE CHAR IN A TO FILE IN X
**************************************
* ENTRY: A,X,FILFLG
* EXIT: FILERR IN Y AND STATUS
*
WRITCH  AND =$7F        MASK OFF BIT 7
        CMP =$A         IGNORE LF
        BNE *+3
        RTS
        STA KCHAR       SAVE CHAR DURING TEST
        LDA =$80        MUST BE WRITE FILE
        JSR TESTFN
        STX CURSEQ
        JSR CPOINT
        LDA KCHAR
        CMP =$20        BLANK?
        BEQ WRITC4
*
WRITC0  STA (POINT),Y
        CMP =$FF                EOF?
        BEQ WRITC1      YES, STORE BUFFER
*
        INY             ELSE COUNT
        BNE WRITC2
*
WRITC1  JSR WRSREC
        BNE WRITC3      SKIP, IF ERROR
        LDY =0          ELSE NEW BUFFER
*
WRITC2  LDX CURSEQ
        TYA
        STA FIBPTB,X
        LDY =0
        STY FILERR
        RTS             NORMAL EXIT
*
WRITC3  TYA
        STY FILERR      ERROR EXIT
        RTS
*
WRITC4  LDA =$81        BLANK
        CPY =0          PRINT,IF START OF
        BEQ WRITC0      BUFFER
        DEY             ELSE LOOK AT LAST CHAR
        LDA (POINT),Y
        BPL WRITC5      SKIP, IF NOT BLANK
        CMP =$FC        MAX BLANK COUNTER
        BCS WRITC5
        CLC
        ADC =1
        BMI WRITC0      ALLWAYS TAKEN
*
WRITC5  INY
        LDA =$81
        BNE WRITC0      ALLWAYS TAKEN
*
* WRSREC: WRITE SEQUENTIAL RECORD
*********************************
*
WRSREC  JSR PREPSR
        BEQ WRSRE1      SKIP, IF DISK
*
        JSR TAPEON
        JSR TDELAY
        LDA =0
        JSR TWRREC
        JMP ENDSRT
*
WRSRE1  JSR PREPSR1
        JSR WRITE
*
ENDSR2  JSR ENDDO
        JMP ENDSRD
*
PREPSR1 DEC TRECNO      FIRST RECORD IS 0
        LDA TRECNO
        CMP FIMAXT,X    TEST SIZE OF FILE
        BCC PREPSR2
        PLA
        PLA
        LDA =$27        FILE TOO LONG
        STA FILERR
        RTS
*
PREPSR2 LDA SECTOR      SET BINARY RECORD
        CLC
        ADC TRECNO
        STA SECTOR
        BCC *+4
        INC TRACK
        JSR PREPDO1
        JMP PREPRW1-2   CONVERT TO TRACK/SECTOR
*
* CLOSE: CLOSE EXISTING FILE IN X
*********************************
* EXIT: FILERRIN Y AND STATUS
*
CLOSE   LDA FIDRTB,X
        JSR TESTFN
        STX CURSEQ
        LDA FIDRTB,X
        AND =$80
        BEQ CLOSE1      SKI, IF READ
*
        LDA =$FF        WRITE LAST CHAR
        JSR WRITCH+2
        BNE CLOSE2+2    SKIP, IF ERROR
*
CLOSE1  LDA FIDRTB,X
        AND =$DF        CLOSE ENTRY IN TABLE
        STA FIDRTB,X
        LDA FIDVTB,X
        AND =2
        BEQ CLOSE3      SKIP, IF DISK
        LDY =0          NORMAL EXIT
*
CLOSE2  STY FILERR
        RTS
*
CLOSE3  LDA FIDRTB,X    TEST DIRECTION
        BMI *+3
        RTS
*
        JSR PREPDO
        LDX CURSEQ
        LDA FITEMP+16,X GET FILE ENTRY NO
        STA SLAST
        TAX
        JSR GETFENT
        LDX CURSEQ
        LDA FIRCTB,X    GET ACTUAL SIZE
        JMP DOPEN3      AND SET UP DIRECTORY
*
* CLOSAL: CLOSE ALL SEQUENTIAL FILES
************************************
*
CLOSAL  LDX MAXSEQ
        STX CURSEQ
*
CLOSA1  LDX CURSEQ
        LDA FIDRTB,X    FILE OPEN?
        AND =$60        AND SEQUENTIAL
        CMP =$20
        BNE *+5
        JSR CLOSE       CLOSE IT
        BNE CLOSA2
        DEC CURSEQ
        BPL CLOSA1
        LDY =0
        STY FILERR
CLOSA2  RTS
*
* RSTFLD: RESET FLOPPY DISK CONTROLLER
**************************************
*
RSTFLD  LDX =7          MAX 8 OPEN FILES
        STX MAXSEQ      DEFAULT, CAN BE <8
        LDA =>FILBUF    DEFAULT BUFFER
        STA FILBU1
        LDA =0          CLEAR ENTRIES
        STA FIDRTB,X
        DEX
        BPL *-4
*
        STA DISFLG      CLEAR INITIALIZED FLAG
        RTS
*
        TIT R65 DISK IO - FILE HANDLER
        PAG
*
*
ITABL   BYT $FF,$FF,$FF,$18     BADTRACK1
        BYT $FF,$FF,$FF,$10     BADTRACK0
        BYT $85,5,13,$0D        SPECIFY
*
*
* INITIALIZATION ROUTINE
************************
*
INITDC  LDX =11
INITD1  LDY =3
        LDA =$35        SPECIFY CMD
        JSR WRCOMM
INITD2  LDA ITABL,X
        JSR WRPARA
        DEX
        BMI INITD3
        DEY
        BPL INITD2
        BMI INITD1
INITD3  RTS
*
*
*
* DRIVE CODE SUBROUTINE
***********************
* SELECTED DRIVE IN FILDRV, OUTPUT IN A
*
DRIVE   LDA FILDRV
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        RTS
*
* SEEK COMMAND
**************
* SELECT DRIVE IN FILDRV
* TRACK ADDRESS IN TRACK
*
SEEK    JSR DRIVE
        ORA =$29        FROM SEEK CMD
        JSR WRCOMM
        LDA TRACK       GET TRACK ADDRESS
        JMP WRPARA
*
*
* READ DRIVE STATUS
*******************
* SELECTED DRIVE IN FILDRV
*
RDSTAT  JSR DRIVE
        ORA =$2C        READ STATUS COMMAND
        JSR WRCOMM
        JMP RESULT
*
*
* READ SPECIAL REGISTER
***********************
* REGISTER ADDRESS IN X
* RESULT RETURNED IN A
*
RDREG   JSR DRIVE       READ SPECIAL REG CMD
        ORA =$3D
        JSR WRCOMM
        TXA
        JSR WRPARA
        JMP RESULT
*
*
* WRITE SPECIAL REGISTER
************************
* REGISTER ADDRESS IN X
* DATA TO BE WRITTEN IN Y
*
WRREG   JSR DRIVE       WRITE SPECIAL REG CMD
        ORA =$3A
        JSR WRCOMM
        TXA
        JSR WRPARA
        TYA
        JMP WRPARA
*
*
* WRITE IN COMMAND REGISTER
***************************
* COMMAND IN A
*
WRCOMM  BIT FDSTAT      BUSY?
        BMI WRCOMM      WAIT IF BUSY
        BVS WRCOMM      WAIT IF COMMAND FULL
        STA FDCOM
        RTS
*
*
* WRITE IN PARAMETER REGISTER
*****************************
* PARAMETER IN A
*
WRPARA  PHA             SAVE PARAMETER
        LDA =$20        MASK FOR PARAMETER FLAG
        BIT FDSTAT
        BNE *-3         WAIT IF PARAMETER FULL
        PLA
        STA FDPARA
        RTS
*
*
* TEST RESULT SUBROUTINE
************************
* Z=0, IF ERROR (ERROR CODE IN RESSAV AND A)
* $FF RETURNED MEANS NO RESULT
*
RESULT  LDA =$10        RESULT FLAG MASK
        BIT FDSTAT
        BMI *-3         WAIT IF BUSY
        BNE RESULT1
        LDA =$FF        NO RESULT
        BNE RESULT1+3
*
RESULT1 LDA FDRES       GET RESULT
        STA RESSAV
        RTS
*
*
* READ OR WRITE OF SINGLE RECORD COMMAND
****************************************
* SELECTED DRIVE AND OPCODE IN A
* TRACK ADDRESS IN TRACK
* SECTOR ADDRESS IN SECTOR
*
SINGLE  JSR WRCOMM
        LDA TRACK
        JSR WRPARA
        LDA SECTOR
        JSR WRPARA
        LDA =#00100001  ONE SECTOR OF 256 BYTES
        JMP WRPARA
*
*
* DATWRIT: DATA WRITE SUBROUTINE
********************************
* DATA TO WRITE IN A
* ERROR, IF FDC NOT BUSY
* RETURNS ONE SUB-LEVEL, IF ERROR
*
DATWRIT PHA             SAVE CODE
        LDA =4          MASK FOR DATA REQUEST
        BIT FDSTAT
        BPL DATWRT1     FDC NOT BUSY ERROR
        BEQ *-5
        PLA
        STA FDDAT
        RTS
*
DATWRT1 PLA             FDC NOT BUSY
        PLA             PULL ONE SUB LEVEL
        PLA             AND SAVED CODE
        JMP RESULT
*
*
* DATREAD: DATA READ SUBROUTINE
*******************************
* RETURNS WITH DATA IN A, SEE DATA WRITE SUB
*
DATREAD LDA =8          MASK FOR DATA PROVIDE
        BIT FDSTAT
        BPL DATWRT1+1   END: FDC NOT BUSY
        BEQ *-5         NO IRQ NOW
        LDA FDDAT
        RTS
*
*
* TURN MOTOR ON SUBROUTINE
**************************
*
MOTON   JSR RDSTAT      IS MOTOR ON?
        PHA
        LDX =$23        FDC OUTPUT PORT
        JSR RDREG
        ORA =$20        MOTOR ON BIT
        TAY
        JSR WRREG
        PLA
        LSR A           OPI=1 MOTOR WAS ON
        BCS *+3         SKIP, IF NOT
        RTS
*
        JMP TDELAY      WAIT 1 SECOND
*
*
* TURN MOTOR OFF SUBROUTINE
***************************
*
MOTOFF  LDX =$23        FDC OUTPUT PORT
        JSR RDREG
        AND =$DF        CLEAR MOTOR ON BIT
        TAY
        JMP WRREG
*
*
* WRITE ONE RECORD TO DISK (256 BYTES)
**************************************
* TRACK AND SECTOR ADDRESS IN TRACK AND SECTOR
* DRIVE CODE IN FILDRV, MOTOR MUST BE ON
* INDIRECT DATA POINTER IN DATA
* MAX 10 TRIALS ARE DONE, NO VERIFY
*
WRITE   LDX =10         TRIAL COUNTER
        JSR WRIT0
        BNE *+3
        RTS             OK
*
        JSR RDSTAT
        SEI
        DEX
        BNE WRITE+2
        JMP DISCERR     NOT OK
*
WRIT0   JSR DRIVE
        ORA =$0B
        JSR SINGLE      WRITE
        LDY =0
WRIT1   LDA (DATA),Y    LOAD DATA
        JSR DATWRIT     DUMP IT
        INY
        BNE WRIT1       END TEST
        JMP RESULT
*
*
* VERIFY ONE RECORD
*******************
* SEE WRITE FOR DETAILS, ONLY ONE TRIAL
*
VERIFY  JSR DRIVE
        ORA =$1F        VERIFY
        JSR SINGLE
        JMP RESULT      TEST RESULT
*
*
* READ ONE RECORD FROM DISK
***************************
* TRACK AND SECTOR ADDRESS IN TRACK AND SECTOR
* INDIRECT DATA POINTER IN DATA,DRIVE IN FILDRV
* MAX 10 TRIALS ARE DONE
*
READ    LDX =10         TRIAL COUNTER
        JSR READ0
        BNE *+3
        RTS             OK
*
        JSR RDSTAT
        SEI
        DEX
        BNE READ+2
        JMP DISCERR     NOT OK
*
READ0   JSR DRIVE
        ORA =$13
        JSR SINGLE
        LDY =0
READ1   JSR DATREAD
        STA (DATA),Y
        INY
        BNE READ1
        JMP RESULT
*
*
* INITIALIZE DISK DRIVE
***********************
* NON DMA MODE,MOTOR MUST BE ON
* INPUT: FILDRV,EXITPN
*
INITDRV JSR INITDC      INITIALIZE FDC
        NOP             ################
        NOP             ################
        NOP             ################
        LDX =$17        MODE REGISTER
        LDY =$C1        NON DMA,DOUBLE ACT
        JSR WRREG
        JSR TRACK0
        JSR RESULT
        BEQ *+5
        JMP DISCERR
*
        JSR DRIVE       SET INITIALIZED FLAG
        ORA DISFLG
        STA DISFLG
        RTS
*
*       SET HEAD TO TRACK0, NO CHECK
*
TRACK0  LDX =0
        STX TRACK
        JMP SEEK
*
*
        TIT R65 DISK IO - DIRECTORY
        PAG
*
* PREPARE DISK OPERATION
* **********************
* INPUT: FILDRV
* OUTPUT: EXITPN,BUFSEC
*
PREPDO  TSX             SAVE STACK POINTER
        INX
        INX             FOR ERROR EXIT
        STX EXITPN
        LDA =$FF
        STA BUFSEC
        LDA USPBD       SET LED 2
        ORA =4
        STA USPBD       FOR DISK
        JSR MOTON
        JSR RDSTAT      CLEAR READY FLAG
        JSR DRIVE       IS DRIVE INITIALIZED?
        AND DISFLG
        BNE *+5         YES, SKIP
        JSR INITDRV     ELSE INITIALIZE IT
        RTS
*
PREPDO1 TSX             PULL ONE LEVEL MORE
        INX
        INX
        JMP PREPDO+1
*
*
* GETFENT: GET ONE FILE ENTRY
*****************************
* INPUT: X=NO OF ENTRY, BUFSEC
* OUTPUT: ENTRY,FILCNT
*
GETFENT JSR GETFREC     READ RECORD
        JSR SDOSPNT
        LDY =31         TRANSFER ENTRY
GETFEN1 LDA (DOSPNT),Y
        STA FILTYP,Y
        DEY
        BPL GETFEN1
        RTS
*
* COMPUTE DOSPNT
****************
*
SDOSPNT JSR FILENT
        STY DOSPNT
        LDA =>DIRBUF
        STA DOSPNT+1
        RTS
*
* GET DIRECTORY RECORD
**********************
* LOADS RECORD ONLY,IF NOT IN MEMORY
* INPUT: X=NO OF ENTRY,BUFSEC,EXITPN
* OUTPUT: BUDSEC,FILCNT,FILCN1,SECTOR
*
GETFREC STX FILCNT      SET FILCNT
        TXA
        AND =7
        STA FILCN1      AND FILCN1
        TXA
        LSR A
        LSR A
        LSR A
        TAX
        INX
        STX SECTOR
        CPX BUFSEC      IM MEMORY?
        BNE READDS      NO, READ IT
        RTS
*
* READ DIRECTORY SECTOR
***********************
* INPUT: FILDRV,SECTOR,EXITPN
* OUTPUT: BUFSEC
*
READDS  JSR SDIRBUF
        JSR READ        READ RECORD
        LDA SECTOR
        STA BUFSEC
        RTS
*
* SET DATA TO DIRBUF
********************
*
SDIRBUF LDA =0
        LDX =>DIRBUF
        STA DATA
        STX DATA+1
        STA TRACK
        RTS
*
* COMPUTE NUMBER OF EMPTY SECTORS
*********************************
* INPUT: FILCNT
* OUTPUT: Y(HIGH), X(LOW) SECTORS
*
EMPTSIZ JSR FILENT      Y=POINTER
        LDA =<NRSEC
        SEC
        SBC DIRBUF+$13,Y
        TAX
        LDA =>NRSEC
        SBC DIRBUF+$14,Y
        TAY
        RTS
*
* STORE DIRECTORY RECORD
************************
* INPUT: BUFSEC,EXITPN,FILDRV
* OUTPUT: SECTOR,TRACK
* DIRECTORY RECORDS ARE VERIFIED AFTER STORE
*
WRITDS  JSR SDIRBUF
        LDA BUFSEC
        STA SECTOR
        LDA =4          4 TRYALS
        STA DISCNT
WRITD1  JSR WRITE
        JSR VERIFY
        BNE *+3
        RTS             OK
*
        DEC DISCNT
        BNE WRITD1
        JMP DISCERR
*
* PREPARE DISK READ/WRITE
*************************
* INPUT: FILSA,FILSIZ,FILLOC
* OUTPUT: DATA,TRACK,SECTOR,FILCN1
*
PREPRW  LDA FILSA
        LDX FILSA+1
        STA DATA
        STX DATA+1
        LDA FILLOC      SET BINARY RECORD
        LDX FILLOC+1
PREPWR0 STA SECTOR      COUNTER
        STX TRACK
*
        LDX =2          START DATA TRACK
PREPRW1 LDA SECTOR      CONVERT TO TRACK
        SEC             AND SECTOR BY
        SBC =SPERTR     REPEATED SUBTRACTION
        TAY             (WORKS FOR ANY RPERTR)
        LDA TRACK
        SBC =0
        BCC PREPRW2     SKIP, IF DONE
*
        STY SECTOR
        STA TRACK
        INX
        BNE PREPRW1     ALLWAYS TAKEN
*
PREPRW2 STX TRACK
        LDA SECTOR
        AND =$0F
        STA SECTOR
        INC SECTOR      SET SECTOR
        LDA FILSIZ+1
        STA FILCN1      NO OF RECORDS
        RTS
*
* PUT FILE ENTRY TO DISK
************************
* INPUT: X=FILE ENTRY
* OUTPUT:
*
PUTFENT STX FILCN1
        JSR SDOSPNT
        LDY =31
PUTFEN1 LDA FILTYP,Y
        STA (DOSPNT),Y
        DEY
        BPL PUTFEN1
        JMP WRITDS
*
* SEARCH IN DIRECTORY
*********************
* INPUT:FILDRV,EXITPN,FILCY1,FILNM1
* FILCY1=0: SEARCH MAXIMAL CYCLUS
* OUTPUT: SCY,SCYFC,SLAST
*
SEARCH  LDX =0
        STX SCY
*
SEARCH1 JSR GETFREC     GET ONE RECORD
        JSR FILENT
        LDA DIRBUF,Y    GET FILTYP
        BNE SEARCH2     SKIP, IF NOT LAST
        LDX FILCNT
        STX SLAST       END OF DIRECTORY
        CLI
        RTS
*
SEARCH2 LDA DIRBUF+$1E,Y        GET FILLNK
        BPL SEARCH4     SKIP, IF NOT DELETED
*
SEARCH3 LDX FILCNT      NEXT ENRTY
        INX
        BNE SEARCH1     ALLWAYS TAKEN
*
SEARCH4 JSR SDOSPNT+3
        LDY =15         COMPARE NAME
SEARCH5 LDA (DOSPNT),Y
        CMP FILNM1-1,Y
        BNE SEARCH3     NEXT ENTRY
        DEY
        BNE SEARCH5
*
        JSR FILENT      FILNAM IS MATCHING
        LDA FILCY1
        BNE SEARCH7     CYCLUS=0?
        LDA SCY         YES, <CURRENT CY?
        CMP DIRBUF+$11,Y
        BCS SEARCH3     NEXT ENTRY, IF NOT
*
SEARCH6 LDA DIRBUF+$11,Y
        STA SCY
        LDA FILCNT
        STA SCYFC
        JMP SEARCH3
*
SEARCH7 LDA FILCY1      CYCLUS # 0
        CMP DIRBUF+$11,Y
        BEQ SEARCH6
        BNE SEARCH3     ALLWAYS TAKEN
*
* COMPUTE FILE ENTRY POINTER
****************************
* INPUT: FILCN1
* OUTPUT: Y
*
FILENT  LDA FILCN1
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        TAY
        RTS
*
* DISK ERROR FROM CONTROLLER
****************************
*
DISCERR LDA RESSAV      GET THE CODE
        LSR A
        AND =$0F
        TAX
        LDA DISCERT,X   GET FROM TABLE
*
DISCER1 STA FILERR
        LDX EXITPN
        TXS             SET STACK POINTER
ENDDO1  LDA RESSAV
        PHA
        JSR MOTOFF
        PLA
        STA RESSAV
        LDA USPBD       TURN LED 2 OFF
        AND =$FB
        STA USPBD
        CLI
        LDA FILERR
        RTS
*
DISCERT BYT 0,0,0,0,1,1,1,2,7,$24,1,1,1
*
* GOOD COMPLETION
*****************
*
ENDDO   LDA =0
        STA FILERR
        JMP ENDDO1
*
* PREPARE FILE READ
*******************
*
PREPRD  JSR PREPDO1
        JSR SEARCH
        LDA SCY
        BNE *+5
        JMP NOTFND      FILE NOT FOUND
*
        LDX SCYFC
        JMP GETFENT
*
* INCREMENT POINTERS FOR FILE R/W
*********************************
*
INCDATP INC DATA+1
        INC SECTOR
        LDA SECTOR
        CMP =$11
        BNE *+8
        LDA =1
        STA SECTOR
        INC TRACK
        RTS
*
* PREPARE WRITE
***************
*
PREPWRA JSR PREPDO1
        JSR SEARCH
        LDX FILCY1
        BNE PREPWRC     SKIP, IF NOT DEFAULT
*
        LDX SCY
        INX
        RTS
*
PREPWRC LDA SCY
        BEQ PREPWRC-1   SKIP, IF NOT SAME
*
        JSR DELETE4     ELSE DELETE THIS FILE
        LDX FILCY1
        RTS
*
PREPWRB LDA =0
        STA FILLNK
        LDX SLAST
        CPX =255         MAX 255 FILE ENTRIES
        BNE *+7
        LDA =8          DIRECTORY FULL
        JMP DISCER1
*
        JSR GETFREC
        JSR FILENT
        LDA DIRBUF+$13,Y
        STA FILLOC
        LDA DIRBUF+$14,Y
        STA FILLOC+1
        JMP EMPTSIZ
*
*
        TIT R65 DISK IO - MAIN DISK ROUTINES
        PAG
*
****************************
* DDIR: PRINT DISK DIRECTORY
****************************
* INPUT: FILDRV
* OUTPUT: FILERR
*
DDIR    JSR PRTINF
        BYT $D,$8A
        JSR PREPDO
        LDX =0
*
DDIR1   JSR GETFENT
        LDA FILTYP      0 MEANS END MARK
        BEQ DDIR2
        LDA FILLNK      BIT 7+1 MEANS DELETED
        BMI *+5         DO NOT PRINT IF DELETED
        JSR PRFLAB
        BCS DDIR2       ESC?
        LDX FILCNT
        INX
        BNE DDIR1       ALLWAYS TAKEN
*
DDIR2   JSR PRTINF
        BYT $D,$A,$A
        BYT 'SECTORS FREE:'+128
        JSR EMPTSIZ
        TYA
        JSR PRTAX
        JSR PRTINF
        BYT $D,$8A
        JMP ENDDO
*
****************************
* DELETE: DELETE DISK FILE *
****************************
* INPUT: FILDRV,FILNM1,FILCY1
* OUTPUT: FILERR
*
DELETE  JSR PREPDO
        LDA FILCY1
        BNE DELETE1
*
NOTFND  LDA =6          FILE NOT FOUND
        JMP DISCER1
*
DELETE1 JSR SEARCH
        LDA SCY
        BEQ NOTFND
*
        JSR DELETE4
        JMP ENDDO
*
DELETE4 LDX SCYFC
        JSR GETFREC
        JSR FILENT
        LDA DIRBUF,Y    PROTECTED?
        BPL DELETE3
*
        TYA
        PHA
        JSR PRTINF
        BYT $D,$a,'DELETE? '+128
        JSR GETCHR
        AND =$5F
        CMP ='Y'
        BEQ DELETE2
*
        LDA =3          ESCAPE FROM DISK OP
        JMP DISCER1
*
DELETE2 JSR PRTINF
        BYT $D,$8A
        PLA
        TAY
*
DELETE3 LDA DIRBUF+$1E,Y
        ORA =$80        SET DELETET FLAG
        STA DIRBUF+$1E,Y
        JMP WRITDS
*
*
**************************
* DRDFIL: LOAD DISK FILE *
**************************
* INPUT: FILDRV,FILNM1,FILCY1
* OUTPUT: FILERR
*
DRDFIL  JSR PREPRD
        LDA FILSA1
        ORA FILSA1+1
        BEQ DRDFIL1
*
        LDA FILSA1
        STA FILSA
        STA FILEA
        LDA FILSA1+1
        STA FILSA+1
        CLC
        ADC FILSIZ+1
        STA FILEA+1
        LDA FILEA
        BNE *+5
        DEC FILEA+1
        DEC FILEA
*
DRDFIL1 LDA FILTYP
        AND =$7F
        CMP ='B'        MUST BE BLOCK FILE
        BEQ *+7
        LDA =5          FILE TYPE ERROR
        JMP DISCER1
*
        JSR PRFLB1
        JSR PREPRW
*
DRDFIL2 JSR READ
        JSR INCDATP
        DEC FILCN1
        BNE DRDFIL2
        JSR ENDDO
        JSR TRACK0
        LDA =0
        RTS
*
**************************
* DWRFIL:STORE DISK FILE *
**************************
* INPUT: FILDRV,FILNM1,FILCY1,ENTRY,FILSA1
* OUTPUT: FILERR
*
DWRFIL  JSR PREPWRA
        STX FILCYC
        LDA FILSIZ      SIZE MUST BE FULL
        BEQ DWRFI3      RECORDS
        INC FILSIZ+1
        EOR =$FF
        SEC
        ADC FILEA
        STA FILEA
        BCC *+5
        INC FILEA+1
        LDA =0
        STA FILSIZ
*
DWRFI3  JSR PREPWRB
        TXA
        CMP FILSIZ+1
        TYA
        SBC =0
        BCS *+7
        LDA =$26        DISK FULL
        JMP DISCER1
*
        LDA FILSA1
        LDX FILSA1+1
        JSR PREPRW+6
*
DWRFI4  JSR WRITE
        JSR INCDATP
        DEC FILCN1
        BNE DWRFI4
*
DWRFI6  LDX SLAST
        TXA
        AND =7          LAST ENTRY OF RECORD
        STA FILCN1
*
        JSR PUTFENT     STORE THIS ENTRY
DWRFI7  LDX SLAST
        INX
        JSR GETFREC
*
        JSR FILENT
        LDX FILCNT
        LDA =0
        STA FILTYP      SET NEW END MARK
        LDA FILLOC
        CLC
        ADC FILSIZ+1
        STA FILLOC
        BCC *+5
        INC FILLOC+1
        JSR PUTFENT     STORE THIS ENTRY
        JMP ENDDO
*
*
        TIT R65 DISK IO - REFERENCE MAP
*
        END
*