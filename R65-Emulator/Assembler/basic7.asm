* BASIC7:A ORIGINAL 7/1/1982, RECOVERED 3/2018
        LDA =$80
        STA TEMP6
FORM3   DEX
        BPL FORM1
        LDY DYADIC+8
        JMP OUTZER+3
*
HEXMAX  BYT $9F,$7F,$FF,$FF,$FF
*
* OUTPUT, IF NOT HEX
*
FORM4   LDA =' '
        BIT SIGN
        BPL *+4
        LDA ='-'
        STA 255,Y
        STA SIGN
        STY DYADIC+8
        INY
        LDA =$F8
        STA POINTC
        LDX EXP
        BEQ OUTCN3
*
        LDA =0
        CPX =$80
        BEQ *+4
        BCS *+11
*
        LDA =<(OUTCT1+10)
        LDY =>(OUTCT1+10)
        JSR MULT-3      MULTIPLY BY 1.0E9
        LDA =$F7
*
        STA POINTC
OUTCN0  LDA =<(OUTCT1+5)
        LDY =>(OUTCT1+5)
        JSR COMPAR
        BEQ OUTCN3
        BPL OUTCN1      TOO BIG FOR INT
        LDA =<OUTCT1
        LDY =>OUTCT1
        JSR COMPAR
        BEQ *+4
        BPL OUTCN1+7
        JSR MULTEN      TOO SMALL FOR INT
        DEC POINTC
        BNE *-16
*
OUTCN1  JSR DIVTEN
        INC POINTC
        BNE OUTCN0      ALLWAYS TAKEN
*
        JSR ADD9
OUTCN3  LDX FORMCD      TEST FORMATTING CODE
        BEQ FORM8       SKIP, IF AUTO FORMAT
        LDA =8
        DEX
        BEQ FORM5       SKIP, IF E-FORMAT
        LDA =0
        SEC
        SBC POINTC
FORM5   SEC
        SBC FORMNO      COMPUTE NEW ROUNDING
        BMI FORM8
        BEQ FORM8
        CMP =$A
        BCS FORM8
        STA FORMCT      ROUNDING IS .5*10^FORMCT
        LDX =<TEMP6
        LDY =>TEMP6
        JSR SAVFLP+4
        LDA =<OUTCT2
        LDY =>OUTCT2
        JSR GETFLP
FORM6   JSR MULTEN
        DEC FORMCT
        BNE FORM6
*
        LDA =<TEMP6
        LDY =>TEMP6
        JSR ADD-3       ADD ROUNDING
        LDA =<(OUTCT1+5)
        LDY =>(OUTCT1+5)
        JSR COMPAR
        BEQ FORM8
        BMI FORM8
        JSR DIVTEN
        INC POINTC
        JSR ADD9
*
FORM8   JSR FLPIN1
        LDX =1
        LDA POINTC
        CLC
        ADC =10
        LDY FORMCD
        BEQ FORM7
        DEY
        BEQ EXPOUT      EXPOUT, IF E-FORMAT
        BNE FORM7+3
*
FORM7   TAY             IN AUTO FORMAT
        BMI EXPOUT      EXPOUT, IF <0.01
*
        CMP =11         IN AUTO AND F=FORMAT
        BPL EXPOUT+1    EXPOUT, IF TOO BIG
*
FIXOUT  CLC
        ADC =255
        CMP =$F5        CORRECTION FOR UNDER-
        BPL *+4         FLOW IN FIXOUT
        LDX =$F5
        TAX             DECIMAL POINT TO X
        LDA =2          DUMMY EXPONTENT
*
EXPOUT  SEC
        SBC =2
        STA CURREX      PRINTED EXPONENT
        STX POINTC      DECIMAL POINT OFFSET
        TXA
        BEQ *+4
        BPL OUTCN2
