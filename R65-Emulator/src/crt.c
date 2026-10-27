// crt.c

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

#include "main.h"
#include "R65.h"
#include "fake6502.h"
#include "crt.h"
#include "time.h"
#include "fdc.h"


#define SETNORMALTEXTCOLOR    Stroke(210,210,210)
#define SETINVERSETEXTCOLOR   Stroke(255,191,64)

#define SETPASCALCOLOR        Stroke(0,210,210)
#define SETINVERSEPASCALCOLOR Stroke(210,210,0); Fill(210,210,0,0)

#define SETDOTCOLOR           Fill(255,180,0,0)
#define SETDOTBACKGROUNDCOLOR Stroke(255,180,0); Fill(36,26,0,0)
#define SETHIDETEXTCOLOR      Stroke(0,0,0) 
#define SETDISKNAMECOLOR      Stroke(255, 20, 20)
#define SETBACKGROUNDCOLOR    Fill(0,0,0,0)
#define SETBUTTONCOLOR        Stroke(210,210,210); Fill(100,0,0,1)
#define SETLEDBORDERCOLOR     Stroke(210,210,210);
#define SETLEDONCOLOR         Fill(255, 0, 0, 0)
#define SETLEDOFFCOLOR        Fill(127, 0, 0, 0)
#define SETINFOBACKGROUND     Stroke(10,45,60); Fill(10,45,60,255)

int      global_pendingCrtUpdate;
int      global_videoBaseAddress;
int      global_curlin;
int      global_curpos;
int      global_curloc;
int      global_graphicsFlag;
int      global_videoMemorySplitted;
double   hcell;
double   vcell;
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

static bool mouseTracking = false;

// Screen and symbol fonts
#ifdef __APPLE__
#define SCREEN_FONT "Monaco"
#define SYMBOL_FONT "Apple Symbols"
#else
#define SCREEN_FONT "DejaVu Sans Mono"
#define SYMBOL_FONT "DejaVu Sans"
#endif

// UTF-8 symbols for character codes $18-$1F
static const char *symbols[8] = {
    "●",  // $18 Black circle
    "○",  // $19 White circle
    "⬢",  // $1A Black hexagon
    "⬡",  // $1B White hexagon
    "�",  // $1C Undefined
    "�",  // $1D Undefined
    "�",  // $1E Undefined
    "�"   // $1F Undefined
};

#define GRAPHIC_LINE_WIDTH  (int)(hcell / 5.0 + 0.5)
#define GRAPHIC_Y_OFFSET    (int)(-vcell * 0.37)
#define GRAPHIC_X_OFFSET    0
#define GRAPHIC_OVERLAP     (int)(hcell / 10.0 + 0.5)

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

/**************************************************************/
static bool graphicsMousePosition(double x, double y,
                                  int *gx, int *gy,
                                  bool clamp)
/**************************************************************/
{
    if (!global_videoMemorySplitted)
        return false;

    double scale;
    int xoff, yoff;

    if (global_graphicsFlag) {
        // Full-size graphics
        scale = (double)(crtWidth / NUMXDOTS);

        int dotWidth  = (int)(NUMXDOTS * scale + 0.999);
        int dotHeight = (int)(NUMYDOTS * scale + 0.999);

        xoff = crtOffset + (crtWidth - dotWidth) / 2;
        yoff = crtOffset + 1 + dotHeight;
    }
    else {
        // Split view: small graphics, right justified
        scale = (double)(crtWidth / (2 * NUMXDOTS));

        int dotWidth  = (int)(NUMXDOTS * scale + 0.999);
        int dotHeight = (int)(NUMYDOTS * scale + 0.999);

        xoff = crtOffset + crtWidth - dotWidth - 1;
        yoff = crtOffset + 1 + dotHeight;
    }

    int dotWidth  = (int)(NUMXDOTS * scale + 0.999);
    int dotHeight = (int)(NUMYDOTS * scale + 0.999);

    double xx = x - xoff;
    double yy = yoff - y;

    if (!clamp) {
        if (xx < 0 || xx >= dotWidth ||
            yy < 0 || yy >= dotHeight)
            return false;
    }

    int px = (int)(xx / scale);
    int py = (int)(yy / scale);

    if (!clamp &&
        (px < 0 || px >= NUMXDOTS ||
         py < 0 || py >= NUMYDOTS))
        return false;

    if (px < 0) px = 0;
    if (px >= NUMXDOTS) px = NUMXDOTS - 1;

    if (py < 0) py = 0;
    if (py >= NUMYDOTS) py = NUMYDOTS - 1;

    *gx = px;
    *gy = py;

    return true;
}

