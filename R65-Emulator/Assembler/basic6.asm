* BASIC6:A ORIGINAL 7/1/1982, RECOVERED 3/2018
        JSR TAN1
        LDA =<TEMP6
        LDY =0
        JMP DIVIDE-3
TAN1    PHA
        JMP SIN0
*
* ATN: BASIC FUNCTION
*********************
*
ATN     LDA SIGN
        PHA
        BPL *+5
        JSR NEGATE
        LDA EXP
        PHA
        CMP =$81
        BCC *+9
        LDA =<LOG1
        LDY =>LOG1
        JSR DIVIDE-3
        LDA =<ATN1
        LDY =>ATN1
        JSR ITERAT
        PLA
        CMP =129
        BCC *+9
        LDA =<SIN1
        LDY =>SIN1
        JSR SUBTR-3
        PLA
        BPL *+5
        JMP NEGATE
        RTS
*
ATN1    BYT $0B
        BYT $76,$B3,$83,$BD,$D3
        BYT $79,$E1,$F4,$A6,$F5
        BYT $7B,$83,$FC,$B0,$10
        BYT $7C,$0C,$1F,$67,$CA
        BYT $7C,$DE,$53,$CB,$C1
        BYT $7D,$14,$64,$70,$4C
        BYT $7D,$B7,$EA,$51,$7A
        BYT $7D,$63,$30,$88,$7E
        BYT $7E,$92,$44,$99,$3A
        BYT $7E,$4C,$CC,$91,$C7
        BYT $7F,$AA,$AA,$AA,$13
        BYT $81,$00,$00,$00,$00
*
* USR: BASIC FUNCTION
*********************
*
USR     JMP (INTEG)
*
        TIT GRAPHIC BASIC - STATEMENTS
*
* STORE: STATEMENT ROUTINE
**************************
*
STORE   JSR GETBFN      GET FILE NAME, DRIVE
        LDA STPROG
        LDX STPROG+1
        STA FILSA
        STX FILSA+1
        LDA STVAR
        LDX STVAR+1
        STA FILEA
        STX FILEA+1
        JSR GETBCD
        STA FILLOC
        STY FILLOC+1
        LDA ='B'
        STA FILSTP
        LDA =0
        STA FILFLG
        JSR FETCH1
        BNE SYNER2      NOT END OF LINE
        JSR WRFILE
        BEQ *+5
FILERR1 JMP FILERR
        RTS
*
GETBFN  JSR FETCH1
        BEQ SYNER2      END OF LINE
GETBF1  JSR EXPRES
        SEC
        JSR TESTTP+1    MUST BE STRING
        JSR PREPST      A=SIZE, TEMP1=START
*
        STA TEMP3
        TAY
        BEQ GETBF5
        LDY =0
        STY FILCYC
        STY FILCY1
GETBF2  LDA (TEMP1),Y
        CPY TEMP3
        BCC *+4         IF STRING TOO SHORT
        LDA =$20
        STA FILNAM,Y
        STA FILNM1,Y
        INY
        CPY =$10
        BCC GETBF2
        JSR FETCH1
        CMP ='.'
        BNE GETBF3
        JSR NUMEXP      GET EXTENSION
        STX FILCYC
        STX FILCY1
GETBF3  JSR DEFARG2
        STA FILDRV
        RTS
*
SYNER2  JMP SYNERR      SYNTAX ERROR
*
GETBF4  JSR FETCH1      DEFAULT NO NAME
        BEQ GETBF5
        CMP =','
        BEQ GETBF5
        JMP GETBF1
*
GETBF5  LDA =0
        STA FILNAM
        STA FILNM1
        JMP GETBF3
*
* LOAD: STATEMENT ROUTINE
*************************
*
LOAD    JSR LOAD9
        JMP WARMST
