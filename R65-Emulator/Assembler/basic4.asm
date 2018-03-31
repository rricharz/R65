* BASIC4:A ORIGINAL 7/1/1982, RECOVERED 3/2018
        SBC EXP
        BEQ ADD2
        BCC ADD1
        STY EXP
        LDY DYADIC+5
        STY SIGN
        EOR =$FF
        ADC =0
        LDY =0
        STY PNT1+1
        LDX =<EXP
        BNE *+6
ADD1    LDY =0
        STY DYADIC+7
        CMP =$F9
        BMI ADD-8
        TAY
        LDA DYADIC+7
        LSR 1,X
        JSR ROR4
*
ADD2    BIT DYADIC+6
        BPL ADD3        SKIP, IF ADD
        LDY =<EXP
        CPX =<DYADIC
        BEQ *+4
        LDY =<DYADIC
        SEC
        EOR =$FF
        ADC PNT1+1
        STA DYADIC+7
        LDA 4,Y
        SBC 4,X
        STA MANT+3
        LDA 3,Y
        SBC 3,X
        STA MANT+2
        LDA 2,Y
        SBC 2,X
        STA MANT+1
        LDA 1,Y
        SBC 1,X
        STA MANT
*
NORMAL  BCS *+5
        JSR COMPL
        LDY =0
        TYA
        CLC
NORM1   LDX MANT
        BNE ADD4
        LDX MANT+1
        STX MANT
        LDX MANT+2
        STX MANT+1
        LDX MANT+3
        STX MANT+2
        LDX DYADIC+7
        STX MANT+3
        STY DYADIC+7
        ADC =8
        CMP =32
        BNE NORM1
*
UNDERF  LDA =0          UNDERFLOW, SET TO 0
        STA EXP
        STA SIGN
        RTS
*
ADD3    ADC PNT1+1
        STA DYADIC+7
        LDA MANT+3
        ADC DYADIC+4
        STA MANT+3
        LDA MANT+2
        ADC DYADIC+3
        STA MANT+2
        LDA MANT+1
        ADC DYADIC+2
        STA MANT+1
        LDA MANT
        ADC DYADIC+1
        STA MANT
        JMP ADD5
*
        ADC =1          SHIFT MANTISSA
        ASL DYADIC+7
        ROL MANT+3
        ROL MANT+2
        ROL MANT+1
        ROL MANT
ADD4    BPL *-12
        SEC
        SBC EXP
        BCS UNDERF
        EOR =$FF
        ADC =1
        STA EXP
ADD5    BCC ADDEND
        INC EXP
        BEQ OVERFL
*
ROR1    ROR MANT
        ROR MANT+1
        ROR MANT+2
        ROR MANT+3
        ROR DYADIC+7
ADDEND  RTS
*
* COMPL: COMPLEMENT MANTISSA
****************************
*
COMPL   LDA SIGN
        EOR =$FF
        STA SIGN
        LDA MANT
        EOR =$FF
        STA MANT
        LDA MANT+1
        EOR =$FF
        STA MANT+1
        LDA MANT+2
        EOR =$FF
        STA MANT+2
        LDA MANT+3
        EOR =$FF
        STA MANT+3
        LDA DYADIC+7
        EOR =$FF
        STA DYADIC+7
        INC DYADIC+7
        BNE *+16
INCM    INC MANT+3
        BNE *+12
        INC MANT+2
        BNE *+8
        INC MANT+1
        BNE *+4
        INC MANT
        RTS
*
*
OVERFL  LDX =$32        NUM OVERFLOW
        JMP ERROR
*
*
* ROTATE RIGHT
**************
*
ROR2    LDX =<TEMP9-1
        LDY 4,X
        STY DYADIC+7
        LDY 3,X
        STY 4,X
        LDY 2,X
        STY 3,X
        LDY 1,X
        STY 2,X
        LDY DYADIC-1
        STY 1,X
ROR2A   ADC =8
        BMI ROR2+2
        BEQ ROR2+2
        SBC =8
        TAY
        LDA DYADIC+7
        BCS ROR5
ROR3    ASL 1,X
        BCC *+4
        INC 1,X
        ROR 1,X
        ROR 1,X
