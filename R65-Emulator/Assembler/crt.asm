*                                16/08/82
*
******************************************
* CRT CONTROLLER FOR R65 COMPUTER SYSTEM *
******************************************
*
* EPROM REVISION 1              16/08/82
* CC RRICHARZ RBAUMANN 1977-1982
* VIDEO MEMORY AT $0400
*
PSTART  EQU $E000       START OF PROGRAM AREA
DSTART  EQU $1780       START OF DATA AREA
*
        TIT R65 CRT-CONTROLLER
*
*
* VIDEO CONTROL FUNCTIONS
*************************         CTRL
*                             VCOD   ASCII
* CURSOR DOWN           CDOWN   E9  X  18
* CURSOR RIGHT          CRIGHT  E8  V  16
* CURSOR LEFT           CLEFT   E7  C  03
* CURSOR UP             CUP     E6  Z  1A
* CURSOR HOME           CHOME   E5  A  01
* INSERT CHAR           INSCHR  E4  U  15
* DELETE CHAR           DELCHR  E3  Y  19
* CLEAR LINE            CLRLIN  E2  E  17
* CLEAR DISPLAY         CLRDSP  E1  Q  11
* INSERT LINE           INSLIN  C4  D  04
* DELETE LINE           DELLIN  C3  F  06
* TOGGLE ALPHA/GRAPHICS TALGRA  E9  L  0C
* ESCAPE                ESCAPE  91     1B
* SET TABULATOR         SETTAB  8B
* ROLL DOWN             RDOWN   89     02
* TO RIGHT MARGIN       CRMARG  88
* TO LEFT MARGIN        CLMARG  87
* ROLL UP               RUP     86  H  08
* REVERSE HOME          RVHOME  85  P  10
* RESUME WRITING        RWRITE  84
* QUIET WRITING         QWRITE  83
* TOGGLE BLACK/WHITE    TBLWHI  82  E  05
* CLEAR GRAPHIC DISPLAY CLRGRA  81
*
* OTHER CONTROL FUNCTIONS
*************************
*
* PRINT ALL ON          PRTON       R  12
* PRINT ALL OFF         PRTOFF      T  14
* DISPLAY CONTROL CHAR  DSPCCH      S  13
* CLEAR TABULATOR       CLRTAB      O  0F
* INVERSE VIDEO         INVVID      N  0E
* NORMAL VIDEO          NORVID      K  0B
* CARRIAGE RETURN       EXCR       (M) 0D
* LINE FEED             EXLF       (J) 0A
* TABULATOR (8)         TAB         I  09
* BELL                  BELL        G  07
* PAD CHARACTER         PADCHR      @  00
*
* PROGRAMMABLE FUNCTION KEYS
****************************
*
* F0-F3 / SHIFT F0-F3               A0-A7
*
* SPECIAL CHARS
***************
* RUBOUT                RUBOUT      7F/5F
*
* PAGE 0 VARIABLES
******************
*
        ORG $E7
*
FETCH   BSS 2   DATA SUBROUTINE REG
VIDPNT  BSS 2   VIDEO POINTER REG
VIPNT2  BSS 2   SECOND VIDEO PNTR
CURLIN  BSS 1   CURRENT LINE OF CURSOR
CURPOS  BSS 1   CURRENT POSITION CURSOR
SAVPC   BSS 1   SAVE PC
*
* PAGE 17 DATA REGISTERS
************************
*
        ORG DSTART
*
* PRESET BY RESET TO 0:
*
VFLAG   BSS 1   VIDEO FLAG REGISTER
*               BIT 7: INVERSE VIDEO
*               BIT 6: GRAPHICS DISPLAYED
*               BIT 5: GRAPHICS INITIALIZED
*               BIT 4: DISPLAY CONTROL CHAR
*               BIT 3: AUTOPRINT ON
*               BIT 2: AUTO LINE FEED ON
*               BIT 1: PRINTING QUIET
*               BIT 0: NO VIDEO KEY EXECUTION
*
SFLAG   BSS 1   SYSTEM FLAG REGISTER
*               BIT 7: ESCAPE FLAG
*
OFFSET  BSS 1   ROLL MEMORY OFFSET
LMARG   BSS 1   CURRENT LEFT MARGIN
VIDKEY  BSS 1   VIDEO IRQ SAVE KEY
CHAR    BSS 1   CHAR SAVE REGISTER
*
* PRESET BY RESET TO TABLE:
*
FULL    BSS 3   LINE SAVE ROUTINE
NUMLIN  BSS 1   NUMBER OF LINES IN VIDMEM
NUMCHR  BSS 1   NUMBER OF CHARS PER LINE
UMARG   BSS 1   CURRENT UPPER MARGIN
VAUTOP  BSS 2   AUTOPRINT VECTOR
VFUNC   BSS 2   FUNCTION VECTOR
TABTB   BSS 8   TABULATOR TABLE
*
DSPLIN  BSS 1   NUMBER OF DISPLAYED LINES
*
        PAG