*
LOAD9   JSR GETBF4
*
LOAD1   LDA STPROG
        LDX STPROG+1
        STA FILSA1
        STX FILSA1+1
        LDA =0
        STA FILFLG
        JSR RDFILE
        BNE FILERR1
        LDA FILSTP
        CMP ='B'
        BEQ *+7
        LDX =29
        JMP FERROR
        LDA FILEA
        LDX FILEA+1
        STA STVAR
        STX STVAR+1
        JSR CRLF
        JSR ADLNP0
        LDA TEMP1
        LDX TEMP1+1
        CLC
        ADC =3
        BCC *+3
        INX
        STA STVAR
        STX STVAR+1
        JMP CLR1-3
*
* DEFARG: GET ARGUMENT OR DEFAULT=0
***********************************
* OUTPUT IS IN A,Y AND INTEG
* DEFARG GETS 16 BIT INTEGER
* DEFARG2 GETS 8 BIT INTEGER
*
DEFARG  JSR FETCH1
        CMP =','
        BNE DEFARG1
        JSR FETCH
        CMP =','
        BEQ DEFARG1
        JSR EXPRES
        JSR TESTTP
        JMP PEEK1
*
DEFARG1 LDA =0
        TAY
        STA INTEG
        STY INTEG+1
        RTS
*
DEFARG2 JSR DEFARG
        CPY =0
        BEQ *+5
        JMP QERR
        RTS
*
*
* SETDEV: SET OUTPUT DEVICE
***************************
*
SETDEV  JSR NUMEXP
        CPX =3
        BNE SETDV0
        JSR PLMD
        LDX =3
        CLC
SETDV0  BCS SETDV2
        LDA =';'
        JSR FOLLOW
        LDA POS
        STA POSTB
SETDV1  LDA DEVTB,X
        STA PVECT
        LDA DEVTB+4,X
        STA PVECT+1
        STX OUTDEV
        LDA DEVTB+8,X
        STA NUMPAD
        LDA POSTB,X
        STA POS
        RTS
*
* SET FILE OUTPUT
*****************
*
SETDV2  STX OUTDEV
        LDA =';'
        JSR FOLLOW
        LDA POS
        STA POSTB
        LDA =<OUTFIL
        STA PVECT
        LDA =>OUTFIL
        STA PVECT+1
        LDA =0
        STA NUMPAD
        STA POS
        JMP SETDV3
*
* RSTDEV: RESET OUTPUT DEVICE
*****************************
*
RSTDEV  TXA
        PHA
        LDX OUTDEV
        CPX =4          SKIP, IF FILE
        BCS *+6
        LDA POS
        STA POSTB,X
        LDX =0
        STX PLMODE
        JSR SETDV1
        PLA
        TAX
        RTS
*
*
DEVTB   BYT <PRTCHR,<PRTRSA,<PRTTTY,<CHAR
        BYT >PRTCHR,>PRTRSA,>PRTTTY,>CHAR
        BYT 0,0,2,0
*
* PLOT
******
*
PLOT    CMP =$A2        PLOT NEW
        BNE PLOT0
        LDA =0
        STA PLMODE
        JSR INITP
        JMP PLOT3+4
*
PLOT0   CMP =$9C        PLOT CLEAR
        BNE PLOT1
        JSR CLEARP
        JMP FETCH
*
PLOT1   CMP =$84        PLOT END
        BNE PLOT2
        LDA VFLAG
        AND =$DF
        STA VFLAG
        LDA =$29
        STA NUMLIN
        JSR ICRTAL
        LDA =$11        CLEAR DISPLAY
        JSR PRTCHR
        JMP FETCH
*
PLOT2   CMP =$90        PLOT STOP
        BNE PLOT3
        JMP PLOT2-11
*
PLOT3   CMP =$9A        PLOT CONT
        BNE PLOT4
        JSR ICRTGR
        JMP FETCH
*
PLOT4   JSR PLOTAR      PLOT X,Y
        JSR PLOTP
PLOTE   LDA =0
        STA PLMODE
        JMP FETCH1
*
* MOVE:
*******
*
MOVE    JSR PLOTAR
        JSR MOVEP
        JMP PLOTE
