*
*       **********************
*       * R65 PASCAL RUNTIME *
*       **********************
*
* VERSION 5.3   01/06/82 RRICHARZ,RBAUMANN
* IMPROVED 2019-2023 RRICHARZ
* VERSION 5.54  STOP CLOSES ALL OPEN FILES
*
        TIT R65 PASCAL RUNTIME
*
* INCLUDES RANDOM ACCESS FILE HANDLING,
* FLOATING POINT MATH, FILE HANDLING ERROR
* TESTING (OPTIONAL) AND CPNT POINTERS
*
        ORG 0
*
ACCU    BSS 4   TOP OF STACKELEMENT
X1      EQU ACCU        FLP ACCU
M1      EQU ACCU+1
E       BSS 4   FLP SCRATCH REGISTER
SP      BSS 2   CURRENT STACK (-128)
PC      BSS 2   PROGRAM COUNTER
RUNERR  BSS 1   RUNTIME ERROR CODE
DEVICE  BSS 1   I/O DEVICE CODE
ENDSTK  BSS 2   END OF STACK (-128)
SIGN    BSS 1   TEMPORARY SIGN
STPROG  BSS 2   START OF USER PROGRAM
EOPROG  BSS 2   END OF USER PRORMA
BUFFPN  BSS 1   INPUT BUFFER POINTER
ENDBUF  BSS 1   END OF INPUT BUFFER
BASE    BSS 2   CURRENT BASE (-128)
ABASE   BSS 2   ALTERNATE BASE (-128)
ARG1    BSS 2   TEMPORARY ARGUMENT
ARG3    BSS 4   TEMPORARY REGISTERS
ARG2    BSS 2
X2      EQU ARG1        FLP REGISTER
M2      EQU ARG1+1
IOCHECK BSS 1   IO ERROR CHECKING FLAG
LINBUF  BSS 56  INPUT LINE BUFFER
*
FILFLG  EQU $DA
FILERR  EQU $DB
FILDRV  EQU $DC
TRACK   EQU $DD
SECTOR  EQU $DE
DATA    EQU $E0
VIDPNT  EQU $E9
POINT   EQU $FA
KCHAR   EQU $FE
*
EMUCOM  EQU $1430       EMULATOR COMMAND REG
MULTA   EQU $14E0
MULTB   EQU $14E1
MULTR   EQU $14E2
*
FILTYP  EQU $0300
FILNAM  EQU $0301
FILCYC  EQU $0311
FILSTP  EQU $0312
FILLOC  EQU $0313
FILSIZ  EQU $0315
FILSA   EQU $031A
FILEA   EQU $031C
FILNM1  EQU $0320
FILCY1  EQU $0330
FILSA1  EQU $0331
SAVRST  EQU $0333
CURSEQ  EQU $0335
MAXSEQ  EQU $0336
MAXSIZ  EQU $0337
FIDRTB  EQU $0339
FIDVTB  EQU $0341
FIBPTB  EQU $0349
FIRCTB  EQU $0351
GRX     EQU $03AE
GRY     EQU $03AF
GRC     EQU $03B0
SFLAG   EQU $1781
NUMCHR  EQU $178A
VMON    EQU $17D5
SAVS    EQU $17FF
*
APLOTCH EQU $C818
GETKEY  EQU $E000
AUTOPR  EQU $E00C
ENDLIN  EQU $E024
PRTINF  EQU $E027
GETCHR  EQU $E003
GETLIN  EQU $E006
PRTCHR  EQU $E009
PRTBYT  EQU $E02D
PRTAX   EQU $E030
PRTRSA  EQU $E836
RDFILE  EQU $E815
SETFID  EQU $E81E
OPEN    EQU $F00F
READCH  EQU $F018
WRITCH  EQU $F01B
GETNAM  EQU $F815
*
        ORG $2000
*
        PAG
*
* ENTRY VECTORS
*
        JMP COLDST      COLD START ENTRY VECTOR
        JMP WARMST      WARM START ENTRY VECTOR
        JMP PERROR      PASCAL ERROR
*
USERST  WRD ENDCODE+32
USEREND WRD $C7FF
*
HARGUM  JMP $FCF2       #######
*
*
* P-CODE 00:  STOP      (END OF EXECUTION)
******************
* NO ARGUMENTS
*
STOP    LDA =47
        STA NUMCHR      FORCE 48 CHARS/LINE
        JSR CLOSAL      CLOSE ALL OPEN FILES
        LDA STPROG      IS ANOTHER PROGRAM
        LDX STPROG+1    RUNNING?
        CMP USERST
        BNE STOP1
        CPX USERST+1
        BNE STOP1
*
        JSR PRTINF      NO, STOP PASCAL
        BYT $0D,$0A,'Quit Pascal'+$80
        LDA SFLAG
        AND =$FE        CLEAR PASCAL RUNTIME BIT
        STA SFLAG       IN SFLAG
        JMP (VMON)
*
STOP1   SEC             YES, COMPUTE OLD SP
        SBC =140
        BCS *+3
        DEX
        STA SP
        STX SP+1
        LDY =140
        JSR GETBACK
        STA EOPROG
        STX EOPROG+1
        JSR GETBACK
        STA STPROG
        STX STPROG+1
        JSR GETBACK
        STA PC
        STX PC+1
        JSR GETBACK
        STA BASE
        STX BASE+1
        JSR GETBACK
        STA ACCU
        STX ACCU+1
        LDX SAVS        RESTORE STACK POINTER
        TXS
        JMP LOOP
