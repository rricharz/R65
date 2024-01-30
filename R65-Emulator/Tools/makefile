
all: pushr65 max7219

pushr65: pushr65.c
	gcc -o pushr65 pushr65.c
	
max7219: max7219.c
	gcc -Wall -pthread -o max7219 max7219.c -lpigpio -lrt

.PHONY : clean
clean :
	-rm -f pushr65 max7219