*
        LDY DYADIC+8
        LDA ='0'
        INY
        STA 255,Y
        LDA ='.'
        INY
        STA 255,Y
        TXA
        BEQ OUTCN2-2
        LDA ='0'
        INY
        STA 255,Y
        INX
        BNE *-5
*
        STY DYADIC+8
OUTCN2  LDY =0
        LDX =128
        LDA MANT+3
        CLC
        ADC OUTCT2+8,Y
        STA MANT+3
        LDA MANT+2
        ADC OUTCT2+7,Y
        STA MANT+2
        LDA MANT+1
        ADC OUTCT2+6,Y
        STA MANT+1
        LDA MANT
        ADC OUTCT2+5,Y
        STA MANT
        INX
        BCS *+6
        BPL OUTCN2+4
        BMI *+4
        BMI OUTCN2+4
        TXA
        BCC *+6
        EOR =$FF
        ADC =$0A
        ADC =$2F
        INY
        INY
        INY
        INY
        STY VARSTP
        LDY DYADIC+8
        INY
        TAX
        AND =$7F
        STA 255,Y
        DEC POINTC
        BNE *+8
        LDA ='.'
        INY
        STA 255,Y
        STY DYADIC+8
*
        LDY VARSTP
        TXA
        EOR =$FF
        AND =$80
        TAX
        CPY =$24
        BEQ OUTCN4
        LDA POINTC
        CMP =$F6
        BMI OUTCN4
        CPY =$3C
        BNE OUTCN2+4
*
OUTCN4  LDY DYADIC+8    GET END OF STRING
        LDX FORMCD
        BEQ FORM10
        TYA
        CLC
        ADC POINTC
        CLC
        ADC FORMNO
        CMP DYADIC+8
        BCS *+3
        TAY
        LDA 255,Y       DO NOT PRINT
        CMP ='.'        ENDING POINT
        BNE *+3
        DEY
        DEX
        BNE FORM11
*
        LDA ='+'
        LDX CURREX
        JMP FORM12
*
FORM10  LDA 255,Y
        DEY
        CMP ='0'
        BEQ *-6
        CMP ='.'
        BEQ *+3
        INY
FORM11  LDA ='+'
        LDX CURREX
        BEQ OUTZER+3
*
FORM12  BPL *+10
        LDA =0
        SEC
        SBC CURREX
        TAX
        LDA ='-'
        STA 257,Y
        LDA ='E'
        STA 256,Y
        TXA
        LDX =$2F
        SEC
        INX
        SBC =10
        BCS *-3
        ADC =$3A
        STA 259,Y
        TXA
        STA 258,Y
        INY
        INY
        INY
        INY
        JMP OUTZER+3
*
OUTZER  STA 255,Y
        LDA =0
        STA 256,Y
        TYA
        TAX
        LDA =0
        LDY =1
        RTS
*
*
* FORMOUT: FORMATTED OUTPUT
***************************
*
FORMOUT LDY =1
        TYA
        PHA
        LDA FORMCS
        JSR OUTCON+4
        PLA
        BNE *+4
        INX
        DEY
        STY TEMP6+1
        TAY
        DEY
        STY TEMP6
        TXA
        SEC
        SBC FORMFL
        BCS OUTEND
*
        EOR =$FF
        STA DYADIC+8
        SEC
        ADC TEMP6
        STA TEMP6+2
        LDA TEMP6+1
        ADC =0
        STA TEMP6+3
        TXA
        TAY
        LDA (TEMP6),Y
        STA (TEMP6+2),Y
        DEY
        BPL *-5
*
        LDY DYADIC+8
        LDA =$20
        STA (TEMP6),Y
        DEY
        BPL *-3
OUTEND  LDA =0
        LDY =1
        RTS
*
*
* FORMAT: SET FORMATTING
************************
*
FORMAT  JSR TLETT
        BCS *+5
        JMP SYNERR      MUST BE LETTER
*
        CMP ='A'        AUTO FORMAT
        BNE FORMAT1
*
        LDA =0
        BEQ FORMAT2
