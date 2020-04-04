#!/bin/bash

docker build -t localhost/u-boot .

rm -rf output/

mkdir ./output

mkdir output/extlinux
cp extlinux.conf output/extlinux/


docker run --name u-boot_product localhost/u-boot

docker cp u-boot_product:/data/boot ./output/boot

mkdir -p output/boot/dtbs/allwinner/
docker cp u-boot_product:/data/sun50i-a64-nanopi-a64.dtb ./output/boot/dtbs/allwinner/

docker cp u-boot_product:/data/Image ./output/boot/vmlinuz-mainline
docker cp u-boot_product:/data/initramfs.igz ./output/boot/initramfs-mainline
docker cp u-boot_product:/data/modloop.squashfs ./output/boot/modloop-mainline

docker cp u-boot_product:/data/u-boot-sunxi-with-spl.bin ./output/

docker rm u-boot_product



# (
#     cd output/
#     mkdir initramfs
#     (
#         cd initramfs
#         gunzip -c ../initramfs.igz | cpio --extract
#     )

#     mkdir modloop
#     (
#         cd modloop
#         unsquashfs ../modloop.squashfs
#     )
# )

cat > output/install.sh <<- EOM
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

sudo mkfs.vfat "\${DEVICE}1"

sudo mkfs.ext4 "\${DEVICE}2"
sudo mount "\${DEVICE}2" "\${MOUNTPOINT}"

#sudo cp -rv boot extlinux "\${MOUNTPOINT}"
BASE=\$(PWD)
(
    cd "\${MOUNTPOINT}"
    tar xvf "\${BASE}/../void-aarch64-ROOTFS-20181111.tar.xz"
)

sudo umount "\${MOUNTPOINT}"

sudo dd if=u-boot-sunxi-with-spl.bin "of=\${DEVICE}" bs=8k seek=1

sync
EOM

chmod +x output/install.sh
