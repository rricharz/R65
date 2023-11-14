// crt.c

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "main.h"
#include "R65.h"
#include "fake6502.h"
#include "crt.h"
#include "time.h"
#include "fdc.h"
#include "exdisp.h"


#define SETNORMALTEXTCOLOR   Stroke(210,210,210)
#define SETDOTCOLOR          Stroke(0,225,225); Fill(0,225,225,0)
#define SETPASCALCOLOR       Stroke(0,210,210)
#define SETHIDETEXTCOLOR     Stroke(0,0,0) 
#define SETINVERSETEXTCOLOR  Stroke(160,160,160); Fill(160,160,160,0)
#define SETINVERSEPTEXTCOLOR Stroke(0,160,160); Fill(0,160,160,0)
#define SETDISKNAMECOLOR     Stroke(255, 20, 20)
#define SETBACKGROUNDCOLOR   Fill(0,0,0,0)
#define SETBUTTONCOLOR       Stroke(210,210,210); Fill(63,63,63,0)
#define SETLEDBORDERCOLOR    Stroke(210,210,210);
#define SETLEDONCOLOR        Fill(255, 0, 0, 0)
#define SETLEDOFFCOLOR       Fill(127, 0, 0, 0)
#define SETINFOBACKGROUND    Stroke(10,45,60); Fill(10,45,60,255)

int      global_pendingCrtUpdate;
int      global_videoBaseAddress;
int      global_curlin;
int      global_curpos;
int      global_curloc;
int      global_graphicsFlag;
int      hcell;
int      vcell;
int      csize;
int      xdot2;
int      ydot2;
int      showCursor;

int led[NUM_LEDS];

/*************/
void crt_init()
/*************/
{
    global_pendingCrtUpdate = 0;
    global_curlin = 0;
    global_curpos = 0;
    global_videoBaseAddress = M_CRTMEM;
    for (int i = 0; i < NUM_LEDS; i++)
        led[i] = 0;
    global_graphicsFlag = 0;
    xdot2 = crtWidth / 112;
    ydot2 = crtHeight / 59;
    printf("Dot size = %0.1f x %0.1f\n", (double)xdot2/2.0, (double)ydot2/2.0);
    // In order to handle the fractional expansion
    // factor on some displays, white (cyan) dots are one dot larger
    // than black ones. This allows to make all visible dots the same
    // size. The alternative would be to have variable dot sizes,
    // but this would be very visible.
}

/*******************************/
void setLed(int index, int value)
/*******************************/
{
    if ((index >= 0) && (index < NUM_LEDS)) {
        if (led[index] != value) {
            led[index] = value;
            global_pendingCrtUpdate = 1;
        }
    }
}


/************************/
void checkInfoBarButtons()
/************************/
// display the information bar
{
    int x, y;
    checkClick(&x, &y);
    
    if (exDisplay) {
        if (checkButton(1) == 0) {
            QuitProgram(0); // shutdown is handled by service
        }
        if (checkButton(2) == 0) {
            QuitProgram(0);
        }
        if (checkButton(3) == 0) {
            printf("Executing NMI\n");
            pendingNMI = 1;
        }
    }
    
    if (x > 0) {
    
        // check for Quit button
        if ((x >= QUIT_HPOS) && (x <= QUIT_HPOS + QUIT_HSIZE)
            && (y <= QUIT_HPOS) && (y >= QUIT_VPOS - QUIT_VSIZE)) {
            QuitProgram(0);
        }
    
        // check for Stop button
        if ((x >= STOP_HPOS) && (x <= STOP_HPOS + QUIT_HSIZE)
           && (y <= QUIT_HPOS) && (y >= QUIT_VPOS - QUIT_VSIZE)) {        
            printf("Executing NMI\n");
            pendingNMI = 1;
        }
            
        // check for Shutdown button
        if ((x >= SDOWN_HPOS) && (x <= SDOWN_HPOS + SDOWN_HSIZE)
           && (y <= QUIT_HPOS) && (y >= QUIT_VPOS - QUIT_VSIZE)) {        
            QuitProgram(1);
        }
    }
}

/*******************************************************/
void crt_show7segmentDisplay(char* s, int y, char* label)
/*******************************************************/

{
    int x;
    int i = 0;
    do {
        if (s[i] == ' ') s[i] = '!';
        i++;
    }
    while ((i<16) && (s[i] != 0));
    x = panelOffset + 5 * panelScale;
    Stroke(210,210,210); Fill(0, 0, 0, 0);
    Rect(x - 2 * panelScale, y + 4 * panelScale, 160 * panelScale, 32 * panelScale);
    Stroke(65, 65, 65);
    Text(x, y, "8.8.8.8.8.8.8.8.",
                "DSEG7 Classic", 24 * panelScale, 0, 1);
    Stroke(255, 20, 20);
    Text(x, y, s,
                "DSEG7 Classic", 24 * panelScale, 0, 1);
    SETBUTTONCOLOR;
    Text(x, y + 15 * panelScale, label,
                "Monospace", 10 * panelScale, 0, 0);
}

