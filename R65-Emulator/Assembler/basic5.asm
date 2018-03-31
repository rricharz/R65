* BASIC5:A ORIGINAL 7/1/1982, RECOVERED 3/2018
        JSR FOLLOW
DIM     LDX =0
        STX TEMP4+1     VARIABLE CAN BE UNDEF
        TAX
        JSR GETVAR+5
        JSR FETCH1
        BNE DIM-5
        RTS
*
* GETARR: GET ARRAY
*******************
*
GETARR  LDA TEMP4+1
        PHA
        LDA RESTYP-1
        ORA RESTYP+1
        PHA
        LDA RESTYP
        PHA
        LDY =0
GETAR1  TYA
        PHA
        LDA VARSYM+1
        PHA
        LDA VARSYM
        PHA
        JSR GETSU       GET SUBSCRIPT
        PLA
        STA VARSYM
        PLA
        STA VARSYM+1
        PLA
        TAY
*
        TSX
        LDA 258,X       RESTYP TO STACK BOT
        PHA
        LDA 257,X
        PHA
        LDA 259,X
        STA 257,X
        LDA MANT+2
        STA 259,X       SUBSCRIPT TO TOP
        LDA MANT+3
        STA 258,X
*
        INY             COUNT SUBSCRIPT
        JSR FETCH1      MORE SUBSCRIPTS?
        CMP =','
        BEQ GETAR1      IF YES, GET THEM
*
        STY INPNT       SAVE NO OF SUBSCRIPTS
        JSR FOLLOW-2    ) MUST FOLLOW
        PLA
        STA RESTYP
        PLA
        STA RESTYP+1
        AND =$7F
        STA RESTYP-1
        PLA
        STA TEMP4+1
*
        LDX EOVAR
        LDA EOVAR+1
GETAR2  STX TRANSP      SEARCH SYMBOL
        STA TRANSP+1    STARTING FROM EOVAR
        CMP STSPAC+1    ENDING WITH STSPAC
        BNE *+6
        CPX STSPAC
        BEQ GETAR4      BRANCH, IF NOT FOUND
        LDY =0
        LDA (TRANSP),Y
        INY
        CMP VARSYM
        BNE *+8
        LDA VARSYM+1
        CMP (TRANSP),Y
        BEQ GETAR3      BRANCH, IF FOUND
        INY
        LDA (TRANSP),Y  GET SIZE LOW
        CLC
        ADC TRANSP
        TAX
        INY
        LDA (TRANSP),Y
        ADC TRANSP+1
        BCC GETAR2      ALLWAYS TAKEN
*
SUBERR  LDX =$6F        SUBSCRIPT ERROR
        JMP ERROR
*
GETAR3  LDX =$64        IF FOUND
        LDA RESTYP-1    REDIMENSION ERROR
        BNE GETAR3-3    YES
        JSR COMPEB
        LDA INPNT
        LDY =4
        CMP (TRANSP),Y
        BNE SUBERR      SUBSCRIPT ERROR
        JMP GETAR6
*
GETAR4  LDA TEMP4+1     IF NOT FOUND
        BEQ *+5
        JMP GETV3+4     UNDEF VAR ERR
*
        JSR COMPEB
        JSR TSROOM
        LDA =0
        TAY
        STA DYADIC+9
        LDX =5
        LDA VARSYM
        STA (TRANSP),Y
        BPL *+3
        DEX
        INY
        LDA VARSYM+1
        STA (TRANSP),Y
        BPL *+4
        DEX
        DEX
        STX DYADIC+8    ELEMENT SIZE
        LDA INPNT
        INY
        INY
        INY
        STA (TRANSP),Y
GETAR5  LDX =11         DEFAULT DIMENSION
        LDA =0
        BIT RESTYP-1
        BVC *+10        SKIP, IF NOT DIM
        PLA
        CLC
        ADC =1
        TAX
        PLA
        ADC =0