*
* INTERFACE CONTROL REGISTERS:
*****************************
*
TIMER1  EQU $1747       TIMER 1 OF KIM-1
PORTA2  EQU $1451       6552-2 PORT A (KEYBRD)
DIRA2   EQU $1453       6552-2 DIRECTION-A REG
TLL22   EQU $1458       6552-2 TIMER 2 L-LATCH
SR2     EQU $145A       6552-2 SHIFT REGISTER
ACR2    EQU $145B       6552-2 CONTROL REGISTER
IFR2    EQU $145D       6522-2 IRQ FLAG REGISTER
IER2    EQU $145E       6552-2 IRQ ENABLE REG
CRTADR  EQU $1420       CRT CONTROLLER ADDRESS
CRTDAT  EQU $1421       CRT CONTROLLER DATA REG
PORTA1  EQU $1702       6530-003 PORT A
DIRA1   EQU $1703       6530-003 DIRECTION
MULTX   EQU $14E0       MULTIPLIER X-REGISTER
MULTY   EQU $14E1       MULTIPLIER Y-REGISTER
MULTR   EQU $14E2       MULTIPLIER DATA REGISTER
PRTRSA  EQU $E836       RS232 PRINT ROUTINE
CRTMEM  EQU $0400       CRT MEMORY START ADDRESS
*
        PAG
*
* START OF PROGRAM
*
        ORG PSTART
*
* VECTORS FOR SUBROUTINE CALLS
******************************
*
        JMP GETKEY      GET KEY FROM KEYBOARD
        JMP GETCHR      GET KEY AND PRINT IT
        JMP GETLIN      GET LINE FROM KEYBOARD
        JMP PRTCHR      PRINT CHAR ON SCREEN
        JMP (VAUTOP)    AUTO PRINT CHAR
        JMP LOCRM       LOCATE ROLL MEMORY
        JMP LOCRM3      COLATE USING OFFSET
        JMP ICRTAL      INITIALIZE TO ALPHA
        JMP ICRTGR      INITIALIZE TO GRAPHICS
        JMP INITCR      INITIALIZE CRT-CONTROL
        JMP IGRAPH      INITIALIZE GRAPHICS
        JMP FILL        FILL WITH A
        JMP ENDLIN      TEST END OF LINE
        JMP PRTINF      PRINT ASCII STRING
        JMP PRTHEX      PRINT HEX CHAR
        JMP PRTBYT      PRINT BYTE
        JMP PRTAX       PRINT 2 BYTES
        JMP PRTREG      PRINT SAVED CP REG.
*
* KEYIRQ: KEYBOARD IRQ HANDLER
******************************
* A AND X SAVED UPON ENTRY, Y AND VIDPNT
* SAVED INTERNAL. VIDEO CONTROL CHARS ARE
* EXECUTED DIRECTLY, ALL OTHER CHARS ARE
* TRANSMITTED TO THE CHAR GEGISTER
* >> DO NOT TO USE SUBROUTINES OF THE VIDEO
*    CONTROLLER WITHOUT DISABLING THE
*    KEYBOARD INTERRUPT!
*
KEYIRQ  LDA PORTA2      LOAD KEY CODE
        BMI VIDIRQ      EXECUTE VIDEO FUNCTION
        STA CHAR        OR SAVE CHAR
IRQ9    PLA
        TAX             GET BACK SAVED X
        PLA             FROM MAIN IRQ HANDLER
        RTI
*
VIDIRQ  LSR VFLAG
        PHP
        ROL VFLAG
        PLP
        BCS KEYIRQ+5
        CMP =$A0        IF FUNCTION KEY
        BCC *+11
        CMP =$A8
        BCS *+7
        AND =7          MASK KEY NO
        JMP (VFUNC)     AND JUMP VIA VECTOR
*
        STA VIDKEY      SAVE A
        LDX =2
        STX IER2
        CLI             AND ALLOW OTHER IRQ
        LDX =$03        SAVE VIDPNT,VIDPN2
        LDA VIDPNT,X    DURING INTERRUPT
        PHA             HANDLING
        DEX
        BPL *-4
        TYA             SAVE Y
        PHA
        JSR EXVIDK      EXECUTE VIDEO KEY
        PLA
        TAY             RESTORE Y
        LDX =$FC
        PLA
        STA VIDPNT+4,X  RESTORE VIDPNT,VIDPN2
        INX
        BNE *-4
        SEI
        LDX =$82        ALLOW KEYBOARD IRQ
        STX IER2
        PLA
        TAX             RESTORE X
        PLA
        RTI
