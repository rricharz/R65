* 18/11/81,25/10/23
**********************************
* R65 COMPUTER SYSTEM: ASSEMBLER *
**********************************
*
* VERSION 8.0   WITH UNLIMITED NO OF LABELS
*               ADDITIONAL PSEUDO OP'S
*               NO RPINTING IN FIRST PASS
*               SOURCE MAY BE IN SEVERAL FILES
*               ONLY 'END' TERMINATES A PASS
* ASSEMBLER FOR R65 COMPUTER SYSTEM
* CC RRICHARZ, RBAUMANN 1978-1981
*       - 32 k MEMORY
*       - VIDEO INTERFACE WITH 4k VIDEO MEMORY
*       - HARDCOPY OUTPUT
*       - TAPE AND OR DISK DRIVE(S)
*
* INPUT FROM 2 DEVICES
*       - COMMAND INPUT FROM KEYBOARD
*       - SOURCE CODE INPUT FROM TAPE OR DISK
*
* OUTPUT TO 3 DEVICES
*       - MESSAGES AND LISTING TO VIDEO DISPLAY
*       - ERROR TABLE, CROSS REFERENCE MAP AND
*         LISTINGS TO HARD COPY
*       - OBJECT FILE(S) TO TAPE OR DISK
*
* COMMANDS (A* IS PRINTED IN COMMAND MODE)
*       F       FIRST PASS
*       S       SECOND PASS
*       C       CONTINUE SAME PASS
*       R       REFERENCE MAP
*       <CR>    EXIT ASSEMBLER
*       <ESC>   EXIT ASSEMBLER
*
*
* SOURCE LINE FORMAT [] MEANS OPTIONAL
* [LABEL] OPCODE [OPERAND] [COMMENT]
* OR *[COMMENT]
*
* PSEUDO OPCODES (ASSEMBLER DIRECTIVES)
*
*       - EQU "EXPRESSION"      ASSIGN LABEL
*       - ORG "EXPRESSION"      ASSIGN PC
*       - BSS "EXPRESSION"      RESERVE BYTES
*       - BYT "EXPR","EXPR",..  ASSIGN BYTES
*               "EXPR" CAN BE 'STRING'
*       - WRD "EXPR","EXPR",..  ASSIGN WORDS
*       - PAG                   NEW PAGE
*       - TIT "MAX 32 CHARS"    ASSIGN TITLE
*       - END                   END OF SOURCE
*       - NPR                   NO PRINTING
*       - PRT                   PRINTING
*
* ERROR CODES: (FULL ERROR ANALYSIS IN FIRST
* PASS INCLUDING FORWARD BRANCHES AND
* UNRESOLVED REFERENCES)
* FOR ERROR CODES <30 SEE SYSTEM ERRORS
*
* ERROR 31  CLOSING ) EXPECTED IN EXPRESSION
* ERROR 32  SYNTAX ERROR IN LABEL
* ERROR 33  HEX CHAR EXPECTED AFTER $
* ERROR 34  LABEL TABLE OVERFLOW
* ERROR 35  LOGICAL CHAR EXPECTED AFTER #
* ERROR 36  EXPRESSION NOT RESOLVED (PASS 2)
* ERROR 37  SYNTAX ERROR IN OPCODE
* ERROR 38  MNEMONIC OR ADDRESSING ILLEGAL
* ERROR 39  ILLEGAL ADDRESSING MODE
* ERROR 40  SYNTAX ERROR IN OPERAND
* ERROR 41  ABSOLUTE ADDRESS ILLEGAL
* ERROR 42  MORE THAN 1 UNRESOLVED LABEL IN
*               FORWARD BRANCH
* ERROR 43  BRANCH EXCEEDS BOUNDS
* ERROR 44  FORWARD BRANCH TO THIS LABEL
*               EXCEEDS BOUNDS
* ERROR 45  DOUBLE LABELDEFINITION
* ERROR 46  MISSMATCH IN SECOND PASS
* ERROR 47  LABEL MISSING IN EQU
* ERROR 48  OPERAND OF BYT TOO LONG
* ERROR 49  EXPRESSION MUST BE RESOLVED
* ERROR 50  LINE TOO LONG
* ERROR 51  CHAR FOLLOWS LOGICAL END OF OPERAND
* ERROR 52  TOO MANY UNRESOLVED BRANCHES
*               NOT INSERTED INTO TEST TABLE
*
        TIT R65 ASSEMBLER V8.0
*
        ORG 0
*
* PAGE ZERO ASSEMBLER VARIABLES
*******************************
*
* TEMPORARY BUFFERS
*
INBUFF  BSS 48  LINE BUFFER
LABEL   BSS 7   LABEL SHIFT REGISTER
TEMP1   BSS 1   TEMPORARY REGISTER
NUMBYT  BSS 1   NUMBER OF BYTES
RESOLV  BSS 3   UNRESOLVED COUNTER
OBJECT  BSS 32  OBJECT CODE LINE BUFFER
VALUE   BSS 2   VALUE OF EXPRESSION
OPCODE  BSS 2   OPCODE SAVE REGISTER
ADMODE  BSS 1   ADDRESSING MODE
INDEX1  BSS 1   MNEMONIC TABLE INDEX
INDEX2  BSS 1   CODE OFFSET INDEX
DEFLB   BSS 1   LABEL DEFINITION FLAG
INBFPN  BSS 1   END OF INPUT POINTER
BRANTB  BSS 48  FORWARD BRANCH TABLE
BASE    BSS 2   REFERENCE TABLE POINTER
LABPNT  BSS 2   LABEL POINTER
LABPN1  BSS 2   SECOND LABEL POINTER
INPFIL  BSS 1   INPUT FILE NUMBER
SAVPNT  BSS 2   SAVED FILE PAR POINTER
*
* PRESET TO 0 IN BOTH PASSES
*
PCOLD   BSS 2   OLD PROGRAM COUNTER
PCNEW   BSS 2   NEW PROGRAMM COUNTER
LINCNT  BSS 2   LINE COUNTER
PAGECN  BSS 1   PAGE COUNTER
OUTREC  BSS 1   OUTPUT RECORD COUNTER
BRANTC  BSS 1   TABLE POINTER
FILCNT  BSS 1   INPUT FILE COUNTER
NUMERR  BSS 1   NUMBER OF ERRORS
*
* PRESET IN BOTH PASSES
*
PASSFL  BSS 1   PASS FLAG
PRTFLG  BSS 1   PRINT FLAG
PAGELN  BSS 1   PAGE LINE COUNTER
OBPNT   BSS 2   OBJECT BUFFER POINTER
OBADDR  BSS 2   OBJECT BASE ADDRESS
*
* PRESET ONLY IN FIRST BASS
*
LABCNT  BSS 2   LABEL COUNTER
TITLE   BSS 32  TITLE OF PROGRAM
*
*
*
* MONITOR LABELS:
*****************
*
FILFLG  EQU $DA         FILE ENTRY FLAG
FILDRV  EQU $DC         FILE DRIVE
CURPOS  EQU $EE         CURSOR HOR. POSITION
INL     EQU $F8         INPUT BUFFER MONITOR
*
FILNAM  EQU $0301       FILE NAME
FILSTP  EQU $0312       FILE SUBTYPE
FILLOC  EQU $0313       FILE LOCATION/SECTOR
FILSIZ  EQU $0315       FILE SIZE
FILSA   EQU $031A       START ADDRESS
FILEA   EQU $031C       END ADDRESS
FILNM1  EQU $0320       SECOND FILE NAME
FILSA1  EQU $0331       SECOND START ADDRESS
FIRCTB  EQU $0351       ROCORD COUNTER
*
VFLAG   EQU $1780       VIDEO FLAG REGISTER
SFLAG   EQU $1781       SYSTEM FLAG REGISTER
NUMLIN  EQU $1789       VIDEO LINES
VMON    EQU $17D5       ADDRESS OF MONITOR START
MNEMR   EQU $E7C0       MNEMONIC TABLE
MNEML   EQU $E780
DISMOD  EQU $E722       ADDRESSING MODE TABLE 1
MODE2   EQU $E766       ADDRESSING MODE TABLE
CLOSAL  EQU $F015
*
EMUCOM  EQU $1430       SIMULATOR COMMAND
*
        PAG
*
* START OF PROGRAM ENTRY VECTORS
********************************
*
        ORG $2000