ROR4    ROR 2,X
        ROR 3,X
        ROR 4,X
        ROR A
        INY
        BNE ROR3
ROR5    CLC
        RTS
*
*
* PREPMO: PREPARE MATH OPERATION
********************************
*
PREPMO  STA TEMP1
        STY TEMP1+1
        LDY =4
        LDA (TEMP1),Y
        STA DYADIC,Y
        DEY
        BNE *-6         LOOP UNTIL DONE
        EOR SIGN
        STA DYADIC+6
        LDA DYADIC+1
        STA DYADIC+5
        ORA =$80
        STA DYADIC+1
        LDA (TEMP1),Y
        STA DYADIC
        LDA EXP
        RTS
*
*
* GETFLP: GET FLP FROM A,Y
**************************
*
GETFLP  STA TEMP1
        STY TEMP1+1
        LDY =4
        LDA (TEMP1),Y
        STA MANT+3
        DEY
        LDA (TEMP1),Y
        STA MANT+2
        DEY
        LDA (TEMP1),Y
        STA MANT+1
        DEY
        LDA (TEMP1),Y
        STA SIGN
        ORA =$80
        STA MANT
        DEY
        LDA (TEMP1),Y
        STA EXP
        STY DYADIC+7
        RTS
*
*
* SAVFLP: SAVE FLP NUMBER
*************************
*
SAVFLP  LDX TEMP3
        LDY TEMP3+1
        JSR ROUND
        STX TEMP1
        STY TEMP1+1
        LDY =4
        LDA MANT+3
        STA (TEMP1),Y
        DEY
        LDA MANT+2
        STA (TEMP1),Y
        DEY
        LDA MANT+1
        STA (TEMP1),Y
        DEY
        LDA SIGN
        ORA =$7F
        AND MANT
        STA (TEMP1),Y
        DEY
        LDA EXP
        STA (TEMP1),Y
        STY DYADIC+7
        RTS
*
* ROUND: ROUND MANTISSA TO 32 BITS
**********************************
*
ROUND   LDA EXP
        BEQ *-3         RTS, IF ZERO
        ASL DYADIC+7
        BCC *-7
        JSR INCM
        BNE *-12
        JMP ROR1-4
*
* TRANS1: DYADIC TO FLP ACCU
****************************
*
TRANS1  LDA DYADIC+5
        STA SIGN
        LDX =5
        LDA DYADIC-1,X
        STA EXP-1,X
        DEX
        BNE *-5
        STX DYADIC+7
        RTS
*
* TRANS2: FLP ACCU TO DYADIC
****************************
*
TRANS2  JSR ROUND
        LDX =6
        LDA EXP-1,X
        STA DYADIC-1,X
        DEX
        BNE *-5
        STX DYADIC+7
        RTS
*
* SGN1: SET ACCU FROM SIGN
**************************
* A=1 IF SIGN+, A=FF IF SIGN-, A=0 IF EXP=0
*
SGN1    LDA EXP
        BEQ *+11        RTS, IF EXP=0
        LDA SIGN
        ROL A
        LDA =$FF
        BCS *+4
        LDA =1
        RTS
*
* SGN: BASIC FUNCTION
*********************
*
SGN     JSR SGN1
FLOAT1  STA MANT        FLOAT 1 BYTE
        LDA =0
        STA MANT+1
        LDX =$88        EXP FOR FLOAT
FLOAT2  LDA MANT        FLOAT 2 BYTES
        EOR =$FF
        ROL A           SIGN INTO C
FLOAT   LDA =0
        STA MANT+3
        STA MANT+2
        STX EXP
        STA DYADIC+7
        STA SIGN
        JMP NORMAL
*
*
* COMPAR: COMPARE FLP NUMBERS
*****************************
*
COMPAR  STA TEMP8
        STY TEMP8+1
        LDY =0
        LDA (TEMP8),Y
        INY
        TAX
        BEQ SGN1
        LDA (TEMP8),Y
        EOR SIGN
        BMI SGN1+4
        CPX EXP
        BNE COMPR1
        LDA (TEMP8),Y
        ORA =$80
        CMP MANT
        BNE COMPR1
        INY
        LDA (TEMP8),Y
        CMP MANT+1
        BNE COMPR1
        INY
        LDA (TEMP8),Y
        CMP MANT+2
        BNE COMPR1
        INY
        LDA =$7F
        CMP DYADIC+7    TO C
        LDA (TEMP8),Y
        SBC MANT+3
        BNE COMPR1
        RTS
