* BASIC3:A ORIGINAL 7/1/1982, RECOVERED 3/2018
        STA BTSTRG+1
        LDY =0
        STY TEMP6+1
        LDA STSPAC
        LDX STSPAC+1
        STA TRANSP
        STX TRANSP+1
        LDA =STRST      START OF STRING STACK
        LDX =0
        STA TEMP1
        STX TEMP1+1
        CMP STRSTP
        BEQ *+7
        JSR PKSTR3
        BEQ *-7         DO UNTIL STACK EMPTY
        LDA =7
        STA SIZE
        LDA STVAR
        LDX STVAR+1
        STA TEMP1
        STX TEMP1+1
        CPX EOVAR+1
        BNE *+6
        CMP EOVAR
        BEQ *+7
        JSR PKSTR2
        BEQ *-11
*
        STA ENDB
        STX ENDB+1
        LDA =3
        STA SIZE
PKSTR1  LDA ENDB
        LDX ENDB+1
        CPX STSPAC+1
        BNE *+9
        CMP STSPAC
        BNE *+5
        JMP PKSTR5      DO UNTIL THROUGH ARRAYS
*
        STA TEMP1
        STX TEMP1+1
        LDY =0
        LDA (TEMP1),Y
        TAX             SAVE IN X
        INY
        LDA (TEMP1),Y
        PHP
        INY
        LDA (TEMP1),Y
        ADC ENDB
        STA ENDB
        INY
        LDA (TEMP1),Y
        ADC ENDB+1
        STA ENDB+1
        PLP
        BPL PKSTR1
        TXA
        BMI PKSTR1
        INY
        LDA (TEMP1),Y
        ASL A
        ADC =5
        LDY =0
        ADC TEMP1
        STA TEMP1
        BCC *+4
        INC TEMP1+1
        LDX TEMP1+1
        CPX ENDB+1
        BNE *+6
        CMP ENDB
        BEQ PKSTR1+4
        JSR PKSTR3
        BEQ *-11
PKSTR2  LDA (TEMP1),Y
        BMI PKSTR4
        INY
        LDA (TEMP1),Y
        BPL PKSTR4
        INY
*
PKSTR3  LDA (TEMP1),Y
        BEQ PKSTR4
        INY
        LDA (TEMP1),Y
        TAX
        INY
        LDA (TEMP1),Y
        CMP BTSTRG+1
        BCC *+8
        BNE PKSTR4
        CPX BTSTRG
        BCS PKSTR4
        CMP TRANSP+1
        BCC PKSTR4
        BNE *+6
        CPX TRANSP
        BCC PKSTR4
        STX TRANSP
        STA TRANSP+1
        LDA TEMP1
        LDX TEMP1+1
        STA TEMP6
        STX TEMP6+1
        LDA SIZE
        STA PNT1
*
PKSTR4  LDA SIZE
        CLC
        ADC TEMP1
        STA TEMP1
        BCC *+4
        INC TEMP1+1
        LDX TEMP1+1
        LDY =0
        RTS
*
PKSTR5  LDX TEMP6+1
        BEQ *-7
        LDA PNT1
        SBC =3
        LSR A
        TAY
        STA PNT1
        LDA (TEMP6),Y
        ADC TRANSP
        STA BEGINB
        LDA TRANSP+1
        ADC =0
        STA BEGINB+1
        LDA BTSTRG
        LDX BTSTRG+1
        STA ENDB
        STX ENDB+1
        JSR MKROOM+7
        LDY PNT1
        INY
        LDA ENDB
        STA (TEMP6),Y
        TAX
        INC ENDB+1
        LDA ENDB+1
        INY
        STA (TEMP6),Y
        JMP PKSTRG+4
*
* TSTTTM: TEST STRING ROOM
**************************
*
TSTRRM  LDX MANT+2
        LDY MANT+3
        STX TEMP5
        STY TEMP5+1
        JSR TSTRR1
        STX MANT
        STY MANT+1
        STA EXP
        RTS
*
* INSSTR: INSERT STRING
***********************
*
INSSTR  LDY =0
        LDA (DYADIC+6),Y
        PHA             A
        INY
        LDA (DYADIC+6),Y
        TAX             X
        INY
        LDA (DYADIC+6),Y
        TAY             Y
        PLA