/************************************/
void crtMouseClick(double x, double y)
/************************************/
{
    mouseTracking = false;
    clearMouseDrag();
    if (!global_videoMemorySplitted) {
        // Alphanumeric display

        double hc = (double)crtWidth / NUMCHAR;
        double vc = 0.99 * (double)crtHeight / NUMLINES;

        double xx = x - crtOffset;
        double yy = y - crtOffset
                      - 8 * panelScale
                      - GRAPHIC_Y_OFFSET;

        if (xx >= 0 && xx < NUMCHAR * hc &&
            yy >= 0 && yy < NUMLINES * vc) {

            int col = (int)(xx / hc);
            int row = (int)(yy / vc);

            setMouseClick(1, col, row);
        }
    }
    else {
        // Graphics display: full-size or split

        int gx, gy;

        if (graphicsMousePosition(x, y, &gx, &gy, false)) {
            setMouseClick(2, gx, gy);
            setMouseDrag(gx, gy);
            mouseTracking = true;
        }
    }
}

/************************************/
void crtMouseMove(double x, double y)
/************************************/
{
    int gx, gy;

    if (mouseTracking &&
        graphicsMousePosition(x, y, &gx, &gy, true))
        setMouseDrag(gx, gy);
}

/************************************/
void crtMouseRelease(void)
/************************************/
{
    mouseTracking = false;
    clearMouseDrag();
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
            
        // check for Quit button
        if ((x >= quit_hpos) && (x <= quit_hpos + quit_hsize)
            && (y <= quit_vpos) && (y >= quit_vpos - quit_vsize)) {
            QuitProgram(0);
        }
    
        // check for Stop button
        if ((x >= stop_hpos) && (x <= stop_hpos + quit_hsize)
           && (y <= quit_vpos) && (y >= quit_vpos - quit_vsize)) {        
            pendingNMI = 1;
        }
            
        // check for Shutdown button
        if ((x >= sdown_hpos) && (x <= sdown_hpos + sdown_hsize)
           && (y <= quit_vpos) && (y >= quit_vpos - quit_vsize)) {
            QuitProgram(1);
        }
    }
}

/*******************************************************/
void crt_show7segmentDisplay(char* s, int y, char* label)
/*******************************************************/
{
    int x, xfield;
    double pitch;
    int i, pos;
    char out[3];

    x = panelOffset + 5 * panelScale;
    xfield = 160 * panelScale;
    pitch = (double)xfield / 8.2;

    Stroke(210,210,210);
    Fill(0, 0, 0, 0);
    Rect(x - 2 * panelScale, y + 4 * panelScale, xfield, 32 * panelScale);

    /* gray background */
    Stroke(65, 65, 65);
    for (pos = 0; pos < 8; pos++) {
        Text(x + (int)(pos * pitch), y, "8",
             "DSEG7 Classic", 24 * panelScale, 0, 1);
    }

    /* red foreground */
    Stroke(255, 20, 20);

    pos = 0;
    i = 0;

    while ((s[i] != 0) && (pos < 8)) {

        if (s[i] == ' ') {
            pos++;
            i++;
        }
        else {
            unsigned char c = (unsigned char)s[i];

            /* ignore non-ASCII completely */
            if (c >= 0x80) {
                i++;
                continue;
            }

            out[0] = c;
            out[1] = 0;
            out[2] = 0;

            /* attach dot to same digit */
            if (s[i + 1] == '.') {
                out[1] = '.';
                out[2] = 0;
                i += 2;
            }
            else {
                i += 1;
            }

            Text(x + (int)(pos * pitch), y, out,
                 "DSEG7 Classic", 24 * panelScale, 0, 1);

            pos++;
        }
    }

    SETBUTTONCOLOR;
    Text(x, y + 15 * panelScale, label,
         SCREEN_FONT, 10 * panelScale, 0, 0);
}

