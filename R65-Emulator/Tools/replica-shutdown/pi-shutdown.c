//
// pi-shutdown.c
// version for R65 Replica
// with LED heartbeat
// 
// Copyright 2017,2018  rricharz 


#include <wiringPi.h>
#include <stdlib.h>

#include <stdio.h>

#define PIN 29       // pin 40, wiring pi 29
#define SWITCH 5     // pin 18, wiring pi 5
//#define LED 26       // pin 32, wiring pi 26

int ledState = 0;

FILE *temperatureFile;

double T;

int main (int argc, char **argv)
{

	printf("Monitoring wiringPi pin %i for shutdown\n", PIN);
        system("/home/pi/bin/max7219 'pi-65'");

	wiringPiSetup();
	pinMode(PIN, INPUT);
	pullUpDnControl (PIN, PUD_UP);
        pinMode(SWITCH, INPUT);
	pullUpDnControl (SWITCH, PUD_UP);
         // pinMode(LED, OUTPUT);
         // digitalWrite(LED, 1);

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
                else if (digitalRead(SWITCH) != 0){
                    ledState = !ledState;
                    //         digitalWrite(LED, ledState)
                    temperatureFile = fopen(
                        "/sys/class/thermal/thermal_zone0/temp", "r");
                    if (temperatureFile != NULL) {
                        fscanf(temperatureFile, "%lf", &T);
                        T = T / 1000.0;
                        char s[64];
                        if (ledState)
                            sprintf(s,"/home/pi/bin/max7219 'Pi65 %2.0fC'", T);
                        else
                            sprintf(s,"/home/pi/bin/max7219 'Pi65-%2.0fC'", T);
                        printf("%s\n",s);
                        system(s);
                    }
                    fclose (temperatureFile);
                }
                
		delay(1000);
	}
	while (1);
}
