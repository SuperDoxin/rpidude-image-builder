#!/usr/bin/env python3
from gpiozero import Button, LED
import os 
from signal import pause

power = LED(27)
power.on()

def on_powerdown():
  os.system("shutdown -h now")
  
btn = Button(26, hold_time=1)
btn.when_pressed = on_powerdown

pause()
