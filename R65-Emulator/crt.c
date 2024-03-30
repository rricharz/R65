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


#define SETNORMALTEXTCOLOR   Stroke(210,210,210)
#define SETDOTCOLOR          Stroke(128,90,0); Fill(255,180,0,0)
#define SETDOTBACKGROUNDCOLOR Stroke(255,180,0); Fill(36,26,0,0)
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
int      global_videoMemorySplitted;
int      hcell;
int      vcell;
int      csize;
double   xdot2;
double   ydot2;
int      showCursor;
int      quit_hsize;     // horizontal size of QUIT button
int      quit_vsize;     // vertical size of QUIT button
int      quit_vpos;      // Vertical position of QUIT button
int      sdown_hpos;     // SHUTDOWN button
int      sdown_hsize;
int      quit_hpos;      // Horizontal position of QUIT button
int      stop_hpos;      // STOP button


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
 
    // In order to handle the fractional expansion
    // factor on some displays, white (cyan) dots are one dot larger
    // than black ones. This allows to make all visible dots the same
    // size. The alternative would be to have variable dot sizes,
    // but this would be very visible.
    quit_hsize  = 42 * panelScale;
    quit_vsize  = 15 * panelScale;
    quit_vpos   = quit_vsize + (crtOffset / 2);
    sdown_hpos  = panelOffset + 2 * panelScale;
    sdown_hsize = 63 * panelScale;
    quit_hpos   = sdown_hpos + sdown_hsize + panelScale * 7;
    stop_hpos   = sdown_hpos + sdown_hsize + quit_hsize + panelScale * 14;

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
    
    if (x > 0) {
        
        // printf("Check button click at %d,%d\n",x,y);
    
        // check for Quit button
        if ((x >= quit_hpos) && (x <= quit_hpos + quit_hsize)
            && (y <= quit_vpos) && (y >= quit_vpos - quit_vsize)) {
            printf("QUIT button clicked\n");
            QuitProgram(0);
        }
    
        // check for Stop button
        if ((x >= stop_hpos) && (x <= stop_hpos + quit_hsize)
           && (y <= quit_vpos) && (y >= quit_vpos - quit_vsize)) {        
            printf("BREAK button clicked\n");
            pendingNMI = 1;
        }
            
        // check for Shutdown button
        if ((x >= sdown_hpos) && (x <= sdown_hpos + sdown_hsize)
           && (y <= quit_vpos) && (y >= quit_vpos - quit_vsize)) {
            printf("SHUTDOWN button clicked\n");        
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
    Rect(quit_hpos, quit_vpos, quit_hsize, quit_vsize);
    Text(quit_hpos + (PANEL_FONTSIZE / 2), quit_vpos - (PANEL_FONTSIZE / 3),
      "QUIT", "Monospace", PANEL_FONTSIZE, 0, 0);
    
    // show STOP button
    Rect(stop_hpos, quit_vpos, quit_hsize, quit_vsize);
    Text(stop_hpos + (PANEL_FONTSIZE / 3), quit_vpos - (PANEL_FONTSIZE / 3),
      "BREAK", "Monospace", PANEL_FONTSIZE, 0, 0);
      
    // show SHUTDOWN button
    Rect(sdown_hpos, quit_vpos, sdown_hsize, quit_vsize);
    Text(sdown_hpos + (PANEL_FONTSIZE / 3), quit_vpos - (PANEL_FONTSIZE / 3),
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
    
    crt_show7segmentDisplay(s1, quit_vpos + 2 * quit_vsize + 16 * panelScale,
        "KIM-1 display");
    crt_show7segmentDisplay(s2, quit_vpos + 2 * quit_vsize + 76 * panelScale,
        "6502 pc and s");
    crt_show7segmentDisplay(s3, quit_vpos + 2 * quit_vsize + 136 * panelScale,
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
    int gcrtxoff;
    int gcrtyoff;

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
        
        int xx, yy;
        
        if (1) {  // always show text
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
        if (global_videoMemorySplitted) {
            SETDOTBACKGROUNDCOLOR;
            if (global_graphicsFlag) {
                xdot2 = (double)crtWidth / (double)NUMXDOTS;
                ydot2 = xdot2; // preserve aspect ratio
                int reducedHeight = (double)crtWidth * (double)NUMYDOTS / (double)NUMXDOTS;
                gcrtxoff = crtOffset;
                gcrtyoff =  crtOffset + 1 + reducedHeight;
                Rect(gcrtxoff,gcrtyoff,crtWidth - 1,reducedHeight);         
            }
            else {
                xdot2=2;
                ydot2=2;
                gcrtxoff = crtOffset + crtWidth - NUMXDOTS * xdot2 - 1;
                gcrtyoff = crtOffset + 1 + ydot2 * NUMYDOTS;
                Rect(gcrtxoff,gcrtyoff,
                    xdot2 * NUMXDOTS - 1,ydot2 * NUMYDOTS);
            }

            SETDOTCOLOR;
            int pnt = 0x0700;
            for (double yy = 0.0; yy < ((double)NUMYDOTS * ydot2); yy += ydot2) {
                for (int xx = 0; xx < NUMXDOTS; xx += 8) {
                    int mask = 128;
                    int val = read6502_8(pnt);
                    pnt++;
                    for (double bit = xdot2 * xx; bit < xdot2 * (xx + 8); bit+= xdot2) {
                        if (val & mask) {
                            Rect(gcrtxoff + bit,  gcrtyoff - yy,
                                    (int)xdot2, (int)ydot2);
                        }
                        mask = mask >> 1;                         
                    }
                }                      
            }
        }
        
        // Update complete
        global_pendingCrtUpdate = 0;
        Paint();
        
        // printf("Updating screen took %0.f msec\n", (double)((clock() - start)/1000));
    }
}
