# Firewall

```sh
# install ufw
paru -S ufw

# enable and start ufw
sudo systemctl enable ufw
sudo systemctl start ufw

# allow ssh
sudo ufw allow ssh

# steam local transfer
sudo ufw allow proto udp from any to any port 27031:27036
sudo ufw allow proto tcp from any to any port 27040

# turn the thing on
sudo ufw enable
```
