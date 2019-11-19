* BASIC1:A ORIGINAL 7/1/1982, RECOVERED 3/2018
*
******************************************
* R65 EXTENDED GRAPHIC BASIC VERSION 6.2 *
******************************************
*
* VERSION 6.2 OPTIMIZED FOR R65 EMULATOR 2018
*
        TIT GRAPHIC BASIC - VARIABLES
*
* PAGE ZERO VARIABLES
*
        ORG 0
*
OUTDEV  BSS 1   OUTPUT DEVICE NO (CRT=0)
NUMPAD  BSS 1   NO OF PAD CHAR,CURR.DEV
POS     BSS 1   POSITION IN LN, CURR.DEV.
*
INBNUM  BSS 2   INPUT BUFFER NUMBER
INTEG   BSS 2   INTEGER
INBUFF  BSS 58  INPUT BUFFER
CHRSAV  BSS 2   CHAR SAVE AND COMPARE
INPNT   BSS 1   INPUT BUFFER POINTER
*
        BSS 1
RESTYP  BSS 2   CURRENT RESULT TYPE
TEMP2   BSS 1   TEMPORARY
FLAG1   BSS 1   ARRAY FLAG
READFL  BSS 1   READ FLAG
        BSS 1
        BSS 1
STRSTP  BSS 2   STRING STACK POINTER
        BSS 1
STRST   BSS 9   STRING STACK (3 LEVELS)
TEMP1   BSS 2
TEMP8   BSS 2
TEMP9   BSS 5
*
STPROG  BSS 2   START OF USER PROG
STVAR   BSS 2   START OF VARIABLE TABLE
EOVAR   BSS 2   END OF VARIABLE TABLE
STSPAC  BSS 2   START OF AVAILABLE SPACE
BTSTRG  BSS 2   BOTTOM OF STRINGS
TPSTRG  BSS 2   TOP OF STRINGS
TPMEM   BSS 2   TOP OF BASIC MEMORY
LINE    BSS 2   CURRENT BASIC LINE
LINSAV  BSS 2   SAVED LINE
PNTSAV  BSS 2   SAVED BASIC POINTER
TEMP7   BSS 2
DATPNT  BSS 2   DATA POINTER
DTSPNT  BSS 2   DATA STATEMENT PONTER
VARSYM  BSS 2   CURRENT VARIABLE SYMBOL
VARSTP  BSS 2   CURRENT VAR STRING P
TEMP3   BSS 2
*
        BSS 1
        BSS 1
LOGIC   BSS 1   LOGIC OPERATOR
TEMP6   BSS 2
TEMP5   BSS 2
        BSS 1
SIZE    BSS 1   VARIABLE SIZE
        BSS 1   SET TO 4C FOR BFUNC
PNT1    BSS 2   POINTER
        BSS 1
*
* BLLOCK AREA
*
ENDB    BSS 2   END OF BLOCK
BEGINB  BSS 2   BEGIN OF BLOCK
        BSS 1
POINTC  BSS 1   CURRENT DIGITS AFTER DEC.P.
CURREX  BSS 1   CURRENT EXP IN NUMBER
TRANSP  BSS 2   TRANSFER POINTER
*
* FLP ACCU
*
EXP     BSS 1   EXPONENT
MANT    BSS 4   MANTISSA
SIGN    BSS 1   SIGN OF MANTISSA
*
CURRSG  BSS 1   CURRENT SIGN IN NUMBER
        BSS 1
DYADIC  BSS 10  DYADIC HOLDING AREA
*
PC      BSS 2   PROGRAM COUNTER
PLMODE  BSS 1   PLOT MODE FLAG
GRPNT   BSS 2   GRAPHIC POINTER
XCURS   BSS 1   CRAPHICS CUSROR
YCURS   BSS 1
XINCR   BSS 2   LINE DRAWING INCR
YINCR   BSS 2
XLOW    BSS 1   LINE DRAWING ROUND REG
YLOW    BSS 1
GRCNT   BSS 1   GRAPHIC COUNTER
LENGHT  BSS 1   LINE LENGTH ESTIMATE
GRPAGE  BSS 1   GRAPHICS PAGE HIGH PNT
PVECT   BSS 2   PRINT VECTOR
POSTB   BSS 4   POSITION REGISTER SAVE
SAVEXY  BSS 2   REGISTER SAVE
INPDEV  BSS 1   INPUT DEVICE
AUTOIN  BSS 1   AUTO INCREMENT
AFILNO  BSS 1   CODE OF ACTIVE FILE
IVECT   BSS 2   INPUT VECTOR
ISAVXY  BSS 2   SAVE X,Y FOR INCHR
FORMCS  BSS 1   SAVED FORMATTING CODE
FORMCD  BSS 1   FORMATTYIONG CODE
FORMNO  BSS 1   FORMATTING NUMBER
FORMFL  BSS 1   FORMATTING FIELD LENGTH
FORMCT  BSS 1   FORMATTING COUNTER
OUTSAV  BSS 1   FILE NO FOR OUT
TEMP4   BSS 3
RNDVAL  BSS 5   RANDOM VARIABLE
*
        PAG