*
* DRAW:
*******
*
DRAW    JSR PLOTAR
        JSR DRAWP
        JMP PLOTE
*
* PLOTAR: PLOT ARGUMENTS
************************
*
PLOTAR  JSR PLOTA1
        PHA
        LDA =','
        JSR FOLLOW
        JSR PLOTA1
        PHA
        JSR PLMD
        PLA
        TAY
        PLA
        TAX
        RTS
*
PLOTA1  JSR EXPRES
        JSR TESTTP
        LDA SIGN
        BPL *+5
        LDA =0
        RTS
*
        LDA EXP
        CMP =$89
        BCC *+5
        LDA =$FF
        RTS
*
        JSR NUMEXP+9
        TXA
        RTS
*
* PLMD: GET PLOT MODE
*********************
*
PLMD    JSR FETCH1
        CMP =','
        BNE PLMD1
        JSR NUMEXP
        TXA
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        STA PLMODE
PLMD1   RTS
*
* CHAR: PRINT ON GRAPHICS DISPLAY
*********************************
*
CHAR    AND =$7F
        CMP =$D         CARRIAGE RETURN
        BNE CHARA
        LDX =0
        STX XCURS
        RTS
*
CHARA   CMP =$A         LINE FEED
        BNE CHARB
        LDA YCURS
        CLC
        ADC =9
        STA YCURS
        RTS
*
CHARB   JMP CHAR0
*
*
* WAIT: STATEMENT ROUTINE
*************************
*
WAIT    JSR EXPRES
        JSR TESTTP
        JSR FLPINT-4
        LDX MANT+3
        LDY MANT+2
	INX
	INY
        JMP WAIT1+2
*
WAIT1   LDX =$FF
        JSR BREAKT
        LDA =6
        STA EMUCOM      WAIT 10 MSEC
        DEX
        BNE WAIT1+2
        DEY
        BNE WAIT1
        JMP FETCH1
*
*
*
* AUTO: SET AUTO LINE MODE
**************************
*
AUTO    LDX =0          DEFAULT LINE NO
        STX INTEG+1
        LDX =10
        STX INTEG
        BCS *+5         SKIP, IF NO NUMBER
        JSR FETCHI
*
        LDX =10         DEFAULT INCREMENT
        CMP =','
        BNE *+5
        JSR NUMEXP      GET INCREMENT
*
        STX AUTOIN
        PLA
        PLA
        LDA INTEG+1
        LDX INTEG
AUTOIN2 JSR OUTINT
        LDA =' '
        JSR OUTCHR
        LDX =0
        JSR INLIN+2
        JMP WARM1+3
*
        TIT GRAPHIC BASIC - FILE HANDLING
        PAG
*
* RESGP: RESET OPEN FILES, AUTOIN AND TAPES
*******************************************
* CALLED IN COLDSTART, NEW AND CLR
*
RESGP   LDA TAPAOF      STOP TAPE A
        LDA TAPBOF      STOP TAPE 2
        JSR RSTIDV
        LDA =0
        STA FORMCS      CLEAR FORMATTING
        STA FORMFL
        STA AFILNO      NO ACTIVE FILE
        LDY =7
        STA FIDRTB,Y    NO OPEN FILE
        STA FISYTB,Y
        DEY
        BPL *-7
        RTS
*
* OPEN: OPEN A FILE
*******************
*
OPENBS  JSR NUMEXP+3    GET FILE NUMBER
        TXA
        CMP =4          MUST BE >=4
        BCS *+7
FNERR   LDX =7          FILE NUMBER ERROR
FERR1   JMP FERROR
*
        STA AFILNO
        JSR SRFILN      SHOULD NOT BE IN TABLE
        BNE *+6
        LDX =0          DOUBLE FILE NO ERROR
        BEQ FERR1
*
        LDA =','
        JSR FOLLOW
        JSR GETBF4      GET FILE NAME
