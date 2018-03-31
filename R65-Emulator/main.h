
#define TIME_INTERVAL   300                         // time interval for timer function in msec

// wrapper for cairo grapics
void Background(int r, int g, int b);
void Stroke(int r, int g, int b);
void Fill(int r, int g, int b, int alpha);
void StrokeWidth(int w);
void Rect(int x, int y, int w, int h);
void Line(int x1, int y1, int x2, int y2);
void Circle(int x, int y, int r);
void Text(int x, int y, char *s, int fontSize, int erase);
void TextMid(int x, int y, char *s, int fontSize, int erase);
void Image(int x, int y, char *filename);
void Paint(void);

// wrapper for main gtk functions
void Alert(char *s, int halt);
void QuitProgram(int shutDownFlag);
int checkPendingEvents();

extern int windowWidth, windowHeight;
extern int global_char;
extern int exDisplay;

// wrapper for inputs
void clearClicks(void);
void checkClick(int *x, int *y);
int  clickStillDown(void);