/**************/
void infoPanel()
/**************/
// display the information bar
{
    char s1[16], s2[16], s3[16];
    char * s; 
    // show Quit button
    SETBUTTONCOLOR;
    Rect(QUIT_HPOS, QUIT_VPOS, QUIT_HSIZE, QUIT_VSIZE);
    Text(QUIT_HPOS + (PANEL_FONTSIZE / 2), QUIT_VPOS - (PANEL_FONTSIZE / 3),
      "QUIT", "Monospace", PANEL_FONTSIZE, 0, 0);
    
    // show STOP button
    Rect(STOP_HPOS, QUIT_VPOS, QUIT_HSIZE, QUIT_VSIZE);
    Text(STOP_HPOS + (PANEL_FONTSIZE / 3), QUIT_VPOS - (PANEL_FONTSIZE / 3),
      "BREAK", "Monospace", PANEL_FONTSIZE, 0, 0);
      
    // show SHUTDOWN button
    Rect(SDOWN_HPOS, QUIT_VPOS, SDOWN_HSIZE, QUIT_VSIZE);
    Text(SDOWN_HPOS + (PANEL_FONTSIZE / 3), QUIT_VPOS - (PANEL_FONTSIZE / 3),
      "SHUTDOWN", "Monospace", PANEL_FONTSIZE, 0, 0);
      
    // show leds
    SETLEDBORDERCOLOR;
    for (int i = 0; i < NUM_LEDS; i++) {
        if (led[i])
            SETLEDONCOLOR;
        else
            SETLEDOFFCOLOR;
        Circle(LED_HPOS + LED_SIZE / 2, LED_VPOS  + i * LED_VDIST - LED_SIZE / 2, LED_SIZE);
    }
    if (exDisplay) {
        setDriveLed(0, led[0]);
        setDriveLed(1, led[1]);
    }
    
    // show disk names
    for (int drive = 0; drive <2; drive++) {
        Stroke(210,210,210); Fill(0, 0, 0, 0);
        Rect(LED_HPOS + 25 * panelScale, LED_VPOS  + drive * LED_VDIST + 5 * panelScale,
            132 * panelScale, 22 * panelScale);
        Stroke(65, 65, 65);
        Text(LED_HPOS + 26 * panelScale, LED_VPOS + drive * LED_VDIST,
            "\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08",
            "Led Panel Station On", 18 * panelScale, 0, 1);       
        SETDISKNAMECOLOR;
        SETBACKGROUNDCOLOR;
        Text(LED_HPOS + 26 * panelScale, LED_VPOS + drive * LED_VDIST,
            floppy[drive].name, "Led Panel Station On", 18 * panelScale, 0, 1);
        SETBUTTONCOLOR;
        char s[16];
        sprintf(s,"Floppy disk %d",drive);
        Text(LED_HPOS, LED_VPOS + drive * LED_VDIST + 16 * panelScale,
          s, "Monospace", 10 * panelScale, 0, 0);
    }
    
    // show 7 segment displays
    int usedByUser = 0;
    int j=0;
    for (int i=0; i<8; i++) {
        if (s1[j]=read6502_8(RS8_LED+i)) usedByUser = 1;
        if (s1[j]&128) {
            s1[j]=s1[j]&127;
            s1[(j++)+1]='.';      
        }
        j++;
    }
    s1[j]=0;
    if (!usedByUser) {
        time_t now;
        struct tm * now_tm;
        now = time(NULL);
        now_tm = localtime(&now);
 
        if (T < 0) {
            FILE *temperatureFile =
                fopen("/sys/class/thermal/thermal_zone0/temp", "r");
 	        if (temperatureFile != NULL) {
		        fscanf(temperatureFile, "%d", &T);
                T  = T / 1000;
		        if (T < 0) T = 0;
		        if (T > 99) T = 99;
		        fclose (temperatureFile);
		    }
	        else T = 0;
        }
        
        sprintf(s1,"%02d.%02d %02d°", now_tm->tm_hour,   
          now_tm->tm_min, (int)T);
    }
    sprintf(s2,"%04X  %02X",pc, spMin);
    sprintf(s3,"%05d %02X", (read6502_16(R16_PPC) - read6502_16(R16_STPROG)),
        pascalMinFree >> 8);
        
    if ((memory[M8_SFLAG] & 1) == 0)
        sprintf(s3,"%05d %02X",0,0);
    
    if (read6502_8(RS8_LED)) {
        s = s1;
    }
    else if ((memory[M8_SFLAG] & 1) == 0) {
        s = s2;
    }
    else {
        s = s3;
    }
    if (exDisplay) led_showstring(s, 0);
    crt_show7segmentDisplay(s1, QUIT_VPOS + 2 * QUIT_VSIZE + 16 * panelScale,
        "KIM-1 display");
    crt_show7segmentDisplay(s2, QUIT_VPOS + 2 * QUIT_VSIZE + 76 * panelScale,
        "6502 pc and s");
    crt_show7segmentDisplay(s3, QUIT_VPOS + 2 * QUIT_VSIZE + 136 * panelScale,
        "Pascal pc and free pages");

    SETBUTTONCOLOR;
    Text(panelOffset + 14 * panelScale, 345 * panelScale,
            "R65 System 1978-1982 RR", "Monospace", 10 * panelScale, 0, 0);    
}

