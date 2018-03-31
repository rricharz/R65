// bootstrap.c
//
// Provides specific functions
// for bootstrap pascal system
//

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#include <termios.h>
#include <unistd.h>

#include "time.h"
#include "load.h"
#include "runtime.h"

/**********/
int getkey()
/**********/
// get a key from keyboard unbuffered
// standard c does not provide this function
{
    struct termios oldt,newt;
    int ch;
    
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    return ch;
}

/*********/
int pgetc()
/*********/
// get a char from pascal device
{
    int ch1;
    if (device == 0) {       // buffered keyboard input
        ch1 = getchar();
        if (ch1 == 0xa) ch1 = 0xd;  // convert linux -> R65
        return ch1;
    }
    else if (device == 1) {  // unbuffered keyboard input
        return(getkey());
    }
    else {
      printf("***** pgetc device=%d, not yet implemented\n", device);
      closeAndExit();
    }
}

/*********/
void rlin()
/*********/
{
    printf("***** rlin not yet implemented\n");
    closeAndExit();
}
