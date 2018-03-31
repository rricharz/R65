* BASIC2:A ORIGINAL 7/1/1982, RECOVERED 3/2018
        CMP ='"'
        BNE *+8
        LDA TEMP2       SET " FLAG
        EOR =$FF
        STA TEMP2
        INY
        LDA (TRANSP),Y
        BNE LIST7       0 MEANS EOL
        TAY
        LDA (TRANSP),Y  GET ADDRESS OF NEXT
        TAX             LINE
        INY
        LDA (TRANSP),Y
        STX TRANSP
        STA TRANSP+1
        BNE LIST2       ALLWAYS TAKEN
LIST4   LDA OUTDEV
        BEQ *+5
        JSR RSTDEV
        JSR CRLF
        LDA =0
        STA OUTDEV
        JMP WARMST
*
LIST7   BPL LIST3+4
        BIT TEMP2
        BMI LIST3+4
        SEC
        SBC =$7F
        TAX             X=CODE-$7F
        STY TEMP3
        LDA =<COMSTB
        LDY =>COMSTB
        STA TEMP4
        STY TEMP4+1
        LDY =$FF
LIST5   DEX
        BEQ LIST6
        INY             FIND TOKEN STRING
        LDA (TEMP4),Y
        BPL *-3
        CLC
        TYA
        ADC TEMP4
        STA TEMP4
        LDY =0
        BCC LIST5
        INC TEMP4+1
        BNE LIST5       ALLWAYS TAKEN
LIST6   INY
        LDA (TEMP4),Y   PRINT CODE STRING
        BMI LIST3
        JSR OUTCHR
        JMP LIST6
*
*
* EXRUN: EXECUTE RUNNING, MAIN LOOP
***********************************
*
EXRUN   JSR BREAKT
        LDA PC
        LDY PC+1
        BEQ *+8         SKIP IF DIRECT MODE
        STA PNTSAV
        STY PNTSAV+1
        LDY =0
*
        LDA (PC),Y
        BEQ *+18        SKIP, IF EOL
        CMP =':         MUST BE :
        BEQ EXCODE
        CMP ='!
        BEQ *+7
SYNERR  LDX =$F         SYNTAX ERROR
        JMP ERROR
*
        JSR REMARK
        LDY =2
        LDA (PC),Y
        CLC
        BEQ STOP1       BRANCH, IF END OF PRO-
        INY             GRAM OR DIRECT MODE
        LDA (PC),Y
	STA LED16
        STA LINE
        INY
        LDA (PC),Y
	STA LED16+1
        STA LINE+1
        TYA
        ADC PC
        STA PC          ADJUST PC
        BCC *+4
        INC PC+1
*
*
EXCODE  JSR FETCH
        JSR EXCOD1
        JMP EXRUN
*
*
* EXCODE: GET STATEMENT VECTOR AND EXECUTE
*
EXCOD1  BEQ FETCHE      RTS, IF EOL
        SEC
        SBC =128
        BCS *+5
        JMP LET         MUST BE LET
        CMP =$30
        BCS SYNERR      NOT LEGAL STATEMENT
        ASL A
        TAY
        LDA STVECT+1,Y  GET VECTOR
        PHA
        LDA STVECT,Y
        PHA             FETCH, THEN EXECUTE CODE
*
*
* FETCH: FETCH NEXT BASIC CHAR
******************************
* INCREMENT PC, FETCH (PC), BLANKS ARE SKIPPED
* C=0 IF NUMBER
*
FETCH   INC PC
        BNE FETCH1
        INC PC+1
*
FETCH1  STY TEMP4       ENTRY WITHOUT INCR PC
        LDY =0
        LDA (PC),Y
        LDY TEMP4
        CMP =$3A        NUMBER TEST
        BCS FETCHE
        CMP =' '        SKIP BLANKS
        BEQ FETCH
        SEC
        SBC =$30
        SEC
        SBC =$D0
FETCHE  RTS
*
*
* STOP: STATEMENT ROUTINE
*************************
*
STOP    BCS *+3
*
*
* END: STATEMENT ROUTINE
************************
*
END     CLC
        BNE FETCHE      RST, IF NOT EOLD
        JSR RSTALL
        LDA PC
        LDY PC+1
        BEQ STOP1-2     SKIP IN DIRECT MODE
        STA PNTSAV
        STY PNTSAV+1
        LDA LINE
        LDY LINE+1
        STA LINSAV
        STY LINSAV+1
        PLA             RETURN ONE LEVEL
        PLA