*
        INY
        STA (TRANSP),Y
        INY
        TXA
        STA (TRANSP),Y
        JSR GETAR8
        STX DYADIC+8
        STY DYADIC+9
        LDY TEMP1
        DEC INPNT
        BNE GETAR5
        ADC ENDB+1
        BCS GETAR7      OUT OF MEMORY
        STA ENDB+1
        TAY
        TXA
        ADC ENDB
        BCC *+5
        INY
        BEQ GETAR7      OUT OF MEMORY
        JSR TSROOM
        STA STSPAC
        STY STSPAC+1
        LDA =0
        INC DYADIC+9
        LDY DYADIC+8
        BEQ *+7
        DEY
        STA (ENDB),Y
        BNE *-3
        DEC ENDB+1
        DEC DYADIC+9
        BNE *-9
        INC ENDB+1
        SEC
        LDA STSPAC
        SBC TRANSP
        LDY =2
        STA (TRANSP),Y
        LDA STSPAC+1
        INY
        SBC TRANSP+1
        STA (TRANSP),Y
        LDA RESTYP-1
        BNE GETAR8-1
        INY
GETAR6  LDA (TRANSP),Y
        STA INPNT
        LDA =0
        STA DYADIC+8
        STA DYADIC+9
        INY
        PLA
        TAX
        STA MANT+2
        PLA
        STA MANT+3
        CMP (TRANSP),Y
        BCC GETAR7+4
        BNE GETAR7-3
        INY
        TXA
        CMP (TRANSP),Y
        BCC GETAR7+5
        JMP SUBERR      SUBSCRIPT ERROR
*
GETAR7  CLI
        JMP OUTMEM      OUT OF MEMORY
*
        INY
        LDA DYADIC+9
        ORA DYADIC+8
        CLC
        BEQ *+12
        JSR GETAR8
        TXA
        ADC MANT+2
        TAX
        TYA
        LDY TEMP1
        ADC MANT+3
        STX DYADIC+8
        DEC INPNT
        BNE GETAR6+8
        STA DYADIC+9
        LDX =5
        LDA VARSYM
        BPL *+3
        DEX
        LDA VARSYM+1
        BPL *+4
        DEX
        DEX
        STX TEMP9+2
        LDA =0
        JSR GETAR8+9
        TXA
        ADC ENDB
        STA VARSTP
        TYA
        ADC ENDB+1
        STA VARSTP+1
        TAY
        LDA VARSTP
        RTS
*
*
GETAR8  STY TEMP1       SAVE POINTER
        LDA (TRANSP),Y
        STA TEMP9+2
        DEY
        LDA (TRANSP),Y
        STA TEMP9+3
        LDA DYADIC+8
        SEI
        STA MULTA
        LDA TEMP9+2
        STA MULTB
        LDX MULTR
        LDA MULTR+1
        LDY TEMP9+3
        STY MULTB
        CLC
        ADC MULTR
        BCS GETAR7      OUT OF MEMORY
        TAY
        LDA MULTR+1
        BNE GETAR7      OUT OF MEMORY
        CLI
        LDA DYADIC+9
        BEQ GETSU-3     RTS, IF ZERO
        SEI
        STA MULTA
        LDA TEMP9+3
        BNE GETAR7      OUT OF MEMORY
        LDA TEMP9+2
        STA MULTB
        TYA
        CLC
        ADC MULTR
        BCS *-31        OUT OF MEMORY
        TAY
        LDA MULTR+1
        BNE *-18        OUT OF MEMORY
        TYA
        CLI
        RTS
*
* GETSU: GET ONE SUBSCRIPT
**************************
*
GETSU   JSR FETCH
        JSR EXPRES
        JSR TESTTP
        LDA MANT+4
        BMI *+5
        JMP FLPINT
        JMP QERR
*
* COMPEB: COMPUTE ENDB
**********************
*
COMPEB  LDA INPNT       NO OF SUBSCRIPTS
        ASL A
        ADC =5          *2, + 5
        ADC TRANSP
        LDY TRANSP+1
        BCC *+3
        INY
        STA ENDB
        STY ENDB+1
        RTS
*
        TIT GRAPHIC BASIC - FUNCTIONS
        PAG
*
* FRE: COMPUTE FREE SPACE IN MEMORY
***********************************
*
FRE     LDA RESTYP
        BEQ *+5
        JSR PREPST
        JSR PKSTRG
        SEC
        LDA BTSTRG
        SBC STSPAC
        TAY
        LDA BTSTRG+1
        SBC STSPAC+1
        JMP INTFLP
