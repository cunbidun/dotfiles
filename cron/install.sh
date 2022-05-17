#!/bin/bash

# Arch linux
check=$(cat /etc/os-release | grep "Arch Linux" | wc -l)
if [ $check != "0" ]; then
	yay -S cronie
	sudo systemctl enable cronie.service
	sudo systemctl start cronie.service
fi
