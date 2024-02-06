// R65.h

// Emulator

#define R8_EMUCOM   0x1430      // Command register
#define R8_EMURES   0x1431      // Result register
#define RS8_LED     0x1432      // LED string register, 8 bytes
#define R16_PPC     0x000A      // Pascal program pounter
#define R16_STPROG  0x0011      // Pascal start of program

// Floppy disk controller

#define R8_FDCOM    0x14C0      // Command register
#define R8_FDSTAT   0x14C0      // Status register
#define R8_FDPARA   0x14C1      // Parameter register
#define R8_FDRES    0x14C1      // Result register
#define R8_FDTSTM   0x14C2      // Test mode register
#define R8_FDDAT    0x14C4      // DACK address
#define D8_USPBD    0x1702      // LED display

// KIM-1

#define KIM_IFR1    0x144D  // irq flag register
#define KIM_IER1    0x144E  // irq enable register
#define KIM_IFR2    0x145D  // irq flag register
#define KIM_IER2    0x145E  // irq enable register
#define KIM_IFR3    0x146D  // irq flag register
#define KIM_IER3    0x146E  // irq enable register
#define KIM_PORTA2  0x1451  // 6552-2 Port A (keyboard)
#define EMU_RAND    0x1706  // KIM timer, rand() in emulator

// Multiplier and timer

#define R8_MULTX    0x14E0  // Multiplier x register
#define R8_MULTY    0x14E1  // Multiplier y register
#define R16_MULTR   0x14E2  // Multiplier result register

#define R8_TMSEC    0x1747  // timer 1: count down msec

// Special memory locations

#define M8_FILDRV   0x00DC
#define M8_FILTYP   0x0300
#define M8_FILNAM   0x0301
#define M8_FILCYC   0x0311
#define M8_FILSTP   0x0312
#define M16_FILLOC  0x0313
#define M16_FILSIZ  0x0315

#define ANUMLIN     0x1789  // number of lines in video text memory
#define ANUMCHAR    0x178A  // number of chars/line 
#define M8_DATE     0x17B9
#define M8_TIME     0x17B5

int r65Setup();
int r65Loop();
int r65Quit();

// functions to handle memory mapped io
uint8_t read6502(uint16_t address);
void write6502(uint16_t address, uint8_t value);
void exec6502(uint32_t tickcount);

// functions not handling memory mapped io
uint8_t read6502_8(uint16_t address);
uint16_t read6502_16(uint16_t address);
void write6502_8(uint16_t address, uint8_t value);

int catchSubroutine(uint16_t ea);
void printRegisters();
void setKeyboardInterrupt();

extern int pendingNMI;
extern int pendingIRQ;
extern uint8_t memory[65536];
extern int spMin;
extern int pascalMinFree;
extern int T;
