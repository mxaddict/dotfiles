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

# Get the UUID for the /swap file
sudo findmnt -no UUID -T /swap

# Get the resume_offset value for the /swap file
sudo filefrag -v /swap | awk '$1=="0:" {print substr($4, 1, length($4)-2)}'

# Add this to your bootloader entry
resume=UUID=<uuid from findmnt> resume_offset=<offset from filefrag>
```
