//
// pi-shutdown.c
// Version for R65 Replica
//
// Without LED heartbeat:
//   LED heartbeat is handled by the kernel
//   put the following line at the end of
//   /boot/config.txt:
//   dtoverlay=pi3-act-led,gpio=12
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
// Copyright 2017,2018,2019  rricharz
//
// cpu usage code from Matheus (https://github.com/hc0d3r)


#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define SHUTDOWN	29      // pin 40, wiring pi 29
#define REDLED1		27      // pin 36, wiring pi 27
#define REDLED2		23      // pin 33, wiring pi 23
#define BREAK		21	// pin 29, wiring pi 21
#define FAN		02	// pin 13, wiring pi 02
#define SWITCH		05	// pin 18, wiring pi 05

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

int blinkForOneSecond(int usage) {
// blink for one second, rate based on usage
    int n = (usage / 10) + 1;
    int d = 500 / n;
    for (int i = 0; i < n; i++) {
        digitalWrite(REDLED1, 1);
	if (d > 15) {
	    delay(10);
	    digitalWrite(REDLED1, 0);
	    delay(d - 10);
	}
	else {
	    delay(d);
	    digitalWrite(REDLED1, 0);
	}
	digitalWrite(REDLED2, 1);
        if (d > 15) {
	    delay(10);
	    digitalWrite(REDLED2, 0);
	    delay(d - 10);
	}
	else {
	    delay(d);
	    digitalWrite(REDLED2, 0);
	}
    }
}


int main (int argc, char **argv)
{
        char buf[256];
	int size, fd, *nums, prev_idle = 0, prev_total = 0, idle, total, i;
        double usage;
	int fanIsOn;
	int max7219IsUsed;
        
	fd = open("/proc/stat", O_RDONLY);

	printf("Monitoring wiringPi pin %i for shutdown\n", SHUTDOWN);
        system("/home/pi/bin/max7219 'pi-65'");

	wiringPiSetup();
	pinMode(SHUTDOWN, INPUT);
	pullUpDnControl(SHUTDOWN, PUD_UP);
	pinMode(BREAK, INPUT);
	pullUpDnControl(BREAK, PUD_UP);
	pinMode(SWITCH, INPUT);
	pullUpDnControl(SWITCH, PUD_UP);
        pinMode(REDLED1, OUTPUT);
        pinMode(REDLED2, OUTPUT);
        digitalWrite(REDLED1, 0);
        digitalWrite(REDLED1, 0);
	pinMode(FAN, OUTPUT);
	digitalWrite(FAN, 0);		// fan initially turned off
	fanIsOn = 0;
	max7219IsUsed = 0;

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
		    
		if (digitalRead(SHUTDOWN) == 0) {
                        delay(1000);
                        if (digitalRead(SHUTDOWN) == 0) {
                                // digitalWrite(LED, 1);
                                system("/home/pi/bin/max7219 'PI OFF'");
                                digitalWrite(REDLED1, 0);
                                digitalWrite(REDLED1, 0);
                                delay(100);
                                system("shutdown -h now");
                                exit(0);
                        }
		}
		
		else if (digitalRead(BREAK) == 0) {
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
			
			sprintf(s,"/home/pi/bin/max7219 '%s'", i1);
			system(s);
			sleep(5);
			sprintf(s,"/home/pi/bin/max7219 '%s'", i2);
			system(s);
			sleep(5);
			pclose(ip);
			max7219IsUsed = 1;
			}
		}
                
                else if ((digitalRead(SWITCH) == 0) &&
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
                    sprintf(s,"/home/pi/bin/max7219 'PI %02.0f %02.0f'",
                        usage, T);
                    system(s);
		    max7219IsUsed = 1;
                    blinkForOneSecond((int)usage);
                
                }
                else { 
		    if (max7219IsUsed) {
			digitalWrite(REDLED1, 0);
			digitalWrite(REDLED2, 0);
			system("/home/pi/bin/max7219 '        '");
			max7219IsUsed = 0;
		    }
		    delay(1000);
		}
		if (T > HIGH_TEMP) {
		    // printf("Fan on, T=%f\n", T);
		    digitalWrite(FAN,1);
		    fanIsOn = 1;
	        }
		else if (T < LOW_TEMP) {
		    // printf("Fan off, T=%f\n", T);
		    digitalWrite(FAN,0);
		    fanIsOn = 0;
	    }
	}
	while (1);
}