*
* POS: BASIC FUNCTION
*********************
*
POSF    JSR NUMEXP+6
        CPX =4
        BCC *+5
        JMP QERR1
        CPX OUTDEV
        BNE POSF2
POSF1   LDY POS
        LDA =0
        JMP INTFLP
POSF2   LDA POSTB,X
        TAY
        JMP POSF1+2
*
* DEF: STATEMENT ROUTINE
************************
*
DEF     JSR DEF1
        JSR ILLDIR
        JSR FOLLOW-6    ( MUST FOLLOW
        LDA =128
        STA FLAG1
        JSR GETVAR
        JSR TESTTP      MUST BE NUMERIC
        JSR FOLLOW-2    ) MUST FOLLOW
        LDA =$BF        CODE FOR =
        JSR FOLLOW
        PHA
        LDA VARSTP+1
        PHA
        LDA VARSTP
        PHA
        LDA PC+1
        PHA
        LDA PC
        PHA
        JSR DATA        ADVANCE IN LINE
        JMP DEF2
*
DEF1    LDA =0  MUST NOT BE DEFINED
        STA TEMP4+1
        LDA =$B2        CODE FOR FN
        JSR FOLLOW
        ORA =$80
        STA FLAG1
        JSR GETVAR+7
        STA TEMP6
        STY TEMP6+1
        JMP TESTTP      MUST BE NUMERIC
*
*
* FUNC: BASIC USER DEFINED FUNCTION
***********************************
*
FUNC    JSR DEF1
        LDA TEMP6+1     SAVE FUNCTION
        PHA             VARIABLE NAME ON STACK
        LDA TEMP6
        PHA
        JSR ARGUM
        JSR TESTTP      MUST BE NUMERIC
        PLA
        STA TEMP6
        PLA
        STA TEMP6+1
        LDY =2
        LDA (TEMP6),Y
        BNE *+5
        JMP UNDFN       UNDEFINED FUNCTION
        STA VARSTP
        TAX
        INY
        LDA (TEMP6),Y
        STA VARSTP+1
        INY
        LDA (VARSTP),Y
        PHA
        DEY
        BPL *-4
        LDY VARSTP+1
        JSR SAVFLP+4
        LDA PC+1
        PHA
        LDA PC
        PHA
        LDA (TEMP6),Y
        STA PC
        INY
        LDA (TEMP6),Y
        STA PC+1
        LDA VARSTP+1
        PHA
        LDA VARSTP
        PHA
        JSR EXPRES
        JSR TESTTP
        PLA
        STA TEMP6
        PLA
        STA TEMP6+1
        JSR FETCH1
        BEQ *+5
        JMP SYNERR
        PLA
        STA PC
        PLA
        STA PC+1
*
DEF2    LDY =0
        PLA
        STA (TEMP6),Y
        PLA
        INY
        STA (TEMP6),Y
        PLA
        INY
        STA (TEMP6),Y
        PLA
        INY
        STA (TEMP6),Y
        PLA
        INY
        STA (TEMP6),Y
        RTS
*
* STR$: BASIC FUNCTION
**********************
*
STR     JSR TESTTP      ARGUMENT NUMERIC
        LDY =0
        JSR FORMOUT+2
        PLA
        PLA
        LDA =255
        LDY =0
        JMP STRSIZ
*
* CHR$: BASIC FUNCTION
**********************
*
CHR     JSR NUMEXP+9
        TXA
        PHA
        LDA =1
        JSR TSTRRM+8
        PLA
        LDY =0
        STA (MANT),Y
        PLA
        PLA
        JMP STRSI3
*
* LEFT$: BASIC FUNCTION
***********************
*
LEFT    JSR MID1
        CMP (TEMP5),Y
        TYA
        BCC *+6
        LDA (TEMP5),Y
        TAX
        TYA
        PHA
