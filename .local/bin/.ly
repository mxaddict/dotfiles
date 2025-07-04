#!/usr/bin/env sh
# vi: ft=sh

mkdir -p ~/.local/log
sudo cp "$HOME/.files/.root/etc/ly/config.ini" /etc/ly/config.ini
sudo cp "$HOME/.files/.root/usr/lib/systemd/system/ly.service" /usr/lib/systemd/system/ly.service
sudo cp "$HOME/.files/.root/etc/vconsole.conf" /etc/vconsole.conf
sudo mkinitcpio -P
sudo systemctl disable display-manager.service
sudo systemctl enable ly.service
