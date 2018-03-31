// load.h

#define SBLOCK  0x2000
#define EBLOCK  0x7FFF

extern uint8_t mem[EBLOCK + 1];
extern uint16_t endprog;

void closeAndExit();