*
COMPR1  LDA SIGN
        BCC *+4
        EOR =$FF
        JMP SGN1+6
*
*
* NUMBER: FLP CONSTANT INPUT IN EXPRES
**************************************
*
NUMBER  BCC *+10
        CMP ='$'        HEX?
        BNE *+5
        JMP NUMBHEX
        SEC
*
        LDY =0          CLEAR WORK AREA
        LDX =10
        STY EXP-4,X
        DEX
        BPL *-3
        BCC NUMB0+3     IF FIST DIGIT=NUMBER
*
        CMP ='-'
        BNE *+6
        STX CURRSG      SET CURRENT SIGN TO FF
        BEQ NUMB0       ALLWAYS TAKEN
        CMP ='+'
        BNE *+7
NUMB0   JSR FETCH
        BCC NUMB5
        CMP ='.'
        BEQ NUMB3
        CMP ='E'
        BNE NUMB4
*
        JSR FETCH       EXPONTENT
        BCC NUMB2+3
        CMP =$B8        CODE FOR -
        BEQ NUMB1
        CMP ='-'
        BEQ NUMB1
        CMP =$B7        CODE FOR +
        BEQ NUMB2
        CMP ='+'
        BEQ NUMB2
        BNE NUMB2+3     IF NOT DIGIT OR SIGN
*
NUMB1   LDA =$80        IF EXP -
        STA EXP-1
*
NUMB2   JSR FETCH       IF EXP +
        BCC NUMB7       BRANCH, IF NUMBER
        BIT EXP-1
        BPL NUMB4       BRANCH, IF POS
        LDA =0
        SEC
        SBC CURREX      ELSE COMPLEMENT CURREX
        JMP NUMB4+2
*
NUMB3   LDA =$80        DECIMAL POINT
        LSR TRANSP
        ORA TRANSP
        STA TRANSP
        BIT TRANSP
        BVC NUMB0       CONTINUE, IF FIRST POINT
*
NUMB4   LDA CURREX      END OF NUMBER
        SEC
        SBC POINTC
        STA CURREX
        BEQ *+20        SKIP, IF RESULTING
        BPL *+11        EXP=0 OR POSITIVE
        JSR DIVTEN      ELSE DIVIDE BY TEN
        INC CURREX
        BNE *-5
        BEQ *+9         ALLWAYS TAKEN
*
        JSR MULTEN
        DEC CURREX
        BNE *-5
*
        LDA CURRSG
        BMI *+3
        RTS
*
        JMP NEGATE
*
NUMB5   PHA             DIGIT ENTRY, SAVE IT
        BIT TRANSP      AFTER DECIMAL POINT?
        BPL *+4
        INC POINTC
        JSR MULTEN
        PLA
        SEC
        SBC =$30        CONVERT ASCII TO NUMBER
        JSR NUMB6
        JMP NUMB0
*
NUMB6   PHA             SAVE CONVERTED TOGIT
        JSR TRANS2      CURRENT RES TO DYADIC
        PLA
        JSR FLOAT1      FLOAT DIGIT
        LDA DYADIC+5
        EOR SIGN
        STA DYADIC+6
        LDX EXP
        JMP ADD         AND ADD TO CURRENT RESUL
*
NUMB7   LDA CURREX      EXPONENT DIGIT
        CMP =12
        BCC *+11
        BIT TRANSP+1
        BMI *+5
        JMP OVERFL
*
        LDA =11
        ASL A           MULTIPLY BY TEN
        ASL A
        CLC
        ADC CURREX
        ASL A
        CLC
        LDY =0
        ADC (PC),Y
        SEC
        SBC =$30        CONVERT ASCII TO NUMBER
        STA CURREX
        JMP NUMB2
*
*
OUTCT1  BYT $9B,$3E,$BC,$1F,$FD
        BYT $9E,$6E,$6B,$27,$FE
        BYT $9E,$6E,$6B,$28,$00
