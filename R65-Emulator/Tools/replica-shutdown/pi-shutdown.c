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
//#define LED 26       // pin 32, wiring pi 26

int ledState = 0;

int main (int argc, char **argv)
{

	printf("Monitoring wiringPi pin %i for shutdown\n", PIN);
        system("/home/pi/bin/max7219 'pi-65'");

	wiringPiSetup();
	pinMode(PIN, INPUT);
	pullUpDnControl (PIN, PUD_UP);
         // pinMode(LED, OUTPUT),
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
                // else {
                //        ledState = !ledState;
                //         digitalWrite(LED, ledState);
                // }
		delay(1000);
	}
	while (1);
}