*
* EXECUTE VIDEO FUNCTION KEY
*
EXVIDK  LDX =22 NO OF VIDEO FUNCTIONS
        LDA VIDKEY
        CMP VIDKTB,X    SEARCH CODE IN TABLE
        BEQ EXCHR
        DEX
        BPL *-6
PAD     RTS             IGNORE, IF NOT FOUND
*
EXCHR   TXA
        ASL A
        TAX
        LDA VIDVTB+1,X  LOAD VECTOR
        PHA             AND PUSH TO STACK
        LDA VIDVTB,X
        PHA
        RTS             EXECUTE FUNCTION
*
* VIDEO KEY CODE TABLE
**********************
*
VIDKTB  BYT $E9,$E8,$E7,$E6,$E5,$E4
        BYT $E3,$E2,$E1,$C4,$C3,$9E
        BYT $91,$8B,$89,$88,$87,$86
        BYT $85,$84,$83,$82,$81
*
* CONTROL KEY CODE TABLE
************************
*
CNTKTB  BYT $18,$16,$03,$1A,$01,$15
        BYT $19,$17,$11,$04,$06,$0C
        BYT $1B,$FF,$02,$FF,$FF,$08
        BYT $10,$FF,$FF,$05,$FF
*
        BYT $12,$14,$13,$0F,$0E
        BYT $0B,$0D,$0A,$09,$07,$00
*
* VIDEO AND CONTROL VECTOR TABLE
********************************
*
VIDVTB  WRD CDOWN-1,CRIGHT-1,CLEFT-1
        WRD CUP-1,CHOME-1,INSCHR-1
        WRD DELCHR-1,CLRLIN-1,CLRDSP-1
        WRD INSLIN-1,DELLIN-1,TALGRA-1
        WRD ESCAPE-1,SETTAB-1
        WRD RDOWN-1,CRMARG-1
        WRD CLMARG-1,RUP-1,RVHOME-1
        WRD RWRITE-1,QWRITE-1,TBLWHI-1
        WRD CLRGRA-1
*
        WRD PRTON-1,PRTOFF-1,DSPCCH-1
        WRD CLRTAB-1,INVVID-1
        WRD NORVID-1,EXCR-1,EXLF-1
        WRD TAB-1,BELL-1,PAD-1
*
* VIDEO KEY SUBROUTINES
***********************
*
CRIGHT  LDX CURPOS      -- CURSOR RIGHT --
        CPX NUMCHR
        BCS *+4
        INC CURPOS
        JMP LOCSET
*
CLEFT   LDX LMARG       -- CURSOR LEFT --
        CPX CURPOS
        BCS *+4
        DEC CURPOS
        JMP LOCSET
*
CLMARG  LDX LMARG       -- CURSOR LEFT MARGIN --
        STX CURPOS
        JMP SETCUR
*
CRMARG  LDX =0          -- CURSOR LEFT TO 0 --
        STX CURPOS
        JMP SETCUR
*
CDOWN   LDX CURLIN      -- CURSOR DOWN --
        CPX NUMLIN
        BCS *+4
        INC CURLIN
LOCSET  JSR LOCRM       LOCATE ROLL MEMORY
        JMP SETCUR      AND SET CURSOR
*
CUP     LDX UMARG       -- CURSOR UP --
        CPX CURLIN
        BCS *+4
        DEC CURLIN
        JMP LOCSET
*
RUP     LDX UMARG       -- ROLL UP --
        CPX OFFSET
        BCS *+5
        DEC OFFSET
        JMP LOCRM3
*
RDOWN   LDA NUMLIN      -- ROLL DOWN --
        SEC
        SBC OFFSET
        SBC DSPLIN
        BCC *+5
        INC OFFSET
        JMP LOCRM3
*
CHOME   LDX UMARG       -- CURSOR HOME --
        STX CURLIN
        STX OFFSET
CHOME1  LDX LMARG
        STX CURPOS
        JMP LOCSET
*
RVHOME  LDX NUMLIN      -- CURSOR REV HOME --
        STX CURLIN
        JSR ROLLOC
        LDY =0
        JSR ENDLIN      LINE EMPTY?
        BNE RVHOM1      BRANCH, IF LAST LINE
        DEX
        BPL RVHOME+3
        INX
        BEQ *+5         TAKEN, IF SCREEN EMPTY
*
RVHOM1  JSR CDOWN
        LDX UMARG
        CPX CURLIN
        BCC *+4
        STX CURLIN
        JMP CLMARG
*
DELCHR  JSR ROLLOC-2    -- DELETE CHAR --
        LDY CURPOS
        BNE *+9         TEST BEFORE DOING
        INY
        LDA (VIDPNT),Y
        DEY
        STA (VIDPNT),Y
        INY
        CPY NUMCHR
        BCC *-10