*
OUTCT2  BYT $80,$00,$00,$00,$00
        BYT $FA,$0A,$1F,$00,$00
        BYT $98,$96,$80,$FF,$F0
        BYT $BD,$C0,$00,$01,$86
        BYT $A0,$FF,$FF,$D8,$F0
        BYT $00,$00,$03,$E8,$FF
        BYT $FF,$FF,$9C,$00,$00
        BYT $00,$0A,$FF,$FF,$FF
        BYT $FF,$FF,$DF,$0A,$80
        BYT $00,$03,$4B,$C0,$FF
        BYT $FF,$73,$60,$00,$00
        BYT $0E,$10,$FF,$FF,$FD
        BYT $A8,$00,$00,$00,$3C
*
* NEGATE: NEGATE FLP ACCU
*************************
*
NEGATE  LDA EXP
        BEQ *+8         RTS, IF ZERO
        LDA SIGN
        EOR =$FF
        STA SIGN
        RTS
*
* MULTEN: MULTIPLY BY TEN
*************************
*
MULTEN  JSR TRANS2
        TAX
        BEQ *+18        RTS
        CLC
        ADC =2          *4
        BCS *+14        OVERFLOW
        LDX =0
        STX DYADIC+6
        JSR ADD+13      4+1=5
        INC EXP         2*5=10
        BEQ *+3         OVERFLOW
        RTS
        JMP OVERFL
*
* DIVTEN: DIVIDE BY TEN
***********************
*
        BYT $84,$20,0,0,0       10.0
DIVTEN  JSR TRANS2
        LDA =<(DIVTEN-5)
        LDY =>(DIVTEN-5)
        LDX =0
        STX DYADIC+6
        JSR GETFLP
        JMP DIVIDE
*
* NUMEXP: NUMERIC EXPRESSION
****************************
*
NUMEXP  JSR FETCH
        JSR EXPRES
        JSR TESTTP      MUST BE NUMERIC
        JSR FLPINT-4
        LDX MANT+2
        BNE *+7
        LDX MANT+3
        JMP FETCH1
QERR    LDX =$2A        QUANTITY ERROR
        JMP ERROR
*
* FLPINT: FLP TO INTEGER CONVERSION
***********************************
*
FLPINF  BYT $90,$80,0,0
*
        LDA SIGN
        BMI *+15
FLPINT  LDA EXP
        CMP =$90
        BCC *+11
        LDA =<FLPINF
        LDY =>FLPINF
        JSR COMPAR
        BNE QERR        QUANT ERROR, TOO LARGE
*
FLPIN1  LDA EXP
        BEQ FLPIN2
        SEC
        SBC =$A0
        BIT SIGN
        BPL *+11
        TAX
        LDA =$FF
        STA DYADIC-1
        JSR COMPL+6
        TXA
        LDX =<EXP
        CMP =$F9
        BPL *+8
        JSR ROR2A
        STY DYADIC-1
        RTS
*
        TAY
        LDA SIGN
        ROL A
        ROR MANT
        JSR ROR4
        STY DYADIC-1
        RTS
*
FLPIN2  STA MANT
        STA MANT+1
        STA MANT+2
        STA MANT+3
        TAY
        RTS
*
* TESTEQ: EQUAL, LESS AND GREATER TEST
**************************************
*
TESTEQ  JSR TESTTP+1
        BCS TESTE1
        LDA DYADIC+5    NUMERIC COMPARE
        ORA =$7F
        AND DYADIC+1
        STA DYADIC+1
        LDA =<DYADIC
        LDY =>DYADIC
        JSR COMPAR
        TAX
        JMP TESTE2+6
*
TESTE1  LDA =0          STRING COMPAR
        STA RESTYP
        DEC LOGIC
        JSR PREPST
        STA EXP
        STX MANT
        STY MANT+1
        LDA DYADIC+3
        LDY DYADIC+4
        JSR PREPST+4
        STX DYADIC+3
        STY DYADIC+4
        TAX
        SEC
        SBC EXP
        BEQ *+10
        LDA =1
        BCC *+6
        LDX EXP
        LDA =$FF
        STA SIGN
        LDY =$FF
        INX