*
        JMP COLDST      COLD START ENTRY
        JMP WARMST      WARM START ENTRY
*
*
* ASSEMBLER BUFFERS AND CONSTANTS:
**********************************
*
OBSTR   WRD $5000       START OF OBJECT BUFFER
OBEND   WRD $8FFE       END OF OBJECT BUFFER -1
*
SAVNAM  WRD $9000       INPUT FILE NAME BUFFER
*
LABSTR  WRD $3000       START OF LABEL TABLE
LABEND  WRD $4FF0       END OF LABEL TABLE
*
TABLE   BYT 50          PRINTED LINES/PAGE
        BYT 69          TOTAL LINES/PAGE
        BYT $0C         FORM FEED CODE
        BYT 0           NO OF ADD. PAD CHARS
        BYT 65          POSITION OF PAPER MARK
        BYT $CE         START POSITION ON PAPER
*
* SUBROUTINE VECTORS
********************
*
GETKEY  EQU $E000
GETCHR  EQU $E003
GETLIN  EQU $E006
PRTCHR  EQU $E009
VAUTOP  EQU $E00C
ENDLIN  EQU $E024
PRTINF  EQU $E027
PRTBYT  EQU $E02D
PRTAX   EQU $E030
WRFILA  JMP WRFILE+12   SPECIAL ENTRY!
WRFILE  EQU $EB14
OPEN    EQU $F00F
CLOSE   EQU $F012
READCH  EQU $F018
PRTDAT  EQU $F80F
GETNAM  EQU $F815
HARGUM  JMP $FCF2
PACKTS  EQU $F919
*
*
* SUBROUTINE SRLAB: SEARCH LABEL
********************************
* SEARCH IN LABTB, RETURN C0 IF NOT
* FOUND, ELSE LBAPNT=ADDRESS OF LABEL
* USED: TEMP1,A; SAVED: X,Y; OUPUT: A,Z
*
SRLAB   STY TEMP1
        LDA LABSTR      SET TO START OF TABLE
        LDY LABSTR+1
*
SRLAB1  STA LABPNT
        STY LABPNT+1
        CMP LABCNT      COMPARE TABLE END
        TYA
        SBC LABCNT+1
        BCS SRLAB4      SKIP, IF END OF TABLE
        LDY =4
SRLAB2  LDA LABEL,Y     COMPARE NOW
        CMP (LABPNT),Y
        BNE SRLAB3
        DEY
        BPL SRLAB2      LOOP UNTIL DONE
        SEC             LABEL FOUND
        LDY TEMP1
        RTS
*
SRLAB3  LDA LABPNT      DIFFERENCE FOUND
        LDY LABPNT+1
        CLC
        ADC =8          NEXT ONE
        BCC SRLAB1
        INY
        BCS SRLAB1      ALLWAYS TAKEN
*
SRLAB4  CLC             NOT FOUND
        LDY TEMP1
        RTS
*
*
* SUBROUTINE STLABN: STORE LABEL NAME
*************************************
* STORE IN LABTAB, ERROR IF TABLE OVERFLOW
* NO DUPLICATE LABEL TEST, LABTB7 SET TO 0
* USED: A,Y; SAVED: X; INPUT: LABCNT;
* OUTPUT: LABCNT, CALLED: ERROR 34
*
STLABN  LDA LABCNT      COMPUTE LABPNT
        LDY LABCNT+1
        CLC
        ADC =8
        BCC *+3
        INY
        PHA
        CMP LABEND      TEST TABLE OVERFLOW
        TYA
        SBC LABEND+1
        PLA
        BCC STLAB1      SKIP, IF NOT FULL
*
        LDA =$34        ERROR 34: TOO MANY
        JSR ERROR       ERRORS
        LDA LABCNT
        LDY LABCNT+1
*
STLAB1  STA LABCNT
        STY LABCNT+1
        SEC
        SBC =8
        BCS *+3
        DEY
        STA LABPNT
        STY LABPNT+1
*
        LDY =4
STLAB2  LDA LABEL,Y
        STA (LABPNT),Y
        DEY
        BPL STLAB2
*
        LDA =0          CLEAR BYTE 7
        LDY =7
        STA (LABPNT),Y
        RTS
*
*  SUBROUTINE RDLAB: READ LABEL FROM BUFFER
*******************************************
* READ 1-7 CHARS, SHIFT INTO 5 BYTES, STORE
* IN LABEL, TERMINATORS ARE NOT LETTERS OR
* NUMBERS. USED: A,X,Y,TEMP1; CALLED: ERROR;
* INPUT:X; OUTPUT: LABEL,X
*
RDLAB   LDY =8          CHAR COUNTER
        LDA =6
        STA TEMP1       TEMP1 = BIT COUNTER
        LDA INBUFF,X    GET ONE CHAR
        CMP =$30        IF NOT LEGAL CODE
        BCC *+6         USE SAME NEXT LOOP
        CMP =$5B        IF LEGAL
        BCC *+5         USE THIS CHAR
        DEX             USE SAME CHAR AGAIN
        LDA =0          USE 0 FILLER
        DEY             COUNT CHAR
        BEQ RDLAB2      LAST CHAR
        ASL A
        ASL A
        CPY =6          IF X<6
        BCC RDLAB1      USE 6 BITS
        DEC TEMP1
        ASL A           TAKE ONLY 5 BITS
        BCC RDLAB1      LEGAL 5 BIT CODE
        LDA =0          ELSE USE FILLER
        DEX
RDLAB1  ASL A           SHIFT INTO LABEL
        ROL LABEL+4
        ROL LABEL+3
        ROL LABEL+2
        ROL LABEL+1
        ROL LABEL
        DEC TEMP1
        BNE RDLAB1      LOOP FOR BITS
        INX
        JMP RDLAB+2
RDLAB2  CMP =0
        BNE *+8         MORE THAN 6 CHARACTERS
        LDA LABEL
        BEQ *+4         FIRST CHAR NOT LETTER
        INX
        RTS
        LDA =$32
        JMP ERROR       RETURN AFTER ERROR
*
*
* SUBROUTINE RDBL: READ BLANKS
******************************
* USED: A; SAVED:Y; INPUT:X; OUTPUT:X
*
RDBL    LDA INBUFF,X
        INX
        CMP =$20
        BEQ RDBL
        DEX
        RTS
*
*
* SUBROUTINE EXPRESSION
***********************
* READ EXPRESSION FROM INBUFF,X.  COMPUTE
* VALUE AND RESOLV-FLAG (GIVES NUMBER OF
* UNRESOLVED REFERENCES USED
* SYNTAX:
* EXPRESSION: FUNCTION [+-FUNCTION]
* FUNCTION:   <ARGUMENT OR >ARGUMENT OR
*               ARGUMENT
* ARGUMENT:   'CHAR['] OR $HEX OR #BINARY OR
*               DECIMAL OR * OR LABEL
* USED: A,X,Y; INPUT:X; OUTPUT: X,VALUE
*               RESOLVE,RESOLV+1;
*               CALLED: FUNC,ERROR
*
EXPRES  LDA =0          SET COUNTER FOR
        STA RESOLV      UNRESOLVED LABELS
        JSR FUNC
EXP1    PHA             PUSH RESULT ON STACK
        LDA VALUE
        PHA
        LDA INBUFF,X    GET NEXT CHAR
        CMP =$2B        IF +
        BNE MINUS
        INX
        JSR FUNC        GET NEXT FUNCTION
        PLA             AND ADD TO SAVED VALUE
        CLC
        ADC VALUE
        STA VALUE
        PLA
        ADC VALUE+1
        STA VALUE+1
        JMP EXP1
MINUS   CMP =$2D        IF -
        BNE EXP2
        INX
        JSR FUNC        GET NEXT FUNCTION
        PLA             AND SUBTRACT FROM SAVED
        SEC
        SBC VALUE
        STA VALUE
        PLA
        SBC VALUE+1
        STA VALUE+1
        JMP EXP1
EXP2    PLA             GET SAVED VALUE BACK
        PLA
        RTS
*
*
* SUBROUTINE FUNCTION
*********************
* CALLED: ARG
*
FUNC    LDA INBUFF,X
        CMP =$3C        IF < (LOW BYTE)
        BNE *+11
        INX
        JSR ARG         GET ARGUMENT