*
* R65 MONITOR VARIABLES
*
FILFLG  EQU $DA
FILDRV  EQU $DC
VIDPNT  EQU $E9
CURPOS  EQU $EE
FILNAM  EQU $0301
FILCYC  EQU $0311
FILSTP  EQU $0312
FILLOC  EQU $0313
FILSA   EQU $031A
FILEA   EQU $031C
FILNM1  EQU $0320
FILCY1  EQU $0330
FILSA1  EQU $0331
CURSEQ  EQU $0335
MAXSEQ  EQU $0336
FILBU1  EQU $0338
FIDRTB  EQU $0339
FIDVTB  EQU $0341
FIRCTB  EQU $0351
GRX     EQU $03AE
GRY     EQU $03AF
GRC     EQU $03B0
GRN     EQU $03B1
VFLAG   EQU $1780
SFLAG   EQU $1781
CHARREG EQU $1785
NUMLIN  EQU $1789
NUMCHR  EQU $178A
VAUTOP  EQU $178C
CNTL30  EQU $17F2
*
        ORG $0380
*
FISYTB  BSS 8           SYMBOLIC FLE NAMES
BUFFER  EQU $C000       BUFFER FOR RENUMBERING
*
* INTERFACE CONTROL
*
PORTB1  EQU $1400
EMUCOM  EQU $1430
MULTA   EQU $14E0       HARDWARE MULTIPLY
MULTB   EQU $14E1
MULTR   EQU $14E2
TAPAOF  EQU $14E5
TAPBOF  EQU $14E7
USPAD   EQU $1700
*
        TIT GRAPHIC BASIC- CONFIGURATION
        PAG
* START OF PROGRAM
*
        ORG $2000
*
* ENTRY VECTORS:
*
        JMP COLDST
        JMP WARMST
*
* BASIC USER RAM MEMORY
*
STRRAM  WRD $4FFF       START OF USER RAM
ENDRAM  WRD $BFFF       END OF USER AREA
*
*
* MONITOR SUBROUTINE VECTORS
****************************
* PART 1: MAIN EPROM ROUTINES (NO JMP)
*
GETKEY  EQU $E000
GETCHR  EQU $E003
GETLIN  EQU $E006
PRTCHR  EQU $E009
LOCRM   EQU $E00F
ICRTAL  EQU $E015
ICRTGR  EQU $E018
IGRAPH  EQU $E01E
PRTRSA  EQU $E836
*
PRTTTY  EQU $1EA0
GETTTY  EQU $1E5A
RDFILE  EQU $E815
WRFILE  EQU $E81B
DELETE  EQU $F00C
OPEN    EQU $F00F
CLOSE   EQU $F012
CLOSAL  EQU $F015
READCH  EQU $F018
WRITCH  EQU $F01B
*
EPLOT   EQU $C815
EPLOTCH EQU $C818
EBITMAP EQU $C81B
EDRAWX  EQU $C81E
EDRAWY  EQU $C821
EDRAWXY EQU $C824
*
* PART 2: OTHER EPROM SUBROUTINES
*
CLRGRA  JMP $E231
GETLIN0 JMP $E52E
TDIR    JMP $EDBE
DDIR    JMP $F009
ADAPT   JMP $F9A1
DIRECT  JMP $FD28
*
* ALPHAD: GO TO ALPHA DISPLAY, X SAVED
*
ALPHAD  LDA VFLAG
        AND =$40
        BEQ *+12
        TXA
        PHA
        JSR ICRTAL
        JSR LOCRM
        PLA
        TAX
        RTS
*
*
* BREAK TEST
*
BREAKT  LDA SFLAG
        BMI *+3
        RTS
        AND =$7F
        STA SFLAG
        SEC
        JMP END+3