*
FORMAT1 CMP ='F'        F-FORMAT
        BNE FORMAT3
        LDA =2
FORMAT2 STA FORMCS
        JSR NUMEXP
        CPX =16
        BCS QERR2
        STX FORMFL
        JSR DEFARG2
        CMP =9
        BCC *+5
QERR2   JMP QERR
        STA FORMNO
        RTS
*
FORMAT3 CMP ='E'        E-FORMAT
        BNE FORMAT4
        LDA =1
        BNE FORMAT2
*
FORMAT4 CMP ='H'        HEX-FORMAT
        BNE FORMAT+5    SYNTAX ERROR
        LDA =3
        BNE FORMAT2
*
*
* HEX INPUT
***********
*
NUMBHEX LDA =0
        STA MANT
        STA MANT+1
        STA MANT+2
        STA MANT+3
NUMBH0  JSR FETCH
        BCC NUMBH1      SKIP, IF NUMBER
        CMP ='A'
        BCC NUMBH3
        CMP ='G'
        BCS NUMBH3
        CLC
        ADC =9
NUMBH1  AND =$F
        ASL A
        ASL A
        ASL A
        ASL A
        LDY =3
NUMBH2  ASL A
        ROL MANT+3
        ROL MANT+2
        ROL MANT+1
        ROL MANT
        BPL *+5
        JMP QERR        INPUT TOO LARGE
        DEY
        BPL NUMBH2
        JMP NUMBH0
*
NUMBH3  LDX =0
        STX RESTYP
        STX DYADIC+7
        STX SIGN
        LDX =$A0
        LDA MANT
        EOR =$FF
        ROL A
        STX EXP
        JMP NORMAL
*
*
* MERGE: MERGE PROGRAM TO OLD ONE
*********************************
*
MERGE   JSR GETBF4      GET NAME ETC.
        LDA STVAR
        LDX STVAR+1
        SEC
        SBC =3
        BCS *+3
        DEX
        JMP LOAD1+4
*
* DIR: PRINT DIRECTORY
**********************
*
DIR     LDX =0
        BCS *+5
        JSR NUMEXP+3
        STX FILDRV
        LDA =0
        STA FILFLG
        TXA
        AND =2
        BNE *+5
        JMP DDIR
        JMP TDIR
*
*
* DELETE: DELETE DISK FILE
**************************
*
DELBAS  JSR GETBF4
        JSR DELETE
        BEQ *+5
        JMP FILERR
        RTS
*
* STA: STATUS FUNCTION
**********************
*
STA     JSR NUMEXP+6    CONVERT TO BYTE
        CPX =3
        BNE STA1
*
        LDX XCURS
        LDY YCURS
        LDA =28
        SEI
        STA MULTA
        STY MULTB
        TXA
        LSR A
        LSR A
        LSR A
        CLC
        ADC MULTR
        STA GRPNT
        LDA MULTR+1
        CLI
        ADC =$07
        STA GRPNT+1
        TXA
        AND =7
        TAX
        LDA GRMASK,X
        LDX =0
        AND (GRPNT,X)
        BEQ *+4
        LDA =1
        TAY
STA6    LDA =0
        JMP INTFLP
*
STA1    BCS STA5
        DEX
        BPL STA2
        JMP FRE
*
STA2    BNE STA3
        SEC
        LDA STVAR
        SBC STPROG
        TAY
        LDA STVAR+1
        SBC STPROG+1
        JMP INTFLP
*
STA3    LDY VFLAG
        JMP STA6
*
STA5    TXA
        JSR SRFILN
        BEQ *+6
        LDY =0
        BEQ STA6
*
        LDA FIDRTB,Y
        ASL A
        ROL A
        TAY
        INY
        JMP STA6
*
GRMASK  BYT $80,$40,$20
        BYT $10,$08,$04
        BYT $02,$01
