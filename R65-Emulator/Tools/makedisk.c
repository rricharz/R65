// makedisk
// initialize a new empty disk file
//
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/******************************/
int main(int argc, char *argv[])
/******************************/
{
    char s[48];
    int i;
    uint8_t buffer[256];
    
    if (argc != 2) {
        printf("Usage: makedisk diskname\n");
        exit(1);
    }
    
    if (((argv[1][0] < 'a') || (argv[1][0] > 'z')) &&
            ((argv[1][0] < 'A') || (argv[1][0] > 'Z'))) {
        printf("Disk name must start with a letter, but starts with %c\n", argv[1][0]);
        exit(1);
    }
    
    if (strlen(argv[1]) > 16) {
        argv[1][16] = 0;
        printf("Disk name too long, maximal size would be %s\n", argv[1]);
        exit(1);
    }
    sprintf(s, "../Disks/%s.disk",argv[1]);
    
    printf("Making disk %s\n",s);
    
    FILE *f = fopen(s, "w");
    if (f == NULL) {
        printf("Cannot open %s\n",s);
        exit(1);
    }
    
    // write 80 tracks of 10 sectors of 256 bytes
    // the last sector on track 0 contains the disk name at position  0xE1 ff
    
    for (i = 0; i < 256; i++)               // initialize buffer to 0
        buffer[i] = 0;
    fwrite(buffer, sizeof(buffer), 9, f);   // write 9 empty blocks
    
    i = 0;
    do
        buffer[0xE1 + i] = argv[1][i];      // write name to block 10, position 0xE1 ff
    while (argv[1][i++] != 0);
    fwrite(buffer, sizeof(buffer), 1, f);   // write block 10
    
    for (i = 0; i < 256; i++)               // initialize buffer again to 0
        buffer[i] = 0;
    for (i = 1; i < 80; i++)
        fwrite(buffer, sizeof(buffer), 10, f);   // track 2 - 80
    
    fclose(f);
    
    
}