*
INSST0  STX TEMP1       X,Y=START
        STY TEMP1+1
        TAY             A=SIZE
        BEQ *+12
        PHA
        DEY
        LDA (TEMP1),Y
        STA (TPSTRG),Y
        TYA
        BNE *-6
        PLA
        CLC
        ADC TPSTRG
        STA TPSTRG
        BCC *+4
        INC TPSTRG+1
        RTS
*
* TESTTP: REST RESULT TYPE
**************************
* C=0: MUST BE NUMERIC, C=1 MUST BE STRING
*
TESTTP  CLC
        BIT RESTYP
        BMI *+5
        BCS *+5
        RTS
        BCS *-1
        LDX =$96        TYPE MISSMATCH
        JMP ERROR
*
* EXPRESSION
************
*
EXPRES  LDX PC          DEC PC BY 1
        BNE *+4
        DEC PC+1
        DEC PC
        LDX =0
        TXA
        PHA             CURRENT ORDER
        LDA =1
        JSR TSSTK
        JSR SIMEXP
        LDA =0
        STA LOGIC
        JSR FETCH1
EXPR1   SEC
        SBC =$BE        CODE FOR >
        BCC EXPR2       SKIP, IF NOT LOGIC OP
        CMP =$03
        BCS EXPR2
*
        CMP =1
        ROL A
        EOR =1          >=BIT1. ==BIT2, <=BIT3
        EOR LOGIC
        CMP LOGIC
        BCS *+5
        JMP SYNERR
        STA LOGIC
        JSR FETCH
        JMP EXPR1
*
EXPR2   LDX LOGIC
        BNE EXPR3       SKIP, IF LOGIC OP
        BCS EXPR6
        ADC =7
        BCC EXPR6
        ADC RESTYP      C+1
        BNE *+5
        JMP STRADD      STRING ADDITION
        ADC =$FF
        STA TEMP1
        ASL A
        ADC TEMP1
        TAY             Y=3*A
EXPR2A  PLA             CURRENT ORDER
        CMP MATHTB,Y    COMPARE WITH NEW ONE
        BCS EXPR6+5
        JSR TESTTP      MUST BE NUMERIC
        PHA
        JSR EXPR4+7
        PLA
        LDY TEMP3+2
        BPL EXPR4
        TAX
        BEQ EXPR6+3
        BNE EXPR7
*
EXPR3   LSR RESTYP
        TXA
        ROL A
        LDX PC          DECR PC
        BNE *+4
        DEC PC+1
        DEC PC
        LDY =$1B        MATHOP =
        STA LOGIC
        BNE EXPR2A      ALLWAYS TAKEN
EXPR4   CMP MATHTB,Y
        BCS EXPR7
        BCC EXPR2A+9    ALLWAYS TAKEN
*
        LDA MATHTB+2,Y
        PHA
        LDA MATHTB+1,Y
        PHA
        JSR EXPR5
        LDA LOGIC
        PHA
        JMP EXPRES+10
*
EXPR5   LDA SIGN
        LDX MATHTB,Y
        TAY
        PLA
        STA TEMP1
        PLA
        STA TEMP1+1     GET MATHOPT ADDRESS
        INC TEMP1
        BNE *+4
        INC TEMP1+1
        TYA
        PHA
MATHOP  JSR ROUND
        LDA MANT+3
        PHA
        LDA MANT+2
        PHA
        LDA MANT+1
        PHA
        LDA MANT
        PHA
        LDA EXP
        PHA
        JMP (TEMP1)     EXECUTE MATHOP
*
EXPR6   LDY =$FF
        PLA
        BEQ EXPR8
        CMP =$64        PRIORITY CODE COMPARE
        BEQ *+5
        JSR TESTTP
        STY TEMP3+2
EXPR7   PLA
        LSR A
        STA READFL+1
        PLA
        STA DYADIC
        PLA
        STA DYADIC+1
        PLA
        STA DYADIC+2
        PLA
        STA DYADIC+3
        PLA
        STA DYADIC+4
        PLA
        STA DYADIC+5
        EOR SIGN
        STA DYADIC+6