DELCH2  LDA =' '
        STA (VIDPNT),Y
        RTS
*
INSCHR  JSR ROLLOC-2    -- INSERT CHAR --
        LDY NUMCHR
        DEY
        LDA (VIDPNT),Y
        INY
        STA (VIDPNT),Y
        DEY
        CPY CURPOS
        BPL *-9
        INY
        JMP DELCH2
*
CLRLIN  JSR ROLLOC-2    -- CLEAR LINE --
        LDY NUMCHR
        LDA =' '
        STA (VIDPNT),Y
        DEY
        CPY CURPOS
        BPL *-5
        INY
        RTS
*
CLRDSP  JSR CLRLIN      -- CLEAR DISPLAY --
        LDX CURLIN
        LDA CURPOS      SAVE CURPOS
        PHA
        LDA =0
        STA CURPOS
        CPX NUMLIN
        BEQ *+12
        INX
        JSR ROLLOC
        JSR CLRLIN+3
        JMP *-12
        PLA             RESTORE CURPOS
        STA CURPOS
        RTS
*
TBLWHI  LDA PORTA1      -- TOGGLE BLACK/WHITE --
        EOR =1
        STA PORTA1
        RTS
*
ESCAPE  LDA SFLAG       -- ESCAPE --
        ORA =$80        SET ESCAPE FLAG
        STA SFLAG
        RTS
*
QWRITE  LDA VFLAG       -- QUIET WRITING --
        ORA =$02
        STA VFLAG
        RTS
*
RWRITE  LDA VFLAG       -- RESUME WRITING --
        AND =$FD
        STA VFLAG
        RTS
*
CLRGRA  LDA VFLAG       -- CLEAR GRAPHICS
        AND =$20        INITIALIZED?
        BEQ CLRGRA-1    RTS, IF NOT
        LDX =$E8        SET END MARK
        LDY =$13        ## REQUIRES FIX ##
        STX VIPNT2
        STY VIPNT2+1
        LDA =0
        TAX             START TO FILL
        LDY =$07        CONTINUE WITH FILL
*
* FILL: FILL MEMORY FROM X,Y WITH A TO VIPNT2
*********************************************
*
FILL    STX VIDPNT
        STY VIDPNT+1
        LDX VIPNT2
        LDY =0
FILL1   STA (VIDPNT),Y
        INC VIDPNT
        BNE *+4
        INC VIDPNT+1
        CPX VIDPNT
        BNE FILL1
        LDY VIDPNT+1
        CPY VIPNT2+1
        BCC FILL1-2
        STA (VIDPNT),Y
        RTS
*
TALGRA  BIT VFLAG       -- TOGGLE ALPHA/GRAPH
        BVC *+5
        JMP ICRTAL
        LDA VFLAG
        AND =$20
        BEQ TALGRA-1    RTS, IF NOT
        JMP ICRTGR      INITIALIZED
*
* SUBROUTINE ROLLOC: COMPUTE ROLL MEMORY PNT
********************************************
* ALL REGISTERS SAVED, ROLLOC-2 SETS X=CURLIN
*
        LDX CURLIN
ROLLOC  PHA
        SEI             DISABLE IRQ FOR MULTIPLY
        STX MULTX
        LDA NUMCHR
        CLC
        ADC =1
        STA MULTY
        CLC
        LDA MULTR
        STA VIDPNT
        LDA MULTR+1
        CLI             ENABLE IRQ
        ADC =>CRTMEM
        STA VIDPNT+1
        PLA
        RTS
*
* CURLOC: COMPUTE CURSOR LOCATION
*********************************
* A SAVED, Y RETURNED=0
*
CURLOC  JSR ROLLOC-2
        PHA
        CLC
        LDA VIDPNT
        ADC CURPOS
        STA VIDPNT
        BCC *+4
        INC VIDPNT+1
        PLA
        LDY =0
        RTS
*
* LOCRM: LOCATE ROLL MEMORY
***************************
* A SAVED
*
LOCRM   PHA
        LDA CURLIN
        SEC
        SBC OFFSET
        BCC LOCRM2
        SBC =$10
        BCC LOCRM3-1
        INC OFFSET
        JMP LOCRM+1
LOCRM2  DEC OFFSET
        JMP LOCRM+1
*
        PLA
LOCRM3  BIT VFLAG
        BVS LOCRM-1     RTS, IF GRAPHICS
        PHA
        LDX OFFSET
        JSR ROLLOC
        LDX =$D
LOCRM4  LDA VIDPNT
        STX CRTADR
        STA CRTDAT
        DEX
        LDA VIDPNT+1
        STX CRTADR
        STA CRTDAT
        PLA
        RTS
