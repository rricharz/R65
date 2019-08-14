/* 7219.c
 
 Raspberry Pi driving the Max7219

 to compile : gcc max7219.c -o max7219 -lwiringPi

 usage: max7219 string
 
 where string is a up to a character string to display

*/
 
#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>


// define our pins :

#define DATA        0 // GPIO 17 (WiringPi pin num 0)   header pin 11
#define CLOCK       3 // GPIO 22 (WiringPi pin num 3)   header pin 15
#define LOAD        4 // GPIO 23 (WiringPi pin num 4)   header pin 16


// The Max7219 Registers :

#define DECODE_MODE   0x09                       
#define INTENSITY     0x0a                        
#define SCAN_LIMIT    0x0b                        
#define SHUTDOWN      0x0c                        
#define DISPLAY_TEST  0x0f                         

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

static void MAX7219Send (unsigned char reg_number, unsigned char dataout)
{
  digitalWrite(LOAD, 1);  // set LOAD 1 to start
  Send16bits((reg_number << 8) + dataout);   // send 16 bits ( reg number + dataout )
  digitalWrite(LOAD, 0);  // LOAD 0 to latch
  usleep(1);
  digitalWrite(LOAD, 1);  // set LOAD 1 to finish
}




int main(int argc, char *argv[])
{
	
  if (argc != 2) {
        printf("Usage: max7219 string\n");
        exit(1);
    }

  if (wiringPiSetup () == -1) exit (1) ;

  //We need 3 output pins to control the Max7219: Data, Clock and Load

  pinMode(DATA, OUTPUT);  
  pinMode(CLOCK, OUTPUT);
  pinMode(LOAD, OUTPUT);
  digitalWrite(LOAD, 0);  // set LOAD 1 to finish
	
  MAX7219Send(SCAN_LIMIT, 7);     // set up to scan all eight digits


/* 

 BCD decode mode off : data bits correspond to the segments (A-G and DP) of the seven segment display.

 BCD mode on :  0 to 15 =  0 to 9, -, E, H, L, P, and ' '
	
*/

  MAX7219Send(DECODE_MODE, 0);   // Set BCD decode modes off
 
  MAX7219Send(DISPLAY_TEST, 0);  // Disable test mode

  MAX7219Send(INTENSITY, 1);     // set brightness 0 to 15
  	
  MAX7219Send(SHUTDOWN, 1);      // come out of shutdown mode	/ turn on the digits
  
  char *s = argv[1];
  int j = 0;
  while ((s[j] != 0) && (j < 8)) {	
    MAX7219Send(8 - j ,segments(s[j]) | (s[j] & 128));
    j++;
  }
  while (j < 8) {
    MAX7219Send(8 - j ,segments(' '));
    j++;
  }
  
 
  return 0;
}
