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
int      QUIT_HPOS;

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
        if ((x >= STOP_HPOS) && (x <= QUIT_HPOS + QUIT_HSIZE)
           && (y <= QUIT_HPOS) && (y >= QUIT_VPOS - QUIT_VSIZE)) {        
            printf("Executing NMI\n");
            pendingNMI = 1;
        }
            
        // check for Shutdown button
        if ((x >= SDOWN_HPOS) && (x <= SDOWN_HPOS + SDOWN_HSIZE)
           && (y <= QUIT_HPOS) && (y >= QUIT_VPOS - QUIT_VSIZE)) {        
            printf("Executing shutdown\n");
            system("sudo shutdown -h now");
        }
    }
}

/*********************************/
void crt_showstring(char* s, int y)
/*********************************/

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
    Stroke(70, 70, 70);
    Text(x, y, "8.8.8.8.8.8.8.8.",
                "DSEG7 Classic", 24 * panelScale, 0, 1);
    Stroke(255, 20, 20);
    Text(x, y, s,
                "DSEG7 Classic", 24 * panelScale, 0, 1);
}

/**************/
void infoPanel()
/**************/
// display the information bar
{    
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
        Rect(LED_HPOS, LED_VPOS  + i * LED_VDIST, LED_SIZE, LED_SIZE);
    }
    if (exDisplay) {
        setDriveLed(0, led[0]);
        setDriveLed(1, led[1]);
    }
    
    // show disk names
    SETDISKNAMECOLOR;
    SETBACKGROUNDCOLOR;
    for (int drive = 0; drive <2; drive++) {
        Text(LED_HPOS + 30 * panelScale, LED_VPOS - panelScale + drive * LED_VDIST,
            floppy[drive].name, "Monospace", 18 * panelScale, 0, 0);
    }
    
    // show spMin and pascalMinFree
    char s[16];
    if (read6502_8(RS8_LED)) {
        for (int i=0; i<8; i++)
          s[i]=read6502_8(RS8_LED+i);
        s[8]=0;
    }
    else if (pascalMinFree == 0xFFFF) {
        sprintf(s,"%04X  %02X",pc, spMin);
    }
    else {
        sprintf(s,"%05d %02X",
                (read6502_16(R16_PPC) - read6502_16(R16_STPROG)),
                pascalMinFree >> 8);
    }
//  printf("Displaying string >%s<\n",s);
    if (exDisplay) led_showstring(s, 0);
    crt_showstring(s, QUIT_VPOS + 2 * QUIT_VSIZE + 16 * panelScale);
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
                        Rect(hcell*xx + crtOffset, vcell*(yy+1) + 3 + crtOffset,
                            hcell, vcell);
                        Stroke(0,0,0);
                        }
                    else if (memory[M8_SFLAG] & 1)
                        SETPASCALCOLOR;
                    else
                        SETNORMALTEXTCOLOR;
                    s[0] = s[0] & 0x7F;
                    if (s[0] == '*')   // the star needs to be placed lower
                        Text(hcell * xx + crtOffset, vcell * (yy + 1) + 3 + crtOffset,
                            s, "Monospace", csize, 0, 0);
                    else
                        Text(hcell * xx + crtOffset, vcell * (yy + 1)  - 4 + crtOffset,
                            s, "Monospace", csize, 0, 0);
                }
            }
        
            // Display cursor
            int onscreenCurlin = (global_curloc - global_videoBaseAddress) / NUMCHAR;
            int onscreenCurpos = (global_curloc - global_videoBaseAddress) % NUMCHAR;
            if (memory[M8_SFLAG] & 1)
                SETPASCALCOLOR;
            else
                SETNORMALTEXTCOLOR;
            xx = hcell * onscreenCurpos;
            yy = vcell * (onscreenCurlin + 1) + 3;
            StrokeWidth(hcell / 5);
            Line(xx + crtOffset, yy  + crtOffset,
                xx + hcell - 1 + crtOffset, yy  + crtOffset);
            StrokeWidth(2);
        }
        
        // Update complete
        global_pendingCrtUpdate = 0;
        Paint();
        
        // printf("Updating screen took %0.f msec\n", (double)((clock() - start)/1000));
    }
}