*
        LDX FILDRV      GETD DRIVE CODE
        CPX =4          DEFAULT =0
        BCC *+6         MUST BE <4
        LDX =21         DRIVE NO ERROR
        BNE FERR1
*
OPEN1   JSR DEFARG2     GET DIRECTION CODE
        CMP =2          DEFAULT 0
        BCC *+6
        LDA =51         FILE DIRECTION ERROR
        BNE FERR1
*
        ASL A
        ASL A
        ASL A
        ASL A
        ASL A
        STA FILFLG
*
        JSR GETBCD      GET LOCATION, IF THERE
        STA FILLOC
        STY FILLOC+1
        LDA ='D'
        STA FILSTP
        JSR OPEN        OPEN FILE
        BEQ *+5
        JMP FILERR
        LDA AFILNO
        STA FISYTB,Y    STORE SYMBOLIC NAME
        RTS
*
* SRFILN: SEARCH FILE NUMBER
****************************
* Z=1 IF FOUND, Y GIVES ENTRY NUMBER, FILE
* NO TO SEARCH MUST BE IN A, A AND X SAVED
*
SRFILN  LDY =7
        CMP FISYTB,Y
        BEQ *+5
        DEY
        BPL *-6
        RTS
*
*
* ERROR STRINGS FOR FILE ERRORS
*******************************
*
FERSTR  BYT 'DOUBLE '
        BYT 'FILE NO'+128
        BYT 'DOUBLE '
        BYT 'DRIVE NO'+128
        BYT 'FILETYPE'+128
        BYT 'TOO MANY FILES'+128
        BYT 'FILE DIRECTION'+128
        BYT 'FILE NOT FOUND'+128
        BYT 'FILE READ'+128
        BYT 'DISK NOT READY'+128
        BYT 'DIRECTORY FULL'+128
        BYT 'DISK FULL OR TAPE BUSY'+128
*
* CONVERSION TABLE FOR SYSTEM FILE ERRORS
*
FERTB   BYT 79,79,79,79,29,65,88,102
        BYT 37,51,07,116,116
*
* SYSTEM FILE ERROR
*******************
*
        TYA
FILERR  CMP =9
        BCC *+4
        SBC =$1A
        CMP =14
        BCS FILERR2
        TAY
        LDA FERTB-1,Y
        TAX
*
* FILE ERROR HANDLING
*********************
*
FERROR  LDA VFLAG
        AND =$67
        STA VFLAG
        LDA OUTDEV
        BEQ *+9
        JSR RSTDEV
        LDA =0
        STA OUTDEV
*
        JSR CRLF
        JSR RSTO1
*
        LDA FERSTR,X
        PHA
        AND =$7F
        JSR OUTCHR
        INX
        PLA
        BPL *-11
        JMP STOP2-7
*
FILERR2 LDX =88
        BNE FERROR
*
* CLOSE: CLOSE OPEN FILE
************************
* IF NO ARGUMENTS GIVEN: CLOSE ALL FILES
*
CLOSEBS BNE CLOSE1
        LDY =7
        LDA FISYTB,Y
        BEQ *+5
        JSR CLOSE2
        DEY
        BPL CLOSEBS+4
        RTS
*
CLOSE1  JSR FETCH1
        JSR NUMEXP+3
        TXA
        CMP =4
        BCS *+5
        JMP FNERR       FILE NUMBER ERROR
*
        JSR SRFILN
        BEQ CLOSE2
NFERR   LDX =65
        JMP FERROR
*
CLOSE2  STY AFILNO
        TYA
        TAX
        JSR CLOSE
        BNE FILERR-1
        LDA =0
        LDY AFILNO
        STA FISYTB,Y
        STA AFILNO
        RTS
*
* SET FILE OUTPUT
*****************
*
SETDV3  TXA
        JSR SRFILN
        BNE NFERR
        STY AFILNO
        RTS
*
* OUTFIL: PRINT TO A FILE
*************************
*
OUTFIL  LDX AFILNO
        LDY =0
        STY FILFLG
        JSR WRITCH
        BEQ OUTFIL-1    RTS, IF OK
        JMP FILERR-1