TESTE2  INY
        DEX
        BNE *+9
        LDX SIGN
        BMI TESTE3
        CLC
        BCC TESTE3      ALLWAYS TAKEN
        LDA (DYADIC+3),Y
        CMP (MANT),Y
        BEQ TESTE2
        LDX =$FF
        BCS TESTE3
        LDX =1
TESTE3  INX
        TXA
        ROL A
        AND READFL+1
        BEQ *+4
        LDA =$FF
        JMP FLOAT1
*
* DIVIDE: FLOATING POINT DIVIDE
*******************************
*
DIVZ    LDX =$78        DIVISION BY ZERO
        JMP ERROR
*
        JSR PREPMO
DIVIDE  BEQ DIVZ
        JSR ROUND
        LDA =0          COMPL EXPONENT
        SEC
        SBC EXP
        STA EXP
        JSR MULEXP      COMPUTE RESULTING EXP
        INC EXP
        BEQ OVERF1      OVERFLOW
        LDX =$FC
        LDA =1
DIVID0  LDY DYADIC+1
        CPY MANT
        BNE DIVID1
        LDY DYADIC+2
        CPY MANT+1
        BNE DIVID1
        LDY DYADIC+3
        CPY MANT+2
        BNE DIVID1
        LDY DYADIC+4
        CPY MANT+3
DIVID1  PHP
        ROL A
        BCC *+11
        INX
        STA TEMP9+3,X
        BEQ DIVID3
        BPL DIVID3+4
        LDA =1
        PLP
        BCS *+16
DIVID2  ASL DYADIC+4
        ROL DYADIC+3
        ROL DYADIC+2
        ROL DYADIC+1
        BCS DIVID1
        BMI DIVID0
        BPL DIVID1
        TAY
        LDA DYADIC+4
        SBC MANT+3
        STA DYADIC+4
        LDA DYADIC+3
        SBC MANT+2
        STA DYADIC+3
        LDA DYADIC+2
        SBC MANT+1
        STA DYADIC+2
        LDA DYADIC+1
        SBC MANT
        STA DYADIC+1
        TYA
        JMP DIVID2
DIVID3  LDA =$40
        BNE DIVID2-3    ALLWAYS TAKEN
*
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        STA DYADIC+7
        PLP
MULEND  LDA TEMP9
        STA MANT
        LDA TEMP9+1
        STA MANT+1
        LDA TEMP9+2
        STA MANT+2
        LDA TEMP9+3
        STA MANT+3
        JMP NORMAL+5
*
OVERF1  JMP OVERFL
*
MULEXP  LDA DYADIC
        BEQ MULEX1
        CLC
        ADC EXP
        BCC *+7
        BMI OVERF1
        CLC
        BCC *+4         ALLWAYS TAKEN
*
        BPL MULEX1
        ADC =128
        STA EXP
        BNE *+5
        STA SIGN
        RTS
*
        LDA DYADIC+6
        STA SIGN
        RTS
*
        LDA SIGN
        EOR =$FF
        BMI OVERF1
MULEX1  PLA
        PLA
        LDA =0
        STA EXP
        STA SIGN
        RTS
*
* MULT: FLOATING POINT MULTIPLICATION
*************************************
*
        JSR PREPMO
MULT    BEQ *-4         RTS, IF ZERO
        JSR MULEXP
        LDA =0          CLEAR WORK AREA
        STA TEMP9
        STA TEMP9+1
        STA TEMP9+2
        STA TEMP9+3
        LDA DYADIC+7
        JSR MULBYT
        LDA MANT+3
        JSR MULBYT
        LDA MANT+2
        JSR MULBYT
        LDA MANT+1
        JSR MULBYT
        LDA MANT
        JSR MULBYT
        JMP MULEND
*
* MULBYT: MULTIPLY 1*5 BYTES
****************************
* HARDWARE 8*8 MULTIPLY USED
*
MULBYT  LDY TEMP9+3
        STY DYADIC+7
        LDY TEMP9+2
        STY TEMP9+3
        LDY TEMP9+1
        STY TEMP9+2
        LDY TEMP9
        STY TEMP9+1
        LDY =0
        STY TEMP9
*
        CMP =0          TEST ACCU
        BNE *+4
