*---------------------------------
* SIEVE PROGRAM
* 1899 PRIMES
* BASED ON .74 SECOND VERSION
*---------------------------------
ARRAY  EQU $3500
SIZE   EQU 8192
ENDARR EQU ARRAY+SIZE
*
*---------------------------------
* PAGE ZERO VARIABLES
*---------------------------------
APNTR  EQU $06
BPNTR  EQU $08
PRIME  EQU $1B
COUNT  EQU $1D
TIMES  EQU $1F
OUTER  EQU $20
*
*---------------------------------
* RUN PROGRAM 10 TIMES
*---------------------------------
       ORG $2000
START  LDA =40
       STA OUTER
LOOP2  JSR RUNS
       DEC OUTER
       BNE LOOP2
       RTS
*
RUNS   LDA =255
       STA TIMES
LOOP   JSR GENPRM
       DEC TIMES
       BNE LOOP
       RTS
*
*---------------------------------
* GENERATE THE PRIMES
*---------------------------------
GENPRM LDY =0
       STY COUNT
       STY COUNT+1
       STY APNTR
       LDA =>ARRAY
       STA APNTR+1
       LDA =1
       LDX =>SIZE
*
*---------------------------------
* SET EACH ELEMENT IN ARRAY TO ONE
*---------------------------------
L1     STA (APNTR),Y
       INY
       BNE L1
       INC APNTR+1
       DEX
       BNE L1
*
*---------------------------------
* SCAN ENTIRE ARRAY FOR PRIMES
*---------------------------------
       LDA =>ARRAY
       STA APNTR+1
L2     LDY =0
       LDA (APNTR),Y
       BEQ L6
*
*---------------------------------
* CALCULATE INDEX INTO FLAG ARRAY
*---------------------------------
       SEC
       LDA APNTR+1
       SBC =>ARRAY
       TAX
       LDA APNTR
*
*---------------------------------
* CALCULATE PRIME P=I+I+3
*---------------------------------
       ASL A
       TAY
       TXA
       ROL A
       TAX
       TYA
       ADC =3
       STA PRIME
       BCC L3
       INX
L3     STX PRIME+1
*
*---------------------------------
* STOP SIEVING ABOVE SQRT(16384)
*---------------------------------
       TXA
       BNE L5
       CPY =127
       BCS L5
*
*---------------------------------
* CLEAR EVERY P-TH ENTRY AFTER P
*---------------------------------
       LDY =0
       LDA APNTR
       STA BPNTR
       LDA APNTR+1
       STA BPNTR+1
       CLC
L4     LDA BPNTR
       ADC PRIME
       STA BPNTR
       LDA BPNTR+1
       ADC PRIME+1
       STA BPNTR+1
       CMP =>ENDARR
       BCS L5
       TYA
       STA (BPNTR),Y
       BEQ L4
*
*---------------------------------
* COUNT PRIME
*---------------------------------
L5     INC COUNT
       BNE L6
       INC COUNT+1
*
*---------------------------------
* ADVANCE OUTER POINTER
*---------------------------------
L6     INC APNTR
       BNE L7
       INC APNTR+1
L7     LDA APNTR+1
       CMP =>ENDARR
       BCC L2
       RTS
*
       END
       