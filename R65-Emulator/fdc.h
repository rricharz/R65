// fdc.h

// Floppy disk controller registers

#define R8_FDCOM    0x14C0      // Command register
#define R8_FDSTAT   0x14C0      // Status register
#define R8_FDPARA   0x14C1      // Parameter register
#define R8_FDRES    0x14C1      // Result register
#define R8_FDTSTM   0x14C2      // Test mode register
#define R8_FDDAT    0x14C4      // DACK address
#define D8_USPBD    0x1702      // LED display 

int fdc_read(uint16_t address);
void fdc_write(uint16_t address, uint8_t value);
void fdc_init();
void fdc_quit();
void checkMotorTurnoff(int tics);
int export_file();
int import_file();
int change_floppy();

struct Ddrive {
    int motor;
    int track;
    int sector;
    FILE *file;
    char name[18];
};

#define NUM_DRIVES   4   // Number of disk drives supported by the emulator

extern struct Ddrive floppy[NUM_DRIVES];