*
* OUT: SET OUTPUT DEVICE
************************
*
OUT     CMP =0
        BNE OUT2
        LDA VFLAG
        AND =$7F
        STA VFLAG
        LDX =1
OUT1    LDA DEVTB,X
        STA VAUTOP
        LDA DEVTB+4,X
        STA VAUTOP+1
        RTS
*
OUT2    JSR NUMEXP+3
        CPX =0
        BEQ OUT+4
        LDA VFLAG
        ORA =8
        STA VFLAG
        CPX =4
        BCC OUT1
*
        LDA =<OUT4
        STA VAUTOP
        LDA =>OUT4
        STA VAUTOP+1
        TXA
        JSR SRFILN
        BEQ *+8
        JSR OUT+4
        JMP NFERR
*
        STY OUTSAV
        RTS
*
OUT4    LDX OUTSAV
        JMP OUTFIL+2
*
*
* RENUMBERING
*************
*
LINBUF  EQU BUFFER-2
SAVPC   EQU XLOW
BEGIN   EQU XINCR
STEP    EQU YINCR
*
* START OF PROGRAM
*
RENUMB  LDX =10         SET DEFAULT LINE #
        STX INTEG
        LDX =0
        STX INTEG+1
        BCS *+5
        JSR FETCHI
        LDX INTEG
        STX BEGIN
        LDX INTEG+1
        STX BEGIN+1
        LDX =10         DEFAULT STEP SIZE
        CMP =','
        BNE *+5
        JSR NUMEXP
        STX STEP
        JSR CLR1-3
*
*
* FILL BUFFER WITH OLD LINE #'S AND
* RENUMBER THE BEGINNING ONLY
*
COPNUM  LDA =<LINBUF
        STA TEMP8
        LDA =>LINBUF
        STA TEMP8+1
        LDA STPROG      BEGIN OF TEXT
        STA TEMP1
        LDA STPROG+1
        STA TEMP1+1
        JSR SETFAC      SET NEW LINE # CNTR
*
COP10   LDY =3
COP20   LDA (TEMP1),Y
        STA (TEMP8),Y
        LDA MANT-3,Y
        STA (TEMP1),Y
        DEY
        CPY =1
        BNE COP20
        LDA (TEMP1),Y
        BEQ COP80
        JSR BUPX2
        TAX
        DEY
        LDA (TEMP1),Y
        STA TEMP1
        STX TEMP1+1
        JSR ADDSTP
        BNE COP10
*
COP80   LDA =$FF
        INY
        STA (TEMP8),Y
        INY
        STA (TEMP8+1),Y
*
RENN    LDA STPROG
        STA PC
        LDA STPROG+1
        STA PC+1
        BNE RN15
RN10    JSR GRAB
RN15    JSR GRAB
        BNE RN20
        JSR CLR1-3
        JSR ADLNP0
        JMP WARMST
RN20    JSR GRAB
        JSR GRAB
RN30    JSR GRAB
RN35    TAX
        BEQ RN10        EOL?
*
RN40    LDX =4
RN45    CMP TOKEN-1,X
        BEQ RN50
        DEX
        BNE RN45
        BEQ RN30        ALL TRIED, FORGET IT
RN50    LDA PC
        STA SAVPC
        LDA PC+1
        STA SAVPC+1
        JSR FETCH
        BCS RN35
        JSR FETCHI
        JSR FINUM
        LDA SAVPC
        STA PC
        LDA SAVPC+1
        STA PC+1
        LDY =0
        LDX =0
*
RN60    LDA $101,X
        BEQ RN70
        PHA
        JSR FETCH
        BCC RN65
        JSR MOVUP
RN65    PLA
        STA (PC),Y
        INX
        BNE RN60
*
RN70    JSR FETCH
RN75    BCS RN80
RN78    JSR MOVDWN
        JSR FETCH1
        BCC RN78
RN80    CMP =','
        BEQ RN50
        BNE RN35
