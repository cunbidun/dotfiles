#/usr/bin/env bash

# Arch linux
check=$(cat /etc/os-release | grep "Arch Linux" | wc -l)
if [ $check != "0" ]; then
	yay -S cronie --needed
	sudo systemctl enable cronie.service
	sudo systemctl start cronie.service
	sudo crontab ./linux/cron/root_jobs
	crontab ./linux/cron/jobs
fi
