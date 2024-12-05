# Firewall

```sh
# INSTALL UFW
paru -S ufw

# ALLOW SSH
sudo ufw allow ssh

# STEAM LOCAL TRANSFER
sudo ufw allow proto udp from any to any port 27031:27036
sudo ufw allow proto tcp from any to any port 27040

# TURN THE THING ON
sudo ufw enable
```