/*********************************************/
void showStatus(int num, char* label, int flag)
/*********************************************/
{
    SETLEDBORDERCOLOR;
  
    if (flag)
        SETLEDONCOLOR;
    else
        SETLEDOFFCOLOR;
    Circle(LED_HPOS + LED_SIZE / 2 + num * STAT_HDIST, STAT_VPOS, LED_SIZE);
    Text(LED_HPOS - LED_SIZE / 6 + num * STAT_HDIST, STAT_VPOS + 21 * panelScale,
        label, SCREEN_FONT, 10 * panelScale, 0, 0);
}

/**************/
void infoPanel()
/**************/
// display the information bar
{
    char s1[16], s2[16], s3[16];
    char * s;
    
    fflush(stdout);
    // show Quit button
    SETBUTTONCOLOR;

    Rect(quit_hpos, quit_vpos, quit_hsize, quit_vsize);
    Text(quit_hpos + (PANEL_FONTSIZE / 2), quit_vpos - (PANEL_FONTSIZE / 4),
     "QUIT", SCREEN_FONT, PANEL_FONTSIZE, 0, 0);
    
    // show STOP button
    Rect(stop_hpos, quit_vpos, quit_hsize, quit_vsize);
    Text(stop_hpos + (PANEL_FONTSIZE / 3), quit_vpos - (PANEL_FONTSIZE / 4),
      "BREAK", SCREEN_FONT, PANEL_FONTSIZE, 0, 0);
      
    // show SHUTDOWN button
    Rect(sdown_hpos, quit_vpos, sdown_hsize, quit_vsize);
    Text(sdown_hpos + (PANEL_FONTSIZE / 3), quit_vpos - (PANEL_FONTSIZE / 4),
      "SHUTDOWN", SCREEN_FONT, PANEL_FONTSIZE, 0, 0);
      
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
        Stroke(16, 16, 16);
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
          s, SCREEN_FONT, 10 * panelScale, 0, 0);
    }
    
    // show 7 segment displays
    int usedByUser = 0;
    int j=0;
    for (int i=0; i<8; i++) {
		s1[j]=read6502_8(RS8_LED+i);
        if (s1[j]) usedByUser = 1;
        if (s1[j]&128) {
            s1[j]=s1[j]&127;
            s1[(j++)+1]='.';      
        }
        j++;
    }
    s1[j]=0;
    
    if (!usedByUser)
		s1[0] = 0;
		
	int stprog = memory[0x11] + (memory[0x12] << 8);		
	int pascalPc = memory[0x0a] + (memory[0x0b] << 8) - stprog - 1;
	if (isAnimation) { 
		fflush(stdout);
	    sprintf(s2,"%04X  %02X", pcSample, spMin);
	    sprintf(s3,"%04X  %02X", pascalPcSample, (pascalMinFree >> 8) & 0xFF);

	}
	else {
		sprintf(s2,"%04X  %02X",pc, spMin);
		sprintf(s3,"%05d %02X", pascalPc & 0xFFFF, (pascalMinFree >> 8) & 0xFF);
	}
        
  if ((memory[M8_SFLAG] & 1) == 0)
        sprintf(s3,"%05d %02X",0,0);
    
  crt_show7segmentDisplay(s1, quit_vpos + 2 * quit_vsize + 13 * panelScale,
        "KIM-1 display");
  crt_show7segmentDisplay(s2, quit_vpos + 2 * quit_vsize + 70 * panelScale,
        "6502 pc and s");
  crt_show7segmentDisplay(s3, quit_vpos + 2 * quit_vsize + 127 * panelScale,
        "Pascal pc and free pages");

  showStatus(0,"TEK",tekTerminal);
  showStatus(1,"PRT", (memory[M8_SFLAG] & 0x02)| (memory[M8_VFLAG] & 0x08));
  showStatus(2,"ANI",isAnimation);
  showStatus(3,"ESC",memory[M8_SFLAG] & 0x80);
   
  SETBUTTONCOLOR;
}