*
        TIT GRAPHIC BASIC - STRING TABLES
        PAG
*
* TABLE OF COMMAND STRINGS
*
COMSTB  BYT 'FORMAT'+128
        BYT 'FOR'+128
        BYT 'NEXT'+128
        BYT 'DATA'+128
        BYT 'END'+128
        BYT 'INPUT'+128
        BYT 'DIM'+128
        BYT 'READ'+128
        BYT 'LET'+128
        BYT 'GOTO'+128
        BYT 'RUN'+128
        BYT 'IF'+128
        BYT 'RESTORE'+128
        BYT 'GOSUB'+128
        BYT 'RETURN'+128
        BYT 'REM'+128
        BYT 'STOP'+128
        BYT 'ON'+128
        BYT 'WAIT'+128
        BYT 'LOAD'+128
        BYT 'STORE'+128
        BYT 'REN'+128
        BYT 'DEF'+128
        BYT 'POKE'+128
        BYT 'OUT'+128
        BYT 'PRINT'+128
        BYT 'CONT'+128
        BYT 'LIST'+128
        BYT 'CLR'+128
        BYT 'MERGE'+128
        BYT 'SYS'+128
        BYT 'OPEN'+128
        BYT 'CLOSE'+128
        BYT 'GET'+128
        BYT 'NEW'+128
        BYT 'COPY'+128
        BYT 'FILES'+128
        BYT 'PLOT'+128
        BYT 'MOVE'+128
        BYT 'DRAW'+128
        BYT 'AUTO'+128
        BYT 'DIR'+128
        BYT 'SCALE'+128
        BYT 'DELETE'+128
        BYT 'PACK'+128
        BYT 'MAT'+128
        BYT $FF
        BYT $FF
*
* TABLE OF OTHER TOKENS
*
        BYT 'TAB('+128
        BYT 'TO'+128
        BYT 'FN'+128
        BYT 'SPC('+128
        BYT 'THEN'+128
        BYT 'NOT'+128
        BYT 'STEP'+128
        BYT '+'+128
        BYT '-'+128
        BYT '*'+128
        BYT '/'+128
        BYT '^'+128
        BYT 'AND'+128
        BYT 'OR'+128
        BYT '>'+128
        BYT '='+128
        BYT '<'+128
        BYT 'SGN'+128
        BYT 'INT'+128
        BYT 'ABS'+128
        BYT 'USR'+128
        BYT 'STA'+128
        BYT 'POS'+128
        BYT 'SQR'+128
        BYT 'RND'+128
        BYT 'LOG'+128
        BYT 'EXP'+128
        BYT 'COS'+128
        BYT 'SIN'+128
        BYT 'TAN'+128
        BYT 'ATN'+128
        BYT 'PEEK'+128
        BYT 'LEN'+128
        BYT 'STR$'+128
        BYT 'VAL'+128
        BYT 'ASC'+128
        BYT 'CHR$'+128
        BYT 'LEFT$'+128
        BYT 'RIGHT$'+128
        BYT 'MID$'+128
        BYT 'PI'+128
        BYT 0
*
*
* COMMAND VECTORS
*
STVECT  WRD FORMAT-1
        WRD FOR-1
        WRD NEXT-1
        WRD DATA-1
        WRD END-1
        WRD INPUT-1
        WRD DIM-1
        WRD READ-1
        WRD LET-1
        WRD GOTO-1
        WRD RUN-1
        WRD IF-1
        WRD RESTOR-1
        WRD GOSUB-1
        WRD RETURN-1
        WRD REMARK-1
        WRD STOP-1
        WRD ON-1
        WRD WAIT-1
        WRD NLOAD-1
        WRD STORE-1
        WRD RENUMB-1
        WRD DEF-1
        WRD POKE-1
        WRD OUT-1
        WRD PRINT-1
        WRD CONT-1
        WRD LIST-1
        WRD CLR-1
        WRD MERGE-1
        WRD SYS-1
        WRD OPENBS-1
        WRD CLOSEBS-1
        WRD GET-1
        WRD NEW-1
        WRD COPY-1
        WRD FILES-1
        WRD PLOT-1
        WRD MOVE-1
        WRD DRAW-1
        WRD AUTO-1
        WRD DIR-1
        WRD UNDEFS-1    SCALE
        WRD DELBAS-1
        WRD UNDEFS-1    PACK
        WRD UNDEFS-1    MAT