EXPR8   LDA EXP
        RTS
*
* STRADD: STRING ADDITION
*************************
*
STRADD  LDA MANT+3
        PHA
        LDA MANT+2
        PHA
        JSR SIMEXP      GET SECOND STRING
        SEC
        JSR TESTTP+1     MUST BE STRING
        PLA
        STA DYADIC+6
        PLA
        STA DYADIC+7
        LDY =0
        LDA (DYADIC+6),Y        SIZE OF S1
        CLC
        ADC (MANT+2),Y          SIZE OF S2
        BCC *+7
        LDX =$A4
        JMP ERROR       STRING TOO LONG
        JSR TSTRRM
        JSR INSSTR
        LDA TEMP5
        LDY TEMP5+1
        JSR PREPST+4
        JSR INSST0+4
        LDA DYADIC+6
        LDY DYADIC+7
        JSR PREPST+4
        JSR STRSI3
        JMP EXPR1-3
*
* SIMEXP: SIMPLE EXPRESSION
***************************
*
SIMEXP  LDA =0
        STA RESTYP
        JSR FETCH
        BCS *+5         SKIP, IF NOT NUMBER
SIMEX1  JMP NUMBER
*
        JSR TLETT
        BCS VARIAB      SKIP, IF VARIABLE
        CMP =$D8        CODE FOR PI
        BNE SIMEX0
*
        LDA =<PI
        LDY =>PI
        JSR GETFLP
        JMP FETCH
PI      BYT $82,$49,$0F,$DA,$A1
*
SIMEX0  CMP ='$'        HEX INPUT
        BEQ SIMEX1
*
        CMP ='.'
        BEQ SIMEX1
        CMP =$B8        CODE FOR -VALUE OF PI
        BEQ SIMEX5
        CMP =$B7        CODE FOR +
        BEQ SIMEXP+4
        CMP ='"'
        BNE SIMEX2      SKIP, IF NOT STRING
*
EXPSTR  LDA PC          STRING EXPRESSION
        LDY PC+1
        ADC =0          INCREMENT BY 1 (C=1)
        BCC *+3
        INY
        JSR STRSIZ
UPDPC   LDX DYADIC+8
        LDY DYADIC+9
        STX PC
        STY PC+1
        RTS
*
SIMEX2  CMP =$B5        CODE FOR NOT
        BNE *+6
        LDY =$18
        BNE SIMEX5+2
*
        CMP =$B2        CODE FOR FN
        BNE *+5
        JMP FUNC        EXECUTE FUNCTION
*
        CMP =$C1        CODE FOR SIGN
        BCC *+5
        JMP BFUNC       EX BASIC FUNCTION
*
ARGUM   JSR FOLLOW-6    MUST BE (
        JSR EXPRES
        JMP FOLLOW-2    MUST BE )
*
SIMEX5  LDY =$15        EXECUTE NEGATE
        PLA
        PLA
        JMP EXPR2A+10
*
* VARIAB: GET VALUE OF VARIABLE
*******************************
*
VARIAB  LDX =$FF        MUST BE DEFINED
        STX TEMP4+1
        JSR GETVAR
        STA MANT+2
        STY MANT+3
        LDA VARSYM
        LDY VARSYM+1
        LDX RESTYP
        BEQ *+3
        RTS             RTS, IF STRING
*
        LDA RESTYP+1
        BPL *+15        SKIP, IF FLP
        LDY =0
        LDA (MANT+2),Y
        TAX
        INY
        LDA (MANT+2),Y
        TAY
        TXA
        JMP INTFLP
*
        LDA MANT+2      GET FLP
        LDY MANT+3
        JMP GETFLP
*
*
* OUTCHR: OUTPUT CHAR
*********************
*
OUTCHR  CMP =$20
        BCC *+4
        INC POS
        CMP =$D
        BNE *+8
        PHA
        LDA =0
        STA POS
        PLA
*
        PHA
        STX SAVEXY
        STY SAVEXY+1
        JSR PRC1
        LDX SAVEXY
        LDY SAVEXY+1
        PLA
        RTS
*
PRC1    JMP (PVECT)
*
* INTFLP: INTEGER TO FLP CONVERSION
***********************************
*
INTFLP  LDX =0
        STX RESTYP
        STA MANT
        STY MANT+1
        LDX =$90
        JMP FLOAT2
