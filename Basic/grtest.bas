 10 REM GRTEST - TEST GRAPHICS
 20 PLOT NEW
 30 MOVE 22,110
 40 PRINT #3; "GRTEST - TEST GRAPHICS"
 50 PLOT 0,0,0
 60 PLOT 223,0,0
 70 PLOT 223,117,0
 80 PLOT 0,117,0
 90 MOVE 10,10
 100 DRAW 216,10
 110 DRAW 216,108
 120 DRAW 10,108
 130 DRAW 10,10
 140 MOVE 12,12
 150 DRAW 214,106
 160 MOVE 12,106
 170 DRAW 214,12
 200 MOVE 30,0
 210 PRINT #3; "TYPE ANY KEY TO QUIT"
 220 GET C1$
 230 PLOT END
