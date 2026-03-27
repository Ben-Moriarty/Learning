# PXE Boot in the Homelab

> **Goal:** Network boot machines to install operating systems without USB drives, using dnsmasq for DHCP/TFTP and nginx to serve boot files over HTTP.

---

## What is PXE?

**PXE (Preboot eXecution Environment)** lets a machine boot from the network before any OS is loaded. The NIC makes a DHCP request, the DHCP server hands it a TFTP server address and a bootloader filename, the machine downloads and runs the bootloader, and from there it can pull a full OS installer over the network.

**Why bother?**
- Re-image machines without hunting for USB drives
- Consistent, repeatable installs across multiple hosts
- Essential skill for bare-metal provisioning / infrastructure work

---

## My Setup

| Component | Role |
|-----------|------|
| ESXi 8.0.3 host (AMD A8-7600, 8GB RAM) | Target machine being PXE booted |
| dnsmasq | DHCP server + TFTP server |
| nginx | HTTP server to serve OS images/installers |
| Local network | Everything on the same subnet |

---

## How PXE Boot Works (The Flow)

```
Client NIC powers on
       │
       ▼
  DHCP Request (broadcast)
       │
       ▼
  dnsmasq responds:
    - IP address
    - next-server (TFTP server IP)
    - filename (bootloader, e.g. pxelinux.0 or ipxe.efi)
       │
       ▼
  Client fetches bootloader via TFTP
       │
       ▼
  Bootloader runs, fetches menu/config via HTTP (nginx)
       │
       ▼
  User selects OS → installer streams over network
```

---

## dnsmasq Configuration

dnsmasq handles two jobs here: DHCP (handing out IPs) and TFTP (serving the initial bootloader).

```ini
# /etc/dnsmasq.conf (relevant PXE sections)

# Don't use /etc/resolv.conf — we control DNS
no-resolv

# DHCP range and lease time
dhcp-range=192.168.1.100,192.168.1.200,12h

# Tell PXE clients where the TFTP server is and what to load
dhcp-boot=pxelinux.0,pxeserver,192.168.1.10

# Enable the built-in TFTP server
enable-tftp
tftp-root=/srv/tftp

# Optional: log DHCP transactions for debugging
log-dhcp
```

## nginx Configuration

nginx serves the heavier files (kernel, initrd, ISO contents) over HTTP, which is much faster than TFTP for large files.

```nginx
# /etc/nginx/sites-available/pxe

server {
    listen 80;
    server_name _;

    root /srv/pxe;
    autoindex on;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Enable it:
```bash
ln -s /etc/nginx/sites-available/pxe /etc/nginx/sites-enabled/
systemctl restart nginx
```

File layout under `/srv/pxe/`:
```
/srv/pxe/
├── ubuntu/
│   ├── vmlinuz
│   ├── initrd
│   └── preseed.cfg   # optional: automated install answers
├── esxi/
│   └── ...
```

---

## TFTP Directory Layout

```
/srv/tftp/
├── pxelinux.0          # BIOS bootloader (from syslinux package)
├── ldlinux.c32
├── menu.c32
├── pxelinux.cfg/
│   └── default         # Boot menu definition
```

Example `pxelinux.cfg/default`:
```
DEFAULT menu.c32
PROMPT 0
TIMEOUT 300

LABEL ubuntu-install
  MENU LABEL Install Ubuntu 22.04
  KERNEL http://192.168.1.10/ubuntu/vmlinuz
  INITRD http://192.168.1.10/ubuntu/initrd
  APPEND root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://192.168.1.10/ubuntu/ubuntu-22.04.iso
```

---

**UEFI vs BIOS:** UEFI machines need a different bootloader. dnsmasq can detect the client architecture from the DHCP request and serve the right file:

```ini
# Detect UEFI clients (option 93, value 7 = x86-64 UEFI)
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-boot=tag:efi-x86_64,bootx64.efi,pxeserver,192.168.1.10
dhcp-boot=tag:!efi-x86_64,pxelinux.0,pxeserver,192.168.1.10
```

---

## Key Takeaways

- PXE boot = DHCP gives you a TFTP address → TFTP gives you a bootloader → bootloader pulls the real stuff over HTTP
- dnsmasq is great for homelabs: it does DHCP + TFTP in one lightweight daemon
- nginx handles the heavy lifting (large ISO/kernel files) because HTTP >> TFTP for speed
- UEFI adds complexity — you need a separate EFI bootloader and dnsmasq arch detection
- Logs are your friend: `journalctl -u dnsmasq -f` and nginx access logs catch most issues fast

---

## Resources

- [dnsmasq man page](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)
- [Syslinux/PXELINUX docs](https://wiki.syslinux.org/wiki/index.php?title=PXELINUX)
- [Arch Wiki: PXE](https://wiki.archlinux.org/title/PXE) — excellent reference even outside Arch
- [iPXE](https://ipxe.org/) — more powerful alternative bootloader with scripting support

---

*Part of my homelab / infrastructure learning notes.*

