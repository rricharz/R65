LIBS = `pkg-config --libs gtk+-3.0`
CFLAGS = `pkg-config --cflags gtk+-3.0`

all : emulator

emulator : main.c main.h fake6502.c fake6502.h R65.c R65.h crt.c crt.h fdc.c fdc.h
	gcc -pthread -o emulator main.c fake6502.c R65.c crt.c fdc.c -lrt $(LIBS) $(CFLAGS)

.PHONY : clean

clean :
	rm -f emulator