*
*
* ERROR STRINGS:
*
ERRSTR   BYT 'NO MATCHING FOR'+128
        BYT 'SYNTAX'+128
        BYT 'NO MATCHING GOSUB'+128
        BYT 'DATA'+128
        BYT 'QUANTITY'+128
        BYT 'OVERFLOW'+128
        BYT 'OUT OF MEMORY'+128
        BYT 'UNDEF STATEMENT'+128
        BYT 'UNDEF VARIABLE'+128
        BYT 'REDIMENSION'+128
        BYT 'SUBSCRIPT'+128
        BYT 'DIVISION BY ZERO'+128
        BYT 'ILLEGAL DIRECT'+128
        BYT 'TYPE MISSMATCH'+128
        BYT 'STRING TOO LONG'+128
        BYT 'FORMULA TOO COMPLEX'+128
        BYT 'CONTINUE'+128
        BYT 'UNDEF FUNCTION'+128
*
* MESSAGE STRINGS:
*
ERRORM  BYT ' ERROR',0
        BYT $D,$A,'READY',$D,$A,0
        BYT $D,$A,'BREAK',0
        BYT ' IN LINE',0
*
        TIT GRAPHIC BASIC - EDITOR
        PAG
*
* MKROOM: MAKE ROOM IN MEMORY
*****************************
* BEGINB AND ENDB DEFINE THE BLOCK. A MOVE IS
* DONE BETWEEN ENDB AND BTSTRG, IF ENOUGH
* FREE SPACE, INSERTION IS NOT DONE IN THIS
* SUBROUTINE. TEMP1 IS USED, ENDB MUST ALSO
* BE IN A,Y.
*
MKROOM  JSR TSROOM      ENOUGH EMPTY?
        STA STSPAC
        STY STSPAC+1
        SEC             COMPUTE SIZE TO TRANSF
        LDA BEGINB
        SBC TRANSP
        STA TEMP1       SAVE IN Y AND TEMP1
        TAY
        LDA BEGINB+1
        SBC TRANSP+1
        TAX             SAVE IN X
        INX
        TYA
        BEQ MKRM2       BRANCH IF SIZE LOW = 0
        LDA BEGINB      SUBTRACT SIZE LOW FROM
        SEC             BEGINB AND RESTORE
        SBC TEMP1
        STA BEGINB
        BCS *+5
        DEC BEGINB+1
        SEC
        LDA ENDB        SAME FOR ENDB
        SBC TEMP1
        STA ENDB
        BCS MKRM1+4
        DEC ENDB+1
        BCC MKRM1+4
*
MKRM1   LDA (BEGINB),Y  TRANSFER PARTIAL PAGE
        STA (ENDB),Y
        DEY
        BNE MKRM1
*
        LDA (BEGINB),Y  TRANSFER FULL PAGES
        STA (ENDB),Y
MKRM2   DEC BEGINB+1
        DEC ENDB+1
        DEX             COUNT FULL PAGES
        BNE MKRM1+4
        RTS
*
*
* TSROOM: TEST FREE ROOM IN MEMORY
**********************************
* INPUT IA A,Y. STRINGS ARE PACKED ONLY IF NOT
* ENOUGH FREE SPACE. ERROR IF STRINGS PACKED
* AND STILL A,Y >= BTSTRG. 12 BYTES ON STACK
* AND SUBROUTINE PKSTRG USED
*
TSROOM  CPY BTSTRG+1    IF A,Y < BTSTRG
        BCC TSROOM-1    THEN RETURN
        BNE *+4
        CMP BTSTRG
        BCC TSROOM-1
*
        PHA             ELSE PACK STRINGS
        LDX =9          SAVE A AND BLOCK AREA
        TYA             AND Y
        PHA
        LDA ENDB-1,X
        DEX
        BPL *-4
*
        JSR PKSTRG      PACK STRINGS
*
        LDY =$F7        RESTORE BLOCK AREA
        PLA             AND Y
        STA TRANSP+2,X
        INX
        BMI *-4
        PLA
        TAY
        PLA
*
        CPY BTSTRG+1    ERROR,IF STILL A,Y
        BCC *+8         >= BTSTRG
        BNE OUTMEM
        CMP BTSTRG
        BCS OUTMEM
        RTS