/**************/
void crtUpdate()
/**************/
// check the info bar buttons, then
// paint the screen, if screen has been updated
{
    char s[2];
    s[1] = 0;

    hcell = crtWidth / NUMCHAR;
    vcell = crtHeight / NUMLINES;
    if (pixelated) 
        csize = hcell * 2.1;       
    else
        csize = hcell * 1.7;
        
//  printf("Cell size = %d x %d, numchr = %d\n", hcell, vcell, NUMCHAR);
    
    checkInfoBarButtons();
    
    if (global_pendingCrtUpdate) {
        
        clock_t start = clock();
        
        Background(0.2, 0.2, 0.2);
        
        // Display Info bar
        
        infoPanel();
        
        // Display characters
        
        Crt_Background(0.0, 0.0, 0.0);
        
        SETDOTCOLOR;
        int xx, yy;
        if (global_graphicsFlag) {
            int pnt = 0x0700;
            for (yy = 0; yy < (118 * ydot2); yy += ydot2) {
                for (xx = 0; xx < 224; xx += 8) {
                    int mask = 128;
                    int val = read6502_8(pnt);
                    pnt++;
                    for (int bit = xdot2 * xx; bit < xdot2 * (xx + 8); bit+= xdot2) {
                        if (val & mask) {
                            Rect((bit >> 1) + 9 + crtOffset, 
                                crtHeight - (yy >> 1) - 15 + crtOffset,
                                    (xdot2 - 3) >> 1, (ydot2 - 3) >> 1);
                        }
                        mask = mask >> 1;                         
                    }
                }                      
            }
        }
        else {
            for (yy = 0; yy < 16; yy++) {
                for (xx = 0; xx < NUMCHAR; xx++) {
                    s[0] = read6502(global_videoBaseAddress + (NUMCHAR * yy) + xx);
                    if (s[0] & 0x80) {
                        if (memory[M8_SFLAG] & 1) {
                            SETINVERSEPTEXTCOLOR; }
                    	else {
                            SETINVERSETEXTCOLOR; }
                        Rect(hcell*xx + crtOffset, vcell*(yy+1) + 8 * panelScale + crtOffset,
                            hcell, vcell);
                        Stroke(0,0,0);
                        }
                    else if (memory[M8_SFLAG] & 1)
                        SETPASCALCOLOR;
                    else
                        SETNORMALTEXTCOLOR;
                    s[0] = s[0] & 0x7F;
                    int coffset;
                    if ((!pixelated) && (s[0] == '*')) coffset = csize/5;
                    else coffset = 0;
                    if (pixelated)
                        Text(hcell * xx + crtOffset, vcell * (yy + 1) + 3 + crtOffset + coffset,
                            s, "basis33", csize, 0, 0);
                    else
                        Text(hcell * xx + crtOffset, vcell * (yy + 1) + 3 + crtOffset + coffset,
                            s, "Monospace", csize, 0, 0);
                }
            }
        
            // Display cursor
            int onscreenCurlin = (global_curloc - global_videoBaseAddress) / NUMCHAR;
            int onscreenCurpos = (global_curloc - global_videoBaseAddress) % NUMCHAR;
            
            if ((onscreenCurlin >= 0) && (onscreenCurlin < 16) && showCursor) {
                if (memory[M8_SFLAG] & 1)
                    SETPASCALCOLOR;
                else
                    SETNORMALTEXTCOLOR;
                if (read6502(global_videoBaseAddress + (NUMCHAR*onscreenCurlin)
                   + onscreenCurpos) & 0x80) Stroke(0,0,0);
                xx = hcell * onscreenCurpos;
                yy = vcell * (onscreenCurlin + 1) + 3;
                if (hcell < 10) StrokeWidth(2);
                else StrokeWidth(hcell / 5); 
                Line(xx + crtOffset, yy  + crtOffset + hcell/3,
                    xx + hcell - 1 + crtOffset, yy  + crtOffset + hcell/3);
                StrokeWidth(2);
            }
        }
        
        // Update complete
        global_pendingCrtUpdate = 0;
        Paint();
        
        // printf("Updating screen took %0.f msec\n", (double)((clock() - start)/1000));
    }
}
