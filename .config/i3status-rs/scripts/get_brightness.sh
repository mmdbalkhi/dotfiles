#!/bin/bash
brightness=$(ddcutil getvcp 10 | grep -oP '\d+%' | head -n 1)
echo "Brightness: $brightness"

