#!/bin/bash
# run R65 emulator with attached R65 hardware

sudo pkill pi-shutdown
sudo pkill pigpiod
sudo pigpiod
/home/pi/Projects/R65/R65-Emulator/emulator -E
sudo pkill pigpiod
sudo systemctl start pi-shutdown