*
*
* RSTO1: RESET INPUT DEVICE AND GRAPHICS
****************************************
* X SAVED
*
RSTO1   TXA
        PHA
        JSR GETEND      RESET INPUT DEVICE
        PLA
        TAX
        JMP ALPHAD
*
* RSTALL: RESTET INPUT,OUTPUT AND GRAPHICS
******************************************
*
RSTALL  PHP             SAVE STATUS
        LDA OUTDEV
        BEQ *+9
        JSR RSTDEV
        LDA =0
        STA OUTDEV
        JSR GETEND
        JSR ALPHAD
        PLP
        RTS
*
* SETINP: SETINPUT DEVICE
*************************
*
SETINP  JSR NUMEXP
        STX INPDEV
        CPX =4
        BCC *+7
        JSR SETDV3
        LDX =4
        LDA =';'
        JSR FOLLOW
SETIN1  LDA INVTB,X     SET VECTOR FOR INCHR
        STA IVECT
        LDA INVTB+5,X
        STA IVECT+1
        RTS
*
INVTB   BYT <GETKEY,<TSTKEY,<GETTTY
        BYT <GETGRA,<INFIL
        BYT >GETKEY,>TSTKEY,>GETTTY
        BYT >GETGRA,>INFIL
*
* RSTIDV: RESET INPUT DEVICE
****************************
*
RSTIDV  LDX =0
        BEQ SETIN1
*
* INCHR INPUT A CHAR
********************
*
INCHR   STX ISAVXY
        STY ISAVXY+1
        JSR INCH1
        LDX ISAVXY
        LDY ISAVXY+1
        AND =$7F
        RTS
*
INCH1   JMP (IVECT)
*
* TSTKEY: TEST KEY
******************
* RESTURN A=0 IF NO KEY PRESSES, ELSE KEY
*
TSTKEY  LDA CHARREG
        BEQ *+7
        LDX =0
        STX CHARREG
        RTS
*
*
* GETGRA: GET KEY AND PRINT TO GRAPHICS
***************************************
*
GETGRA  JSR GETKEY
        PHA
        CMP =$7F
        BEQ *+11
        CMP =$5F
        BEQ *+7
        JSR CHAR
        PLA
        RTS
*
        LDA XCURS
        SEC
        SBC =6
        BCS *+4
        LDA =0
        STA XCURS
        PHA             SAVE XCURS
        LDA =$80
        STA PLMODE
        LDA =$5C
        JSR CHAR
        LDA =0
        STA PLMODE
        PLA
        STA XCURS
        PLA
        RTS
*
* INFIL: INPUT FROM FILE
************************
*
INFIL   LDX AFILNO
        LDA =0
        STA FILFLG
        JSR READCH
        BEQ INFIL-1     RTS, IF OK
        JMP FILERR-1
*
*
* COPY: COPY FROM ANY DEVICE TO ANY DEVICE
******************************************
* DEVICE CAN BE SYMBOLIC FILE OR PHYSICAL
* DEVICE (I/O CODES 0-3)
*
COPY    JSR NUMEXP+3    GET INPUT DEVICE
        STX INPDEV
        CPX =4
        BCC *+7
        JSR SETDV3
        LDX =4
        LDA =','
        JSR SETIN1-3    SET DEVICE
        JSR FETCH1
        JSR NUMEXP+3
        CPX =3
        BCS *+8
        JSR SETDV1-4
        JMP COPY1
*
        STX OUTDEV
        JSR SETDV2+7
*
COPY1   LDA INPDEV
        CMP OUTDEV
        BNE *+5
        JMP FNERR
*
        JSR DEFARG2
        CMP =0           TERMINATOR
        BNE *+4
        LDA =$1F
        STA LENGHT
*
COPY2   LDA INPDEV
        CMP =4
        BCC COPY3
        JSR SRFILN
        BNE COPY6
        STY AFILNO