/********************************************************/
void DrawGraphicCharacter(int xx, int yy, unsigned char c)
/********************************************************/
{
    // Character cell boundaries
    int x1 = hcell * xx + crtOffset + GRAPHIC_X_OFFSET;
    int x2 = hcell * (xx + 1) + crtOffset + GRAPHIC_X_OFFSET;
    int y1 = vcell * yy + 8 * panelScale + crtOffset
             + GRAPHIC_Y_OFFSET;
    int y2 = vcell * (yy + 1) + 8 * panelScale + crtOffset
             + GRAPHIC_Y_OFFSET;

    // Center of character cell
    int cx = (x1 + x2) / 2;
    int cy = (y1 + y2) / 2;

    StrokeWidth(GRAPHIC_LINE_WIDTH);

    if (c & 0x01)  // Up
        Line(cx, cy, cx, y1 - GRAPHIC_OVERLAP);

    if (c & 0x02)  // Right
        Line(cx, cy, x2 + GRAPHIC_OVERLAP, cy);

    if (c & 0x04)  // Down
        Line(cx, cy, cx, y2 + GRAPHIC_OVERLAP);

    if (c & 0x08)  // Left
        Line(cx, cy, x1 - GRAPHIC_OVERLAP, cy);

    StrokeWidth(2);
}

/**************************************************/
void DrawCircleCharacter(int xx, int yy, int filled)
/**************************************************/
{
    int cx = hcell * xx + crtOffset + hcell / 2;
    int cy = vcell * yy + 8 * panelScale + crtOffset
             + GRAPHIC_Y_OFFSET + vcell / 2;

    DrawCircle(cx, cy, 2 * hcell, filled);
}

/********************************************/
static void SetCharacterColor(unsigned char c)
/********************************************/
{
    int pascal = (memory[M8_SFLAG] & 1) != 0;
    int inverse = (c & 0x80) != 0;

    if (pascal) {
        if (inverse) {
            SETINVERSEPASCALCOLOR;
        }
        else
            SETPASCALCOLOR;
        
    }
    else {
        if (inverse)
            SETINVERSETEXTCOLOR;
        else
            SETNORMALTEXTCOLOR;
    }
}

/****************************************************************/
static void DrawEnlargedCharacter(int xx, int yy, unsigned char c)
/****************************************************************/
{
    int cx = hcell * xx + crtOffset + hcell / 2;
    int cy = vcell * yy + 8 * panelScale + crtOffset
             + GRAPHIC_Y_OFFSET + vcell / 2;

    switch (c) {
        case 0x10:  // White stone (filled)
            DrawCircle(cx, cy, 2 * hcell, 1);
            break;

        case 0x11:  // Black stone (outlined)
            DrawCircle(cx, cy, 2 * hcell, 0);
            break;
            
        case 0x12:
            DrawFadedCircle(cx, cy, 2 * hcell, 1);
            break;

        case 0x13:
            DrawFadedCircle(cx, cy, 2 * hcell, 0);
            break;
            
        // $14-$17: Reserved for additional enlarged objects
    }
}

