#!/bin/bash -e

docker build -t localhost/u-boot \
  --build-arg NCPUS=16 \
  --build-arg UBOOT_REPO=git://www.denx.de/git/u-boot.git \
  --build-arg LINUX_SOURCE_TAR=linux-5.6.2.tar.xz \
  .

rm -rf installer/

mkdir ./installer

mkdir installer/extlinux
cp extlinux.conf installer/extlinux/


docker run --name u-boot_product localhost/u-boot

mkdir ./installer/lib
docker cp u-boot_product:/data/modules ./installer/lib/modules

mkdir -p installer/boot/dtbs/allwinner/
docker cp u-boot_product:/data/sun50i-a64-nanopi-a64.dtb ./installer/boot/dtbs/allwinner/

docker cp u-boot_product:/data/Image ./installer/boot/vmlinuz-mainline
docker cp u-boot_product:/data/initramfs.igz ./installer/boot/initramfs-mainline

docker cp u-boot_product:/data/u-boot-sunxi-with-spl.bin ./installer/

docker rm u-boot_product


cat > installer/install.sh <<- EOM
#!/bin/bash

set -e
set -x

DEVICE=/dev/sdc
MOUNTPOINT=/media/foo

# sudo wipefs -a \${DEVICE}? || true
# sudo wipefs -a \${DEVICE}

echo 'start=2048, size=50M
size=500M, type=83, bootable
type=83' | sudo sfdisk "\${DEVICE}"

# partition 1 might need to exist as vfat for u-boot to save its parameters
sudo mkfs.vfat "\${DEVICE}1"

# the root filesystem
sudo mkfs.ext4 "\${DEVICE}2"
sudo mount "\${DEVICE}2" "\${MOUNTPOINT}"

# copy built products to the root filesystem
# boot/ (kernel, initrd, and device tree images)
# extlinux/ (bootloader menu)
# lib/ (for kernel modules)
sudo cp -rv boot extlinux lib "\${MOUNTPOINT}"

# Void Linux specifics
BASE=\$(pwd)
(
    cd "\${MOUNTPOINT}"
    # extract the ROOTFS tarball
    sudo tar xvf "\${BASE}/../void-aarch64-musl-ROOTFS-20191109.tar.xz"
    # enable a login console on the UART serial port
    sudo ln -s /etc/sv/agetty-ttyS0 etc/runit/runsvdir/default
)

sudo umount "\${MOUNTPOINT}"

# write the bootloader
sudo dd if=u-boot-sunxi-with-spl.bin "of=\${DEVICE}" bs=8k seek=1

sync
EOM

chmod +x installer/install.sh