*
*
* MATH OPERATION TABLE
**********************
* FORMAT: PRIORITY CODE, ADDRESS-1
*
MATHTB  BYT $79
        WRD ADD-1
        BYT $79
        WRD SUBTR-1
        BYT $7B
        WRD MULT-1
        BYT $7B
        WRD DIVIDE-1
        BYT $7F
        WRD POWER-1
        BYT $50
        WRD AND-1
        BYT $46
        WRD OR-1
        BYT $7D
        WRD NEGATE-1
        BYT $5A
        WRD NOT-1
        BYT $64
        WRD TESTEQ-1
*
*
        TIT GRAPHIC BASIC - STATEMENTS
        PAG
*
* FOR: STATEMENT ROUTINE
************************
*
FOR     LDA =128
        STA FLAG1
        JSR LET
        JSR STACK
        BNE *+7         SKIP, IF NOT FOR ON ST
        TXA
        ADC =15
        TAX
        TXS
        PLA             GET RETURN ADDRESS
        PLA
        LDA =9
        JSR TSSTK       18 BYTES ON STACK?
        JSR SEDPN       SEARCH EOLL OR ":"
        CLC
        TYA
        ADC PC          SAVE ADDRESS OF NEXT
        PHA
        LDA PC+1
        ADC =0
        PHA
        LDA LINE+1      SAVE CURRENT LINE
        PHA
        LDA LINE
        PHA
        LDA =$B1        CODE FOR "TO"
        JSR FOLLOW
        JSR TESTTP      MUST BE NUMERIC
        JSR EXPRES
        JSR TESTTP      MUST BE NUMERIC
        LDA SIGN
        ORA =$7F
        AND MANT
        STA MANT
        LDA =<FOR1
        LDY =>FOR1
        STA TEMP1
        STY TEMP1+1
        JMP MATHOP
*
FOR1    LDA =<VAL1      LOAD 1.0E0
        LDY =>VAL1
        JSR GETFLP
        JSR FETCH1
        CMP =$B6        STEP?
        BNE *+11
        JSR FETCH
        JSR EXPRES
        JSR TESTTP      MUST BE NUMERIC
        JSR SGN1
        JSR EXPR5+5
        LDA TEMP3+1     STEP TO STACK
        PHA
        LDA TEMP3
        PHA
        LDA =$81        CODE FOR FOR
        PHA
        JMP EXRUN
*
VAL1    BYT $81,0,0,0,0    1.0E0
*
*
* ON: STATEMENT ROUTINE
***********************
*
ON      JSR NUMEXP+3
        PHA
        CMP =$8D        CODE FOR GOSUB
        BEQ ON1
        CMP =$89        CODE FOR GOTO
        BEQ ON1
        JMP SYNERR
*
ON1     DEC MANT+3
        BNE *+6
        PLA
        JMP EXCOD1+3
*
        JSR FETCH
        JSR FETCHI
        CMP =','
        BEQ ON1
        PLA
        RTS
*
*
* GET: STATEMENT ROUTINE
************************
*
GET     JSR ILLDIR      ILLEGAL IN DIRECT MODE
        CMP ='#'
        BNE *+5
        JSR SETINP      SET INPUT DEVICE
*
        LDX =<(INBUFF+1)
        LDY =0
        STY INBUFF+1
        LDA =$40
        JSR READ+6
GETEND  LDX INPDEV
        BEQ *+9
        JSR RSTIDV
        LDX =0
        STX INPDEV
        RTS
*
*
* INPUT: STATEMENT ROUTINE
**************************
*
INPUT   CMP ='#'
        BNE *+8
        JSR SETINP      SET INPUT DEVICE
        JMP INPUT1
*
        CMP ='"'
        BNE INPUT1
        JSR EXPSTR
        LDA =';'
        JSR FOLLOW
        JSR OUTSTR+3
*
INPUT1  JSR ILLDIR      ILLEGAL IN DIRECT MODE
        LDA =$2C
        STA INTEG+1
        JSR INPUT2
        LDA INBUFF
        BEQ *+10        SKIP, IF EMPTY
        LDA =0
        JSR READ+6
        JMP GETEND