MULBT9  CLI
        RTS
*
        SEI
        LDY =4
        STA MULTA
        LDA DYADIC+4
        STA MULTB
        LDA DYADIC+7
        CLC
        ADC MULTR
        STA DYADIC+7
        LDA TEMP9+3
        ADC MULTR+1
        STA TEMP9+3
        BCC MULBT2      SKIP, IF NO CARRY
*
MULBT1  TYA
        TAX
        DEX
        BEQ *+6
        INC TEMP9-1,X
        BEQ *-5
*
MULBT2  DEY
        BEQ MULBT9
        LDA DYADIC,Y
        STA MULTB
        LDA TEMP9,Y
        CLC
        ADC MULTR
        STA TEMP9,Y
        LDA TEMP9-1,Y
        ADC MULTR+1
        STA TEMP9-1,Y
        BCS MULBT1
        BCC MULBT2      ALLWAYS TAKEN
*
* UNDEFINED FUNCTION ERROR
*
UNDFN   LDX =$CE
        JMP ERROR
*
*
*
* BASIC FUNCTION TABLE
**********************
*
FUNCTB  WRD SGN
        WRD INT
        WRD ABS
        WRD USR
        WRD STA
        WRD POSF
        WRD SQR
        WRD RND
        WRD LOG
        WRD EXPF
        WRD COS
        WRD SIN
        WRD TAN
        WRD ATN
        WRD PEEK
        WRD LEN
        WRD STR
        WRD VAL
        WRD ASC
        WRD CHR
        WRD LEFT
        WRD RIGHT
        WRD MID
*
* NOT: MATH OPERATION
*********************
*
NOT     JSR FLPINT
        LDA MANT+3
        EOR =$FF
        TAY
        LDA MANT+2
        EOR =$FF
        JMP INTFLP
*
* BFUNC: BASIC FUNCTION
***********************
*
BFUNC   ASL A
        PHA             SAVE 2*CODE
        TAX
        JSR FETCH
        CPX =$A9
        BCC BFUNC0      SKIP, IF NOT STR
*
        JSR FOLLOW-6    "(" MUST FOLLOW
        JSR EXPRES
        LDA =','
        JSR FOLLOW
        SEC
        JSR TESTTP+1    MUST BE STRING
        PLA
        TAX
        LDA MANT+3
        PHA
        LDA MANT+2
        PHA
        TXA
        PHA             SAVE 2*CODE AGAIN
        JSR NUMEXP+3    GET SECOND ARG
        PLA
        TAY
        TXA
        PHA
        JMP BFUNC1+5
*
BFUNC0  CPX =$88        IF USR
        BNE BFUNC1
        JSR FOLLOW-6    GET 2 ARGS
        JSR EXPRES      ADDRESS
        JSR TESTTP
        JSR PEEK1       CONVERT TO INTEGER
        LDA =','
        JSR FOLLOW
        JSR EXPRES      GET SECOND ARG
        JSR TESTTP      MUST BE NUMERIC
        JSR FOLLOW-2
        JMP BFUNC1+3
*
BFUNC1  JSR ARGUM
        PLA
        TAY
        LDA FUNCTB-$82,Y
        STA PNT1
        LDA FUNCTB-$81,Y
        STA PNT1+1
        JSR PNT1-1      EXECUTE
        JMP TESTTP      MUST BE NUMERIC
*
* OR: MATH OPERATION
********************
*
OR      LDY =$FF
        BNE *+4         ALLWAYS TAKEN
*
* AND: MATH OPERATION
*********************
*
AND     LDY =0
        STY INPNT
        JSR FLPINT
        LDA MANT+2
        EOR INPNT
        STA CHRSAV
        LDA MANT+3
        EOR INPNT
        STA CHRSAV+1
        JSR TRANS1
        JSR FLPINT
        LDA MANT+3
        EOR INPNT
        AND CHRSAV+1
        EOR INPNT
        TAY
        LDA MANT+2
        EOR INPNT
        AND CHRSAV
        EOR INPNT
        JMP INTFLP
*
        TIT GRAPHIC BASIC - ARRAYS
        PAG
*
* DIM: STATEMENT ROUTINE
************************
*
        LDA =','