*
*
* TSSTK: TEST STACK ROOM
************************
* ERROR, IF NOT 2*A+$40 FREE BYTES ON STACK
*
TSSTK   ASL A
        ADC =$40
        BCS OUTMEM
        STA TEMP1
        TSX
        CPX TEMP1
        BCC OUTMEM
        RTS
*
*
OUTMEM  LDX =$3A        OUT OF MEMORY ERROR
*
*
* ERROR: PRINT ERROR MESSAGE
****************************
* SAVES LINE FOR CONT, GOES INTO COMMAND MODE
*
ERROR   LDA VFLAG       RESET INVERSE VIDEO
        AND =$67        AND CLEAR DISPLAY FLAG
        STA VFLAG
        LDA OUTDEV      CHECK OUTPUT DEVICE
        BEQ *+9         MUST BE VIDEO
        JSR RSTDEV
        LDA =0
        STA OUTDEV
*
        JSR CRLF
        JSR RSTO1
*
        LDA ERRSTR,X    PRINT ERROR MESSAGE
        PHA
        AND =$7F        MASK OFF BIT 7
        JSR OUTCHR
        INX
        PLA
        BPL *-11
        JSR SAVE        SAVE PC AND BASIC LINE
        LDA =<ERRORM
        LDY =>ERRORM
STOP2   JSR OUTSTR
        LDY LINE+1      FF MEANS NOT RUNNING
        INY
        BEQ WARMST
        JSR OUTLIN      PRINT LINE NO
*
*
* WARMST: WARM START AND COMMAND ENTRY
**************************************
*
WARMST  LDA =<(ERRORM+7)
        LDY =>(ERRORM+7)
        JSR OUTSTR
WARM1   JSR INLIN       INPUT LINE
        STX PC
        STY PC+1
        JSR FETCH
        BEQ WARMST      NEXT LINE IF EMPTY
        LDX =$FF        CLEAR RUN FLAG
        STX LINE+1
        BCC INSLIN      NUMBER >> INSERT LINE
        JSR ANALYZ
        LDA =0
        STA AUTOIN      CLEAR AUTO NUMBERING
        JMP EXCODE      NO NUMBER >> EXECUTE
*
*
* INSLIN: INSERT LINE
*********************
*
INSLIN  JSR INSL0
        JMP ADLNPN
*
INSL0   JSR FETCHI      FETCH LINE NUMBER
        JSR ANALYZ
        STY INPNT       INPUT BUFFER PNT SAVE
        JSR SEARLN
        BCC INSL1+14    SKIP, IF LINE NOT FOUND
*
        LDY =1          CLEAR EXISTING LINE
        LDA (TRANSP),Y
        STA ENDB+1
        LDA STVAR
        STA ENDB
        LDA TRANSP+1
        STA BEGINB+1
        LDA TRANSP
        DEY
        SBC (TRANSP),Y
        CLC
        ADC STVAR
        STA STVAR
        STA BEGINB
        LDA STVAR+1
        ADC =$FF
        STA STVAR+1
        SBC TRANSP+1
        TAX
        SEC
        LDA TRANSP
        SBC STVAR
        TAY
        BCS *+5
        INX
        DEC BEGINB+1
        CLC
        ADC ENDB
        BCC *+5
        DEC ENDB+1
        CLC
INSL1   LDA (ENDB),Y
        STA (BEGINB),Y
        INY
        BNE INSL1
        INC BEGINB+1
        INC ENDB+1
        DEX             COUNT FULL PAGES
        BNE INSL1
*
        LDA INBUFF
        BEQ INSLE       SKIP, IF LINE EMPTY
        LDA TPMEM
        LDY TPMEM+1
        STA BTSTRG      CLEAR EXISTING STRINGS
        STY BTSTRG+1
        LDA STVAR
        STA BEGINB
        ADC INPNT
        STA ENDB
        LDY STVAR+1
        STY BEGINB+1
        BCC *+3
        INY
        STY ENDB+1
        JSR MKROOM      MAKE ROOM FOR LINE
        LDA STSPAC
        LDY STSPAC+1
        STA STVAR       CLEAR VARIABLES
        STY STVAR+1
        LDY INPNT
        DEY
        LDA INBNUM,Y    INSERT CODE
        STA (TRANSP),Y
        DEY
        BPL *-6
INSLE   RTS
*
ADLNPN  JSR CLR1-3      CLEAR VAR ETC
        JSR ADLNP0      ADJUST LINE ADDRESSES
        LDA AUTOIN
        BNE *+5
        JMP WARM1
        CLC
        ADC INTEG
        LDY INTEG+1
        BCC *+3
        INY
        TAX
        TYA
        JMP AUTOIN2
