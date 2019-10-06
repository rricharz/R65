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

#define BORDER      12   // border in pixels
#define NUMCHAR     48   // number of chars per line
#define NUMLINES    16   // number of lines

#define INFO_HEIGHT 30   // vertical pixels for info bar area
#define QUIT_HPOS   14   // Horizontal position of QUIT button
#define QUIT_VPOS    1   // Vertical position of QUIT button
#define QUIT_HSIZE  45   // Horizontal size of QUIT button

#define NUM_LEDS     2   // Number of leds
#define LED_VPOS    24
#define LED_HPOS   140
#define LED_SIZE    13
#define LED_HDIST  240

#define NAME_HPOS  160


#define STOP_HPOS (2 * QUIT_HPOS +QUIT_HSIZE)    // horizontal position of STOP button

#define MIN_WINDOW_WIDTH    800   // proposed minimal width of main window
#define MIN_WINDOW_HEIGHT   480   // proposed minimal height of main window
#define MAX_WINDOW_WIDTH    1024  // proposed max width of main window
#define MAX_WINDOW_HEIGHT   696   // proposed max height of main window
#define WINDOW_NAME     "R65 Emulator"    // name of main window
#define ICON_NAME       ""                // path to icon for window

extern int      global_pendingCrtUpdate;
extern int      global_videoBaseAddress;
extern int      global_curlin;
extern int      global_curpos;
extern int      global_curloc;
extern int      global_graphicsFlag;
    
void crt_init();
void crtUpdate();
void setLed(int index, int value);