*
* SETCUR: SET CURSOR
********************
*
SETCUR  JSR CURLOC
        LDX =$0F        VIDEO CONTROLLER
        PHA
        JMP LOCRM4
*
* ENDLIN
********
*
ENDLIN  LDA (VIDPNT),Y
        AND =$7F
        CMP =$20
        BNE *+10        NOT EMPTY
        CPY NUMCHR
        BEQ *+5         EMPTY
        INY
        BNE ENDLIN
        RTS
*
*
EXCR    LDA =4          -- CARRIAGE RETURN --
        BIT VFLAG       AUTO LF ON?
        BEQ *+5
        JSR EXLF+7      EXECUTE A LF
        JMP CLMARG      EXECUTE A CR
*
EXLF    LDA =4          -- LINE FEED --
        BIT VFLAG       AUTO LF ON?
        BNE EXCR-1      RTS, IF ON
        LDA CURLIN
        CMP NUMLIN
        BCS *+5
        JMP CDOWN       EXECUTE LF
        JSR FULL        SAVE LINE AND MOVE UP
*
* MOVEUP: FAST MOVEUP FOR LINE FEED
***********************************
*
MOVEUP  LDX NUMLIN      X=LINE COUNTER
        LDA =>CRTMEM
        STA VIPNT2+1
        STA VIDPNT+1
        LDA =0
        STA VIPNT2
        STA VIDPNT
MOVEU1  LDA VIPNT2
        SEC
        ADC NUMCHR      ADD NUMCHR+1
        STA VIPNT2
        BCC *+4
        INC VIPNT2+1
        LDY NUMCHR
MOVEU2  LDA (VIPNT2),Y
        STA (VIDPNT),Y
        DEY
        BPL MOVEU2
        LDA VIPNT2+1
        STA VIDPNT+1
        LDA VIPNT2
        STA VIDPNT
        DEX
        BNE MOVEU1
        LDX NUMLIN      CLEAR LAST LINE
        DEX
        JMP CLRDSP+5
*
*
INVVID  LDA VFLAG       -- INVERSE VIDEO --
        ORA =$80
        STA VFLAG
        RTS
*
NORVID  LDA VFLAG       -- NORMAL VIDEO
        AND =$7F
        STA VFLAG
        RTS
*
PRTON   LDA VFLAG       -- AUTOPRINT ON --
        ORA =$08
        STA VFLAG
        RTS
*
PRTOFF  LDA VFLAG       -- AUTOPRINT OFF --
        AND =$F7
        STA VFLAG
        RTS
*
CAPSON  LDA VFLAG       -- CAPITAL LETTERS --
        ORA =$01
        STA VFLAG
        RTS
*
CAPSOF  LDA VFLAG       -- CAPITALS OFF --
        AND =$FE
        STA VFLAG
        RTS
*
DSPCCH  LDA VFLAG       -- DISPLAY CONTROL CHR
        EOR =$10        TOGGLE
        STA VFLAG
        RTS
*
BELL    LDA =32         FREQUENCY IN A
        LDX =8          LENGHT IN X
*
* OUTPUT A TONE
***************
* FREQUENCY IN A, LENGHT IN X
* TIMER 1 OF KIM IS USED FOR TIMING
* SHIFT REGISTER AND TIMER 2 OF 6522-2
*
TONE    JSR CONTON      START TONE OUT
        LDY =20
        STX TIMER1
        LDA TIMER1
        BPL *-3
        DEY
        BNE *-9
*
ENDTON  LDA ACR2        CAN BE CALLED
        AND =$E3
        STA ACR2
        RTS
*
CONTON  STA TLL22       SET TIMER 2 LATCH
        LDA ACR2        OF 6552-2
        AND =$F3        ACR3=0, ACR2=0
        ORA =$10        ACR4=1
        STA ACR2
        LDA =$2D        PREPARE SHIFT REGISTER
        STA SR2         OF TIMER 2
        RTS
*
*
SETTAB  JSR COMTAB      -- TABULATE --
        ORA TABTB,Y
        STA TABTB,Y
        RTS
*
*
CLRTAB  LDA =0          -- CLEAR TABS --
        LDX =7
        STA TABTB,X
        DEX
        BPL *-4
        RTS
*
*
TAB     JSR PRTCH9+5    -- TABULATE
        LDA CURPOS
        CMP NUMCHR
        BEQ TAB-1       RTS, IF END OF LINE
        JSR COMTAB
        AND TABTB,Y
        BEQ TAB
        RTS
*
*
COMTAB  LDA CURPOS
        AND =7
        TAX
        LDA CURPOS
        LSR A
        LSR A
        LSR A
        AND =7
        TAY
        LDA MASKTB,X
        RTS
