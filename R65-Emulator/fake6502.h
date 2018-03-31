// fake6502.h

#define FLAG_CARRY     0x01
#define FLAG_ZERO      0x02
#define FLAG_INTERRUPT 0x04
#define FLAG_DECIMAL   0x08
#define FLAG_BREAK     0x10
#define FLAG_CONSTANT  0x20
#define FLAG_OVERFLOW  0x40
#define FLAG_SIGN      0x80

#define BASE_STACK     0x100

extern uint16_t pc;
extern uint8_t sp, a, x, y, status;

void reset6502();
void step6502();
void nmi6502();
void irq6502();

void push16(uint16_t pushval);
uint16_t pull16();