STOP1   LDA =<(ERRORM+17)       BREAK MESSAGE
        LDY =>(ERRORM+17)
        BCC *+5
        JMP STOP2
        JMP WARMST
*
*
* RESTORE: STATEMENT ROUTINE
****************************
*
RESTOR  BEQ *+19
        JSR FETCHI      GET LINE NO
        JSR SEARLN
        BCS *+5
        JMP UNDEFS
        LDA TRANSP
        LDY TRANSP+1
        BCS *+7         ALLWAYS TAKEN
*
        LDA STPROG
        LDY STPROG+1
*
        SEC
        SBC =1
        BCS *+3
        DEY
        STA DATPNT
        STY DATPNT+1
        RTS
*
*
* CLR: STATEMENT ROUTINE
************************
*
CLR     BNE *-3         RTS, IF NOT EOLD
        JMP CLR1
*
*
* RUN: STATEMENT ROUTINE
************************
*
RUN     BNE *+5
        JMP CLR1-3      SET PC, CLR AND RUN
*
        JMP LOAD9       LOAD NEW USER PROGRAM
*
*
* GOSUB: STATEMENT ROUTINE
**************************
*
GOSUB   LDA =3
        JSR TSSTK
        LDA PC+1
        PHA             SAVE PC ON STACK
        LDA PC
        PHA
        LDA LINE+1      SAVE LINE
        PHA
        LDA LINE
        PHA
        LDA =$8D        CODE FOR GOSUB
        PHA
        JSR FETCH1
        JSR GOTO
        JMP EXRUN
*
*
* GOTO: STATEMENT ROUTINE
*************************
*
GOTO    JSR FETCHI
        JSR SEEOL
        LDA LINE+1
        CMP INTEG+1
        BCS GOTO1       SEARCH FROM START
*
        TYA             SEARCH FOR NEXT LIN
        SEC
        ADC PC
        LDX PC+1        COMPUTE NEXT LINE
        BCC GOTO1+4
        INX
        BCS GOTO1+4
*
GOTO1   LDA STPROG
        LDX STPROG+1
        JSR SEARLN+4
        BCS *+7
UNDEFS  LDX =$47
        JMP ERROR       UNDEFINED STATEMENT
        LDA TRANSP
        SBC =1
        STA PC          SET NEW PC
        LDA TRANSP+1
        SBC =0
        STA PC+1
        RTS
*
*
* RETURN: STATEMENT ROUTINE
***************************
*
RETURN  BNE *-1         RTS, IF NOT EOLL
        LDA =$FF
        STA TEMP3
        JSR STACK
        TXS
        CMP =$8D        CODE FOR GOSUB
        BEQ *+7
        LDX =$15
        JMP ERROR       NO MATCHING GOSUB
*
        PLA             GET CODE FOR GOSUB
        PLA             GET LINE
        STA LINE
        PLA
        STA LINE+1
        PLA             GET PC FROM STACK
        STA PC
        PLA
        STA PC+1        CONTINUE WITH DATA
*
*
* DATA: STATEMENT ROUTINE
*************************
* SKIPS RESTOF LINE, OR UP TO NEXT ":"
*
DATA    JSR SEDPN
        TYA
        CLC
        ADC PC
        STA PC
        BCC *+4
        INC PC+1
DATAE   RTS
*
*
* SUBROUTINE TO SEARCH IN LINE
******************************
* SEDPN SEARCHES ":" OR EOLD
* SEEOL SEARCHES EOL
* OUTPUT IS Y
*
SEDPN   LDX =$3A
        BNE *+4
SEEOL   LDX =0
        STX CHRSAV
        LDY =0
        STY CHRSAV+1
SEEOL1  LDA CHRSAV+1
        LDX CHRSAV
        STA CHRSAV
        STX CHRSAV+1
        LDA (PC),Y      RTS, IF EOL
        BEQ DATAE
        CMP CHRSAV+1
        BEQ DATAE       RTS, IF MATCHING
        INY
        CMP ='"'        DO NOT SEARCH ":"
        BEQ SEEOL1      IN STRING
        BNE SEEOL1+8    ALLWAYS TAKEN