*
        LDA INPDEV      IF EMPTY
        BNE INPUT1+7
        CLC
        JMP END+16
*
INPUT2  LDA INPDEV
        BNE INPUT3      SKIP, IF NOT DEV 0
        LDA ='?'
        JSR OUTCHR
        LDA =' '
        JSR OUTCHR
        JMP INLIN       GET LINE
*
INPUT3  LDX =0          GET FROM OTHER DEVICE
        JSR INCHR
        BEQ *-3         IGNORE 0
	INX		SET ANY EOF TO NEXT BYTE
	CMP =$1F	EOF?
	BEQ INPUT5
	DEX
        CMP =$7F        RUBOUT?
        BEQ *+4
        CMP =$5F        OR DELETE
        BNE INPUT4
*
        TXA             YES,TEST X
        BEQ INPUT3+2
        DEX
        JMP INPUT3+2
*
INPUT4  AND =$7F
        STA INBUFF,X
        INX
        CPX =56         END OF BUFFER?
        BEQ *+7
        CMP =$D         CARRIAGE RETURN
        BNE INPUT3+2
*
        DEX
INPUT5  LDY =0
        STY INBUFF,X    SET EOL MARK
        LDX =<(INBUFF-1)
        RTS
*
*
* READ: STATEMENT ROUTINE
*************************
*
READ    LDX DATPNT
        LDY DATPNT+1
        LDA =$98
        STA READFL
        STX DTSPNT
        STY DTSPNT+1
        LDX =0
        STX TEMP4+1     VARIABLE MUST NOT BE DEF
        JSR GETVAR
        STA TEMP3
        STY TEMP3+1
        LDA PC          SAVE PC
        LDY PC+1
        STA INTEG
        STY INTEG+1
        LDX DTSPNT
        LDY DTSPNT+1
        STX PC
        STY PC+1
        JSR FETCH1
        BNE READ2       SKIP, IF NOT EOL
*
        BIT READFL      IF EOL
        BVC *+13
        JSR INCHR
        STA INBUFF
        LDY =0
        LDX =<(INBUFF-1)
        BNE READ2-4     ALLWAYS TAKEN
*
        BMI READ5
        JSR INPUT2
*
        STX PC
        STY PC+1
READ2   JSR FETCH
        BIT RESTYP
        BPL READ3       SKIP, IF NOT STRING
        BIT READFL
        BVC *+13
        LDA =0
        STA CHRSAV
        INX
        STX PC
        TYA
        JMP READ2A
*
        STA CHRSAV
        CMP ='"'
        BEQ READ2A+1
        LDA =':'
        STA CHRSAV
        LDA =','
READ2A  CLC
        STA CHRSAV+1
        LDA PC
        LDY PC+1
        ADC =0
        BCC *+3
        INY
        JSR STRSIZ+6
        JSR UPDPC
        JSR LET1+4      SAVE STRING
        JMP READ3+8
*
READ3   JSR NUMBER
        LDA RESTYP+1
        JSR LET0
        JSR FETCH1
        BEQ *+9         SKIP IF NOT END OF STMNT
        CMP =','
        BEQ *+5
        JMP READ7
*
        LDA PC
        LDY PC+1
        STA DTSPNT
        STY DTSPNT+1
        LDA INTEG
        LDY INTEG+1
        STA PC
        STY PC+1
        JSR FETCH1
        BEQ READ6       SKIP, IF EOL
        LDA =','
        JSR FOLLOW
        JMP READ+12     NEXT VARIABLE
*
READ5   JSR SEDPN       SEARCH EOL OR ":"
        INY
        TAX
        BNE *+18
        INY
        LDA (PC),Y
        BEQ DATAER      IF END OF PROGRAM
        INY
        LDA (PC),Y
        STA TEMP7
        INY
        LDA (PC),Y
        STA TEMP7+1
        INY
        LDA (PC),Y      GET COMMAND CODE
        TAX
        JSR DATA+3
        CPX =$83        CODE FOR DATA
        BNE READ5
        JMP READ2
*
READ6   LDA DTSPNT
        LDY DTSPNT+1
        LDX READFL
        BPL *+5
        JMP RESTOR+29
