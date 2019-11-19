#!/bin/bash

docker build -t localhost/u-boot .
docker run --name u-boot_product localhost/u-boot
docker cp u-boot_product:/data/u-boot/u-boot-sunxi-with-spl.bin ./
docker rm u-boot_product

echo "# sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/sdx bs=8k seek=1"
echo "# sync"