*
MASKTB  BYT 128,64,32,16,8,4,2,1
*
*
DELLIN  LDX CURLIN      -- DELETE LINE --
        JSR MVUP
        INX
        CPX NUMLIN
        BCC DELLIN+2
        JSR CHOME1
        LDX NUMLIN
        JSR ROLLOC
        JMP CLRLIN+3
*
*
INSLIN  JSR CRMARG
        LDX NUMLIN      -- INSERT LINE --
        JSR ROLLOC
        LDY =0
        JSR ENDLIN
        BEQ INSL0
        JSR FULL
        JSR MOVEUP
        JSR CUP
INSL0   LDX NUMLIN
        DEX
INSL1   JSR MVDOWN
        DEX
        CPX CURLIN
        BPL INSL1
        JSR CHOME1
        JMP CLRLIN
*
MVUP    JSR ROLLOC
        TXA
        PHA
        LDX NUMCHR
        INX
        LDY NUMCHR
        INY
        LDA (VIDPNT),Y
        LDY =0
        STA (VIDPNT),Y
        INC VIDPNT
        BNE *+4
        INC VIDPNT+1
        DEX
        BNE MVUP+9
        PLA
        TAX
        RTS
*
MVDOWN  JSR ROLLOC
        TXA
        PHA
        LDX NUMCHR
        INX
        LDY =0
        LDA (VIDPNT),Y
        LDY NUMCHR
        INY
        STA (VIDPNT),Y
        INC VIDPNT
        BNE *+4
        INC VIDPNT+1
        DEX
        BNE MVDOWN+9
        PLA
        TAX
        RTS
*
* PRTCHR: PRINT CHAR ON CRT
***************************
* CHAR IS ALLSO PRINTED ON AUTOPR, IF AUTOPRINT
* FLAG IS SET, REGISTERS SAVED
*
PRTCHR  PHP             SAVE STATUS
        SEI
        STA VIDKEY      SAVE CHAR
        PHA             ALLSO ON STACK
        TXA             SAVE REGISTERS
        PHA
        TYA
        PHA
        LDA VIDKEY      GET BACK CHAR
        PHA
        CLI
        LDA =$08        TEST PRINT FLAG
        BIT VFLAG
        BEQ *+7
        PLA
        PHA
        JSR JAUTOP
        PLA
        LDX =2          DISABLE KEYBOARD IRQ
        STX IER2
        STA VIDKEY
        JSR PRTCH1
        PLA
        TAY
        PLA
        TAX
        LDA =$82        ENABLE KEYBOARD IRQ
        SEI
        STA IER2
        PLA
        PLP
        RTS
*
JAUTOP  JMP (VAUTOP)
*
PRTCH2  JMP EXCHR       EXECUTE CONTROL FUNC
*
PRTCH1  LDA VIDKEY
        CMP =$13        DISPLAY OFF
        BEQ *+9
        LDA =$10
        BIT VFLAG
        BNE PRTCH0
        LDA VIDKEY
        LDX =33         NO OF CONTROL FUNCTIONS
        CMP CNTKTB,X
        BEQ PRTCH2
        DEX
        BPL *-6
*
PRTCH0  LDA VIDKEY
        CMP =$5F        IF NOT FOUND, RUBOUT?
        BEQ *+6
        CMP =$7F
        BNE PRTCH4
        JSR CLEFT
        JSR CURLOC
        LDA =' '
        STA (VIDPNT),Y
        RTS
*
PRTCH4  BIT VFLAG
        BPL *+4
        ORA =$80
PRTCH9  JSR CURLOC
        STA (VIDPNT),Y
        LDA CURPOS
        CMP NUMCHR
        BNE *+8
        JSR EXCR        AUTO CRLF IF END OF LINE
        JMP EXLF
        JMP CRIGHT
*
* GETKEY: GET A KEY FROM KEYBOARD
*********************************
* NO RPINT ON CRT, REGISTERS SAVED
*
GETKEY  CLI
        LDA SFLAG       TEST ESCAPE
        BMI GETK1
        LDA CHAR
        BEQ GETKEY+1    WAIT FOR CHAR
        PHA
        LDA =0
        STA CHAR
        PLA
        RTS
*
GETK1   AND =$7F
        STA SFLAG
        LDA =0          RETURN AFTER ESC
        RTS
*
* GETCHR: GET A CHAR FROM KEYBOARD
**********************************
* WITH PRINT ON DISPLAY, REGISTERS SAVED
*
GETCHR  JSR GETKEY
        JMP PRTCHR
*
*
* GETLIN: GET A LINE FROM KEYBOARD
**********************************
* VIDEO DISPLAY AS BUFFER IS UNSED
* ON EXIT VIDPNT,Y IS COMPUTED AND C=1
* IF ESCAPE WAS PRESSED
*
GETLIN  LDX CURPOS
        STX LMARG       SET LEFT MARGIN