*
*
* STACK: PREPARE STACK
**********************
* USED IN NEXT AND RETURN
*
STACK   TSX
        INX
        INX
        INX
        INX
        LDA $101,X      STACK PAGE
        CMP =$81
        BNE STACK4
        LDA TEMP3+1
        BNE *+12
        LDA $102,X
        STA TEMP3
        LDA $103,X
        STA TEMP3+1
        CMP $103,X
        BNE *+9
        LDA TEMP3
        CMP $102,X
        BEQ STACK4
        TXA
        CLC
        ADC =18
        TAX
        BNE STACK+5
STACK4  RTS
*
*
* FETCHI: FETCH INTEGER
***********************
*
FETCHI  LDX =0
        STX INTEG
        STX INTEG+1
        BCS STACK4      RTS, IF NOT DIGIT
        SBC =$2F        CONVERT TO DIGIT(C=0)
        STA CHRSAV+1
        LDA INTEG+1
        STA TEMP1
        CMP =$19
        BCC *+5
        JMP SYNERR
*
        LDA INTEG       INTEG=10*INTEG+DIGIT
        ASL A
        ROL TEMP1
        ASL A
        ROL TEMP1
        ADC INTEG
        STA INTEG
        LDA TEMP1
        ADC INTEG+1
        ASL INTEG
        ROL A
        STA INTEG+1
        LDA INTEG
        ADC CHRSAV+1
        STA INTEG
        BCC *+4
        INC INTEG+1
        JSR FETCH
        JMP FETCHI+6
*
*
* OUTSTR: PRINT STRING AT A,Y
*****************************
* END MARK IS 0
*
OUTSTR  JSR STRSIZ
        JSR PREPST
*
* A=NO OF CHARS, TEMP1=START
*
        TAX
        LDY =0
        INX
        DEX
        BEQ STACK4      RTS, IF X=0
        LDA (TEMP1),Y
        JSR OUTCHR
        INY
        CMP =$D         IF CR,PADOUT
        BNE *-11
        JSR PADOUT
        JMP *-16
*
*
* STRSIZ: STRING SIZE IN A,Y
****************************
*
STRSIZ  LDX ='"'
        STX CHRSAV
        STX CHRSAV+1
        STA DYADIC+6
        STY DYADIC+7    SAVE START
        STA MANT
        STY MANT+1
*
        LDY =$FF
STRSI1  INY
        LDA (DYADIC+6),Y
        BEQ STRSI2+4    END MARK
        CMP CHRSAV
        BEQ STRSI2
        CMP CHRSAV+1
        BNE STRSI1
STRSI2  CMP ='"'
        BEQ *+3
        CLC
        STY EXP         SAVE SIZE IN EXP
        TYA
        ADC DYADIC+6    DYADIC+6=START
        STA DYADIC+8    DYADIC+8=END
        LDX DYADIC+7
        BCC *+3
        INX
        STX DYADIC+9
        LDA DYADIC+7
        BNE STRSI3      SKIP, IF STRING NOT
*                       IN PAGE 0
        TYA
        JSR TSTRRM      TEST STRING ROOM
        LDX DYADIC+6
        LDY DYADIC+7
        JSR INSST0      INSERT STRING
*
STRSI3  LDX STRSTP
        CPX =STRST+9
        BNE *+7
        LDX =$B3        FORMULA TOO LONG
        JMP ERROR
*
        LDA EXP
        STA 0,X         SAVE SIZE
        LDA MANT        SAVE START
        STA 1,X
        LDA MANT+1
        STA 2,X
        LDY =0
        STX MANT+2      POINTER TO SAVED
        STY MANT+3
        DEY
        STY RESTYP
        STX STRSTP+1
        INX
        INX
        INX
        STX STRSTP
        RTS