FUNC1   LDA =0          AND SET HIGH BYTE TO 0
        STA VALUE+1
        RTS
*
        CMP =$3E        IF > (HIGH BYTE)
        BNE ARG
        INX
        JSR ARG         GET ARGUMENT
        STA VALUE       STORE HIGH BYTE IN
        JMP FUNC1       LOW BYTE AND CLEAR HIGH
*
*
* SUBROUTINE ARGUMENT
*********************
* CALLED: ERROR,PACKTS,TSTBIN,DIGTST,RDLAB,
* SRLAB,STLABN,SETREF
*
ARG     LDA INBUFF,X
        CMP =$28        IF (
        BNE ARG05
        INX
        JSR EXPRES+4    GET EXPRESSION
        LDA INBUFF,X    MUST BE )
        CMP =$29
        BEQ *+7
        LDA =$31
        JSR ERROR
        INX
        LDA VALUE+1
        RTS
*
ARG05   CMP =$27        IF '
        BNE ARG10
        INX
        LDA INBUFF,X    GET CHAR
        STA VALUE
        INX
        LDA INBUFF,X    IGNORE SECOND '
        CMP =$27
        BNE *+3
        INX
        LDA =0
        STA VALUE+1
        RTS
*
ARG10   CMP =$24        IF $ (HEX)
        BNE ARG20
        INX
        LDA =0
        STA INL
        STA INL+1
        LDA INBUFF,X
        JSR PACKTS+2
        BEQ *+7
        LDA =$33
        JSR ERROR
        INX
        LDA INBUFF,X
        JSR PACKTS+2
        BEQ *-6
        LDA INL
        STA VALUE
        LDA INL+1
        STA VALUE+1
        RTS
*
ARG20   CMP =$23        IF # (BINARY)
        BNE ARG30
        INX             READ BINARY NUMBER
        LDA =0
        STA VALUE
        STA VALUE+1
        JSR TSTBIN
        BEQ *+7
        LDA =$35
        JSR ERROR
        INX
        JSR TSTBIN
        BEQ *-4
        LDA VALUE+1
        RTS
*
ARG30   JSR DIGTST      IF DECIMAL NUMBER
        BCS ARG40
        LDA =0          READ DECIMAL NUMBER
        STA VALUE
        STA VALUE+1
        JSR DIGTST
        INX
        JSR DIGTST
        BCC *-4
        LDA VALUE+1
        RTS
*
ARG40   CMP =$2A        IF *
        BNE ARG50
        INX             GET PROGRAM COUNTER
        LDA PCOLD
        STA VALUE
        LDA PCOLD+1
        STA VALUE+1
        RTS
*
ARG50   JSR RDLAB       MUST BE LABEL
        JSR SRLAB
        BCC ARG52       BRANCH IF UNKNOWN
        JSR SETREF      INSERT INTO REF TABLE
        JSR DEFIN       IF DEFINED
        BEQ ARG51
        LDA PASSFL
        BEQ *+10
        LDY =7
        LDA (LABPNT),Y  GET RFLAG
        BMI *+4
        INC RESOLV
        LDY =5
        LDA (LABPNT),Y  GET VALUE
        STA VALUE
        INY
        LDA (LABPNT),Y
        STA VALUE+1
        RTS
ARG51   INC RESOLV      COUNT UNRESOLVED REF
        LDA LABPNT
        STA RESOLV+1
        LDA LABPNT+1
        STA RESOLV+2    SAVE LABEL NUMBER
        LDA PASSFL
        BEQ *+7
        LDA =$36
        JSR ERROR
        LDA =0
        STA VALUE       RETURN VALUE = 0
        STA VALUE+1
        RTS
ARG52   JSR STLABN      STORE LABEL NAME
        LDA PASSFL
        BEQ *+7
        LDA =$36
        JSR ERROR
        LDA =$FF        SET TO UNRESOLVED
        LDY =5
        STA (LABPNT),Y
        INY
        STA (LABPNT),Y
        JSR SETREF
        JMP ARG51
*
*
* SUBROUTINE TSTBIN: GET AND TEST BINARY NUMBER
***********************************************
*
TSTBIN  LDA INBUFF,X
        CMP =$30
        CLC
        BEQ *+7
        CMP =$31
        BNE *+9
        SEC
        ROL VALUE
        ROL VALUE+1
        LDA =0          SET ZERO FLAG
        RTS
*
*
* SUBROUTINE DIGTST: TEST AND GET DECIMAL
*****************************************
*
DIGTST  LDA INBUFF,X
        CMP =$30
        BCC *+6
        CMP =$3A
        BCC *+4
        SEC             C=1 >> NOT DECIMAL
        RTS
*
        ASL VALUE       MULTIPLY VALUE BY 10
        ROL VALUE+1
        LDA VALUE       SAVE 2*VALUE
        STA INL
        LDA VALUE+1
        STA INL+1
        ASL VALUE
        ROL VALUE+1
        ASL VALUE
        ROL VALUE+1     8*VALUE
        LDA VALUE
        CLC
        ADC INL
        STA VALUE
        LDA VALUE+1
        ADC INL+1
        STA VALUE+1     10*VALUE
        LDA INBUFF,X
        AND =$0F        CONVERT TO BCD
        CLC
        ADC VALUE       ADD TO 10*VALUE
        STA VALUE
        BCC *+4
        INC VALUE+1
        CLC             C=0 >> DECIMAL
        RTS
*
*
* SUBROUTINE DEFIN
******************
* RETURN Z=1 IF LABEL UNDEFINED
* INPUT: LABEL IN LABPNT
*
DEFIN   LDY =5
        LDA (LABPNT),Y
        INY
        AND (LABPNT),Y
        CMP =$FF
        RTS
*
*
* SUBROUTINE RDOPC: READ OPCODE FROM INBUFF
*******************************************
* PACK IN OPCODE WITH SAME FORMAT AS DISASSEM-
* BLER (5BIT/CHAR, OFFSET=$3F, LEFT SHIFTED 1)
* USED: A,X,Y,TEMP1; INPUT: X; OUTPUT; X,
* OPCODE; CALLED: ERROR
*
RDOPC   LDA =3
        STA TEMP1       CHAR COUNTER
RDOPC1  LDA INBUFF,X    GET A CHAR
        CMP =$41        TEST FOR LETTER
        BCC ERR7
        CMP =$5B
        BCC *+13
ERR7    LDY =0
        STY OPCODE
        STY OPCODE+1
        LDA =$37
        JMP ERROR
*
        INX
        SEC
        SBC =$3F        SUBTRACT OFFSET
        ASL A
        ASL A
        ASL A
        LDY =5          BIT COUNTER
RDOPC2  ASL A
        ROL OPCODE+1
        ROL OPCODE
        DEY
        BNE RDOPC2
        DEC TEMP1       NEXT CHAR
        BNE RDOPC1
        ASL OPCODE+1
        ROL OPCODE
        LDA INBUFF,X    TEST NEXT CHAR
        INX
        CMP =$20        MUST BE BLANK
        BEQ *+5
        JSR ERR7+6
        RTS
*
*
* SUBROUTINE SROPC: SEARCH OPCODE IN TABLE
******************************************
* USE OPCODE AND ADDRESSING MODE FOR TEST
*
SROPC   LDX =$41        POINTER TO MNEMONIC TB
        DEX
        BNE *+14
        LDA =$38
        JSR ERROR
        LDA =0
        STA OBJECT
        JMP ERR10+5     ASSUME ABS AND OPCODE=0
*                       IF NOT FOUND
        LDA OPCODE+1
        CMP MNEMR-1,X
        BNE SROPC+2
        LDA OPCODE
        CMP MNEML-1,X
        BNE SROPC+2
        DEX
        STX INDEX1
        TXA
        ASL A
        ASL A
        ASL A
        STA INDEX2
        BCS SROP30
SROP20  JSR TSTADM      ITS XXXXX000 INST
        BEQ *+7
ERR9    LDA =$39
        JSR ERROR
        RTS
SROP30  ASL INDEX2
        BCS SROP50
        BPL SROP40
        LDA INDEX2      ITS 1XXX1010 INST
        ORA =$8A        COMPUTE OPCODE
        BNE SROP20