GETL1   BIT SFLAG
        BMI GETL9
        LDX =$82        ENABLE KEYBOARD IRQ
        STX IER2
        JSR GETKEY
        BEQ GETL8
        LDX =2  DISABLE KEYBOARD IRQ
        STX IER2
        STA VIDKEY
        PHA
        JSR PRTCH1
        PLA
        CMP =$D         IF NOT CARRIAGE RETURN
        BNE GETL1
        LDA VFLAG       DO NOT STOP, IF DISPLAY
        AND =$10        FLAG ON
        BNE GETL1
*
        LDX CURLIN
        LDA VFLAG       IF AUTO LF
        AND =$04
        BEQ *+3
        DEX             DECREMENT LINE NO
        JSR ROLLOC
        LDA =$08
        BIT VFLAG       IF AUTOPRINT SET
        BEQ GETL3
*
        LDY LMARG
GETL2   TYA
        TAX             SAVE POINTER
        JSR ENDLIN
        BEQ GETL3
        TXA
        PHA
        TAY
        LDA (VIDPNT),Y
        JSR JAUTOP
        PLA
        TAY
        INY
        CPY NUMCHR
        BCC GETL2
        BEQ GETL2
*
GETL3   LDA SFLAG       TEST ESCAPE FLAG
        CLC
        BPL *+8
        AND =$7F        CLEAR IF SET
        STA SFLAG
        SEC
*
GETL4   LDY LMARG
        LDA =0
        STA LMARG
        RTS             RETURN WITH C=1 IF ESC
*
GETL8   JSR INSL1+8     CLEAR LINE
        SEC
        BCS GETL4
*
GETL9   JSR INSL1+8     CLEAR LINE
        JMP GETL3
*
*
* INITIALIZE CRT CONTROLLER
*
ICRTAL  LDA VFLAG
        AND =$BF
        STA VFLAG
        JSR LOCRM3
        JSR SETCUR
        LDA =<CRTTBA
        LDX =>CRTTBA
        LDY =12
        BNE ICRT
*
ICRTGR  LDA VFLAG       INITIALIZE GRAPHICS
        ORA =$40
        STA VFLAG
        LDA =<CRTTBG
        LDX =>CRTTBG
        LDY =14
*
ICRT    STA VIPNT2
        STX VIPNT2+1
        LDA =$3F
        STA DIRA1
        LDA (VIPNT2),Y
        STA PORTA1
        DEY
ICRT1   STY CRTADR
        LDA (VIPNT2),Y
        STA CRTDAT
        CPY =6          IF VERT. DISPLAYED
        BNE *+5
        STA DSPLIN      SAVE IN DSPLIN
        DEY
        BPL ICRT1
        RTS
*
* ALPHA INITIALIZATION 16 LINES / 48 CHARS
*
CRTTBA  BYT $46,$30,$38,$06,$14,$01
        BYT $10,$12,$00,$0E,$6D,$0D
        BYT $1C
*
CRTTBG  BYT $27,$1C,$20,$03,$7F,$1F
        BYT $76,$7F,$00,$01,$00,$00
        BYT $07,$00
        BYT $22
*
* IGRAPH: INITIALIZE FOR GRAPHICS DISPLAY
*****************************************
*
IGRAPH  LDX CURLIN      MOVE OFF LINES
        CPX =$10
        BCC INIT1       IF MORE THAN 16
        JSR MOVEUP+3
        DEC CURLIN
        BNE IGRAPH
*
INIT1   LDX =$F         16 LINES ALPHA
        STX NUMLIN
        LDX =0
        STX OFFSET
        LDA VFLAG
        ORA =$20
        STA VFLAG
        JSR LOCRM3
        JMP ICRTGR
*
* INITCR: INITIALIZE CT-CONTROL-PROGRAM
***************************************
*
INITCR  LDX =5
        LDA =0
        STA VFLAG,X
        DEX
        BPL *-4
*
        LDA =$80        DEFAULT TABS
        JSR CLRTAB+2
*
        LDX =9
        LDA CRTTBI,X
        STA FULL,X
        DEX
        BPL *-7
*
        JSR CHOME
        JSR CLRDSP
        JSR ICRTAL
*
INITKB  LDA ACR2
        ORA =1          ENABLE LATCH
        STA ACR2
        LDA =$82        ENABLE IRQ
        STA IER2
        RTS
*
* 40 LINES IN MEMORY / 48 CHARS
*
CRTTBI  BYT $60,$00,$00 DEFAULT FULL ROUTINE
        BYT $29,$2F,0   NUMLIN,NUMCHR,UMARG
        WRD PRTRSA      DEFAULT AUTOPRINT
        WRD IRQ9        DUMMY FUNCTION KEY