*
*
* PREPST: PREPARE STRING FOR OUTPUT
***********************************
*
PREPST  LDA MANT+2
        LDY MANT+3
        STA TEMP1
        STY TEMP1+1
        JSR PREPS1
        PHP
        LDY =0
        LDA (TEMP1),Y
        PHA             SIZE TO A
        INY
        LDA (TEMP1),Y
        TAX             ADDRESS LOW TO X
        INY
        LDA (TEMP1),Y
        TAY             ADDRESS HIGH TO Y
        PLA
        PLP
        BNE PREPS0
        CPY BTSTRG+1
        BNE PREPS0      BRANCH, IF NOT STORED
        CPX BTSTRG      STRING IN STRING AREA
        BNE PREPS0
        PHA
        CLC
        ADC BTSTRG
        STA BTSTRG
        BCC *+4
        INC BTSTRG+1
        PLA
PREPS0  STX TEMP1
        STY TEMP1+1
        RTS
*
PREPS1  CPY STRSTP+2
        BNE PREPS2
        CMP STRSTP+1
        BNE PREPS2
        STA STRSTP
        SBC =3
        STA STRSTP+1
        LDY =0
PREPS2  RTS
*
*
* COLDST: COLD START
********************
*
COLDST  LDX =$FF
        STX LINE+1
        STX INBNUM+1
        TXS
        CLI
        CLD
        JSR CLOSAL
        LDA =$4C
        STA PNT1-1      VECTOR FOR BFUNC
        LDA PORTB1      WRITE DISABLE BASIC
        AND =$FF        DUMMY
        LDA PORTB1      DUMMY, WAS STA
        LDA =0
        STA CURRSG+1
        STA OUTDEV
        STA INPDEV
        STA AUTOIN
        STA STRSTP+2
        STA NUMPAD
        STA POS
        STA POSTB
        STA POSTB+1
        STA POSTB+2
        STA POSTB+3
        PHA
        STA STRSTP-1
        LDA =3
        STA SIZE
        LDA =$2C
        STA INTEG+1
        JSR RSTDEV
        LDX =STRST      SET STRING STACK POINTER
        STX STRSTP
*
        LDA STRRAM      START OF USER AREA
        LDX STRRAM+1
        STA STPROG
        STX STPROG+1
        LDA ENDRAM      END OF USER AREA
        LDX ENDRAM+1
        STA TPMEM
        STX TPMEM+1
        STA BTSTRG
        STX BTSTRG+1
        LDY =0
        TYA
        STA (STPROG),Y
        INC STPROG
        BNE *+4
        INC STPROG+1
        LDA STPROG
        LDY STPROG+1
        JSR TSROOM
        JSR CRLF
        LDA =<HEADM
        LDY =>HEADM
        JSR OUTSTR
        LDA TPMEM
        SEC
        SBC STPROG
        TAX
        LDA TPMEM+1
        SBC STPROG+1
        JSR OUTINT
        JSR NEW+2
        JMP WARMST
*
HEADM   BYT $D,$A,$A
        BYT 9,'-- R65 GRAPHIC BASIC V 6.1 --'
        BYT $D,$A,$A,'BYTES FREE: ',0
*
*
* CONT: COMMAND ROUTINE
***********************
*
CONT    BNE CONTE       RTS, IF NOT EOL
        LDX =$C6        CONT ERROR?
        LDY PNTSAV+1    =0 IF CONT ILL
        BNE *+5
        JMP ERROR
        LDA PNTSAV
        STA PC
        STY PC+1
        LDA LINSAV
        LDY LINSAV+1
        STA LINE
        STY LINE+1
CONTE   RTS
*
*
* IF: STATEMENT ROUTINE
***********************
*
IF      JSR EXPRES
        JSR FETCH1
        CMP =$89        CODE FOR GOTO
        BEQ *+7
        LDA =$B4        CODE FOR THEN
        JSR FOLLOW      MUST FOLLOW
        LDA EXP         EXP=0:SKIP REST OF LINE
        BNE *+8
*
*
* REMARK: STATEMENT ROUTINE
***************************
*
REMARK  JSR SEEOL
        JMP DATA+3
*
* CONTINUE IF
*
        JSR FETCH1
        BCS *+5
        JMP GOTO
        JMP EXCOD1
*
*
* LET: STATEMENT ROUTINE
************************
*
LET     LDX =0          VARIABLE CAN BE DEFINED
        STX TEMP4+1
        JSR GETVAR
        STA TEMP3       SAVE START
        STY TEMP3+1
        LDA =$BF        CODE FOR =
        JSR FOLLOW      MUST FOLLOW
        LDA RESTYP+1
        PHA
        LDA RESTYP
        PHA
        JSR EXPRES
        PLA
        ROL A           TEST RESULT TYPE
        JSR TESTTP+1
        BNE LET1+3
        PLA
