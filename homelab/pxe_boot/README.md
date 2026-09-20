# PXE Boot in the Homelab
<img width="456" height="48" alt="image" src="https://github.com/user-attachments/assets/564ed263-aaaa-42e9-9d47-37d89ab2b4f3" />

the client sends a DHCP Discover request with special options signifying a PXE boot

the dnsmasq service, acting as a DHCP proxy, sends a response with info about the TFTP server and where to find the bootloader (pxelinux.0)

the client loads pxelinux.0 over TFTP, which then loads pxelinux.cfg/default

the linux kernel (vmlinuz) and temporary filesystem (initrd) are loaded

I'm using proxmox and used [this](https://forum.proxmox.com/threads/automated-installation-pxe-boot.169009/) tutorial to extract the initrd file from the auto-generated iso.

The only issue is the process from that turotial generated a 1.6G file that took 111 minutes to transfer over tftp.

The first thing I did was allow dnsmasq to auto-resolve tftp blocksize (commenting out 'tftp-no-blocksize') going from 512 bytes to 1410 bytes. Decreasing the transfer time from 1 hour and 40 minutes to just 40 minutes.
