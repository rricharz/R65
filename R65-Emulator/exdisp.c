/* exdisp.c
 
 External display drivers


*/
 
#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#include "main.h"

#define NOEXPDISPLAY 1    // standard is no external display


// define pins :

#define DATA          0  // GPIO 17 (WiringPi pin num  0)  header pin 11
#define CLOCK         3  // GPIO 22 (WiringPi pin num  3)  header pin 15
#define LEDCS         4  // GPIO 23 (WiringPi pin num  4)  header pin 16
#define BUTTON_SWITCH 5  // GPIO 24 (WiringPi pin num  5)  header pin 18
#define BUTTON_DOWN   29 // GPIO 21 (WiringPi pin num 29)  header pin 40
#define BUTTON_QUIT   22 // GPIO 06 (WiringPi pin num 22)  header pin 31
#define BUTTON_STOP   21 // GPIO 05 (WiringPi pin num 21)  header pin 29
#define LED0          27 // GPIO 16 (WiringPi pin num 27)  header pin 36
#define LED1          23 // GPIO 13 (WiringPi pin num 23)  header pin 33      


// The Max7219 Registers :

#define DECODE_MODE   0x09                       
#define INTENSITY     0x0a                        
#define SCAN_LIMIT    0x0b                        
#define SHUTDOWN      0x0c                        
#define DISPLAY_TEST  0x0f

int buttonDebounce[3];                    

int segments(char ch)
{
    char ch1 = ch & 0x7f;
    if (ch1 > 0x5f) ch1 -= 0x20;
    switch (ch1) {
    case '0': return(0b01111110); break;
    case '1': return(0b00110000); break;
    case '2': return(0b01101101); break;
    case '3': return(0b01111001); break;
    case '4': return(0b00110011); break;
    case '5': return(0b01011011); break;
    case '6': return(0b01011111); break;
    case '7': return(0b01110000); break;
    case '8': return(0b01111111); break;
    case '9': return(0b01111011); break;
    case ' ': return(0b00000000); break;
    case 'A': return(0b01110111); break;
    case 'B': return(0b00011111); break;
    case 'C': return(0b01001110); break;
    case 'D': return(0b00111101); break;
    case 'E': return(0b01001111); break;
    case 'F': return(0b01000111); break;
    case 'H': return(0b00010111); break;
    case 'I': return(0b00000110); break;
    case 'J': return(0b00111000); break;
    case 'L': return(0b00001110); break;
    case 'O': return(0b01111110); break;
    case 'P': return(0b01100111); break;
    case 'S': return(0b01011011); break;
    case 'T': return(0b00001111); break;
    case 'U': return(0b00111110); break;
    case '-': return(0b00000001); break;
    case '_': return(0b00001000); break;
    case '.': return(0b10000000); break;
    default: return(0);
  }
}


static void Send16bits (unsigned short output)
{
	
  unsigned char i,j;

  for (i=16; i>0; i--) 
  {
    unsigned short mask = 1 << (i - 1); // calculate bitmask
  
    digitalWrite(CLOCK, 0);  // set clock to 0
    usleep(1);
    
    // Send one bit on the data pin
    
    if (output & mask)   
      digitalWrite(DATA, 1);          
		else                              
      digitalWrite(DATA, 0);
      
    usleep(1);
        
    digitalWrite(CLOCK, 1);  // set clock to 1  	 
  }
}


// Take a reg number and data and send to the max7219

static void MAX7219Send(unsigned char reg_number, unsigned char dataout)
{
  digitalWrite(LEDCS, 1);  // set LEDCS 1 to start
  Send16bits((reg_number << 8) + dataout);   // send 16 bits ( reg number + dataout )
  digitalWrite(LEDCS, 0);  // LEDCS 0 to latch
  usleep(1);
  digitalWrite(LEDCS, 1);  // set LEDCS 1 to finish
}

void led_showstring(char *s, int first)
{
  int j = 0;
  while ((s[j] != 0) && (j < (8 - first))) {	
    MAX7219Send(8 - j + first,segments(s[j]) | (s[j] & 0x80));
    j++;
  }
}

int checkButton(int buttonNumber)
{
  int button;
  if ((buttonNumber < 0) || (buttonNumber > 3)) return 1;
  
  switch (buttonNumber) {
    case 0: return digitalRead(BUTTON_SWITCH);
    case 1: button = BUTTON_DOWN; break;
    case 2: button = BUTTON_QUIT; break;
    case 3: button = BUTTON_STOP; break;
    default: return 1;
  }
  if (digitalRead(button) == 0) {
    // debounce
    if (buttonDebounce[buttonNumber] <= 0){
       buttonDebounce[buttonNumber] = 5;
       return 0;
     }
    else
       return 1;
  }
  else {
    if (buttonDebounce[buttonNumber] > 0)
       buttonDebounce[buttonNumber]--;
  }
  return 1;
  
}

void setDriveLed(int led, int val)
{
  // printf("SetDriveLed %d,%d\n", led, val);
  if (led == 0) digitalWrite(LED0, val);
  else if (led == 1) digitalWrite(LED1, val);
}

void init_exdisp(void)
{
  if (wiringPiSetup () == -1) {
      exDisplay = 0;
      return;
  }
  if (NOEXPDISPLAY == 1) {
      exDisplay = 0;
      return;
  }
  
  
  for (int i = 0; i < 3; i ++)
      buttonDebounce[i] = 0;
  
  pinMode(LED0, OUTPUT);
  pinMode(LED1, OUTPUT);
  digitalWrite(LED0, 0);
  digitalWrite(LED1, 0);
  
  pinMode(BUTTON_SWITCH, INPUT);
  pullUpDnControl(BUTTON_SWITCH, PUD_UP);
  pinMode(BUTTON_DOWN, INPUT);
  pullUpDnControl(BUTTON_DOWN, PUD_UP);
  pinMode(BUTTON_QUIT, INPUT);
  pullUpDnControl(BUTTON_QUIT, PUD_UP);
  pinMode(BUTTON_STOP, INPUT);
  pullUpDnControl(BUTTON_STOP, PUD_UP);

  pinMode(DATA, OUTPUT);  
  pinMode(CLOCK, OUTPUT);
  pinMode(LEDCS, OUTPUT);
  digitalWrite(LEDCS, 0);
	
  MAX7219Send(SCAN_LIMIT, 7);     // set up to scan all eight digits
 
  // BCD decode mode off : data bits correspond to the segments (A-G and DP)
  // BCD mode on :  0 to 15 =  0 to 9, -, E, H, L, P, and ' '	


  MAX7219Send(DECODE_MODE, 0);   // Set BCD decode modes off 
  MAX7219Send(DISPLAY_TEST, 0);  // Disable test mode
  MAX7219Send(INTENSITY, 1);     // set brightness 0 to 15  	
  MAX7219Send(SHUTDOWN, 1);      // come out of shutdown mode	/ turn on the digits
   
  led_showstring("        ", 0);

}

void quit_exdisp(void)
{
  led_showstring("        ", 0);
  MAX7219Send(SHUTDOWN, 1);
  setDriveLed(0, 0);
  setDriveLed(1, 0);
}
