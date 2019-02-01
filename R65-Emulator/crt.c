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


#define SETNORMALTEXTCOLOR  Stroke(210,210,210)
#define SETDOTCOLOR         Stroke(0,225,225); Fill(0,225,225,0)
#define SETPASCALCOLOR      Stroke(0,210,210)
#define SETHIDETEXTCOLOR    Stroke(0,0,0) 
#define SETINVERSETEXTCOLOR Stroke(210,210,0)
#define SETDISKNAMECOLOR    Stroke(255,0,0)
#define SETBACKGROUNDCOLOR  Fill(0,0,0,0)
#define SETBUTTONCOLOR      Stroke(210,210,210); Fill(63,63,63,0)
#define SETLEDBORDERCOLOR   Stroke(210,210,210);
#define SETLEDONCOLOR       Fill(255, 0, 0, 0)
#define SETLEDOFFCOLOR      Fill(127, 0, 0, 0)
#define SETINFOBACKGROUND   Stroke(10,45,60); Fill(10,45,60,255)

int      global_pendingCrtUpdate;
int      global_videoBaseAddress;
int      global_curlin;
int      global_curpos;
int      global_cursor_color;
int      global_curloc;
int      global_graphicsFlag;
int      hcell;
int      vcell;
int      csize;
int      xdot2;
int      ydot2;

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
    global_cursor_color = 0xFF;
    global_graphicsFlag = 0;
    hcell = windowWidth / NUMCHAR;
    vcell = (windowHeight - INFO_HEIGHT - 20) / NUMLINES;
    csize = vcell - 2;
    printf("Cell size = %d x %d\n", hcell, vcell);
    xdot2 = windowWidth / 112;
    ydot2 = (windowHeight - INFO_HEIGHT - 20) / 59;
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
        if ((x >= QUIT_HPOS) && (x <= QUIT_HPOS + QUIT_HSIZE) && (y <= INFO_HEIGHT - QUIT_VPOS)) {
            QuitProgram(0);
        }
    
        // check for Stop button
        if ((x >= STOP_HPOS) && (x <= STOP_HPOS + QUIT_HSIZE) && (y <= INFO_HEIGHT - QUIT_VPOS)) {
            printf("Executing NMI\n");
            pendingNMI = 1;
        }
    }
}

/************/
void infoBar()
/************/
// display the information bar
{
    // display the background
    SETINFOBACKGROUND;
    Rect(1,INFO_HEIGHT+5,windowWidth-1,INFO_HEIGHT+1);
    
    // show Quit button
    SETBUTTONCOLOR;
    Rect(QUIT_HPOS, INFO_HEIGHT - QUIT_VPOS, QUIT_HSIZE, INFO_HEIGHT - 9);
    Text(QUIT_HPOS+2, INFO_HEIGHT - QUIT_VPOS - 5, "QUIT", 16, 0);
    
    // show STOP button
    Rect(STOP_HPOS, INFO_HEIGHT - QUIT_VPOS, QUIT_HSIZE, INFO_HEIGHT - 9);
    Text(STOP_HPOS+2, INFO_HEIGHT - QUIT_VPOS - 5, "STOP", 16, 0);
    
    // show leds
    SETLEDBORDERCOLOR;
    for (int i = 0; i < NUM_LEDS; i++) {
        if (led[i])
            SETLEDONCOLOR;
        else
            SETLEDOFFCOLOR;
        Rect(LED_HPOS + i * LED_HDIST, LED_VPOS, LED_SIZE, LED_SIZE);
    }
    if (exDisplay) {
        setDriveLed(0, led[0]);
        setDriveLed(1, led[1]);
    }
    
    // show disk names
    SETDISKNAMECOLOR;
    SETBACKGROUNDCOLOR;
    for (int drive = 0; drive <2; drive++) {
        Text(NAME_HPOS + LED_HDIST * drive, INFO_HEIGHT - QUIT_VPOS - 3,
            floppy[drive].name, 24, 0);
    }
    
    // show spMin and pascalMinFree
    char s[16];
    int ledword;
    if (ledword = read6502_16(R16_LED16))
        sprintf(s,"%05d %02X", ledword, spMin);
    else if (pascalMinFree == 0xFFFF) {
        time_t now = time(NULL);
        char buff[20];
//        if (exDisplay) {
//            strftime(buff,20,"%H%M",localtime(&now));
//            buff[1] |= 0x80;
//        }
//        else
            strftime(buff,20,"%H:%M",localtime(&now));
        sprintf(s,"%s %02X", buff, spMin);
    }
    else
        sprintf(s,"%05d %02X", pascalMinFree, spMin);
//    if (exDisplay)
//        led_showstring(s, 0);
//    else
        Text(NAME_HPOS + LED_HDIST * 2, INFO_HEIGHT - QUIT_VPOS - 3, s, 24, 0);
}

/**************/
void crtUpdate()
/**************/
// check the info bar buttons, then
// paint the screen, if screen has been updated
{
    char s[2];
    s[1] = 0;
    
    checkInfoBarButtons();
    
    if (global_pendingCrtUpdate) {
        
        clock_t start = clock();
        
        Background(0, 0, 0);
        
        // Display Info bar
        
        infoBar();
        
        // Display characters
        
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
                            Rect((bit >> 1) + 9, 
                                windowHeight - (yy >> 1) - 15,
                                    (xdot2 - 3) >> 1, (ydot2 - 3) >> 1);
                        }
                        mask = mask >> 1;                         
                    }
                }                      
            }
        }
        else {
            for (yy = 0; yy < 16; yy++) {
                for (xx = 0; xx < 48; xx++) {
                    s[0] = read6502(global_videoBaseAddress + (48 * yy) + xx);
                    if (s[0] & 0x80)
                        SETINVERSETEXTCOLOR;
                    else if (memory[M8_SFLAG] & 1)
                        SETPASCALCOLOR;
                    else
                        SETNORMALTEXTCOLOR;
                    s[0] = s[0] & 0x7F;
                    if (s[0] == '*')   // the star needs to be placed lower
                        Text(hcell * xx + BORDER, vcell * (yy + 1) + BORDER + 3 + INFO_HEIGHT,
                            s, csize, 0);
                    else
                        Text(hcell * xx + BORDER, vcell * (yy + 1) + BORDER - 3 + INFO_HEIGHT,
                            s, csize, 0);
                }
            }
        
            // Display cursor
            int onscreenCurlin = (global_curloc - global_videoBaseAddress) / NUMCHAR;
            int onscreenCurpos = (global_curloc - global_videoBaseAddress) % NUMCHAR;
            SETNORMALTEXTCOLOR;
            xx = hcell * onscreenCurpos + BORDER;
            yy = vcell * (onscreenCurlin + 1) + BORDER + 3;
            StrokeWidth(2);
            Line(xx, yy  + INFO_HEIGHT, xx + hcell - 1, yy  + INFO_HEIGHT);
        }
        
        // Update complete
        global_pendingCrtUpdate = 0;
        Paint();
        
        // printf("Updating screen took %0.f msec\n", (double)((clock() - start)/1000));
    }
}