*
COPY3   JSR INCHR
        CMP =$1F
        BEQ COPY5
        CMP LENGHT
        BEQ COPY5
*
        LDX OUTDEV
        CPX =4
        BCC COPY4
        PHA
        TXA
        JSR SRFILN
        BNE COPY6-1
        STY AFILNO
        PLA
*
COPY4   JSR OUTCHR
        CMP =$D
        BNE *+7
        LDA =$A
        JSR OUTCHR
        JSR BREAKT
        JMP COPY2
*
COPY5   LDA OUTDEV
        BEQ *+9
        JSR RSTDEV
        LDA =0
        STA OUTDEV
        JMP GETEND
*
        PLA
COPY6   JMP FNERR
*
* FILES: PRINT OPEN FILES TO DISPLAY
************************************
*
FILES   LDA =<FILEM
        LDY =>FILEM
        JSR OUTSTR
*
FILE1   LDY =7
        LDA FISYTB,Y
        BEQ *+5
        JSR FILE2
        DEY
        BPL FILE1+2
        RTS
*
FILE2   JSR FILE3       PRINT SYMBOLIC NAME
        LDA FIDVTB,Y
        JSR FILE3       PRINT DEVICE
        LDA FIDRTB,Y
        ASL A
        LDA =0
        ROL A
        JSR FILE3       PRINT R/W DIRECTION
        LDA FIRCTB,Y
        JSR FILE3
        JMP CRLF
*
FILE3   TAX
        TYA
        PHA
        LDA =0
        JSR OUTINT
        PLA
        TAY
        LDA =9
        JMP OUTCHR
*
FILEM   BYT $D,$A,'MO',9,'DRIVE'
        BYT 9,'DIR',9,'RECORD'
        BYT $D,$A,0
*
*
* GETBCD: GET BASIC ARGUMENT, CONVERT TO
****************************************
* 4 DIGIT BCD NUMBER IN A,Y
*
GETBCD  JSR DEFARG
        LDA =0
        STA MANT
        STA MANT+1
        LDX =15
GETBCD1 ASL INTEG
        ROL INTEG+1
        BCC GETBCD2
        SED
        LDA MANT
        ADC GETBCD3,X
        STA MANT
        LDA MANT+1
        ADC GETBCD3+16,X
        STA MANT+1
        CLD
GETBCD2 DEX
        BPL GETBCD1
        LDA MANT
        LDY MANT+1
        RTS
*
GETBCD3 BYT 0,1,3
        BYT 7,$15,$31
        BYT $63,$27,$55
        BYT $11,$23,$47
        BYT $95,$91,$83
        BYT $67
*
        BYT 0,0,0
        BYT 0,0,0
        BYT 0,1,2
        BYT 5,$10,$20
        BYT $40,$81,$63
        BYT $32
*
*
*
* OUTCON: OUTPUT CONVERSION (WITH FORMATTING)
*********************************************
*
OUTCON  LDY =1          START OF STRING
        LDA =0
        STA FORMCD      TEST FORMATTING CODE
        CMP =3          HEX FORMATTING
        BNE FORM4       SKIP, IF NOT
*
        LDA ='$'
        STA 255,Y
        STY DYADIC+8
        LDA =<HEXMAX
        LDY =>HEXMAX
        JSR COMPAR      TEST MAX VALUE
        BMI *+5
        JMP QERR
*
        JSR FLPIN1
        LDX =7
        STX TEMP6
FORM1   LDY =3
        ASL MANT+3
        ROL MANT+2
        ROL MANT+1
        ROL MANT
        ROL A
        DEY
        BPL FORM1+2
        AND =$F
        BNE FORM2
        BIT TEMP6
        BMI FORM2
        CPX FORMNO
        BCC FORM2
        BCS FORM3
*
FORM2   CMP =$A         CONVERT TO HEX DIGIT
        CLC
        BMI *+4
        ADC =7
        ADC =$30
        INC DYADIC+8
        LDY DYADIC+8
        STA 255,Y