*
*
* ADLNP0: ADJUST LINE ADDRESSES
*******************************
*
ADLNP0  LDA STPROG
        LDY STPROG+1
        STA TEMP1
        STY TEMP1+1
        CLC
        LDY =1
        LDA (TEMP1),Y
        BNE *+3         END OF PROGRAM?
        RTS
        LDY =4
        INY
        LDA (TEMP1),Y   SEARCH EOL
        BNE *-3
        INY
        TYA
        ADC TEMP1
        TAX
        LDY =0
        STA (TEMP1),Y
        LDA TEMP1+1
        ADC =0
        INY
        STA (TEMP1),Y
        STX TEMP1
        STA TEMP1+1
        BNE ADLNP0+9    ALLWAYS TAKEN
*
*
* INLIN: INPUT LINE FROM KEYBOARD
*********************************
* INPUT MUST BE FROM DEVICE 0, R65 LINE EDITOR
* IS USED, GETLIN AND NUMCHR ARE MONITOR LABELS
* IF ENTERED WITH CURPOS#0, FIRST PART SAVED
*
INLIN   LDX CURPOS
        JSR GETLIN0
        LDX =0
        LDA (VIDPNT),Y
        AND =$7F
        STA INBUFF,X
        INX
        INY
        CPY NUMCHR
        BCC *-11
        BEQ *-13
*
        DEX
        BMI *+8         EMPTY LINE
        LDA INBUFF,X
        CMP =$20        INGNORE ENDING BLANKS
        BEQ *-7
        LDY =0
        STY INBUFF+1,X
        LDX =<(INBUFF-1)
*
*
* CRLF: EXECUTE A CRLF (X,Y SAVED)
**********************************
*
CRLF    LDA =$D
        JSR OUTCHR
        LDA =$A
        JSR OUTCHR
PADOUT  LDA OUTDEV
        BEQ *+18
        TXA
        PHA
        LDX NUMPAD
        BEQ *+10
        LDA =0
        JSR OUTCHR
        DEX
        BNE *-4
        PLA
        TAX
        RTS
*
*
*
* ANALYZ: ANALYZE INPUT
***********************
*
ANALYZ  LDX PC
        LDY =4
        STY TEMP2       FLAG FOR ",DATA,REM
        LDA 0,X         GET CHAR FROM INBUFF
        JSR ADAPT
*
        CMP =$20
        BEQ ANA20       INSERT BLANK AS IT IS
        STA CHRSAV
        CMP ='"'
        BEQ ANA25+8     STRING
        BIT TEMP2
        BVS ANA20       IF ",DATA,REM
        CMP ='?'
        BNE *+6
        LDA =$99        CODE FOR PRINT
        BNE ANA20
        CMP =$30        NUMBER?
        BCC *+6
        CMP =$3C
        BCC ANA20
*
        STY DYADIC+8
        LDY =<COMSTB
        STY TEMP4
        LDY =>COMSTB
        STY TEMP4+1
        LDY =0
        STY INPNT
        DEY
        STX PC
        DEX
ANA10   INY
        INX
        LDA 0,X
        JSR ADAPT
        SEC
        SBC (TEMP4),Y   COMPARE WITH TOKEN
        BEQ ANA10
        CMP =$80
        BNE ANA30       END MATCH
        ORA INPNT
        LDY DYADIC+8
*
ANA20   INX
        INY
        STA INBUFF-5,Y
        LDA INBUFF-5,Y
        BEQ ANA35       END MARK
        SEC
        SBC =':'
        BEQ *+6
        CMP =$49        A=$83: DATA
        BNE *+4
        STA TEMP2
        SEC
        SBC =$55        A=$8F: REM
        BNE ANALYZ+6
        STA CHRSAV
ANA25   LDA 0,X         GET WITHOUT ADAPT
        BEQ ANA20
        CMP CHRSAV
        BEQ ANA20
        INY
        STA INBUFF-5,Y
        INX
        BNE ANA25       ALLWAYS TAKEN
*
ANA30   LDX PC
        INC INPNT
        DEY
        INY
        LDA (TEMP4),Y
        BPL *-3
        INY
        LDA (TEMP4),Y
        BNE ANA35+8
        LDA 0,X
        JSR ADAPT
        JMP ANA20-2     NOT FOUND IN TABLE
