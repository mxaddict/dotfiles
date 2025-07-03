#!/usr/bin/env sh

mkdir -p ~/.local/log
sudo cp "$HOME/.files/.config/ly/config.ini" /etc/ly/config.ini
sudo systemctl disable display-manager.service
sudo systemctl enable ly.service
