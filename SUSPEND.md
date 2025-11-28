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

# Find the RESUME and RESUME_OFFSET values
findmnt -no UUID -T /swap
sudo filefrag -v /swap | awk '{ if(==0:){print substr(, 1, length()-2)} }'
```
