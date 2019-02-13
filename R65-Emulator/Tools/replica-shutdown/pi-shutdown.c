//
// pi-shutdown.c
// Version for R65 Replica
//
// Without LED heartbeat
//   LED heartbeat is handled by the kernel
//   put the following line at the end of
//   /boot/config.txt:
//   dtoverlay=pi3-act-led,gpio=12
//   where 12 is the gpio of the external led
//
// Displays CPU load and temperature on
// segment display of R65 Replica,
// if SWITCH is on. Turn SWITCH off when
// running R65 emulator to see R65 stack
// pointer and free Pascal memory
// 
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

#define PIN 29       // pin 40, wiring pi 29

FILE *temperatureFile;
     
double T;

int *parser_result(const char *buf, int size){
	static int ret[10];
	int i, j = 0, start = 0;

	for(i=0; i<size; i++){
		char c = buf[i];
		if(c >= '0' && c <= '9'){
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



int main (int argc, char **argv)
{
        char buf[256];
	int size, fd, *nums, prev_idle = 0, prev_total = 0, idle, total, i;
        double usage;
        
	fd = open("/proc/stat", O_RDONLY);

	printf("Monitoring wiringPi pin %i for shutdown\n", PIN);
        system("/home/pi/bin/max7219 'pi-65'");

	wiringPiSetup();
	pinMode(PIN, INPUT);
	pullUpDnControl (PIN, PUD_UP);

	do {
		if (digitalRead(PIN) == 0) {
			printf("Shutting down...\n");
                        delay(1000);
                        if (digitalRead(PIN) == 0) {
                                // digitalWrite(LED, 1);
                                system("/home/pi/bin/max7219 'PI OFF'");
                                delay(100);
                                system("shutdown -h now");
                                exit(0);
                        }
		}
                
                else if (system("pidof -x emulator >/dev/null") != 0) {
                
                    size = read(fd, buf, sizeof(buf));
                    if(size > 0) {

                        nums = parser_result(buf, size);

		        idle=nums[3];

                        for(i=0, total=0; i<10; i++){
			    total += nums[i];
		        }


		        int diff_idle = idle-prev_idle;
		        int diff_total = total-prev_total;
		        usage = (double)(((double)(1000*(diff_total-diff_idle))/(double)diff_total+5)/(double)10);
                        printf("\r%%%6.2f", usage);
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
                
                    char s[64];
                    sprintf(s,"/home/pi/bin/max7219 'PI %02.0f %02.0f'",
                        usage, T);
                    printf("%s\n",s);
                    system(s);
                
                }
                
		delay(1000);
	}
	while (1);
}