*
*
* FIND OLD # IN BUFFER, GENERATE A NEW
* LINE #
*
FINUM   JSR SETFAC
        LDA =<BUFFER
        STA TEMP8
        LDA =>BUFFER
        STA TEMP8+1
FN10    LDY =1
        LDA (TEMP8),Y
        CMP INTEG+1
        BEQ FN50
        CMP =$FF
        BNE FN60
        STA MANT
        STA MANT-1
FN20    LDA MANT-1
        STA MANT+1
        LDX =$90
        SEC
        JSR FLOAT
        JMP OUTCON
*
FN50    DEY
        LDA (TEMP8),Y
        CMP INTEG
        BEQ FN20
FN60    JSR ADDSTP
        JSR BUPX2
        BNE FN10
*
*
* MOVE TEXT UP ONE CHAR
*
MOVUP   JSR SETPTR
MU10    LDY =0
        LDA (TEMP1),Y
        INY
        STA (TEMP1),Y
        JSR CMPX
        BNE MU40
        INC STVAR
        BNE MU20
        INC STVAR+1
*
MU20    DEY
        RTS
MU40    LDY TEMP1
        BNE MU60
        DEC TEMP1+1
MU60    DEC TEMP1
        JMP MU10
*
*
* MOVE TEXT DOWN ONE CHAR
*
MOVDWN  JSR SETPTR
MD10    LDY =1
        LDA (TEMP8),Y
        DEY
        STA (TEMP8),Y
        JSR CMPX
        BEQ MD30
MD20    JSR BUPX1
        BNE MD10
MD30    LDY STVAR
        BNE MD35
        DEC STVAR+1
MD35    DEC STVAR
MD40    RTS
*
*
* SET POINTER FOR MOVE
*
SETPTR  LDA STVAR
        STA TEMP1
        LDA STVAR+1
        STA TEMP1+1
        LDA PC
        STA TEMP8
        LDA PC+1
        STA TEMP8+1
        RTS
*
*
* SETUP MANT TO GENERATE NEW LINE #'S
*
SETFAC  LDA BEGIN
        STA MANT-1
        LDA BEGIN+1
        STA MANT
        RTS
*
*
* ADD STEP TO MANT
*
ADDSTP  LDA MANT-1
        CLC
        ADC STEP
        STA MANT-1
        BCC ARTS
        INC MANT
ARTS    RTS
*
*
* COMPARE THE TWO INDICES
* Z-FLAG SET OF EQUAL
*
CMPX    LDA TEMP1
        CMP TEMP8
        BNE CRTS
        LDA TEMP1+1
        CMP TEMP8+1
CRTS    RTS
*
*
* INCREMENT TEMP8 1 OR 2
*
BUPX2   JSR BUPX1
BUPX1   INC TEMP8
        BNE BRTS
        INC TEMP8+1
BRTS    RTS
*
*
* GET A CHAR, SET Z FLAG
*
GRAB    LDY =0
        INC PC
        BNE GR10
        INC PC+1
GR10    LDA (PC),Y
        RTS
*
*
* TABLE OF TOKENS
*
TOKEN   BYT $B4         THEN
        BYT $89         GOTO
        BYT $8D         GOSUB
        BYT $8C         RESTORE
*
        TIT GRAPHIC BASIC - GRAPHPACK
        PAG