*
ANA35   STA INBUFF-3,Y
        LDA =<INBUFF-1
        STA PC
        RTS
*
        CLC
        TYA
        ADC TEMP4
        STA TEMP4
        BCC *+4
        INC TEMP4+1
        LDY =0
        BEQ ANA10+2     ALLWAYS TAKEN
*
*
* SEARCH LINE: SEARCH BASIC LINE
********************************
* INPUT IS LINE NO IN INTGER, OUTPUT IS ADDRESS
* IN TRANSP, C=1IFLINE FOUND
*
SEARLN  LDA STPROG
        LDX STPROG+1
*
        LDY =1
        STA TRANSP
        STX TRANSP+1
        LDA (TRANSP),Y
        BEQ SEARL9-1    END OF PROGRAM
        INY
        INY
        LDA INTEG+1
        CMP (TRANSP),Y
        BCC SEARL9
        BEQ *+5
        DEY
        BNE SEARL5
        LDA INTEG
        DEY
        CMP (TRANSP),Y
        BCC SEARL9
        BEQ SEARL9
SEARL5  DEY
        LDA (TRANSP),Y  GET ADDRESS OF NEXT LINE
        TAX
        DEY
        LDA (TRANSP),Y
        BCS SEARLN+4
        CLC
SEARL9  RTS
*
        TIT GRAPHIC BASIC - MAIN COMMANDS
        PAG
*
* NEW: COMMAND ROUTINE
**********************
*
NEW     BNE *-3         RTS, IF NOT EOLD
        LDA =0
        TAY
        STA (STPROG),Y  END OF PROGRAM MARK
        INY
        STA (STPROG),Y
        LDA STPROG
        ADC =2
        STA STVAR       SET START OF VARIABLES
        LDA STPROG+1
        ADC =0
        STA STVAR+1
*
        JSR SETPC
*
CLR1    LDA TPMEM       CLEAR STRINGS
        LDY TPMEM+1
        STA BTSTRG
        STY BTSTRG+1
*
        JSR RESGP       RESETGP
*
        LDA STVAR       CLEAR VARIABLES
        LDY STVAR+1
        STA EOVAR
        STY EOVAR+1
        STA STSPAC
        STY STSPAC+1
        JSR RESTOR+19   SET DATA POINTER
*
SAVE    LDX =<STRST     RESET STRING STACK
        STX STRSTP
        PLA             RESET MAIN STACK
        STA $1FD
        PLA
        STA $1FE
        LDX =$FC
        TXS
        LDA =0          CONTINUE NOT LEGAL
        STA PNTSAV+1
        STA FLAG1
        RTS
*
*
* SETPC: SET PC TO STPROG-1
***************************
*
SETPC   CLC
        LDA STPROG
        ADC =$FF
        STA PC
        LDA STPROG+1
        ADC =$FF
        STA PC+1
        RTS
*
*
* LIST: COMMAND ROUTINE
***********************
*
LIST    CMP ='#'
        BNE *+5
        JSR SETDEV
        JSR FETCH1
        BCC *+8         BRANCH, IF NUMBER
        BEQ *+6         BRANCH, IF EOL
        CMP =$B8        CODE FOR -
        BNE *-19        RTS, IF NOT
*
        JSR FETCHI      GET LINE NO
        JSR SEARLN
        JSR FETCH1
        BEQ *+14
        CMP =$B8        CODE FOR -
        BNE LIST-1
        JSR FETCH
        JSR FETCHI      GETS SECOND LINE NO
        BNE LIST-1      RTS, IF NOT
*
        PLA
        PLA
        LDA INTEG
        ORA INTEG+1
        BNE LIST2
        LDA =$FF
        STA INTEG       SET LAST LINE TO FFFF
        STA INTEG+1
*
LIST2   LDY =1
        STY TEMP2
        LDA (TRANSP),Y
        BEQ LIST4       END OF PROGRAM
        JSR BREAKT      BREAK TEST
        JSR CRLF
        INY
        LDA (TRANSP),Y
        TAX
        INY
        LDA (TRANSP),Y
        CMP INTEG+1
        BNE *+6
        CPX INTEG
        BEQ *+4
        BCS LIST4
        STY TEMP3
        JSR OUTINT
*
        LDA =' '
LIST3   LDY TEMP3
        AND =$7F
        JSR OUTCHR