LEFT1   TXA
        PHA
        JSR TSTRRM+8
        LDA TEMP5
        LDY TEMP5+1
        JSR PREPST+4
        PLA
        TAY
        PLA
        CLC
        ADC TEMP1
        STA TEMP1
        BCC *+4
        INC TEMP1+1
        TYA
        JSR INSST0+4
        JMP STRSI3
*
* RIGHT$: BASIC FUNCTION
************************
*
RIGHT   JSR MID1
        CLC
        SBC (TEMP5),Y
        EOR =$FF
        JMP LEFT+6
*
* MID$ BASIC FUNCTION
*********************
*
MID     LDA =$FF
        STA MANT+3
        JSR FETCH1
        CMP =')'
        BEQ *+10
        LDA =','
        JSR FOLLOW
        JSR NUMEXP+3
*
        JSR MID1
        DEX
        TXA
        PHA
        CLC
        LDX =0
        SBC (TEMP5),Y
        BCS LEFT1
        EOR =$FF
        CMP MANT+3
        BCC LEFT1+1
        LDA MANT+3
        BCS LEFT1+1     ALLWAYS TAKEN
*
MID1    JSR FOLLOW-2    ) MUST FOLLOW
        PLA
        STA PNT1
        PLA
        STA PNT1+1
        PLA
        PLA
        PLA
        TAX
        PLA
        STA TEMP5
        PLA
        STA TEMP5+1
        LDY =0
        TXA
        BNE *+5
QERR1   JMP QERR
        INC PNT1        PREPARE RETURN
        BNE *+4
        INC PNT1+1
        JMP (PNT1)      SIMULATE RTS
*
* LEN:  BASIC FUNCTION
**********************
*
LEN     JSR LEN1
        LDA =0
        JMP INTFLP
*
LEN1    SEC
        JSR TESTTP+1    ARGUMENT STRING
        JSR PREPST
        LDX =0
        STX RESTYP
        TAY
        RTS
*
* ASC: BASIC FUNCTION
*********************
*
ASC     JSR LEN1
        BEQ QERR1       QUANTITY ERROR, IF 0
        LDY =0
        LDA (TEMP1),Y
        TAY
        JMP LEN+3
*
* VAL: BASIC FUNCTION
*********************
*
VAL     JSR LEN1
        BNE *+5
        JMP ADD3-7      SET RESULT TO 0
        LDX PC
        LDY PC+1
        STX DYADIC+8
        STY DYADIC+9
        LDX TEMP1
        STX PC
        CLC
        ADC TEMP1
        STA TEMP8
        LDX TEMP1+1
        STX PC+1
        BCC *+3
        INX
        STX TEMP8+1
        LDY =0
        LDA (TEMP8),Y
        PHA
        LDA =0
        STA (TEMP8),Y
        JSR FETCH1
        JSR NUMBER
        PLA
        LDY =0
        STA (TEMP8),Y   RESTORE END MARK
        JMP UPDPC
*
* PEEK: BASIC FUNCTION
**********************
*
PEEK    JSR PEEK1
        LDY =0
        LDA (INTEG),Y
        TAY
        LDA =0
        JMP INTFLP
*
PEEK1   LDA SIGN
        BMI QERR1
        LDA EXP
        CMP =$91
        BCS QERR1
        JSR FLPIN1
        LDA MANT+3
        LDY MANT+2
        STY INTEG+1
        STA INTEG
        RTS
*
* POKE: STATEMENT ROUTINE
*************************
*
POKE    JSR POKE1
        TXA
        LDY =0
        STA (INTEG),Y
        RTS
*
POKE1   JSR EXPRES
        JSR TESTTP
        JSR PEEK1
        LDA =','
        JSR FOLLOW
        JMP NUMEXP+3
*
* ABS: BASIC FUNCTION
*********************
*
ABS     LSR SIGN
        RTS
*
* INT: BASIC FUNCTION
*********************
*
INT     LDA EXP
        CMP =$A0
        BCS *-5         RTS, IF >1E9
        JSR FLPIN1
        STY DYADIC+7
        LDA SIGN
        STY SIGN
        EOR =$80
        ROL A
        LDA =$A0
        STA EXP
        LDA MANT+3
        STA CHRSAV
        JMP NORMAL
