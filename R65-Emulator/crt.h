// crt.h

// CRT controller and keyboard addresses

#define R8_CRTADR   0x1420      // CRT controller address register
#define R8_CRTDAT   0x1421      // CRT controller address register
#define M8_CURLIN   0x00ED      // Current cursor line
#define M8_CURPOS   0x00EE      // Current cursor position
#define M_CRTMEM    0x0400      // Start of video memory
#define M8_VFLAG    0x1780      // video flag register
#define M8_SFLAG    0x1781      // system flag register
#define M8_OFFSET   0x1782      // display memory offset (lines)
#define M8_CHAR     0x1785      // char register

#define NUMCHAR     (read6502(0x178A)+1)
#define NUMLINES    16   // number of lines

#define NUMXDOTS    224     // size of graphics area in dots
#define NUMYDOTS    118

#define NUM_LEDS    2   // Number of leds
#define LED_VPOS   (245 * panelScale)
#define LED_HPOS   (panelOffset + 5 * panelScale)
#define LED_SIZE   (13 * panelScale)
#define LED_VDIST  (50 * panelScale)

#define MIN_WINDOW_WIDTH    1160   // proposed minimal width of main window
#define MIN_WINDOW_HEIGHT   660    // proposed minimal height of main window
#define PANEL_FONTSIZE      (12.0 * panelScale)
#define WINDOW_NAME     "R65 Emulator"    // name of main window
#define ICON_NAME       ""                // path to icon for window

extern int      global_pendingCrtUpdate;
extern int      global_videoBaseAddress;
extern int      global_curlin;
extern int      global_curpos;
extern int      global_curloc;
extern int      global_graphicsFlag;
extern int      showCursor;
    
void crt_init();
void crtUpdate();
void setLed(int index, int value);