*
*
DOPEN1  JMP $F0FF
DOPEN4  JMP $F145
PRFLB1  JMP $F151
CPOINT  JMP $F159
PREPSR  JMP $F1E0
PREPSR1 JMP $F29E
CLOSE   JMP $F012
CLOSAL  JMP $F015
READ    JMP $F457
WRITE   JMP $F425
PREPDO  JMP $F4A7
DISCER1 JMP $F5FD
ENDDO   JMP $F625
PREPRD  JMP $F62C
PREPWRA JMP $F651
PREPWRB JMP $F66D
*
*
* P-CODE 01: RETN       (RETURN FROM PROCEDURE
*****************
* NO ARGUMENTS
*
RETN    LDA BASE        SP=BASE-2
        SEC
        SBC =2
        STA SP
        LDA BASE+1
        SBC =0
        STA SP+1
        LDY =128        GET STACK TOP ELEMENT
        LDA (SP),Y
        STA ACCU
        INY
        LDA (SP),Y
        STA ACCU+1
        LDY =132
        LDA (SP),Y      GET SAVED OLD BASE
        STA BASE
        INY
        LDA (SP),Y
        STA BASE+1
        INY
        LDA (SP),Y      AND RETURN ADDRESS
        CLC
        ADC =2
        STA PC
        INY
        LDA (SP),Y
        ADC =0
        STA PC+1
        RTS
*
* P-CODE 02: NEGA       (NEGATE ACCU)
*****************
* NO ARGUMENTS
*
NEGA    LDA =0
        SEC
        SBC ACCU
        STA ACCU
        LDA =0
        SBC ACCU+1
        STA ACCU+1
        RTS
*
* P-CODE 03: ADDA       (ADD)
*****************
* NO ARGUMENTS
*
ADDA    LDY =126
        CLC
        LDA (SP),Y
        ADC ACCU
        STA ACCU
        INY
        LDA (SP),Y
        ADC ACCU+1
        STA ACCU+1
*
DECS2   LDA SP
        SEC
        SBC =2
        STA SP
        BCS *+4
        DEC SP+1
        RTS
*
* P-CODE 04: SUBA       (SUBTRACT)
*****************
* NO ARGUMENTS
*
SUBA    LDY =126
        SEC
        LDA (SP),Y
        SBC ACCU
        STA ACCU
        INY
        LDA (SP),Y
        SBC ACCU+1
        STA ACCU+1
        JMP DECS2
*
* P-CODE 05: MULA       (MULTIPLY)
*****************
* NO ARGUMENTS
*
MULA    JSR GETSIGN     COMPUTE SIGN OF RESULT
        LDA ACCU
        SEI
        STA MULTA
        LDA ARG1        GET SAVED ARGUMENT
        STA MULTB
        LDA MULTR
        STA ACCU
        LDA MULTR+1
        LDX ARG1+1
        STX MULTB
        CLC
        ADC MULTR
        LDX ACCU+1
        STX MULTA
        LDX ARG1
        STX MULTB
        CLC
        ADC MULTR
        CLI
        AND =$7F
        STA ACCU+1
        JSR DECS2
        LDA SIGN
        BMI NEGA
        RTS
*
GETSIGN LDA ACCU+1
        STA SIGN
        BPL *+5
        JSR NEGA
*
        LDY =127
        LDA (SP),Y
        BPL GETSI1
        EOR SIGN
        STA SIGN
        DEY
        LDA =0
        SEC
        SBC (SP),Y
        STA ARG1
        INY
        LDA =0
        SBC (SP),Y
        STA ARG1+1
        RTS
*
GETSI1  STA ARG1+1
        DEY
        LDA (SP),Y
        STA ARG1
        RTS
*
* PCODE 06: DIVA        (DIVIDE)
****************
*
DIVA    LDY =126
        LDA (SP),Y
        STA ARG1
        INY
        LDA (SP),Y
        STA ARG1+1
        JSR DECS2
*
        LDA ARG1+1
        AND =$80
        BEQ *+4
        LDA =$FF
        STA ARG2
        STA ARG2+1
        TAX
        CLC
        ADC ARG1
        STA ARG1
        TXA
        ADC ARG1+1
        STA ARG1+1
        TXA
        EOR ACCU+1
        STA SIGN
        BPL *+5
        JSR NEGA
        LDY =$11
        LDA ACCU
        ORA ACCU+1
        BNE DIV1
        LDX =$81        PASCAL RUNTIME ERROR
        JMP PERROR      DIVISION BY ZERO
*
DIV1    SEC
        LDA ARG2
        SBC ACCU
        PHA
        LDA ARG2+1
        SBC ACCU+1
        PHA
        EOR ARG2+1
        BMI DIV2
        PLA
        STA ARG2+1
        PLA
        STA ARG2
        SEC
        BCS DIV3
*
DIV2    PLA
        PLA
        CLC
DIV3    ROL ARG1
        ROL ARG1+1
        ROL ARG2
        ROL ARG2+1
        DEY
        BNE DIV1
        LDA ARG1
        LDX ARG1+1
        STA ACCU
        STX ACCU+1
        LDA SIGN
        BPL *+5
        JMP NEGA
        RTS
*
* P-CODE 07: LOWB       (LOW BIT)
*****************
* NO ARGUMENTS
*
LOWB    LDA ACCU
        AND =1
LOWB1   STA ACCU
        LDA =0
        STA ACCU+1
        RTS
*
* P-CODE 08: TEQU       (TEST EQUAL)
*****************
*
TEQU    JSR SUBA
        LDA ACCU
        ORA ACCU+1
        BEQ TEQU1
        LDA =0
        BEQ LOWB1       UNCOND.
*
TEQU1   LDA =1
        BNE LOWB1       UNCOND.
*
* PCODE 09: TNEQ        (TEST NOT EQUAL)
****************
*
TNEQ    JSR TEQU
        LDA ACCU
        EOR =1
        STA ACCU
        RTS
*
* P-CODE 0A: TLES       (TEST LESS)
*****************
*
TLES    JSR SUBA
        LDA =0
        ASL ACCU+1
        ROL A
        BCC LOWB1       UNCOND.
*
* P-CODE 0B: TGRE       (TEST GREATER OR EQUAL)
*****************
*
TGRE    JSR TLES
        JMP TNEQ+3
*
* P-CODE 0C: TGRTS      (TEST GREATER)
******************
*
TGRT    JSR EXST
        JMP TLES
*
* P-CODE 0D: TLEE       (TEST LESS OR EQUAL)
*****************
*
TLEE    JSR TGRT
        JMP TNEQ+3
*
* P-CODE 0E: ORAC       (BITWISE OR)
*****************
*
ORAC    LDY =126
        LDA (SP),Y
        ORA ACCU
        STA ACCU
        INY
        LDA (SP),Y
        ORA ACCU+1
        STA ACCU+1
        JMP DECS2
*
* P-CODE 0F: ANDA       (BITWISE AND)
*****************
*
ANDA    LDY =126
        LDA (SP),Y
        AND ACCU
        STA ACCU
        INY
        LDA (SP),Y
        AND ACCU+1
        STA ACCU+1
        JMP DECS2
*
* PCODE 10: EORA        (BITWISE OR)
****************
*
EORA    LDY =126
        LDA (SP),Y
        EOR ACCU
        STA ACCU
        INY
        LDA (SP),Y
        EOR ACCU+1
        STA ACCU+1
        JMP DECS2
*
* P-CODE 11: NOTA       (BITWISE NOT)
*****************
*
NOTA    LDA ACCU
        EOR =$FF
        STA ACCU
        LDA ACCU+1
        EOR =$FF
        STA ACCU+1
        RTS
*
* P-CODE 12: LEFT       (SHIFT LEFT N BYTES)
*****************
*
        JSR NEGA
LEFT    LDA ACCU+1
        BMI RIGH-3      ARGUMENT NEGATIVE
*
        LDX ACCU
        BEQ LEFT2       TAKE ONLY LOW BYTE
        JSR GETS2       GET SECOND NO FROM ST
LEFT1   ASL ACCU
        ROL ACCU+1
        DEX
        BNE LEFT1
        RTS
*
LEFT2   JMP GETS2
*
* P-CODE 13: RIGH       (SHIFT RIGHT N BYTES)
*****************
*
        JSR NEGA
RIGH    LDA ACCU+1
        BMI LEFT-3
        LDX ACCU
        BEQ LEFT2
        JSR GETS2
RIGH1   LSR ACCU+1
        LDA =0
        BCC *+4
        LDA =128
        LSR ACCU
        ORA ACCU
        STA ACCU
        DEX
        BNE RIGH1
        RTS
*
* P-CODE 14:INCA        (INCREMENT ACCU)
****************
*
INCA    INC ACCU
        BNE *+4
        INC ACCU+1
        RTS
*
* P-CODE 15: DECA       (DECREMENT ACCU)
*****************
*
DECA    LDA ACCU
        BNE *+4
        DEC ACCU+1
        DEC ACCU
        RTS
*
* P-CODE 16: COPY       (COPY ACCU0
*****************
*
COPY    JSR INCS2       INCREMENT STACK
        LDY =126
        LDA ACCU
        STA (SP),Y
        INY
        LDA ACCU+1
        STA (SP),Y
        RTS
*
INCS2   LDA =2
        CLC
        ADC SP
        STA SP
        BCC *+4
        INC SP+1
INCS2A  CMP ENDSTK      TEST STACK OVERFLOW
        LDA SP+1
        SBC ENDSTK+1
        BCS INCS2B
        LDA =5          LET EMULATOR KNOW THAT
        STA EMUCOM      SP HAS BEEN INCREASED
        RTS
*
INCS2B  LDY =$82        PASCAL RUN TIME ERROR
        JMP PERROR      STACK OVERFLOW
*
* GETS2
*
GETS2   LDY =126
        LDA (SP),Y
        STA ACCU
        INY
        LDA (SP),Y
        STA ACCU+1
        JMP DECS2
*
* P-CODE 17: PEEK
*****************
*
PEEK    LDY =0
        LDA (ACCU),Y
        STA ACCU
        STY ACCU+1
        RTS
*
* P-CODE 18: POKE
*****************
*
POKE    LDX ACCU
        JSR GETS2
        LDY =0
        TXA
        STA (ACCU),Y
        JMP GETS2
*
* P-CODE 19: CALA
*****************
*
CALA    JSR CALA1
        JMP GETS2
*
CALA1   JMP (ACCU)
*
* P-CODE 1A: RLIN
*****************
*
RLIN    JSR GETLIN
        LDX =0
        LDA (VIDPNT),Y
        AND =$7F
        STA LINBUF,X
        INX
        INY
        CPY NUMCHR
        BCC *-11
        BEQ *-13
        DEX
        BMI *+8
        LDA LINBUF,X
        CMP =$20
        BEQ *-7
        INX
        STX ENDBUF
        LDA =0
        STA BUFFPN
        JSR PRTINF
        BYT $D,$8A
        RTS
*
* P-CODE 1B: GETC
*****************
*
GETC    JSR COPY
        JSR GETCHR0
GETC1   STA ACCU
        LDA =0
        STA ACCU+1
        RTS
*
* P-CODE 1C: GETN
*****************
*
GETN    JSR COPY
        LDA =0
        STA ACCU
        STA ACCU+1
        STA SIGN
GETN0   JSR GETCHR0
        CMP =' '
        BEQ GETN0
        CMP ='-'
        BNE GETN1
*
        DEC SIGN
        JMP GETN2
*
GETN1    CMP ='+'
        BNE GETN2+3
*
GETN2   JSR GETCHR0
        CMP ='0'
        BCC GETN3
        CMP ='9'+1
        BCS GETN3
        SEC
        SBC ='0'
        PHA
        ASL ACCU
        ROL ACCU+1
        LDX ACCU
        LDY ACCU+1
        ASL ACCU
        ROL ACCU+1
        ASL ACCU
        ROL ACCU+1
        CLC
        TXA
        ADC ACCU
        STA ACCU
        TYA
        ADC ACCU+1
        STA ACCU+1
        PLA
        CLC
        ADC ACCU
        STA ACCU
        BCC GETN2
        INC ACCU+1
        BCS GETN2
*
GETN3   LDA SIGN
        BEQ *+5
        JMP NEGA
        RTS
*
* P-CODE 1D: PRTC
*****************
*
PRTC    LDA ACCU
        JSR PRTCHR0
        JMP GETS2
*
* P-CODE 1E: PRTN
*****************
*
PRTN    LDA ACCU+1
        BPL PRTN1
        JSR NEGA
        LDA ='-'
        JSR PRTCHR0
*
PRTN1   LDA ACCU
        LDX ACCU+1
        STA ARG2
        STX ARG2+1
        LDA =$1F
        STA ARG3
        STA ARG3+2
        LDA =$2A
        STA ARG3+1
        STA ARG3+3
        LDX ARG2
        LDY ARG2+1
        SEC
PRTN2   INC ARG3
        TXA
        SBC =$10
        TAX
        TYA
        SBC =$27
        TAY
        BCS PRTN2
PRTN3   DEC ARG3+1
        TXA
        ADC =$E8
        TAX
        TYA
        ADC =$03
        TAY
        BCC PRTN3
        TXA
PRTN4   SEC
PRTN5   INC ARG3+2
        SBC =$64
        BCS PRTN5
        DEY
        BPL PRTN4
PRTN6   DEC ARG3+3
        ADC =$A
        BCC PRTN6
        ORA =$30
        STA ARG2
        LDA =$20
        STA ARG2+1
        LDX =$FB
PRTN7   STX SIGN
        LDA ARG2+1,X
        ORA ARG2+1
        CMP =$20
        BEQ PRTN8
        LDY =$30
        STY ARG2+1
        ORA ARG2+1
        JSR PRTCHR0
PRTN8   LDX SIGN
        INX
        BNE PRTN7
        JMP GETS2
*
* P-CODE 1F: PRTS
*****************
*
PRTS    ASL ACCU
        ROL ACCU+1
        LDA SP
        SEC
        SBC ACCU
        STA ACCU
        PHA
        LDA SP+1
        SBC ACCU+1
        STA ACCU+1
        PHA
OUTST1  LDY =128
        LDA (ACCU),Y
        JSR PRTCHR0
        LDA ACCU
        CLC
        ADC =2
        STA ACCU
        BCC *+4
        INC ACCU+1
        CMP SP
        LDA ACCU+1
        SBC SP+1
        BCC OUTST1
        PLA
        STA SP+1
        PLA
        STA SP
        JMP GETS2
*
* P-CODE 20: LITB
*****************
*
LITB    JSR COPY
        JSR FETCH
        STA ACCU
        LDA =0
        STA ACCU+1
        RTS
*
* P-CODE 21: INCB
*****************
*
INCB    LDY =128        SAVE CURRENT ACCU
        LDA ACCU
        STA (SP),Y
        INY
        LDA ACCU+1
        STA (SP),Y
        JSR FETCH
        LDX =0
        TAY             TEST A
        BPL *+3
        DEX
        CLC
        ADC SP
        STA SP
        TXA
        ADC SP+1
        STA SP+1
INCB1   LDA SP
        JSR INCS2A      TEST STACK OVERFLOW
        LDY =128        AND GET NEW ACCU
        LDA (SP),Y
        STA ACCU
        INY
        LDA (SP),Y
        STA ACCU+1
        RTS
*
* P-CODE 22: LITW
*****************
*
LITW    JSR COPY
        JSR FETCH
        STA ACCU
        JSR FETCH
        STA ACCU+1
        RTS
*
* FETCH
*
FETCH   LDY =0
        LDA (PC),Y
        INC PC
        BNE *+4
        INC PC+1
        RTS
*
* P-CODE 23: INCW
*****************
*
INCW    LDY =128        SAVE CURRENT ACCU
        LDA ACCU
        STA (SP),Y
        INY
        LDA ACCU+1
        STA (SP),Y
        JSR FETCH
        CLC
        ADC SP
        STA SP
        JSR FETCH
        ADC SP+1
        STA SP+1
        JMP INCB1
*
* P-CODE 24: JUMP
*****************
*
JUMP    LDY =0
        LDA (PC),Y
        CLC
        ADC PC
        TAX
        INY
        LDA (PC),Y
        ADC PC+1
        STX PC
        STA PC+1
        RTS
*
* P-CODE 25: JMPZ
*****************
*
JMPZ    LSR ACCU
        PHP
        JSR GETS2
        PLP
        BCC JUMP
*
        LDA PC
        CLC
        ADC =2
        STA PC
        BCC *+4
        INC PC+1
        RTS
*
* P-CODE 26: JMPO
*****************
*
JMPO    LDA ACCU
        EOR =1
        STA ACCU
        JMP JMPZ
*
* P-CODE 27: LOAD
*****************
*
LOAD    JSR COPY
        JSR FETCH
        TAX             LEVEL DIFFERENCE
        JSR FETCH
        STA ARG1
        JSR FETCH
LOAD1   STA ARG1+1
        JSR FBASE3
LOAD2   LDY =128
        LDA (ABASE),Y
        STA ACCU
        INY
        LDA (ABASE),Y
        STA ACCU+1
        RTS
*
* FBASE
*
FBASE   LDA BASE
        LDY BASE+1
        STA ABASE
        STY ABASE+1
        CPX =0
        BEQ FBASE2
*
FBASE1  LDY =128
        LDA (ABASE),Y
        PHA
        INY
        LDA (ABASE),Y
        STA ABASE+1
        PLA
        STA ABASE
        DEX
        BNE FBASE1
FBASE2  RTS
*
FBASE3  JSR FBASE
        CLC
        LDA ARG1
        ADC ABASE
        STA ABASE
        LDA ARG1+1
        ADC ABASE+1
        STA ABASE+1
        RTS
*
* P-CODE 28: LODX
*****************
*
LODX    JSR FETCH
        TAX
        JSR FETCH
        ASL ACCU
        ROL ACCU+1
        CLC
        ADC ACCU
        STA ARG1
        PHP
        JSR FETCH
        PLP
        ADC ACCU+1
        JMP LOAD1
*
* P-CODE 29: STOR
*****************
*
STOR    JSR FETCH
        TAX
        JSR FETCH
        STA ARG1
        JSR FETCH
        STA ARG1+1
STOR1   JSR FBASE3
STOR2   LDY =128
        LDA ACCU
        STA (ABASE),Y
        INY
        LDA ACCU+1
        STA (ABASE),Y
        JMP GETS2
*
* P-CODE 2A: STOX
*****************
*
STOX    JSR FETCH
        TAX
        LDY =126
        LDA (SP),Y
        ASL A
        STA ARG1
        INY
        LDA (SP),Y
        ROL A
        STA ARG1+1
        JSR FETCH
        CLC
        ADC ARG1
        STA ARG1
        JSR FETCH
        ADC ARG1+1
        STA ARG1+1
        JSR DECS2
        JMP STOR1
*
* P-CODE 2B: CALL
*****************
*
CALL    JSR FETCH
        TAX
        JSR FBASE
        LDY =130
        LDA ABASE
        STA (SP),Y
        INY
        LDA ABASE+1
        STA (SP),Y
        INY
        LDA BASE
        STA (SP),Y
        INY
        LDA BASE+1
        STA (SP),Y
        INY
        LDA PC
        STA (SP),Y
        INY
        LDA PC+1
        STA (SP),Y
        LDA SP
        CLC
        ADC =2
        STA BASE
        LDA SP+1
        ADC =0
        STA BASE+1
        JMP JUMP
*
* PCODE 2C: SDEV
****************
*
SDEV    LDA ACCU
        STA DEVICE
        JMP GETS2
*
* PCODE 2D: RDEV
****************
*
RDEV    LDA =0
        STA DEVICE
        RTS
*
* PCODE 2E: FNAM
****************
*
FNAM    JSR PRTINF
        BYT ' = '+128
        JSR GETLIN
        JSR GETNAM
        JSR HARGUM
        STA FILDRV
        JSR HARGUM
        STA FILLOC
        JSR PRTINF
        BYT $D,$8A
        RTS
*
* P-CODE 2F: OPNR
*****************
*
* NO AUTOMATIC ERROR TESTING
*
OPNR    LDA =0
        STA FILFLG
        JSR COPY
        JSR OPEN
        INY
        INY
        STY ACCU
        STA ACCU+1
        RTS
*
* P-CODE 30: OPNW
*****************
*
OPNW    LDA =$20
        JMP OPNR+2
*
* P-CODE 31: CLOS
*****************
*
* NO AUTOMATIC ERROR CHECKING
*
CLOS    LDX ACCU
        DEX
        DEX
        JSR CLOSRA
        JMP GETS2
*
* P-CODE 32: PRTI
*****************
*
PRTI    JSR FETCH
        PHA
        AND =$7F
        JSR PRTCHR0
        PLA
        BPL PRTI
        RTS
*
* P-CODE 33: GHGH       (GET HIGH)
*****************
*
GHGH    LDA ACCU+1
        STA ACCU
*
* P-CODE 34: GLOW
*****************
*
GLOW    LDA =0
        STA ACCU+1
        RTS
*
* P-CODE 35:PHGH
****************
*
PHGH    LDY =126
        LDA (SP),Y
        STA ACCU+1
        JMP DECS2
*
* P-CODE 36: PLOW
*****************
*
PLOW    LDY =126
        LDA (SP),Y
        STA ACCU
        JMP DECS2
*
* P-CODE 37: GSEC
*****************
* DEVICE HAS TO BE SET  ########
*
GSEC    JSR PREPSEC
        JMP READ
        JMP ENDDO
*
* P-CODE 38: PSEC
*****************
* DEVICE HAS TO BE SET  ########
*
PSEC    JSR PREPSEC
        JSR WRITE
        JMP ENDDO
*
PREPSEC LDA ACCU
        LDX ACCU+1
        STA DATA
        STX DATA+1
        LDY =126
        LDA (SP),Y
        STA SECTOR
        LDY =124
        LDA (SP),Y
        STA TRACK
        LDA SP
        SEC
        SBC =4
        JSR DECS2+5
        JSR GETS2
        JMP PREPDO
*
* P-CODE 39: NBYT       LOAD N BYTES IMMEDIATELY
*****************
*
NBYT    JSR FETCH
        TAX             BYTE COUNTER
NBYT1   JSR COPY
        JSR FETCH
        STY ACCU+1      Y=0
        STA ACCU
        DEX
        BNE NBYT1
        RTS
*
* P-CODE 3A: NWRD       LOAD N WORD IMMEDIATELY
*****************
*
NWRD    JSR FETCH
        TAX             WORD COUNTER
NWRD1   JSR COPY
        JSR FETCH
        STA ACCU
        JSR FETCH
        STA ACCU+1
        DEX
        BNE NWRD1
        RTS
*
* P-CODE 3B: LODN       LOAD N MORE WORDS
*****************
*
LODN    JSR FETCH
        TAX
LODN1   JSR COPY
        LDA ABASE
        CLC
        ADC =2
        STA ABASE
        BCC *+4
        INC ABASE+1
        JSR LOAD2
        DEX
        BNE LODN1
        RTS
*
* P-CODE 3C: STON       STORE N MORE WORDS
*****************
*
STON    JSR FETCH
        TAX
STON1   LDA ABASE
        SEC
        SBC =2
        STA ABASE
        BCS *+4
        DEC ABASE+1
        JSR STOR2
        DEX
        BNE STON1
        RTS
*
* P-CODE 3D: LODI       LOAD INDIRECT
*****************
*
LODI    JSR GETACC
        JMP LOAD2
*
GETACC  LDA ACCU
        LDX ACCU+1
        SEC
        SBC =128
        BCS *+3
        DEX
        STA ABASE
        STX ABASE+1
        RTS
*
* P-CODE 3E: STOI       STORE INDIRECT
*****************
*
STOI    JSR GETACC
        JSR GETS2
        JMP STOR2
*
* P-CODE 3F: EXST       EXCHANGE STACK
*****************
*
EXST    LDY =126
        LDA (SP),Y
        TAX
        LDA ACCU
        STA (SP),Y
        STX ACCU
        INY
        LDA (SP),Y
        TAX
        LDA ACCU+1
        STA (SP),Y
        STX ACCU+1
        RTS
*
* P-CODE 40 TIND        TEST INDEX
****************
*
TIND    JSR FETCH       LOWLIM-1
        TAX
        JSR FETCH
        CPX ACCU
        SBC ACCU+1
        BVS TINDERR
*
        JSR FETCH       HIGHLIM
        TAX
        JSR FETCH
        CPX ACCU
        SBC ACCU+1
        BCC TINDERR
        RTS
*
TINDERR LDX =$83        RUNTIME ERROR
        JMP PERROR      INDEX OUT OF BOUNDS
*
* P-CODE 41: RUNP       RUN PROGRAM
*****************
*
RUNP    LDY =130
        LDA ACCU        SAVE ACCU
        LDX ACCU+1
        JSR SAVE
        LDA BASE        SAVE BASE
        LDX BASE+1
        JSR SAVE
        LDA PC          SAVE PC
        LDX PC+1
        JSR SAVE
        LDA STPROG      SAVE STPROG
        LDX STPROG+1
        JSR SAVE
        LDA EOPROG      SAVE EOPROG
        LDX EOPROG+1
        JSR SAVE
        LDA SP          GET SP
        LDX SP+1
        CLC
        ADC =140
        BCC *+3
        INX             COMPUTE NEW STPROG
        JMP EXEC3
*
*
SAVE    STA (SP),Y
        INY
        TXA
        STA (SP),Y
        INY
        RTS
*
*
GETBACK DEY
        LDA (SP),Y
        TAX
        DEY
        LDA (SP),Y
        RTS
*
*
* P-CODE 42: ADDF
*****************
*
ADDF    JSR GETFLP2
        JSR FADD
*
PUTFLP0 LDA SP          DECREMENT SP BY 4
        SEC
        SBC =4
        STA SP
        BCS PUTFLP
        DEC SP+1
PUTFLP  LDA M1+1        AND SAVE HALF OF NUMBER
        LDY =126
        STA (SP),Y
        INY
        LDA M1+2
        STA (SP),Y
        RTS
*
GETFLP2 LDY =122        GET SECOND NUMBER
        LDA (SP),Y
        STA M2+1
        INY
        LDA (SP),Y
        STA M2+2
        INY
        LDA (SP),Y
        STA X2
        INY
        LDA (SP),Y
        STA M2
GETFLP  LDY =126        AND HALF OF FIRST
        LDA (SP),Y
        STA M1+1
        INY
        LDA (SP),Y
        STA M1+2
        RTS
*
* P-CODE 43: SUBF
*****************
*
SUBF    JSR GETFLP2
        JSR FSUB
        JMP PUTFLP0
*
* P-CODE 44: MULF
*****************
*
MULF    JSR GETFLP2
        JSR FMUL
        JMP PUTFLP0
*
* P-CODE 45: DIVF
*****************
*
DIVF    JSR GETFLP2
        JSR FDIV
        JMP PUTFLP0
*
* P-CODE 46: FLOF
*****************
*
FLOF    LDA ACCU
        STA M1+1        HIGH BYTE IS IN ACCU
*                       SAME AS M1
        JSR FLOAT
        JSR INCS2
        JMP PUTFLP
*
* P-CODE 47: FIXF
*****************
*
FIXF    JSR GETFLP
        JSR FIX
        LDA M1+1
        STA ACCU
        JMP DECS2
*
* P-CODE 48: FEQU       =
*****************
*
FEQU    JSR TESTF
        BEQ TRUE
*
FALSE   LDX =0
        STX ACCU
        STX ACCU+1
DECS6   LDA SP
        SEC
        SBC =6
        STA SP
        BCS *+4
        DEC SP+1
        RTS
*
TRUE    LDX =1
        STX ACCU
        DEX
        STX ACCU+1
        JMP DECS6
*
TESTF   JSR GETFLP2
        JSR FSUB
        LDA M1
        RTS
*
* P-CODE 49: FNEQ       <>
*****************
*
FNEQ    JSR TESTF
        BNE TRUE
        BEQ FALSE
*
* P-CODE 4A: FLES       <
*****************
*
FLES    JSR TESTF
        BPL FALSE
        BMI TRUE
*
* P-CODE 4B: FGRE       >=
*****************
*
FGRE    JSR TESTF
        BPL TRUE
        BMI FALSE
*
* P-CODE 4C: FGRT       >
*****************
*
FGRT    JSR TESTF
        BMI FALSE
        BEQ FALSE
        BPL TRUE
*
* P-CODE 4D: FLEE       <=
*****************
*
FLEE    JSR TESTF
        BMI TRUE
        BEQ TRUE
        BPL FALSE
*
* P-CODE 4E: FCOM       COMPLEMENT
*****************
*
FCOM    JSR GETFLP
        JSR FCOMPL
        JMP PUTFLP
*
*
* P-CODE 4F: TFER       TEST FILE ERROR
*****************
*
TFER    LDX IOCHECK
        BEQ TFER1
        LDX FILERR
        BNE TFER2
TFER1   RTS             OK
*
TFER2   JMP PERROR
*
* P-CODE 50: OPRA       OPEN RA-FILE
*****************
*
OPRA    JSR COPY        SAVE ACCU
        JSR OPENRA      OPEN FILE
        INY
        INY
        STY ACCU        SAVE FILE NO
        LDA =0
        STA ACCU+1
        RTS
*
* P-CODE 51: GETR       GET FROM RA FILE
*****************
*
* NO AUTOMATIC ERROR CHECKING
*
GETR    JSR GETR1
        JSR GETBYTE
        STA ACCU
        LDA =0
        STA ACCU+1
        RTS
*
GETR1   JSR DECS2
        LDY =128
        LDA (SP),Y      GET FILE NO
        TAX
        DEX
        DEX
        LDA ACCU        GET POINTER
        LDY ACCU+1
        RTS
*
* P-CODE 52: PUTR       PUT TO RA=FILE
*****************
*
* NO AUTOMATIC ERROR CHECKING
*
PUTR    LDA ACCU
        STA KCHAR
        JSR GETS2
        JSR GETR1
        JSR PUTBYTE
        JMP GETS2
*
* P-CODE 53: SWA2       SWAP 2 AND 3 ON STACK
*****************
*
SWA2    LDY =126
        JSR SWA3
        LDY =127
*
SWA3    LDA (SP),Y
        TAX
        DEY
        DEY
        LDA (SP),Y
        INY
        INY
        STA (SP),Y
        TXA
        DEY
        DEY
        STA (SP),Y
        RTS
*
* P-CODE 54: LDXI       PREPARE LOAD CPNT
*****************
*
LDXI    LDY =0          INDIRECTION
        LDA ACCU+1
        BEQ NILERR
        LDA (ACCU),Y
        STA ACCU
        STY ACCU+1
        RTS
*
* P-CODE 55: STXI       STORE CPNT INDEXED
*****************
*
STXI    JSR FETCH
        TAX
        LDY =126
        LDA (SP),Y
        STA ARG2
        INY
        LDA (SP),Y
        STA ARG2+1      ARG2 IS INDEX
        JSR FETCH
        STA ARG1
        JSR FETCH
        STA ARG1+1      ARG1 IS ADDRESS
        JSR DECS2       OF VARIABLE
        JSR FBASE3
        JSR INDI        INDIRECTION
        CLC
        LDA ABASE
        ADC ARG2        ADD INDEX
        STA ABASE
        LDA ABASE+1
        ADC ARG2+1
        STA ABASE+1
        CMP EOPROG+1    DO NOT ALLOW WRITING
        BCC PRGERR      INTO PROGRAM SPACE
        BEQ PRGERR      CHECK ONLY HIGH BYTE
        LDY =0          MUST BE LARGER
        LDA ACCU
        STA (ABASE),Y   ONLY ONE BYTE
        JMP GETS2
*
PRGERR  LDX =$90
        JMP PERROR
*
NILERR  LDX =$89        CPNT IS NIL
        JMP PERROR
*
INDI    LDY =129        INDIRECTION
        LDA (ABASE),Y
        BEQ NILERR      NIL STRING
        TAX
        DEY
        LDA (ABASE),Y   POINTER IS IN A,X
        STA ABASE
        STX ABASE+1
        RTS
*
* P-CODE 56: CPNT       CPNT CONSTANT
*****************
*
CPNT    JSR COPY
        JSR FETCH       STRING SIZE IN A
        TAX
        INX
        LDA PC          PC IS POINTER
        STA ACCU        TO RETURN
        LDA PC+1
        STA ACCU+1
        TXA
        CLC
        ADC PC          ADVANCE PC
        STA PC
        BCC *+4
        INC PC+1
        RTS
*
* P-CODE 57: WRCP       WRITE CPNT
*****************
*
WRCP    LDY =0
        LDA (ACCU),Y
        BEQ WRCP2
        JSR PRTCHR0     END MARK
        INY
        CPY =63
        BNE WRCP+2
WRCP2   JMP GETS2
*
* GETCHR0: GET A CHAR FROM SPECIFIED FILE
*****************************************
*
GETCHR0 LDX DEVICE
        BNE GETCHR4
*
GETCHR1 LDX BUFFPN
        BPL GETCHR2
        JSR RLIN
        JMP GETCHR1
*
GETCHR2 CPX ENDBUF      IS IS END OF BUFFER?
        BNE GETCHR3
        LDA =$FF
        STA BUFFPN
        LDA =$D
        RTS
*
GETCHR3 INC BUFFPN
        LDA LINBUF,X
        RTS
*
GETCHR4 DEX
        BNE GETCHR5     SKIP, IF NOT KEY
        JMP GETKEY
*
GETCHR5 DEX
        LDA =0
        STA FILFLG
        JSR READCH
        JMP TFER
*
GETCHR6 RTS
*
* PRTCHR0: PRINT CHAR TO SPECIFIED FILE
***************************************
*
PRTCHR0 LDX DEVICE
        BMI PRTCHR3     Plot text?
        BNE PRTCHR1
        JMP PRTCHR
*
PRTCHR1 DEX
        BNE PRTCHR2
        JMP AUTOPR
*
PRTCHR2 DEX
        LDY =0
        STY FILFLG
        JSR WRITCH
        JMP TFER
*
PRTCHR3 CMP =$0D        Plot CR?
        BNE PRTCHR4
        LDA =0
        STA GRX
PRTCHRE RTS
*
PRTCHR4 CMP =$0A        PLOT LF?
        BNE PRTCHR6
        LDA GRY
        SBC =8
        BPL PRTCHR5
        LDA =0
*
PRTCHR5 STA GRY
        RTS
*
PRTCHR6 STA GRC
        JMP APLOTCH     PLOT THE CHARACTER
*
* PERROR: PASCAL RUNTIME ERROR
******************************
*
PERROR  LDA =47         CHECK CHARS/LINE
        CMP NUMCHR
        BEQ PERROR0
        STA NUMCHR      SET TO 48 CHARS/LINE
        JSR PRTINF      AND CLEAR SCREEN
        BYT $01,$91     HOME,CLRSCR
PERROR0 JSR PRTINF
        BYT $D,$A,7,'Pascal error '+128
        LDA =0
        STA DEVICE
        TXA
        STA RUNERR
        JSR PRTBYT
        LDA PC
        SEC
        SBC STPROG
        STA ACCU
        LDA PC+1
        SBC STPROG+1
        STA ACCU+1
        BEQ PERROR1
        BMI PERROR1
        JSR PRTINF
        BYT ' at '+128
        JSR PRTN
        JSR PRTINF
        BYT $D,$8A
*
PERROR1 JMP STOP
*
*
* WARM START ENTRY POINT
************************
*
WARMST  LDA SFLAG       SET PASCAL RUNTIME BIT
        ORA =$01        IN SFLAG
        STA SFLAG
        TSX
        STX SAVS        SAVE STACK POINTER
        LDX =0
        STX PC+1
        STX DEVICE
        DEX
        STX ENDBUF
        STX IOCHECK
        LDX =0
*
EXEC    LDY =0
        STY PC+1
        LDA EXTABLE,X
        STA FILNM1,X
        INX
        INY
        CPY =16
        BCC EXEC+2
        LDA =0
        STA FILCY1
*
EXECUTE LDA =0
        STA FILFLG
        LDA USEREND
        LDX USEREND+1
        SEC
        SBC =144
        BCS *+3
        DEX
        STA ENDSTK
        STX ENDSTK+1
*
EXEC1   LDA USERST
        LDX USERST+1
EXEC3   STA STPROG
        STX STPROG+1
        STA FILSA1
        STX FILSA1+1
        JSR RDFILE      READ FILE TO EXECUTE
        BNE EXECE       PROGRAM NOT LOOADED?
*
        LDA FILSTP
        CMP ='R'        IS PASCAL PROGRAM?
        BEQ RUN
EXECE   LDA =$84        PASCAL RUNPROG ERROR
        STA RUNERR
        JMP STOP        SILENT ERROR
*
RUN     LDY =0          READ END ADDRESS
        LDA (STPROG),Y  FROM FILE
        CLC
        ADC STPROG
        STA EOPROG
        INY
        LDA (STPROG),Y
        ADC STPROG+1
        STA EOPROG+1
        LDA EOPROG      GET END OF STACK
        LDX EOPROG+1
        SEC
        SBC =128
        STA BASE
        STA SP
        BCS *+3
        DEX
        STX BASE+1
        STX SP+1
*
        LDA STPROG
        LDX STPROG+1
        CLC
        ADC =2
        STA PC
        BCC *+3
        INX
        STX PC+1
        LDA =0
        STA RUNERR
LOOP    LDX SAVS        RESTORE STACK POINTER
        TXS
        JSR EXCODE
        LDA SFLAG
        BMI ESCERR
        JMP LOOP
*
*
EXCODE  JSR FETCH
        STA =$F1
        CMP =$58        TEST CODENUMBER
        BCC *+7
ILLC    LDX =$86        PASCAL RUNTIME ERROR
        JMP PERROR      ILLEGAL P-CODE
*
        ASL A
        TAX
        LDA TABLE,X
        STA ARG1
        LDA TABLE+1,X
        STA ARG1+1
        JMP (ARG1)
*
ESCERR  LDA SFLAG       CLEAR ESCAPE FLAG
        AND =$7F
        STA SFLAG
        LDX =$86        PASCAL RUNTIME ERROR
        JMP PERROR      ESCAPE DURING EXECUTION
*
EXTABLE BYT 'SYSTEM:R        '
*
TABLE   WRD STOP,RETN,NEGA,ADDA,SUBA,MULA
        WRD DIVA,LOWB,TEQU,TNEQ,TLES,TGRE
        WRD TGRT,TLEE,ORAC,ANDA,EORA,NOTA
        WRD LEFT,RIGH,INCA,DECA,COPY,PEEK
        WRD POKE,CALA,RLIN,GETC,GETN,PRTC
        WRD PRTN,PRTS,LITB,INCB,LITW,INCW
        WRD JUMP,JMPZ,JMPO,LOAD,LODX,STOR
        WRD STOX,CALL,SDEV,RDEV,FNAM,OPNR
        WRD OPNW,CLOS,PRTI,GHGH,GLOW,PHGH
        WRD PLOW,GSEC,PSEC,NBYT,NWRD,LODN
        WRD STON,LODI,STOI,EXST,TIND,RUNP
        WRD ADDF,SUBF,MULF,DIVF,FLOF,FIXF
        WRD FEQU,FNEQ,FLES,FGRE,FGRT,FLEE
        WRD FCOM,TFER,OPRA,GETR,PUTR,SWA2
        WRD LDXI,STXI,CPNT,WRCP
*
* COLDSTART
***********
*
COLDST  CLI
        CLD
        LDA USERST
        LDX USERST+1
        STA STPROG
        STX STPROG+1
        LDY =0
        TYA
        STA (STPROG),Y
        INY
        CPY =4
        BCC *-5
        JMP WARMST
*
        TIT R65 PASCAL: FLP-MATH
        PAG
*
********************************
* R65 PASCAL FLP MATH ROUTINES *
********************************
*
*
ADD     CLC
        LDX =2
ADD1    LDA M1,X
        ADC M2,X
        STA M1,X
        DEX
        BPL ADD1
        RTS
*
MD1     ASL SIGN
        JSR ABSWAP
ABSWAP  BIT M1
        BPL ABSWP1
        JSR FCOMPL
        INC SIGN
ABSWP1  SEC
*
* SWAP: EXCHANGE F1 AND F2
**************************
*
SWAP    LDX =4
SWAP1   STY E-1,X
        LDA <(X1-1),X
        LDY X2-1,X
        STY <(X1-1),X
        STA X2-1,X
        DEX
        BNE SWAP1
        RTS
*
* FLOAT: FLOAT M1,M1+1 TO RESULT IN F1
**************************************
*
FLOAT   LDA =$8E
        STA X1
        LDA =0
        STA M1+2
        BEQ NORM
NORM1   DEC X1
        ASL M1+2
        ROL M1+1
        ROL M1
NORM    LDA M1
        ASL A
        EOR M1
        BMI RTS1
        LDA X1
        BNE NORM1
RTS1    RTS
*
* FSUB: F1=F2-F1
****************
*
FSUB    JSR FCOMPL
SWPALG  JSR ALGNSW
*
* FADD: F1=F2+F1
****************
*
FADD    LDA X2
        CMP X1
        BNE SWPALG
        JSR ADD
ADDEND  BVC NORM
        BVS RTLOG
ALGNSW  BCC SWAP
RTAR    LDA M1
        ASL A
RTLOG   INC X1
        BEQ OVFL
RTLOG1  LDX =$FA
ROR1    LDA =$80
        BCS ROR2
        ASL A
ROR2    LSR E+3,X
        ORA E+3,X
        STA E+3,X
        INX
        BNE ROR1
        RTS
*
* FMUL: F1=F2*F1
****************
*
FMUL    JSR MD1
        ADC X1
        JSR MD2
        CLC
MUL1    JSR RTLOG1
        BCC MUL2
        JSR ADD
MUL2    DEY
        BPL MUL1
MDEND   LSR SIGN
NORMX   BCC NORM
FCOMPL  SEC
        LDX =3
COMPL1  LDA =0
        SBC X1,X
        STA X1,X
        DEX
        BNE COMPL1
        BEQ ADDEND
*
* FDIV: F1=F2/F1
****************
*
FDIV    JSR MD1
        SBC X1
        JSR MD2
FDIV1   SEC
        LDX =2
FDIV2   LDA M2,X
        SBC E,X
        PHA
        DEX
        BPL FDIV2
        LDX =$FD
FDIV3   PLA
        BCC FDIV4
        STA M2+3,X
FDIV4   INX
        BNE FDIV3
        ROL M1+2
        ROL M1+1
        ROL M1
        ASL M2+2
        ROL M2+1
        ROL M2
        BCS OVFL
        DEY
        BNE FDIV1
        BEQ MDEND
MD2     STX M1+2
        STX M1+1
        STX M1
        BCS OVCHK
        BMI MD3
        PLA
        PLA
        BCC NORMX
MD3     EOR =$80
        STA X1
        LDY =$17
        RTS
OVCHK   BPL MD3
OVFL    JMP DIV1-5      PASCAL RUNTIME ERROR
*
* FIX: FIX F1 IN M1, M1+1
*************************
*
        JSR RTAR
FIX     LDA X1
        CMP =$8E
        BNE FIX-3
RTRN    RTS
*
        TIT R65 PASCAL: RANDOM ACCESS
        PAG
*
* RANDOM ACCESS FILE HANDLER
****************************
*
*
* OPENRA: OPEN A FILE FOR RANDOM ACCESS
***************************************
*
* ENTRY: FILNM1,FILCY1,FILDRV,FILFLG
* FILFLG: BIT 7: PROTECTED (NEW ONLY)*
*         BIT 6: NO PRINTED OUTPUT
*         BIT 5: DIRECTION (0=READ)
*         BIT 4: 1=NEW, 0=OLD
*
* NEW ONLY: MAXSIZ,FILSA
*
* EXIT: NO OF OPEN FILE IN Y, STATUS IN A
*       AND FILERR, Y IS ONLY VALID
*       IF A=0
*
*
OPENRA  LDY MAXSEQ      SEARCH EMPTY ENTRY
        LDA FIDRTB,Y    BIT 5=1: ENTRY USED
        AND =$20
        BEQ OPENRA1     FOUND, SKIP
        DEY
        BPL OPENRA+3
*
        LDA =$23        TOO MANY OPEN FILES
        STA FILERR
        RTS
*
OPENRA1 STY CURSEQ      SAVE CURRENT ENTRY NO
        LDA FILDRV      GET AND TEST DRIVE
        STA FIDVTB,Y
        AND =$FE
        BEQ OPENRA2     SKIP, IF OK
*
        LDA =$28        ILLEGAL DRIVE FOR RA
        STA FILERR
        RTS
*
OPENRA2 LDA =$10        TEST OLD/NEW FLAG
        AND FILFLG
        BEQ OPENOLD     SKIP, IF OLD
*
* OPEN A NEW FILE
*
OPENNEW LDA FILFLG
        AND =$80        GET PROTECTED FLAG
        ORA ='B'        BLOCK FILE
        STA FILTYP      SET FILE TYPE
*
        LDA =0
        LDX MAXSIZ      SIZE OF FILE
        STA FILSIZ
        STX FILSIZ+1
*
        DEX             COMPUTE FILEA
        LDA FILSA
        CLC
        ADC =$FF
        STA FILEA
        TXA
        ADC FILSA+1
        STA FILEA+1
*
        JSR SETFID      SET FILEDATE
*
        LDX =16
OPENNE1 LDA FILNM1,X    SET FILNM1 AND FILCY1
        STA FILNAM,X    TO FILNAM AND FILCYC
        DEX
        BPL OPENNE1
*
* SEARCH IN DIRECTORY AND RETURN CYCLUS
* AND DIRECTORY ENTRY TO USE, TEST EXISTING
* FILES FOR SAME NAME AND CYCLUS, DISK
* OPERATION IS INITIALIZED
*
        JSR PREPWRA
        STX FILCYC
*
* FIND FIRST EMPTY DISK DIRECTORY ENTR
* FETCH ITAND SET FIRST SECTOR OF FILE TO
* FILLOC, OUTPUT Y,X AS NUMBER OF EMPTY
* SECTORS
*
        JSR PREPWRB
        TXA
        CMP FILSIZ+1
        TYA
        SBC =0          COMPARE WITH REQUESTED
        BCS OPENNE3     SECTORS
*
        LDA =$26        DISK OVERFLOW
        JMP DISCER1
*
* SET FITEMP,Y AND FITEMP+8,YNTO FIRST SECTOT
* OF FILE ON DISK, FIMAXT,Y TO SIZE, DIRECTORY
* ENTRY NO TO FITEMP+16,Y
* THEN PUT THIS ENTRY ONTO THE DISKMAND SET
* A NEW END OF DIRECTORY MARK
*
OPENNE3 JSR DOPEN4
*
        LDY CURSEQ      SETUP DUMMY FIRST SECTOR
        LDA =0
        STA FIBPTB,Y
        STA FIRCTB,Y
*
OPENNE4 LDY CURSEQ      OPEN FILE
        LDA FILFLG
        ASL A
        ASL A
        AND =$80        GET DIRECTION
        PHA
        AND FILTYP
        BEQ OPENNE5     OK, SKIP
        PLA             PROTECTED FILE
*
        LDA =$29
        STA FILERR
        RTS
*
OPENNE5 PLA
        ORA =$60        RA FILE, OPENIT
        STA FIDRTB,Y
*
        LDA =0          NORMALEXIT
        STA FILERR
OPENNE6 RTS
*
* OPEN AN OLD FILE:
* PREPARE DISK OPERATION, SEARCH REQUESTED
* FILE AND GET CORRSPONDING DISK ENTRY
*
OPENOLD JSR PREPRD
*
        JSR PRFLB1      PRINT LABEL, IF REQ.
        LDA FILTYP
        AND =$7F
        CMP ='B'        MUST BE BLOCK FILE
        BEQ OPENOL1     SKIP, IF OK
*
        LDA =5
        JMP DISCER1     FILE TYPE ERROR
*
OPENOL1 JSR ENDDO       END OF DISK OPERATION
*
* SET NOW FIRST SECTOR AND SIZE TO TABLE
*
        JSR DOPEN1
*
        LDA =0          GET FIRST RECORD
        JSR GETTREC
        BNE OPENNE6     SKIP, IF NOT OK
        BEQ OPENNE4     ELSE OPEN FILE
*
*
* GETTREC: GET ONE RECORD FROM RA-FILE
* RECORD NUMBER IS IN A, FILE NUMBER IN CURSEQ
* RESULT IUS Z=1,OF OK, ELSE Z=0 AND FILERR
*
GETTREC LDX CURSEQ      SAVE RECORD NO
        STA FIRCTB,X
        LDA =0          CLEAR UPDATED FLAG
        STA FIBPTB,X
        LDA FIDVTB,X    SET DRIVE NO
        STA FILDRV
*
* COMPUTE DATA-POINTER AND BINARY
* TRACK,SECTOR, SETUP FILDRV
*
        JSR PREPSR
*
* ADD RECORD NUMBER TO BINARY TRAC/SECTOR
* TEST SIZE OF FILE, CONVERT TO TRACK AND
* SECTOR, INITIALIZE DISK OPERATION
*
        JSR PREPSR1
*
        JSR READ        READ ON SECTOR
*
        JMP ENDDO       END OF DISK OPERATION
*
* PUTTREC: SAVE CURRENT RECORD ON DISK
* FILE NUMBER IN CURSEQ, RECORD NUMBER IN
* FIRCTB,Y, RETURNS Z=1 IF OK, ELSE FILERR
*
PUTTREC LDA FIDVTB,X
        STA FILDRV
        JSR PREPSR      SEE GETTREC FOR
        JSR PREPSR1     COMMENTS
        JSR WRITE
        JMP ENDDO
*
* GETNEWR: GET A NEW RECORD, SAVE OLD, IF
* OLD HAS BEEN UPDATED
* ENTRY: NEW RECORD IN A, FILE NO IN CURSEQ
* EXIT: z=1 IF OK, ELSE FILERR
*
GETNEWR STA SAVRST+1    SAVE REQUESTED RECORD
        LDX CURSEQ
        LDA FIBPTB,X    UPDATED?
        BPL GETNEW1
*
        JSR PUTTREC     YES, SAVE IT
        BNE EXIT
*
GETNEW1 LDA SAVRST+1    GET REQUESTED RECORD
        JMP GETTREC
*
* GETBYTE: GET ONE BYTE FROM FILE
*********************************
* ENTRY: FILE NUMBER IN X
*        POINTER IN A(LOW) AND Y(HIGH)
* EXIT:  FILERR IN Y AND STATUS, BYTE IN A
*
GETBYTE STA SAVRST      SAVE A
        JSR TESTRA
*
        TYA
        CMP FIRCTB,X    IS IT IN CURRENT RECORD?
        BEQ GETBYT1     YES, SKIP
*
        JSR GETNEWR     NO, GET NEW RECORD
        BNE EXIT
*
GETBYT1 JSR CPOINT      COMPUTE BUFFER PNT
        LDY SAVRST      RESTORE LOW POINTER
        LDA (POINT),Y   GET THE BYTE
        LDY =0
        STY FILERR      OK
EXIT    RTS
*
* PUTBYTE: PUT ONE BYTE TO FILE
*******************************
*
* ENTRY: BYTE STORED IN KCHAR
*        FILE NUMBER IN X
*        POINTER IN A(LOW) AND Y(HIGH)
* EXIT:  FILERR IN Y AND STATUS
*
PUTBYTE STA SAVRST
        JSR TESTRA
        LDA FIDRTB,X    IS WRITE ALLOWED?
        BMI PUTBYT0     YES,SKIP
        LDY =$29        WRITE NOT ALLOWED
        STY FILERR
        RTS
*
PUTBYT0 TYA             FOR COMMENTS
        CMP FIRCTB,X    SEE GETBYTE
        BEQ PUTBYT1
*
        JSR GETNEWR
        BNE EXIT
*
PUTBYT1 JSR CPOINT
        LDA =$80        SET UPDATED FLAG
        STA FIBPTB,X
        LDY SAVRST
        LDA KCHAR       GET BACK KCHAR
        STA (POINT),Y
        LDY =0
        STY FILERR
        RTS
*
*
* TESTRA: TEST X FOR LEGAL RA-FILE
*
TESTRA  STX CURSEQ
        CPX MAXSEQ
        BCS TESTRA2
*
TESTRA1 LDA FIDRTB,X
        AND =$60
        CMP =$60
        BNE TESTRA3     SKIP, IF NOT OK
        RTS
*
TESTRA2 BEQ TESTRA1
TESTRA3 PLA
        PLA
        LDY =$25        FILE NUMBER NOT ALLOWED
        STY FILERR
        RTS
*
* CLOSRA: CLOSE RA OR SEQUENTIAL FILE IN X
******************************************
* ENTRY: FILE IN X
* EXIT: FILERR IN Y AND STATUS
*
CLOSRA  LDA FIDRTB,X
        AND =$40        SEQUENTIAL FILE?
        BNE CLOSRA1     NO, SKIP
        JMP CLOSE       YES, CLOSE IT
*
CLOSRA1 JSR TESTRA      MUST BE RA-FILE
        LDA FIBPTB,X    UPDATED?
        BEQ CLOSRA2     NO, SKIP
*
        JSR PUTTREC
        BNE CLOSRA3
*
CLOSRA2 LDX CURSEQ
        LDA =0
        STA FIDRTB,X    CLOSE IT
        TAY
        STY FILERR
CLOSRA3 RTS
*
ENDCODE EQU *
*
        TIT R65 PASCAL: LABELS
*
        END