*
**************************
* R65 SYSTEM GRAPHPACK 2 *
**************************
*
* VERSION FOR R65 GRAPHIC BASIC V6.2
*
* SUBROUTINES FOR GRAPHIC DISPLAY ON THE R65
* VIDEO INTERFACE
*
* INIT          INITIALIZE GRAPHIC DISPLAY AND
*               CRT MEMORY
* CLEAR         CLEAR GRAPHIC DISPLAY AND SET
*               GRAPHIC CURSOR TO (0/0)
* MOVE (X,Y)    MOVE GRAPHIC CURSOR TP (X,Y)
* PLOT (X,Y)    PLOT A DOT AT (X,Y) AND MOVE
*               GRAPHICS CURSOR
* DRAW (X,Y)    DRAW A STRAIGHT LINE FROM THE
*               CURRENT POSITION OF THE GRAPHIC
*               CURSOR TO (X,Y) AND MOVE THE
*               GRAPHIC CURSOR
* CHAR (A)      SET STANDARD UPPER CASE ASCII
*               CHAR IN A TO CURRENT POSITION
*               OF THE GRAPHIC CURSOR, INCRE-
*               MENT THE X-POSITION BY 8
*               8*8 MATRIX IS USED
*
* COORDINATES:
*
* THE (0/0) IS IN THE UPPER LEFT, INCREMENTING
* X TO THE RIGHT, INCREMENTING Y DOWN. IN GRAPHI
* BASIC, INCREMENTING Y GOES UP
*
* 0 <= X <= 223         0 <= Y <= 117
*
* COORDINATES, WHICH EXCEED THE LIMITS, ARE
* TRUNCATED TO THE MAXIMAL VALUE
*
*
* PLOT MODE FLAG: (PRESET TO 0 BY INIT)
* BIT 7:        0 PLOT WHITE
*               1 PLOT BLACK
* BIT 6:        0 NORMAL DRAWING MODE
*                1 EXCLUSIVE OR DRAWING
*
*
*
*
*
VIPNT2  EQU $EB         SECOND VIDEO POINTER
*
*
* CALLS TO SYSTEM SUBROUTINES
*****************************
*
FILL    JMP $E245
*
*
* INIT
******
* CONFIGURE VIDEO MEMORY FOR SWAPPED ALPHA
* AND GRAPHICS DISPLAY, SET THE GRAPHIC
* CURSOR TP (0/0)AND CLEAR THE GRAPHIC MEMORY
*
*
INITP   JSR IGRAPH
*
        LDA =$07
        STA GRPAGE
        LDA =0
        STA PLMODE      CLEAR MODE FLAGS
*
*
* CLEAR
*******
* CLEAR GRAPHIC DISPLAY AND MOVE GRAPHIC
* CURSOR TO (0/0)
*
CLEARP  LDA VFLAG
        AND =$20
        BNE *+3
        RTS
        LDA GRPAGE
        TAY
        CLC
        ADC =$C         12 PAGES GRAPHIC
        LDX =$E8
        STX VIPNT2
        STA VIPNT2+1
        LDA =0
        TAX
        JSR FILL
        LDY =117
        LDX =0
        STY YCURS
        STX XCURS
        RTS
*
*
* MOVE (X,Y)
************
* MOVE GRAPHIC CURSOR TO X,Y. TEST DISPLAY
* LIMITS
*
MOVEP   JSR LIMIT
        STX XCURS
        STY YCURS
        RTS
*
*
LIMIT   CPX =224
        BCC *+4
        LDX =223
        CPY =118
        BCC *+4
        LDY =117
        RTS
*
*
* PLOT (X,Y)
************
* MOVE GRAPHIC CURSOR TO (X,Y), TEST DISPLAY
* LIMITS AND SET THE DOT AT (X,Y)
*
PLOTP   JSR MOVEP
        STX GRX
        STY GRY
        LDA PLMODE
        STA GRC
        JMP EPLOT
*
*
* DRAW (X,Y)
************
* DRAW A LINE FROM CURRENT POSITION OF THE
* GRAPHIC CURSOR TO (X,Y). SET GRAPHIC
* CURSOR TO X,Y.
*
DRAWP   LDA XCURS       OLD CURSOR TO GRX,GRY
        STA GRX
        LDA YCURS
        STA GRY
*
        JSR MOVEP
        LDA PLMODE
        STA GRC
        TXA
        CMP GRX         SAME X?
        BNE DRAW2
*
        TYA
        SEC
        SBC GRY
        BCC DRAW1       SKIP IF NEW Y LOWER