LET0    BPL LET1
*
* SAVE INTEGER
*
        JSR ROUND
        JSR FLPINT
        LDY =0
        LDA MANT+2
        STA (TEMP3),Y
        INY
        LDA MANT+3
        STA (TEMP3),Y
        RTS
*
* SAVE FLP
*
LET1    JMP SAVFLP
*
* SAVE STRING
*
        PLA
        LDY =2
        LDA (MANT+2),Y
        CMP BTSTRG+1
        BCC LET2        SKIP, IF NOT SAVED S
        BNE *+9
        DEY
        LDA (MANT+2),Y
        CMP BTSTRG
        BCC LET2
        LDY MANT+3
        CPY STVAR+1
        BCC LET2
        BNE LET2+7
        LDA MANT+2
        CMP STVAR
        BCS LET2+7
*
LET2    LDA MANT+2
        LDY MANT+3
        JMP LET3
*
        LDY =0
        LDA (MANT+2),Y
        JSR TSTRRM
        LDA TEMP5
        LDY TEMP5+1
        STA DYADIC+6
        STY DYADIC+7
        JSR INSSTR
        LDA =<EXP
        LDY =0
LET3    STA TEMP5
        STY TEMP5+1
        JSR PREPS1
        LDY =0
        LDA (TEMP5),Y
        STA (TEMP3),Y
        INY
        LDA (TEMP5),Y
        STA (TEMP3),Y
        INY
        LDA (TEMP5),Y
        STA (TEMP3),Y
        RTS
*
*
* PRINT: STATEMENT ROUTINE
**************************
*
PRINT   CMP ='#'        DEVICE
        BNE PRINT1-3
        JSR SETDEV
        JSR PRINT1-3
        JSR RSTDEV
        LDX =0
        STX OUTDEV
        RTS
*
        JSR OUTSTR+3
        JSR FETCH1