*
* SYS: STATEMENT ROUTINE
************************
*
SYS     JSR EXPRES
        JSR TESTTP
        JSR PEEK1
        JMP (INTEG)
*
* LOG: BASIC FUNCTION
*********************
*
LOG     JSR SGN1
        BEQ *+4
        BPL *+5
        JMP QERR        QUANTITY ERROR
        LDA EXP
        SBC =127
        PHA
        LDA =128
        STA EXP
        LDA =<LOG2
        LDY =>LOG2
        JSR ADD-3
        LDA =<(LOG2+5)
        LDY =>(LOG2+5)
        JSR DIVIDE-3
        LDA =<LOG1
        LDY =>LOG1
        JSR SUBTR-3
        LDA =<(LOG1+5)
        LDY =>(LOG1+5)
        JSR ITERAT
        LDA =<(LOG2+10)
        LDY =>(LOG2+10)
        JSR ADD-3
        PLA
        JSR NUMB6
        LDA =<(LOG2+15)
        LDY =>(LOG2+15)
        JMP MULT-3
*
LOG1    BYT $81,0,0,0,0
        BYT 3
        BYT $7F,$5E,$56,$CB,$79
        BYT $80,$13,$9B,$0B,$64
        BYT $80,$76,$38,$93,$16
        BYT $82,$38,$AA,$3B,$20
LOG2    BYT $80,$35,$04,$F3,$34
        BYT $81,$35,$04,$F3,$34
        BYT $80,$80,$00,$00,$00
        BYT $80,$31,$72,$17,$F8
*
* SQR: BASIC FUNCTION
*********************
*
SQR     JSR TRANS2
        LDA =<OUTCT2    0.5
        LDY =>OUTCT2
        JSR GETFLP
*
* POWER: MATH OPERATION
***********************
*
POWER   BEQ EXPF
        LDA DYADIC
        BNE *+5
        JMP ADD3-5
        LDX =<TEMP6
        LDY =>TEMP6
        JSR SAVFLP+4
        LDA DYADIC+5
        BPL *+17
        JSR INT
        LDA =<TEMP6
        LDY =>TEMP6
        JSR COMPAR
        BNE *+5
        TYA
        LDY CHRSAV
        JSR TRANS1+2
        TYA
        PHA
        JSR LOG
        LDA =<TEMP6
        LDY =>TEMP6
        JSR MULT-3
        JSR EXPF
        PLA
        LSR A
        BCS *+3
        RTS
        JMP NEGATE
*
* EXP: BASIC FUNCTION
*********************
*
EXPF    LDA =<EXP1
        LDY =>EXP1
        JSR MULT-3
        LDA DYADIC+7
        ADC =80
        BCC *+5
        JSR ROUND+8
        STA PNT1+1
        JSR TRANS2+3
        LDA EXP
        CMP =136
        BCC *+5
        JSR MULEX1-6
        JSR INT
        LDA CHRSAV
        CLC
        ADC =129
        BEQ *-11
        SEC
        SBC =1
        PHA
        LDX =5
        LDA DYADIC,X
        LDY EXP,X
        STA EXP,X
        STY DYADIC,X
        DEX
        BPL *-9
        LDA PNT1+1
        STA DYADIC+7
        JSR SUBTR
        JSR NEGATE
        LDA =<(EXP1+5)
        LDY =>(EXP1+5)
        JSR ITERA1
        LDA =0
        STA DYADIC+6
        PLA
        JSR MULEXP+2
        RTS
*
* ITERAT: FUNCTION ITERATION
****************************
*
ITERAT  STA DYADIC+8
        STY DYADIC+9
        LDX =<(ENDB-1)
        LDY =0
        JSR SAVFLP+4
        LDA =<(ENDB-1)
        JSR MULT-3
        JSR ITERA1+4
        LDA =<(ENDB-1)
        LDY =0
        JMP MULT-3
*
ITERA1  STA DYADIC+8
        STY DYADIC+9
        LDX =<(POINTC-1)
        LDY =0
        JSR SAVFLP+4
        LDA (DYADIC+8),Y
        STA CURRSG
        LDY DYADIC+8
        INY
        TYA
        BNE *+4
        INC DYADIC+9
        STA DYADIC+8
        LDY DYADIC+9