*
*
PRTTY   EQU $2800       TTY ROUTINE
*
* PRTREG: PRINT CPU REGISTER CONTENT (SAVED)
********************************************
*
PRTREG  JSR PRTINF
        BYT $D,$8A
        LDX =$FA
PRTR1   LDA PRTR4-$FA,X
        JSR PRTCHR
        JSR PRTINF
        BYT 128+'='
        LDA SAVPC+7,X
        JSR PRTBYT
        CPX =$FA
        BNE PRTR2
        LDA SAVPC
        JSR PRTBYT
PRTR2   JSR PRTINF
        BYT $20,$A0
        INX
        BNE PRTR1
        RTS
*
PRTR4   BYT 'PFSAYX'
*
*
* PRTINF: PRINT A STRING OF ASCII
*********************************
* STRING FOLLOWS SUBROUTINE CALL, LAST
* CHAR HAS BIT7=1, REGS X AND Y SAVED, A NOT
*
PRTINF  PLA             GET PROGRAM COUNTER
        STA FETCH
        PLA
        STA FETCH+1
        TYA
        PHA             SAVE Y
        LDY =0
PRTIF1  JSR IFETCH
        LDA (FETCH),Y
        BMI PRTIF2
        JSR PRTCHR      PRINT ONE CHAR
        JMP PRTIF1
PRTIF2  AND =$7F
        JSR PRTCHR      PRINT LAST CHAR
        PLA
        TAY
        JSR IFETCH
        JMP (FETCH)
*
IFETCH  INC FETCH
        BNE *+4
        INC FETCH+1
        RTS
*
* PRTAX: PRINT 2 BYTES
**********************
*
PRTAX   JSR PRTBYT
        TXA             CONTINUE WITH PRTBYT
*
* PRTBYT: PRINT A AS TWO HEX CHARS
**********************************
* ALL REGISTERS SAVED
*
PRTBYT  PHA
        LSR A
        LSR A
        LSR A
        LSR A
        JSR PRTHEX
        PLA
        PHA
        JSR PRTHEX
        PLA
        RTS
*
PRTHEX  AND =$0F
        CMP =$0A
        CLC
        BMI *+4
        ADC =7
        ADC =$30
        JMP PRTCHR
*
*
        PAG
*
* TABLE OF OPCODES AND ADDRESSING MODES
***************************************
* USED FOR ASSEMBLER AND DISASSEMBLER
*
        ORG $E722
*
DISMOD  BYT $40,$02,$45,$03,$D0,$08
        BYT $40,$09,$30,$22,$45,$33
        BYT $D0,$08,$40,$09,$40,$02
        BYT $45,$33,$D0,$08,$40,$09
        BYT $40,$02,$45,$B3,$D0,$08
        BYT $40,$09,$00,$22,$44,$33
        BYT $D0,$8C,$44,$00,$11,$22
        BYT $44,$33,$D0,$8C,$44,$9A
        BYT $10,$22,$44,$33,$D0,$08
        BYT $40,$09,$10,$22,$44,$33
        BYT $D0,$08,$40,$09,$62,$13
        BYT $78,$A9
*
MODE2   BYT $00,$21,$01,$02,$00,$80
        BYT $59,$4D,$11,$12,$06,$4A
        BYT $05,$1D
*
CHAR1   BYT $2C,$29,$2C,$3D,$28,$41
*
CHAR2   BYT $59,$00,$58,$00,$00,$00
*
MNEML   BYT $1C,$8A,$1C,$23,$5D,$8B
        BYT $1B,$A1,$9D,$8A,$1D,$23
        BYT $9D,$8B,$1D,$A1,$00,$29
        BYT $19,$AE,$69,$A8,$19,$23
        BYT $24,$53,$1B,$23,$24,$53
        BYT $19,$A1,$00,$1A,$5B,$5B
        BYT $A5,$69,$24,$24,$AE,$AE
        BYT $A8,$AD,$29,$00,$7C,$00
        BYT $15,$9C,$6D,$9C,$A5,$69
        BYT $29,$53,$84,$13,$34,$11
        BYT $A5,$69,$23,$A0
*
MNEMR   BYT $D8,$62,$5A,$48,$26,$62
        BYT $94,$88,$54,$44,$C8,$54
        BYT $68,$44,$E8,$94,$01,$B4
        BYT $08,$84,$74,$B4,$28,$6E
        BYT $74,$F4,$CC,$4A,$72,$F2
        BYT $A4,$8A,$01,$AA,$A2,$A2
        BYT $74,$74,$74,$72,$44,$68
        BYT $B2,$32,$B2,$01,$22,$01
        BYT $1A,$1A,$26,$26,$72,$72
        BYT $88,$C8,$C4,$CA,$26,$48
        BYT $44,$44,$A2,$C8
*
        END
        