PRINT1  BNE *+5
        JMP CRLF        CRLF, IF EOL
        CMP ='!'        COMMENT?
        BEQ PRINT1+2    YES, SAME AS EOL
        CMP =$B0
        BEQ TAB         CODE FOR TAB(
        CMP =$B3        CODE FOR SPC(
        BEQ TAB
        CMP =','
        BEQ AUTOTB
        CMP =';'
        BEQ TAB1+8
        CMP ='['
        BEQ PRINT2
        JSR EXPRES
        BIT RESTYP
        BMI PRINT1-6    IF STRING
        JSR FORMOUT
        JSR OUTSTR
        LDA FORMFL
        BNE *+7
        LDA =' '
        JSR OUTCHR
        JMP PRINT1-3
*
AUTOTB  LDA POS
        SEC
        SBC =12
        BCS *-2
        EOR =$FF
        ADC =1
        BNE TAB1-1      ALLWAYS TAKEN
*
TAB     PHA             SAVE CODE
        JSR NUMEXP
        CMP =')'
        BEQ *+5
        JMP SYNERR
        PLA
        CMP =$B0        TAB(
        BNE TAB1+14
        TXA
        SBC POS
        BCC TAB1+8
        BEQ TAB1+8
        TAX
TAB1    LDA =' '
        JSR OUTCHR
        DEX
        BNE TAB1
        JSR FETCH
        BNE PRINT1+5
        RTS
*
        INX
        JMP TAB1+5
*
PRINT2  JSR FETCH       GET FORMAT CODE
        JSR FORMAT
        LDA =']'
        JSR FOLLOW
        JMP PRINT1
*
* FOLLOW: CHAR IN A MUST FOLLOW
*******************************
*
        LDA ='('        FOLLOW-6: "(" MUST FOLLO
        BNE *+4
        LDA =')'        FOLLOW-1: ")" MUST FOLLO
FOLLOW  LDY =0
        CMP (PC),Y
        BNE *+5
        JMP FETCH
        JMP SYNERR
*
        TIT GRAPHIC BASIC - EXPRESSIONS
        PAG
*
* GETVAR: GET VARIABLE
**********************
*
GETVAR  LDX =0
        JSR FETCH1
        STX RESTYP-1
        STA VARSYM
        JSR FETCH1      FETCH SAME AGAIN
        JSR TLETT
        BCS *+5
SYNER1  JMP SYNERR
*
        LDX =0
        STX RESTYP
        STX RESTYP+1
        JSR FETCH
        BCC *+7         SKIP, IF NUMBER
        JSR TLETT
        BCC *+13
        TAX             SAVE SECOND CHAR IN X
        JSR FETCH
        BCC *-3         SKIP NUMBERS
        JSR TLETT       SKIP LETTERS
        BCS *-8
*
        CMP ='$'        STRING?
        BNE *+8
        LDA =$FF
        STA RESTYP
        BNE GETV1       ALLWAYS TAKEN
*
        CMP ='%'        INTEGER?
        BNE GETV1+7
        LDA FLAG1
        BNE SYNER1
        LDA =$80
        STA RESTYP+1
        ORA VARSYM
        STA VARSYM
GETV1   TXA             GET BACK SECOND CHAR
        ORA =$80
        TAX
        JSR FETCH
*
        STX VARSYM+1
        SEC             NEXT CHAR IN A
        ORA FLAG1
        SBC ='('
        BNE *+5
        JMP GETARR      GET ARRAY
*
        LDA =0
        STA FLAG1
        LDA STVAR
        LDX STVAR+1
        LDY =0
        STX TRANSP+1
GETV2   STA TRANSP      SEARCH IN VAR TB
        CPX EOVAR+1
        BNE *+6
        CMP EOVAR
        BEQ GETV3       BRANCH, IF END OF TABLE
        LDA VARSYM
        CMP (TRANSP),Y
        BNE *+10
        LDA VARSYM+1
        INY
        CMP (TRANSP),Y
        BEQ GETV9       BRANCH, IF FOUND
        DEY
        CLC
        LDA TRANSP
        ADC =7
        BCC GETV2
        INX
        BNE GETV2-2
*
GETV3   LDA TEMP4+1
        BEQ *+7
        LDX =$56
        JMP ERROR       UNDEFINED VARIABLE
        LDA EOVAR
        LDY EOVAR+1
        STA TRANSP
        STY TRANSP+1
        LDA STSPAC
        LDY STSPAC+1
        STA BEGINB
        STY BEGINB+1
        CLC
        ADC =7
        BCC *+3
        INY
        STA ENDB
        STY ENDB+1
        JSR MKROOM
        LDA ENDB        SET END OF VAR TB
        LDY ENDB+1
        INY
        STA EOVAR
        STY EOVAR+1     1+END OF TABLE
        LDY =0
        LDA VARSYM      SAVE SYMBOL
        STA (TRANSP),Y
        INY
        LDA VARSYM+1
        STA (TRANSP),Y
        LDA =0
        INY
        STA (TRANSP),Y  CLEAR VALUE
        CPY =6
        BNE *-5
*
GETV9   LDA TRANSP
        CLC
        ADC =2
        LDY TRANSP+1
        BCC *+3
        INY
        STA VARSTP
        STY VARSTP+1
        RTS
*
* TLETT: TEST LETTER (C=1 IF LETTER)
************************************
*
TLETT   CMP =$41
        BCC *+7
        SBC =$5B
        SEC
        SBC =$A5
        RTS
*
* TSTRR1
*
TSTRR1  LSR TEMP2
        PHA
        EOR =$FF
        SEC
        ADC BTSTRG
        LDY BTSTRG+1
        BCS *+3
        DEY
        CPY STSPAC+1
        BCC TSTRR2
        BNE *+6
        CMP STSPAC
        BCC TSTRR2
        STA BTSTRG
        STY BTSTRG+1
        STA TPSTRG
        STY TPSTRG+1
        TAX
        PLA
        RTS
*
TSTRR2  LDX =$3A
        LDA TEMP2
        BPL *+5
        JMP ERROR       OUT OF MEMORY
        JSR PKSTRG
        LDA =$80
        STA TEMP2
        PLA
        BNE TSTRR1+2
*
* PKSTRG: PACK STRINGS
**********************
*
PKSTRG  LDX TPMEM
        LDA TPMEM+1
        STX BTSTRG
       