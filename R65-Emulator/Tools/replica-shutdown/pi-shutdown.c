//
// pi-shutdown.c
// Version for R65 Replica
//
// Without LED heartbeat:
//   LED heartbeat is handled by the kernel
//   put the following line at the end of
//   /boot/config.txt:
//   dtoverlay=act-led,gpio=12
//   where 12 is the gpio of the external led
//
// If SWITCH is off and R65 emulator is not running:
// Displays CPU load and temperature on
// 7 segment display of R65 Replica
// and blinks the red leds based on CPU usage
// 
// Turn SWITCH on to use 7 segment display and red leds
//
// display IP address if BREAK button is pressed
//
// The program also controls a FAN
// If the CPU temperature is above HIGH_TEMP, the fan is turned on
// If the CPU temperature is below LOW_TEMP, the fan is turned off
// 
// Copyright 2017,2018,2019,2022  rricharz
//
// cpu usage code from Matheus (https://github.com/hc0d3r)


#include <pigpio.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include "max7219.h"

#define SHUTDOWN	21      // pin 40
#define REDLED1		16      // pin 36
#define REDLED2		13      // pin 33
#define BREAK		05	// pin 29
#define FAN		27	// pin 13
#define SWITCH		24	// pin 18

#define HIGH_TEMP 63.0		// turn fan on above this temperature (in °C)
#define LOW_TEMP  53.0		// turn fan off below this temperature (in °C)

FILE *temperatureFile;
     
double T;

int *parser_result(const char *buf, int size) {
	static int ret[10];
	int i, j = 0, start = 0;

	for(i=0; i<size; i++){
		char c = buf[i];
		if(c >= '0' && c <= '9') {
			if(!start){
				start = 1;
				ret[j] = c-'0';
			} else {
				ret[j] *= 10;
				ret[j] += c-'0';
			}
		} else if(c == '\n'){
			break;
		} else {
			if(start){
				j++;
				start = 0;
			}
		}
	}

	return ret;
}

void blinkForOneSecond(int usage) {
// blink for one second, rate based on usage
    int n = (usage / 10) + 1;
    int d = 500 / n;
    for (int i = 0; i < n; i++) {
        gpioWrite(REDLED1, 1);
	if (d > 15) {
	    usleep(10000);
	    gpioWrite(REDLED1, 0);
	    usleep(1000*(d - 10));
	}
	else {
	    usleep(d*1000);
	    gpioWrite(REDLED1, 0);
	}
	gpioWrite(REDLED2, 1);
        if (d > 15) {
	    usleep(1000);
	    gpioWrite(REDLED2, 0);
	    usleep(1000*(d - 10));
	}
	else {
	    usleep(d*1000);
	    gpioWrite(REDLED2, 0);
	}
    }
}


int main (int argc, char **argv)
{
        char buf[256];
	int size, fd, *nums, prev_idle = 0, prev_total = 0, idle, total, i;
        double usage;
	int max7219IsUsed;
        
	fd = open("/proc/stat", O_RDONLY);

	printf("Monitoring BCM pin %i for shutdown\n", SHUTDOWN);

	gpioInitialise();
	gpioSetMode(SHUTDOWN, PI_INPUT);
	gpioSetPullUpDown(SHUTDOWN, PI_PUD_UP);
	gpioSetMode(BREAK, PI_INPUT);
	gpioSetPullUpDown(BREAK, PI_PUD_UP);
	gpioSetMode(SWITCH, PI_INPUT);
	gpioSetPullUpDown(SWITCH, PI_PUD_UP);
        gpioSetMode(REDLED1, PI_OUTPUT);
        gpioSetMode(REDLED2, PI_OUTPUT);
        gpioWrite(REDLED1, 0);
        gpioWrite(REDLED1, 0);
	gpioSetMode(FAN, PI_OUTPUT);
	gpioWrite(FAN, 0);		// fan initially turned off
        max7219Init();
	max7219IsUsed = 0;
	maxSendString("pi-65");

	do {
		temperatureFile = fopen(
                        "/sys/class/thermal/thermal_zone0/temp", "r");
		if (temperatureFile != NULL) {
		    fscanf(temperatureFile, "%lf", &T);
                        if (T < 0.0) T = 0.0;
                        if (T > 99999.0) T = 99999.0;
                        T = T / 1000.0;
                        fclose (temperatureFile);
                    }
		else T = 0.0;
		    
		if (gpioRead(SHUTDOWN) == 0) {
                        usleep(1000*1000);
                        if (gpioRead(SHUTDOWN) == 0) {
                                // gpioWrite(LED, 1);
                                maxSendString("PI OFF");
                                gpioWrite(REDLED1, 0);
                                gpioWrite(REDLED1, 0);
                                usleep(100000);
				gpioTerminate();
                                system("shutdown -h now");
                                exit(0);
                        }
		}
		
		else if (gpioRead(BREAK) == 0) {
		    printf("Break\n");
		    char s[255], i1[10], i2[10];
		    FILE *ip = popen("hostname -I","r");
		    if (ip) {
			int ch;
			int i = 0;
			int dot = 0;
			while (( i < 8)  && (dot < 2) && ((ch = fgetc(ip)) != EOF)) {
			    if (ch == '.') {
				i1[i-1] += 128;
				dot++;
			    }
			    else i1[i++] = ch;
			}
			i1[i] = 0; // end of string
			i = 0;
			dot = 0;
			while (( i < 8) && ((ch = fgetc(ip)) != EOF)) {
			    if (ch == '.') {
				i2[i-1] += 128;
				dot++;
			    }
			    else i2[i++] = ch;
			}
			i2[i] = 0; // end of string
			
			sprintf(s,"%s", i1);
			maxSendString(s);
			sleep(5);
			sprintf(s,"%s", i2);
			maxSendString(s);
			sleep(5);
			pclose(ip);
			max7219IsUsed = 1;
			}
		}
                
                else if ((gpioRead(SWITCH) == 0) &&
				(system("pidof -x emulator >/dev/null") != 0)) {
                
                    size = read(fd, buf, sizeof(buf));
                    if(size > 0) {

                        nums = parser_result(buf, size);

		        idle=nums[3];

			total = 0;
                        for(i=0; i<10; i++){
			    total += nums[i];
		        }


		        int diff_idle = idle-prev_idle;
		        int diff_total = total-prev_total;
		        usage = (double)(((double)(1000*(diff_total-diff_idle))/(double)diff_total+5)/(double)10);
		        fflush(stdout);
                    }
                    else {
                        usage = 0.0;
                    }
                    
                    if (usage < 0.0) usage = 0.0;
                    if (usage > 99.0) usage = 99.0;

		    prev_total = total;
		    prev_idle = idle;

		    lseek(fd, 0, SEEK_SET);
                
                    char s[64];
                    sprintf(s,"PI %02.0f %02.0f", usage, T);
                    maxSendString(s);
		    max7219IsUsed = 1;
                    blinkForOneSecond((int)usage);
                
                }
                else { 
		    if (max7219IsUsed) {
			gpioWrite(REDLED1, 0);
			gpioWrite(REDLED2, 0);
			maxSendString("        ");
			max7219IsUsed = 0;
		    }
		    usleep(1000000);
		}
		if (T > HIGH_TEMP) {
		    // printf("Fan on, T=%f\n", T);
		    gpioWrite(FAN,1);
	        }
		else if (T < LOW_TEMP) {
		    // printf("Fan off, T=%f\n", T);
		    gpioWrite(FAN,0);
	    }
	}
	while (1);
}