*
SROP40  ASL INDEX2      ITS XXXYY100 INST
        LDY =3
        TYA
        SEC
        ROL A
        ASL A
        ASL A
        ORA INDEX2
        JSR TSTADM
        BNE *+3
        RTS             RETURN, IF FOUND
        DEY             TRY AGAIN
        BPL SROP40+4
        LDX INDEX1      IF NOT FOUND, SEARCH
        INX             CODE AGAIN (DOUBLE
        JMP SROPC+2     CODES IN TABLE!)
*
SROP50  ASL INDEX2
        BCS SROP60      IF XXXYYY10 INST
        LDY =7
        TYA
        SEC
        ROL A
        ASL A
        ORA INDEX2
        JSR TSTADM      TEST ADDRESSING
        BNE *+3
        RTS             RETURN, IF FOUND
        DEY             TRY NEXT Y
        BPL SROP50+6
        JMP ERR9
*
SROP60  LDY =7
        TYA
        ASL A
        SEC
        ROL A
        ORA INDEX2
        JSR TSTADM
        BNE *+3
        RTS             RETURN, IF FOUND
        DEY
        BPL SROP60+2
        JMP ERR9
*
*
* SUBROUTINE TSTADM: TEST ADDRESSING MODE
*****************************************
* ADDRESSING MODE CAN BE CHANGED IF NEEDED
*
TSTADM  STA OBJECT      SAVE OPCODE
        LSR A           COMPUTE ADDRESSING MODE
        BCC *+7         FOR THIS CODE
        LSR A
        AND =7
        ORA =$80
        LSR A
        TAX
        LDA DISMOD,X    LOAD MODE FROM TABLE
        BCS *+6
        LSR A
        LSR A
        LSR A
        LSR A
        AND =$0F        COMPUTE MODE IN A
        TAX             AND SAVE IN X
        CMP =$0D                IF RELATIVE
        BNE TSTAD1
        LDA ADMODE      CONVERT IT
        CMP =2          CAN BE ZERO PAGE
        BEQ *+6
        CMP =3          CAN BE ABSOLUTE
        BNE *+5
        STX ADMODE
        RTS
*
TSTAD1  LDA ADMODE
        CMP =2          ZERO PAGE
        BNE TSTAD3
        LDA OBJECT
        CMP =$4C        IF JMP
        BEQ *+6
        CMP =$20        OR JSR
        BNE TSTAD2
        LDA =3          SET TO ABSOLUTE
        STA ADMODE
TSTAD2  CPX ADMODE      TEST NOW
        RTS
*
TSTAD3  CMP =$0C        ZERO PAGE,Y
        BNE TSTAD2
        LDA OBJECT
        AND =$0F
        CMP =$09
        BEQ TSTAD2
        LDA =$A         CONVERT TO ABS,Y
        JMP TSTAD2-2    IF CODE =X9
*
*
* SUBROUTINE OPER: INTERPRET OPERAND
************************************
* USED: A,X,Y,TEMP1; INPUT:X; OUTPUT:RESOLV
* VALUE,D(ADDRESSING MODE); CALLED: EXPRES,
* ERROR,ZPAGE
*
OPER    LDA INBUFF,X
        CMP =$3D        IF =
        BNE *+9
        INX             IMMEDIATE (1)
        JSR EXPRES
        LDA =1
        RTS
*
        CMP =$20        IF BLANK
        BNE *+6
        INX
        LDA =4          IMPLIED (4)
        RTS
*
        CMP =$41        IF A
        BNE OPER15
        INX
        LDA INBUFF,X    AND BLANK
        CMP =$20
        BNE *+5
        LDA =5          ACCUMULATOR (5)
        RTS
*
*
        DEX
        LDA INBUFF,X
*
OPER15  CMP =$28        IF (
        BNE OPER20
        INX
        JSR EXPRES      GET EXPRESSION
        LDA INBUFF,X
        CMP =$2C        IF NOW ,
        BNE OPER16
        INX
        LDA INBUFF,X
        CMP =$58        MUST BE X
        BNE ERR10
        INX
        LDA INBUFF,X
        CMP =$29        AND )
        BNE ERR10
        JSR ZPAGE       MUST BE ZERO PAGE
        BEQ *+5
        JSR ERR11
        INX
        LDA =6          (X.PAGE,X) (6)
        RTS
*
OPER16  CMP =$29        MUST BE )
        BNE ERR10
        INX
        LDA INBUFF,X
        CMP =$20        IF NOW BLANK
        BNE OPER17
        INX
        LDA =$0B        (ABSOLUTE) (11)
        RTS
*
ERR10   LDA =$40        SYNTAX ERROR IN OPER
        JSR ERROR
        LDA =3          ASSUME ABSOLUTE
        RTS
*
ERR11   LDA =$41        MUST BE ZERO PAGE IND
        JMP ERROR
*
OPER17  CMP =$2C        MUST BE ,
        BNE ERR10
        INX
        LDA INBUFF,X
        CMP =$59        MUST BE Y
        BNE ERR10
        INX
        JSR ZPAGE
        BEQ *+5         MSU BE ZERO PAGE
        JSR ERR11
        LDA =7          (ZERO PAGE),Y (7)
        RTS
*
OPER20  JSR EXPRES      MUST BE EXPRESSION
        LDA INBUFF,X
        CMP =$20        IF NOW BLANK
        BNE OPER25
        JSR ZPAGE
        BNE *+5
        LDA =2          ZERO PAGE (2)
        RTS
*
        LDA =3          ABSOLUTE
        RTS
*
OPER25  CMP =$2C        MUST BE ,
        BNE ERR10
        INX
        LDA INBUFF,X
        INX
        CMP =$58        IF NOW X
        BNE OPER30
        JSR ZPAGE
        BNE *+5
        LDA =8          ZERO PAGE,X (8)
        RTS
*
        LDA =9          ZERO PAGE,Y (12)
        RTS
*
OPER30  CMP =$59        MUST BE Y
        BNE ERR10
        JSR ZPAGE
        BNE *+5
        LDA =$0C        ZERO PAGE,Y (12)
        RTS