*
        STA GRN         NUMBER OF POINTS
        INC GRN
        JMP EDRAWY
*
DRAW1   EOR =$FF
        CLC
        ADC =2
        STA GRN
        STY GRY
        JMP EDRAWY
*
DRAW2   TYA
        CMP GRY         SAME Y
        BNE DRAW4
        TXA
        SEC
        SBC GRX
        BCC DRAW3       SKIP,IF NEW X LOWER
*
        INC GRN
        STA GRN
        JMP EDRAWX
*
DRAW3   EOR =$FF
        CLC
        ADC =2
        STA GRN
        STX GRX
        JMP EDRAWX
*
DRAW4   LDA =0
        STA XINCR+1
        STA YINCR+1
        TXA             BOTH X AND Y DIFF
        SEC
        SBC GRX
        STA XINCR
        BCS DRAW5
        DEC XINCR+1
DRAW5   TYA
        SEC
        SBC GRY
        STA YINCR
        BCS DRAW6
        DEC YINCR+1
DRAW6   LDA =$80        ROUNDING POSITIONS
        STA XLOW
        STA YLOW
        LDA =0
        STA GRN
        LDA GRX
        STA TEMP6
        LDA GRY
        STA TEMP6+1
        JSR EPLOT       PLOT FIRST DOT
DRAW7   CLC
        LDA XLOW
        ADC XINCR
        STA XLOW
        LDA GRX
        ADC XINCR+1
        STA GRX
        CLC
        LDA YLOW
        ADC YINCR
        STA YLOW
        LDA GRY
        ADC YINCR+1
        STA GRY
*
        LDA GRX         PLOT ONLY IF CHANGE
        CMP TEMP6
        BNE DRAW8
        LDA GRY
        CMP TEMP6+1
        BEQ DRAW9       BOTH EQUAL, DON'T PLOT
*
DRAW8   LDA GRX
        STA TEMP6
        LDA GRY
        STA TEMP6+1
        JSR EPLOT       PLOT NEXT 256 DOTS
*
DRAW9   DEC GRN
        BNE DRAW7
*
        RTS
*
*
* CHAR0 (A)
***********
* SET STANDARD UPPER CASE ASCII CHAR I A
* TO THE CURRENT POSITION OF THE GRAPHIC
* CURSOR, THEN MOVE 8 POSITIONS RIGHT
*
CHAR0   LDX XCURS
        CPX =216
        BCC *+4
        LDX =215
        LDY YCURS
        CPY =110
        BCC *+4
        LDY =109
*
        STX GRX
        STY GRY
        STA GRC
        TXA
        CLC
        ADC =8
        CMP =216
        BCC *+4
        LDA =215
        STA XCURS
        JMP EPLOTCH
*
*
* NLOAD
*******
* NEW LOAD - ALSO LOADS PROGRAM FROM OPEN
* SEQUENTIAL FILE, IF CALLED LOAD #D1;
* WHERE D1 IS A FILE OPEN FOR READ
*
NLOAD   CMP ='#'        IS IT A OPEN DEVICE?
        BEQ *+5
        JMP LOAD        NO, LOAD BINARY FILE
*
        JSR FETCH1
        JSR SETINP      SET INPUT DEVICE
NLOAD1  LDA =$2C
        STA INTEG+1
        JSR INPUT2
        LDA INBUFF      LOAD FIRST CHARACTER
        BEQ NLOADE      SKIP, IF EMPTY
        LDX =<INBUFF
        LDY =>INBUFF
        STX PC
        STY PC+1
        JSR FETCH1
        JSR INSL0
        LDA ='.'        HEART BEAT
        JSR OUTCHR
        JSR ADLNP0
        JMP NLOAD1      NEXT LINE
*
*
NLOADE  JSR GETEND      RESET INPUT DEVICE
        LDA =0          CLOSE ALL OPEN FILES
        JSR CLOSEBS     AND RETURN
	JMP WARMST
*
*
        END
*