*
        LDY =0
        LDA (DTSPNT),Y
        BEQ *+13        RTS, IF EOL
        LDA INPDEV
        BNE *+9
        LDA =<(*+8)
        LDY =>(*+6)
        JMP OUTSTR
        RTS
*
        BYT '?EXTRA IGNORED',$D,$A,0
REDO    BYT '?REDO FROM START',$D,$A,0
*
READ7   LDA READFL
        BEQ *+19
        BMI *+6
        LDY =$FF
        BNE *+6         ALLWAYS TAKEN
        LDA TEMP7
        LDY TEMP7+1
        STA LINE
        STY LINE+1
        JMP SYNERR
*
        LDA INPDEV
        BEQ *+7
DATAER  LDX =$26         DATA ERROR
        JMP ERROR
        LDA =<REDO
        LDY =>REDO
        JSR OUTSTR
        LDA PNTSAV
        LDY PNTSAV+1
        STA PC
        STY PC+1
        RTS
*
*
* NEXT: STATEMENT ROUTINE
*************************
*
NEXT    BNE *+6         SKIP, IF NOT EOL
        LDY =0
        BEQ *+9         ELSE SET Y=0
        LDA =$FF        VARIABLE MUST BE DEF
        STX TEMP4+1
        JSR GETVAR
        STA TEMP3       SAVE ADDRESS
        STY TEMP3+1
        JSR STACK
        BEQ *+7
        LDX =0
        JMP ERROR       NO MATCHING FOR
*
        TXS
        INX
        INX
        INX
        INX
        TXA             FLP ADDRESS LOW
        INX
        INX
        INX
        INX
        INX
        INX
        STX TEMP1+2
        LDY =1          FLP ADDRESS HIGH
        JSR GETFLP
        TSX
        LDA 265,X
        STA SIGN
        LDA TEMP3
        LDY TEMP3+1
        JSR ADD-3
        JSR SAVFLP
        LDY =1
        JSR COMPAR+2
        TSX
        SEC
        SBC 265,X
        BEQ *+25
        LDA 271,X
        STA LINE
        LDA 272,X
        STA LINE+1
        LDA 274,X
        STA PC
        LDA 273,X
        STA PC+1
        JMP EXRUN
*
        TXA
        ADC =17         CLEAR STACK
        TAX
        TXS
        JSR FETCH1
        CMP =','
        BNE *-13
        JSR FETCH
        JSR NEXT+6      NO RTS FROM THIS SUBR.
*
*
* ILLDIR: ILLEGAL IN DIRECT MODE
********************************
*
ILLDIR  LDX LINE+1
        INX
        BNE *+7         RTS, IF NOT DIRECT
        LDX =$88
        JMP ERROR
        RTS
*
*
* OUTLIN: PRINT LINE NO
***********************
*
OUTLIN  LDA =<(ERRORM+25)
        LDY =>(ERRORM+25)
        JSR OUTSTR
        LDA LINE+1
        LDX LINE
*
*
* OUTINT: PRINT INTEGER IN A,X
******************************
*
OUTINT  STA MANT
        STX MANT+1
        LDX =$90        EXP FOR FLOAT
        SEC
        JSR FLOAT
        JSR OUTCON
        JMP OUTSTR
*
        TIT GRAPHIC BASIC - MATH OPERATIONS
        PAG
*
* SUBTR: SUBTRACT FLOATING POINT
********************************
*
        JSR PREPMO
SUBTR   LDA SIGN
        EOR =$FF
        STA SIGN
        EOR DYADIC+5
        STA DYADIC+6
        LDA EXP
        JMP ADD
*
ADD9    LDA =<OUTCT2
        LDY =>OUTCT2
        JMP ADD-3
*
*
* ADD: ADD FLOATING POINT
*************************
*
        JSR ROR2A
        BCC ADD2
        JSR PREPMO
ADD     BNE *+5
        JMP TRANS1      IF ZERO, RES=OTHER ARG
        LDX DYADIC+7
        STX PNT1+1
        LDX =<DYADIC
        LDA DYADIC
        TAY
        BNE *+3
        RTS             RTS, IF OTHER ARG=0
*
        SEC