/*******************************************************************/
static void DrawCharacter(int xx, int yy, unsigned char c, int csize)
/*******************************************************************/
{
    char s[2] = {c, 0};

    if (c < 0x10) {
        DrawGraphicCharacter(xx, yy, c);
    }
    else if (c < 0x18) {
        // Enlarged objects: handled in second pass
    }
    else if (c < 0x1F) {
        // Unicode symbols ($18-$1B)
        Text(hcell * xx + crtOffset,
             vcell * (yy + 1) - 5 + crtOffset,
             symbols[c - 0x18],
             SYMBOL_FONT, csize, 0, 0);
    }
    else {
        // Normal characters
        int coffset = (!pixelated && c == '*') ? csize/5 : 0;

        Text(hcell * xx + crtOffset,
             vcell * (yy + 1) - 5 + crtOffset + coffset,
             s, pixelated ? "basis33" : SCREEN_FONT,
             csize, 0, 0);
    }
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

    hcell = (double)crtWidth / (double)NUMCHAR;
    vcell = 0.99 * (double)crtHeight / (double)NUMLINES;
    if (pixelated) 
        csize = hcell * 2.1;       
    else
        csize = hcell * 1.7;
            
    checkInfoBarButtons();
    
	if (global_pendingCrtUpdate && (!isAnimation || global_forceCrtUpdate)) {
       
        clock_t start = clock();
        
        Background(0.2, 0.2, 0.2);
        
        // Display Info bar
        
        infoPanel();
        
        // Display characters
        
        Crt_Background(0.0, 0.0, 0.0);
        
        int xx, yy;
        
        if (1) {  // always show text
          // First pass: text, line graphics and Unicode symbols
          for (yy = 0; yy < 16; yy++) {
              for (xx = 0; xx < NUMCHAR; xx++) {

                  unsigned char c =
                      read6502(global_videoBaseAddress + NUMCHAR * yy + xx);

                  // Enlarged objects ($10-$17) are drawn in pass 2
                  if ((c & 0x7F) >= 0x10 && (c & 0x7F) < 0x18)
                      continue;

                  SetCharacterColor(c);
                  DrawCharacter(xx, yy, c & 0x7F, csize);
              }
          }
          
          // Second pass: enlarged objects ($10-$17)
          for (yy = 0; yy < 16; yy++) {
              for (xx = 0; xx < NUMCHAR; xx++) {

                  unsigned char c =
                      read6502(global_videoBaseAddress + NUMCHAR * yy + xx);

                  // Skip everything except enlarged objects
                  if ((c & 0x7F) < 0x10 || (c & 0x7F) >= 0x18)
                      continue;

                  SetCharacterColor(c);
                  DrawEnlargedCharacter(xx, yy, c & 0x7F);
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
              Line(xx + crtOffset, yy  + crtOffset + hcell/3 - 7,
                  xx + hcell - 1 + crtOffset, yy  + crtOffset + hcell/3 - 7);
              StrokeWidth(2);
            }
        }   
        if (global_videoMemorySplitted) {

			SETDOTBACKGROUNDCOLOR;

			if (global_graphicsFlag) {

				/* full view:
				use largest possible scale,
				centered horizontally */

				xdot2 = crtWidth / NUMXDOTS;

				if (xdot2 < 1) {

					/* use fractional scaling only if necessary */

					xdot2 = (double)crtWidth / (double)NUMXDOTS;

                if (xdot2 > 1.0)
                        xdot2 = 1.0;
				}

				ydot2 = xdot2;

				int dotWidth  = (int)(NUMXDOTS * xdot2 + 0.999);
				int dotHeight = (int)(NUMYDOTS * ydot2 + 0.999);

				gcrtxoff = crtOffset + (crtWidth - dotWidth) / 2;
				gcrtyoff = crtOffset + 1 + dotHeight;

				Rect(gcrtxoff - 1,
						gcrtyoff + 1,
						dotWidth + 2,
						dotHeight + 2);
				}
			else {

				/* split view:
				use half of full-view scale,
				right justified */

				xdot2 = (crtWidth / NUMXDOTS) / 2;

				if (xdot2 < 1) {

					xdot2 = (double)crtWidth /
							(2.0 * (double)NUMXDOTS);

					if (xdot2 > 1.0)
							xdot2 = 1.0;
				}

				ydot2 = xdot2;

				int dotWidth  = (int)(NUMXDOTS * xdot2 + 0.999);
				int dotHeight = (int)(NUMYDOTS * ydot2 + 0.999);

				gcrtxoff = crtOffset + crtWidth - dotWidth - 1;
				gcrtyoff = crtOffset + 1 + dotHeight;

				Rect(gcrtxoff - 1,
						gcrtyoff + 1,
						dotWidth + 2,
						dotHeight + 2);
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
                            FillRect(gcrtxoff + bit,  gcrtyoff - yy,
                                    (int)xdot2, (int)ydot2);
                        }
                        mask = mask >> 1;                         
                    }
                }                      
            }
        }
        
        // Update complete
		global_pendingCrtUpdate = 0;
		global_forceCrtUpdate = 0;
        Paint();
        
    }
}
