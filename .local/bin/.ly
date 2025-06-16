#!/usr/bin/env sh

sudo cp "$HOME/.files/.config/ly/config.ini" /etc/ly/config.ini
sudo systemctl enable ly.service