ITERA2  JSR MULT-3
        LDA DYADIC+8
        LDY DYADIC+9
        CLC
        ADC =5
        BCC *+3
        INY
        STA DYADIC+8
        STY DYADIC+9
        JSR ADD-3
        LDA =(POINTC-1)
        LDY =0
        DEC CURRSG
        BNE ITERA2
        RTS
*
EXP1    BYT $81,$38,$AA,$3B,$29
        BYT $07
        BYT $71,$34,$58,$3F,$56
        BYT $74,$16,$7E,$B3,$1B
        BYT $77,$2F,$EE,$E3,$85
        BYT $7A,$1D,$84,$1C,$2A
        BYT $7C,$63,$59,$58,$0A
        BYT $7E,$75,$FD,$E7,$C6
        BYT $80,$31,$72,$18,$10
        BYT $81,$00,$00,$00,$00
*
* RND: BASIC FUNCTION
*********************
*
RND     JSR SGN1
        BMI RND2
        BEQ RND1
*
        LDA =<RNDVAL
        LDY =>RNDVAL
        JSR MULT-3
        LDA =<RND3
        LDY =>RND3
        JSR MULT-3
        LDA =<(RND3+4)
        LDY =>(RND3+4)
        JSR ADD-3
RND2    LDA MANT+3
        LDX MANT
        ADC $1706       ADD REAL RANDOM
        STX MANT+3
        STA MANT
        LDX MANT+1
        LDA MANT+2
        ADC $1706       ADD REAL RANDOOM
        STA MANT+1
        STX MANT+2
        LDA =0
        STA SIGN
        LDA EXP
        STA DYADIC+7
        LDA =128
        STA EXP
        JSR NORMAL+5
        LDX =<RNDVAL
        LDY =>RNDVAL
        JMP SAVFLP+4
*
RND1    LDA =<RNDVAL
        LDY =>RNDVAL
        JMP GETFLP
*
RND3    BYT $98,$35,$44,$7A
        BYT $68,$28,$B1,$46
*
* COS: BASIC FUNCTION
*********************
*
COS     LDA =<SIN1
        LDY =>SIN1
        JSR ADD-3
*
* SIN: BASIC FUNCTION
*********************
*
SIN     JSR TRANS2
        LDA =<(SIN1+5)
        LDY =>(SIN1+5)
        LDX DYADIC+5
        JSR DIVTEN+9
        JSR TRANS2
        JSR INT
        LDA =0
        STA DYADIC+6
        JSR SUBTR
        LDA =<(SIN1+10)
        LDY =>(SIN1+10)
        JSR SUBTR-3
        LDA SIGN
        PHA
        BPL SIN0
        LDA =<OUTCT2
        LDY =>OUTCT2
        JSR ADD-3
        LDA SIGN
        BMI SIN0+3
        LDA READFL+1
        EOR =$FF
        STA READFL+1
SIN0    JSR NEGATE
        LDA =<(SIN1+10)
        LDY =>(SIN1+10)
        JSR ADD-3
        PLA
        BPL *+5
        JSR NEGATE
        LDA =<(SIN1+15)
        LDY =>(SIN1+15)
        JMP ITERAT
*
SIN1    BYT $81,$49,$0F,$DA,$A2
        BYT $83,$49,$0F,$DA,$A2
        BYT $7F,$00,$00,$00,$00
        BYT 05
        BYT $84,$E6,$1A,$2D,$1B
        BYT $86,$28,$07,$FB,$F8
        BYT $87,$99,$68,$89,$01
        BYT $87,$23,$35,$DF,$E1
        BYT $86,$A5,$5D,$E7,$28
        BYT $83,$49,$0F,$DA,$A2
*
* TAN: BASIC FUNCTION
*********************
*
TAN     LDX =<(ENDB-1)
        LDY =0
        JSR SAVFLP+4
        LDA =0
        STA READFL+1
        JSR SIN
        LDX =<TEMP6
        LDY =0
        JSR SAVFLP+4
        LDA =<(ENDB-1)
        LDY =0
        JSR GETFLP
        LDA =0
        STA SIGN
        LDA READFL+1
