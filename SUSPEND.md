# Resume/Suspend support for `/swap` file

```sh
# Create the swap file
sudo fallocate -l<RAM SIZE> /swap
sudo chmod 600 /swap
sudo mkswap /swap

# Add this to the /etc/fstab
/swap  none  swap  sw  0  0

# Turn on swap
sudo swapon -a
```
