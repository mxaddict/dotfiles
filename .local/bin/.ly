#!/usr/bin/env sh

mkdir -p ~/.local/log
sudo cp "$HOME/.files/.root/etc/ly/config.ini" /etc/ly/config.ini
sudo cp "$HOME/.files/.root/usr/lib/systemd/system/ly.service" /usr/lib/systemd/system/ly.service
sudo systemctl disable display-manager.service
sudo systemctl enable ly.service