*
        LDA =$0A        ABSOLUTE,Y (10
        RTS
*
*
* SUBROUTINE ZPAGE
******************
* TEST FOR ZERO PAGE ADDRESSING
* RETURN Z=1 IF ZERO PAGE
*
ZPAGE   LDA RESOLV
        BNE *+4         ASSUME ABS IF UNDEFINED
        LDA VALUE+1
        RTS
*
*
* SUBROUTINE DEFLAB: DEFINE LABEL
*********************************
* USED: A,Y; SAVED:X; INPUT: LABEL, VALUE,
* LABPNT; CALLED SRLAB,STLAB,ERROR,DEFIN
*
DEFLAB  JSR SRLAB       IF LABEL IN TAB;E
        BCS *+8           DO NOT STORE
        JSR STLABN      ELSE STORE
        JMP DEFL1
*
        LDA PASSFL
        BNE *+5
        JSR RESFBR      RESOLVE BRANCHES
        JSR DEFIN
        BEQ DEFL1       IF DEFINED
        LDA PASSFL        TEST PASS FLAG
        BNE *+7
        LDA =$45
        JMP ERROR
*
        LDY =5
        LDA (LABPNT),Y  COMPARE IN PASS 2
        CMP VALUE
        BNE *+9
        INY
        LDA (LABPNT),Y
        CMP VALUE+1
        BEQ *+7
        LDA =$46
        JSR ERROR
        JMP DEFL2
*
DEFL1   LDA VALUE       STORE ADDRESS
        LDY =5
        STA (LABPNT),Y
        LDA VALUE+1
        INY
        STA (LABPNT),Y
*
DEFL2   LDA PASSFL
        BEQ *+10
        LDY =7
        LDA (LABPNT),Y
        ORA =$80        SET RFLAG
        STA (LABPNT),Y
        RTS
*
*
* SUBROUTINE INTLIN:INTERPRET ONE LINE
**************************************
*OUTPUT: OBJECT,NUMBYT
*
INTLIN  LDX =0          CLEAR BUFFER POINTER
        STX NUMBYT      CLEAR NUMBER OF BYTES
        STX DEFLB       CLEAR LABEL DEF FLAG
        LDA INBUFF,X    GET FIRST CHAR
        CMP =$2A        IF *
        BNE *+3
        RTS             RETURN (COMMENT LINE)
*
        CMP =$20        NOT A BLANK
        BEQ INTL2
        JSR RDLAB       READ LABEL, NO STORING
        LDA =$FF        AT THIS MOMENT, BUT SET
        STA DEFLB       LABEL DEFINITION FLAG
        LDA PCOLD       GET ADDRESS FOR LABEL
        STA VALUE
        LDA PCOLD+1
        STA VALUE+1
*
INTL2   JSR RDBL        READ BLANKS
        JSR RDOPC       READ NOW OPCODE
*
        LDY =9          SEARCH IN PSEUDO TABLE
        LDA OPCODE
        CMP PSEUDO,Y
        BEQ *+7
        DEY
        BPL *-6
        BMI *+9         BRANCH IF NOT FOUND
        LDA OPCODE+1
        CMP PSEUDO+10,Y
        BNE *-10
*
        TYA
        PHA
        BNE INTL10      FOUND. IF EQU (0)
        LDA DEFLB         TEST DEF FLAG
        BNE *+7
        LDA =$47        LABEL MISSING IN EQU
        JMP ERROR
*
        LDY =4          SAVE LABEL
INTL5   LDA LABEL,Y
        PHA
        DEY
        BPL INTL5
*
        JSR EXPDEF      GET VALUE FOR EQU
*
        LDY =0
INTL6   PLA             GET BACK LABEL
        STA LABEL,Y
        INY
        CPY =5
        BNE INTL6
*
INTL10  LDA DEFLB       IF LABEL DEFNITION
        BEQ *+5
        JSR DEFLAB      DEFINE IT NOW
*
        PLA             GET AGAIN PSEUDO NUMBER
        BNE *+3
        RTS             RETURN NOW FROM EQU
*
        CMP =1          IF ORG (1)
        BNE INTL12
        JSR EXPDEF        GET NEW PC
        LDA VALUE
        STA PCNEW
        LDA VALUE+1
        STA PCNEW+1
        JMP CLOSRC      CLOSE EXISTING OBJ. REC
*
INTL12  CMP =2          IF BSS (2)
        BNE INTL13
        JSR EXPDEF        GET VALUE
        CLC             ADD TO PCOLD
        LDA PCOLD
        ADC VALUE
        STA PCNEW
        LDA PCOLD+1
        ADC VALUE+1
        STA PCNEW+1
        JMP CLOSRC      CLOSE EXISTING OBJ. REC
*
INTL13  CMP =3          IF BYT (3)
        BNE INTL14
BYT     LDA INBUFF,X    GET ONE BYTE
        CMP =$27        IF '
        BNE BYT3
        INX             GET ASCII STRING
        LDA INBUFF,X
BYT1    LDY NUMBYT
        CPY =$20
        BCS ERR18
        STA OBJECT,Y    STORE
        INC NUMBYT
        INX
        CPX =$2E        TEST END OF INBUFF
        BCS ERR18
        LDA INBUFF,X    TEST NEXT CHAR
        CMP =$27
        BNE BYT1        CONTINUE STRING READ
        INX
        DEC NUMBYT
        LDA OBJECT,Y
        STA VALUE
        LDA =0
        JSR EXP1
        JMP BYT2
*
BYT3    JSR EXPRES
BYT2    LDA VALUE
        LDY NUMBYT
        STA OBJECT,Y
        INC NUMBYT
        LDA INBUFF,X
        INX
        CMP =$2C
        BEQ BYT
        DEX
        RTS
*
ERR18   LDA =$48
        JMP ERROR       RETURN AFTER ERROR
*
INTL14  CMP =$04                IF WRD (4)
        BNE INTL15
WRD     JSR EXPRES      GET WORD
        LDY NUMBYT
        LDA VALUE
        STA OBJECT,Y
        INY
        LDA VALUE+1
        STA OBJECT,Y
        INY
        STY NUMBYT
        LDA INBUFF,X
        INX
        CMP =$2C        IF ,
        BEQ WRD         CONTINUE
        DEX
        RTS
*
INTL15  CMP =5          IF PAG (5)
        BNE INTL16
PAGE    LDA PAGELN      . SET BIT 7 (PAGE FLAG)
        ORA =$80
        STA PAGELN
        RTS
*
INTL16  CMP =6          IF TIT (6)
        BNE INTL17
        LDY =$1F          LOAD 32 CHARS
        LDA INBUFF,X
        STA TITLE,Y
        INX
        DEY
        BPL *-7
        RTS
*
INTL17  CMP =7          IF END (7)
        BNE *+5
        JMP END         GO TO END
*
INTL18  CMP =$08        IF NPR (8)
        BNE INTL19
        LDA =0
        STA PRTFLG      INHIBIT PRINTING
        RTS
*
INTL19  CMP =$09        IF PRT (9)
        BNE INTL20
        LDA PASSFL      DO NOTHIN IN FIRST PASS
        BEQ *+6
        LDA =$80        SET PRINTING FLAG
        STA PRTFLG
        RTS
*
INTL20  JSR OPER        MUST BE OPCODE
        STA ADMODE      SAVE ADDRESSING MODE
        LDA INBUFF,X
        CMP =$20
        BEQ *+7
        LDA =$51
        JSR ERROR
        LDA VALUE
        STA OBJECT+1
        LDA VALUE+1
        STA OBJECT+2
        JSR SROPC       SEARCH OPCODE
        LDY ADMODE
        LDA MODE2,Y     COMPUTE NUMBYT
        AND =$03
        TAX
        INX
        STX NUMBYT
        CPY =$0D        IF RELATIVE ADDRESSING
        BEQ *+3         GO TO COMPUTE OFFSET
        RTS
*
        LDA PASSFL
        BNE BRAN2
        LDA RESOLV      IF OPERAND RESOLVED
        BEQ BRAN2
        CMP =2
        BCC *+7
        LDA =$42
        JSR ERROR       MORE THAN 1 UNRES LABEL
        JSR FORBR       INSERT FORWARD BRANCH
        LDA =0
        STA OBJECT+1
        RTS
*
* SUBROUTINE TO COMPUTE RELATIVE ADDRESS
****************************************
*
BRAN1   LDA OBJECT+1
        SEC
        SBC =2
        PHA
        LDA OBJECT+2
        SBC =0
        TAY
        PLA
        SEC
        SBC PCOLD
        STA OBJECT+1
        PHP
        TYA
        SBC PCOLD+1
        PLP
        RTS
*
*
BRAN2   JSR BRAN1
        BMI BRAN3
        CMP =0
        BEQ *+7
        LDA =$43
        JSR ERROR
        RTS
BRAN3   CMP =$FF
        BNE *-8
        RTS
*
*
* PSEUDO OPCODE TABLE
*
PSEUDO  BYT $34,$84,$1D,$1E,$C4,$88,$AA,$33
        BYT $7C,$8C
        BYT $AC,$D0,$28,$AA,$CA,$90,$AA,$CA
        BYT $66,$EA
*
*
* EXPDEF: GET A RESOLVED EXPRESSION
***********************************
*
EXPDEF  JSR EXPRES
        LDA RESOLV
        BEQ *+7
        LDA =$49
        JSR ERROR
        RTS
*
*
* JSR PRINTLIN: PRINT A LINE
****************************
* INPUT: OBJECT,NUMBYT,PCOLD,PCNEW,PAGELN
* PAGECN,LINCNT
*
PRTLIN  LDA =0
        STA TEMP1       POINTER IN OBJ
        SED
        CLC             INCREMENT LINE COUNTER
        LDA =1
        ADC LINCNT      DECIMAL INCREMENT
        STA LINCNT
        LDA LINCNT+1
        ADC =0
        STA LINCNT+1
        CLD
PRTL10  BIT PRTFLG
        BPL PRTL21-2
        LDA LINCNT+1
        LDX LINCNT
        JSR PRTAX       PRINT LINE NUMBER
        JSR PRTINF
        BYT $20,$A0     PRINT 2 BLANKS
        LDA PCNEW
        CMP PCOLD
        BNE *+8
        LDA PCNEW+1
        CMP PCOLD+1
        BEQ PRTL20
        LDA PCOLD+1
        LDX PCOLD
        JSR PRTAX       PRINT PROGRAM COUNTER
        JSR PRTINF
        BYT $AD         PRINT -
PRTL20  LDX =$0B
        JSR TAB
        LDX =3          PRINT MAX 3 OBJ BYTES
PRTL21  LDY TEMP1
        LDA OBJECT,Y
        CPY NUMBYT
        BEQ PRTL25
        INC TEMP1
        BIT PRTFLG
        BPL *+5
        JSR PRTBYT
        INC PCOLD
        BNE *+4
        INC PCOLD+1
        BIT PRTFLG
        BPL *+6
        JSR PRTINF      PRINT BLANK
        BYT $A0
        DEX
        BNE PRTL21
PRTL25  LDY TEMP1
        CPY =4
        BCS PRTL30
        BIT PRTFLG
        BPL *+7
        LDX =$16
        JSR TAB         TABULATE TO POS $16
        LDX =0
PRTL26  BIT PRTFLG
        BPL *+7
        LDA INBUFF,X
        JSR PRTCHR      PRINT TEXT
        INX
        CPX INBFPN
        BCC PRTL26
PRTL30  LDA NUMBYT
        CMP TEMP1
        BEQ *+12        RETURN
        BIT PRTFLG
        BPL *+5
        JSR NEWLIN
        JMP PRTL10
        RTS
*
*
* SUBROUTINE TAB: TABULATOR (TO X)
**********************************
*
TAB     LDA =$20
        JSR PRTCHR
        CPX CURPOS
        BCS TAB+2
        RTS
*
*
* SUBROUTINE NEWLIN: START NEW LINE
***********************************
*
NEWLIN  JSR CRLF
        INC PAGELN
        LDA PAGELN
        BMI NEWL06
        CMP TABLE       PRINTED LINES
        BCS NEWL06
        RTS             RETURN IF NOT NEW PAGE
NEWL06  INC PAGELN
        LDA VFLAG       TEST AUTOPRINT FLAG
        AND =8
        BEQ *+8
        LDA TABLE+2     $D FOR IBM, $A FOR TTY
        JSR VAUTOP      EXECUTE LFON HARD COPY
*
NEWL10  JSR CRLF
        LDA =0
        STA PAGELN
        SED
        SEC
        ADC PAGECN      INCREMENT PAGE NUMBER
        STA PAGECN
        CLD
        LDX =$1F
        LDA TITLE,X     PRINT TITLE
        JSR PRTCHR
        DEX
        BPL *-6
        LDX =34
        JSR TAB
        JSR PRTDAT
        JSR PRTINF
        BYT '  R65 ASSEMBLER  PAGE',$A0
        LDA PAGECN
        JSR PRTBYT
        JSR CRLF
CRLF    JSR PRTINF
        BYT $0D,$8A
*
CRLF1   RTS
*
*
*
* SUBROUTINE GET: GET A LINE FROM FILE
**************************************
*
GET     LDX =$2F        CLEAR INBUFF
        LDA =$20
        STA INBUFF,X
        DEX
        BPL GET+4
*
        LDX =0          POINTER IN INBUFF
GET10   STX INBFPN
        LDX INPFIL
        LDA =0
        STA FILFLG
        JSR READCH      GET ONE CHARACTER
        BEQ *+5
        JMP GETERR
        CMP =$1F        EOF
        BEQ GET20
        CMP =$0D
        BNE *+3
        RTS
        LDX INBFPN
        JSR STINB
        JMP GET10
*
GET20   LDX INPFIL
        JSR CLOSE
        INC FILCNT
GET25   LDA PASSFL
        BEQ GET27
        JSR BACKNM      GET SAVED FILE NAME
        JMP GET28
*
GET27   JSR PRTINF
        BYT $D,$A,'NEXT FILE? '+128
*
        LDA CURPOS
        PHA             SAVE CURPOS ON STACK
        LDX =0
GET27A  LDA FILNM1,X
        CMP ='0'        IF DIGIT
        BMI GET27B
        CMP ='9'
        BPL GET27B
        CLC
        ADC =1          ADD 1
GET27B  CMP =$20
        BEQ GET27C
        JSR PRTCHR
        INX
        CPX =15
        BNE GET27A
GET27C  JSR PRTINF
        BYT '.00,'+128
        CLC
        LDA FILDRV
        ADC ='0'
        JSR PRTCHR
        PLA             RESTORE CURPOS
        STA CURPOS
*
        JSR INNAME
GET28   LDA PRTFLG
        BPL *+6
        JSR PRTINF
        BYT $94
        LDA =0
        STA FILFLG
        JSR OPEN
        BNE GETERR+1
*
GET30   STY INPFIL
        JMP GET
*
GETERR  TYA             INPUT ERROR
        JSR ERROR       THIS ERROR IS FATAL
        JMP WARMST
*
STINB   CPX =$30                IF NOT OVERFLOW
        BEQ *+6
        STA INBUFF,X
        INX
        RTS
        LDA =$50
        JMP ERROR       RETURN AFTER ERROR
*
*
* SUBROUTINE PUT: PUT OBJECT CODE INTO
**************************************
* OUTPUT BUFFER, RETURN IF FIRST PASS.
* IS ONLY CALLED, IF NUMBYT>0
*
PUT     LDA PASSFL
        BNE *+3
        RTS
*
        JSR OBEMPT      IF BUFFER EMPTY
        BNE PUT10
        LDA PCOLD       STORE PCOLD
        STA OBADDR      AT BASE ADDRESS
        LDA PCOLD+1
        STA OBADDR+1
*
PUT10   LDA OBEND       IF BUFFER FULL
        SEC
        SBC OBPNT
        STA TEMP1
        LDA OBEND+1
        SBC OBPNT+1
        PHA
        LDA TEMP1
        CMP NUMBYT
        PLA
        SBC =0
        BCS *+8
        JSR CLOSRC      CLOSE RECORD
        JMP PUT         AND OPEN NEW ONE
*
        LDY =0          STORE OBJECT CODE
        LDX =0
PUT20   LDA OBJECT,X
        STA (OBPNT),Y
        INC OBPNT
        BNE *+4
        INC OBPNT+1
        INX
        CPX NUMBYT
        BNE PUT20
        RTS
*
*
CLOSRC  LDA PASSFL
        BNE *+3
        RTS
        JSR OBEMPT      IF BUFFER EMPTY
        BNE *+3
        RTS             DO NOTHING
*
        TXA
        PHA
        JSR PRTINF
        BYT $14,$0D,$0A,$0E
        BYT 'STORE OBJECT FILE:',$0B
        BYT $0D,$0A,'FILENAME.CY,DRIVE,LOC?'
        BYT $A0
        JSR GETLIN
*
        JSR ENDLIN      SKIP STORE IF INPUT EMP
        BEQ CLOSRC0     (USER DOES NOT WANT TO
*
        JSR GETNAM
        JSR HARGUM
        STA FILDRV
        JSR HARGUM
        STA FILLOC
        STX FILLOC+1
        LDX =16
        LDA FILNM1,X
        STA FILNAM,X
        DEX
        BPL *-7
*
        JSR PRTINF
        BYT $D,$8A
*
        LDA OBPNT       SET FILE SIZE
        SEC
        SBC OBSTR
        STA FILSIZ
        LDA OBPNT+1
        SBC OBSTR+1
        STA FILSIZ+1
        LDA OBSTR       SET START IN RAM
        STA FILSA1
        LDA OBSTR+1
        STA FILSA1+1
        LDA =0
        STA FILFLG
        LDA ='M         OBJECT FILE FROM
        STA FILSTP      ASSEMBLER
        LDA OBADDR
        STA FILSA
        CLC
        ADC FILSIZ
        STA FILEA
        LDA OBADDR+1
        STA FILSA+1
        ADC FILSIZ+1
        STA FILEA+1
        LDA FILEA
        BNE *+5
        DEC FILEA+1
        DEC FILEA
        JSR WRFILA
        BNE PUTERR
CLOSRC0 LDA OBSTR       RESET BUFFER
        STA OBPNT
        LDA OBSTR+1
        STA OBPNT+1
        PLA
        TAX
        RTS
*
PUTERR  PLA             WRITE ERROR
        TAX
        TYA
        JMP ERROR
*
*
OBEMPT  LDA OBPNT
        CMP OBSTR
        BNE *+7
        LDA OBPNT+1
        CMP OBSTR+1
        RTS
*
*
* SUBROUTINE ERROR: PRINT ERROR MESSAGE
***************************************
* SET PRINT FLAG; SAVED: X,Y
*
ERROR   PHA
        JSR PRTINF
        BYT $12
        BYT '*** ERROR',$A0
        PLA
        JSR PRTBYT
        INC NUMERR
        TXA
        PHA
        LDA PASSFL
        BNE ENDERR
        JSR PRTINF
        BYT '  IN LINE '+128
        LDA LINCNT+1
        LDX LINCNT
        JSR PRTAX
ENDERR  JSR CRLF
        PLA
        TAX
        RTS
*
*
* CONFIGURATE PRINTER FOR 96 CHARS
*
PRCON   LDX =2
        LDA PRTAB,X
        STX TEMP1
        JSR VAUTOP
        LDX TEMP1
        DEX
        BPL PRCON+2
        RTS
*
*
* GET FILE NAME
*
INNAME  JSR GETLIN
        JSR GETNAM
        JSR HARGUM
        PHA
        LDY FILCNT
        LDA SAVNAM
INNA5   CLC
        DEY
        BMI INNA10
        ADC =20
        JMP INNA5
INNA10  STA SAVPNT
        LDA SAVNAM+1
        STA SAVPNT+1
        LDY =18
INNA20  LDA FILNM1-1,Y
        STA (SAVPNT),Y
        DEY
        BNE INNA20
        PLA
        STA (SAVPNT),Y
        RTS
*
*
* GET FILE NAME BACK FROM BUFFER
*
BACKNM  LDY FILCNT
        LDA SAVNAM
BACK10  CLC
        DEY
        BMI BACK20      CALCULATE POINTER
        ADC =20
        JMP BACK10
BACK20  STA SAVPNT
        LDA SAVNAM+1
        STA SAVPNT+1
        LDY =18
BACK30  LDA (SAVPNT),Y
        STA FILNM1-1,Y
        DEY
        BNE BACK30
        LDA (SAVPNT),Y
        STA FILDRV
        RTS
*
*
* INITIALIZATION
****************
*
COLDST  LDA =$20
        LDX =$1F
        STA TITLE,X     CLEAR TITLE
        DEX
        BPL *-3
*
        JSR PRTINF
        BYT $D,$A,9,9,'R65 ASSEMBLER',$D,$A
        BYT $A,'SOURCE FILE: ',$D
        BYT $A,'FILENAME.CY,DRIVE?',$A0
        LDA =0
        STA FILCNT
        JSR INNAME
*
WARMST  JSR PRTINF
        BYT $D,$A,'A*'+128
        JSR PRCON
        JSR GETCHR
*
        CMP =$46        F=FIRST PASS
        BEQ *+5
        JMP WARM10
        LDA LABSTR
        LDX LABSTR+1
        STA LABCNT
        STX LABCNT+1
        LDA =0
        STA PASSFL
        STA PRTFLG      PRINTING OFF
        LDA TABLE+5
        STA PAGELN
PASS    LDA =0
        STA FILCNT      START WITH FIRST FILE
        JSR BACKNM
*
        LDA =0
        STA FILFLG
        JSR OPEN        OPEN SOURCE
        BEQ *+5
        JMP GETERR+1
*
        STY INPFIL
        LDA OBSTR       OBJECT START
        STA OBPNT
        LDA OBSTR+1
        STA OBPNT+1
        LDX =(NUMERR-PCOLD)  SET ALL TO 0
        LDA =0
        STA PCOLD,X
        DEX
        BPL *-3
        LDA =$80
        STA OUTREC
*
LINE    JSR PRTINF      AUTOPRINT OFF
        BYT $94
        LDA SFLAG       ESCAPE TEST
        BPL LINE1
        AND =$7F
        STA SFLAG
        JMP WARMST
LINE1   JSR GET
        JSR INTLIN
        CLC
        LDA PCNEW
        ADC NUMBYT
        STA PCNEW
        BCC LINE2
        INC PCNEW+1
        JSR PRTINF      HEART BEAT
        BYT '.'+128
LINE2   LDA NUMBYT
        BEQ *+5
        JSR PUT
        BIT PRTFLG
        BPL *+6
        JSR PRTINF
        BYT $92         AUTOPRINT ON
        JSR PRTLIN
        BIT PRTFLG
        BPL *+5
        JSR NEWLIN
        LDA PCNEW
        STA PCOLD
        LDA PCNEW+1
        STA PCOLD+1
        JMP LINE        HANDLE LINES
*
WARM10  CMP =$53        S=SECOND PASS
        BNE WARM20
        LDA =1
        STA PASSFL
        LDA =$80
        STA PRTFLG      PRINTING ON
        LDA =8
        STA EMUCOM      PREPARE LISTING TO FILE
        JSR PRCON
        JSR CLRRFL      CLEAR R-FLAG
        LDA TABLE+5
        STA PAGELN
        LDA =0
        STA PAGECN
        JSR PRTINF
        BYT $92         AUTOPRINT ON
        JSR NEWLIN
        JSR PRTINF
        BYT $94         AUTOPRINT OFF
        JMP PASS
*
WARM20  CMP =$0D        <CR>?
        BNE WARM30
*
EXIT    JSR PRTINF
        BYT $D,$A,'EXIT ASSEMBLER'+128
        JMP (VMON)      GO TO MONITOR
*
WARM30  CMP =$00         <ESC>
        BEQ EXIT
*
        CMP =$52        R=REFERENCE TABLE
        BEQ MAP
        JSR PRTINF
        BYT $87         BELL
        JMP WARMST
*
*
PRTAB   BYT 20,117,27
*
*
* CLEAR R-FLAG
*
CLRRFL  LDY =7
        LDA LABSTR
        LDX LABSTR+1
CLRRF1  STA LABPNT
        STX LABPNT+1
        CMP LABCNT
        TXA
        SBC LABCNT+1
        BCC *+3
        RTS
*
        LDA (LABPNT),Y
        AND =$7F
        STA (LABPNT),Y
        LDA LABPNT
        LDX LABPNT+1
        CLC
        ADC =8
        BCC CLRRF1
        INX
        BCS CLRRF1      ALWAYS TAKEN
*
*
* PRINT REFERENCE TABLE
***********************
*
MAP     LDA PASSFL
        BEQ MAP1
        LDA =$80
        STA PRTFLG
        JSR PRTINF
        BYT 'MAP DESTROYED'+128
        JMP WARMST
MAP1    JSR PRCON
        LDA TABLE+5
        STA PAGELN
        LDA =0
        STA PAGECN
        JSR PRTINF
        BYT $92         AUTOPRINT ON
        JSR NEWLIN
        JSR PRTINF
        BYT 'CROSS REFERENCE MAP',$BA
        JSR NEWLIN
        JSR CLRRFL      CLEAR R-FLAG
*
CROSS0  LDA LABSTR
        LDX LABSTR+1
CROSS1  STA LABPNT
        STX LABPNT+1
        CMP LABCNT
        TXA
        SBC LABCNT+1
        BCC CROSS2
        JSR NEWLIN
        JSR PRTINF
        BYT $94
        JMP WARMST
*
CROSS2  LDY =7
        LDA (LABPNT),Y
        BPL CROSS3      SKIP, IF FOUND
        LDA LABPNT
        LDX LABPNT+1
        CLC
        ADC =8
        BCC CROSS1
        INX
        BCS CROSS1
*
CROSS3  LDA LABPNT
        LDX LABPNT+1
CROSS4  CLC
        ADC =8
        STA LABPN1
        BCC *+3
        INX
        STX LABPN1+1
        CMP LABCNT
        TXA
        SBC LABCNT+1
        BCS CROSS7      SKIP, IF FOUND
*
        LDY =7
        LDA (LABPN1),Y
        BPL CROSS6
CROSS5  LDA LABPN1
        LDX LABPN1+1
        JMP CROSS4
*
CROSS6  SEC
        LDY =4
        LDA (LABPNT),Y  COMPARE NOW
        SBC (LABPN1),Y
        DEY
        BPL CROSS6+3
        BCC CROSS5
        LDA LABPN1
        LDX LABPN1+1
        STA LABPNT
        STX LABPNT+1
        JMP CROSS4
*
CROSS7  LDY =7
        LDA (LABPNT),Y  SET R-FLAG
        ORA =$80
        STA (LABPNT),Y
        JSR PRLABN
        JMP CROSS0
*
*
* END OF SOURCE
*
END     LDA =0
        STA PCNEW
        STA PCNEW+1
        LDA PASSFL      ONLY IN SECOND PASS
        BEQ END0-3
        JSR PRTINF      AUTOPRINT ON
        BYT $92
        JSR PRTLIN
END0    JSR NEWLIN
        JSR PRTINF
        BYT 'LABELS',$BD
        LDA =0
        STA LABPNT+1
        LDA LABCNT
        SEC
        SBC LABSTR
        STA LABPNT
        LDA LABCNT+1
        SBC LABSTR+1
        LDY =4
END1    ASL LABPNT
        ROL A
        ROL LABPNT+1
        DEY
        BPL END1
        TAX
        LDA LABPNT+1
        JSR PRTAX
        JSR NEWLIN
        JSR PRTINF
        BYT 'ERRORS',$BD
        LDA NUMERR
        JSR PRTBYT
        JSR NEWLIN
        JSR PRTINF
        BYT 'RECORDS',$BD
        LDX INPFIL
        LDA FIRCTB,X
        JSR PRTBYT
        JSR NEWLIN
        JSR CLOSRC
        LDX INPFIL
        JSR CLOSE
        JSR PRTINF
        BYT 'UNRESOLVED',$BA
        LDA =9          FINISH LISTING
        STA EMUCOM
        JSR CLRRFL      CLEAR R-FLAG
        LDA LABSTR
        LDX LABSTR+1
UNRES   STA LABPNT
        STX LABPNT+1
        CMP LABCNT
        TXA
        SBC LABCNT+1
        BCC *+5
        JMP CROSS0
        JSR DEFIN
        BEQ END2
        LDY =7
        LDA (LABPNT),Y
        ORA =$80
        STA (LABPNT),Y
END2    LDA LABPNT
        LDX LABPNT+1
        CLC
        ADC =8
        BCC *+3
        INX
        JMP UNRES
*
*
* SUBROUTINE PRLABN: PRINT NAME OF LABEL
****************************************
*
PRLABN  LDY =0
        LDA (LABPNT),Y
        STA LABEL,Y
        INY
        CPY =5
        BNE PRLABN+2
*
        JSR NEWLIN
        LDY =7          CHAR COUNTER
PRLAB0  LDX =6
        CPY =6
        BCC *+3
        DEX
        LDA =0
PRLAB1  ROL LABEL+4
        ROL LABEL+3
        ROL LABEL+2
        ROL LABEL+1
        ROL LABEL
        ROL A
        DEX
        BNE PRLAB1
        CMP =0
        BEQ PRLAB3
        CMP =$30
        BPL *+4
        ORA =$40
        JSR PRTCHR
PRLAB3  DEY
        BNE PRLAB0
        LDX =8
        JSR TAB
        JSR DEFIN
        BNE *+12
        JSR PRTINF
        BYT '???',$BF
        JMP *+16
*
        LDY =6
        LDA (LABPNT),Y
        JSR PRTBYT
        DEY
        LDA (LABPNT),Y
        JSR PRTBYT
        JSR CBASE
        LDY =7
        LDA (LABPNT),Y
        AND =$7F
        ASL A
        TAY             Y=2*NO OF REFERENCES
*
PRLAB4  LDA =10         REFERENCES PER LINE
        STA TEMP1
        LDX =16
        JSR TAB
PRLAB5  CPY =0
        BEQ PRLAB6
        DEY
        LDA (BASE),Y
        JSR PRTBYT
        DEY
        LDA (BASE),Y
        JSR PRTBYT
        JSR PRTINF
        BYT $A0
        DEC TEMP1
        BPL PRLAB5
        TYA
        BEQ PRLAB6
        PHA
        JSR NEWLIN
        PLA
        TAY
        BNE PRLAB4
PRLAB6  RTS
*
*
* SUBROUTINE FORBR: INSERT FORWARD BRANCH
*****************************************
* INPUT: OBJECT, BRANTC, ONLY IN FIRST PASS
* RESOLV+1
*
FORBR   LDA BRANTC
        CMP =12
        BCC *+7
        LDA =$52
        JMP ERROR
        TAY
        LDA RESOLV+1
        STA BRANTB,Y    STORE NO OF LABELS
        LDA RESOLV+2
        STA BRANTB+12,Y
        JSR BRAN1
        LDY BRANTC
        STA BRANTB+36,Y STORE HIGH BYTE
        LDA OBJECT+1
        STA BRANTB+24,Y STORE LOW BYTE
        INC BRANTC
        RTS
*
*
* SUBROUTINE RESFBR: RESOLVE FORWARD BRANCH
*******************************************
* INPUT: LABPNT; ONLY IN FIRST PASS
* SAVED: X,Y
*
RESFBR  TXA
        PHA
RESF1   LDX BRANTC
        BEQ RESF0       TABLE EMPTY
        DEX
RESF8   LDA LABPNT
        CMP BRANTB,X
        BNE RESF6
        LDA LABPNT+1
        CMP BRANTB+12,X
        BEQ RESF7
RESF6   DEX
        BPL RESF8
RESF0   PLA
        TAX
        RTS
*
RESF7   TXA
        PHA
        JSR RESF2
        PLA
        TAX
        JMP RESF1
*
RESF2   LDA BRANTB+24,X
        CLC
        ADC VALUE
        PHP
        LDA BRANTB+36,X
        ADC VALUE+1
        PLP
        BMI RESF3
        CMP =0
        BEQ RESF4
ERR14   TYA
        PHA
        LDA =$44
        JSR ERROR
        PLA
        TAY
        JMP RESF4
*
RESF3   CMP =$FF
        BNE ERR14
*
RESF4   INX
        CPX BRANTC
        BCS RESF5
        LDA BRANTB,X
        STA BRANTB-1,X
        LDA BRANTB+12,X
        STA BRANTB+11,X
        LDA BRANTB+24,X
        STA BRANTB+23,X
        LDA BRANTB+36,X
        STA BRANTB+35,X
        JMP RESF4
*
RESF5   DEC BRANTC
        RTS
*
*
* SUBROUTINE CBASE: COMPUTE BASE
********************************
* INPUT: LABCNT
*
CBASE2  LDA LABCNT
        LDX LABCNT+1
        STA LABPNT
        STX LABPNT+1
*
CBASE   LDA OBSTR
        STA BASE
        LDA OBSTR+1
        STA BASE+1
        LDA LABPNT
        LDX LABPNT+1
CBASE1  SEC
        SBC =8
        STA LABPN1
        BCS *+3
        DEX
        STX LABPN1+1
        CMP LABSTR
        TXA
        SBC LABSTR+1
        BCS *+3
        RTS
        LDY =7
        LDA (LABPN1),Y
        AND =$7F
        ASL A
        ADC BASE
        STA BASE
        BCC *+4
        INC BASE+1
        LDA LABPN1
        LDX LABPN1+1
        JMP CBASE1
*
*
* SUBROUTINE: SETREF: SET REFERENCE
***********************************
* SAVED: X,Y; INPUT: LABPNT
*
SETREF  STX INDEX1      SAVE X
        STY INDEX2
        LDA PASSFL
        BEQ *+3
        RTS
*
        LDY =7
        LDA (LABPNT),Y
        AND =$7F
        CMP =$7F
        BNE *+5
        LDY INDEX2      NOT INSERTED IN FULL
        RTS
*
        LDA LABPNT
        PHA
        LDA LABPNT+1
        PHA
        JSR CBASE2
        PLA
        STA LABPNT+1
        PLA
        STA LABPNT
*
        LDA BASE
        STA OBPNT
        CMP OBEND
        LDA BASE+1
        STA OBPNT+1
        SBC OBEND+1
        BCS SETR1
*
        LDX TEMP1
        LDY =7
        LDA (LABPNT),Y
        CLC
        ADC =1
        STA (LABPNT),Y
        JSR CBASE
SETR2   LDA OBPNT
        CMP BASE
        LDA OBPNT+1
        SBC BASE+1
        BCC SETR3
        LDY =0
        LDA (OBPNT),Y
        LDY =2
        STA (OBPNT),Y
        SEC
        LDA OBPNT
        SBC =1
        STA OBPNT
        BCS *+4
        DEC OBPNT+1
        JMP SETR2
*
SETR3   JSR CBASE
        LDY =0
        LDA PCOLD
        STA (BASE),Y
        INY
        LDA PCOLD+1
        STA (BASE),Y
SETR1   LDY INDEX2
        LDX INDEX1
        RTS
*
*
        END
