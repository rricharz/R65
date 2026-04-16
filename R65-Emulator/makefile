CC = gcc

LIBS = `pkg-config --libs gtk+-3.0`
CFLAGS = `pkg-config --cflags gtk+-3.0` -Isrc

SRC = src/main.c src/fake6502.c src/R65.c src/crt.c src/fdc.c

all: emulator

emulator: $(SRC)
	$(CC) -pthread -o emulator $(SRC) $(CFLAGS) $(LIBS)

.PHONY: clean

clean:
	rm -f emulator