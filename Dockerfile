FROM ubuntu:bionic as BASE

RUN apt-get update
RUN apt-get install -y apt-utils


# Build a cross-compiler base image with most of our build requirements
FROM BASE as CROSS

RUN apt-get install -y build-essential flex bison git
RUN apt-get install -y crossbuild-essential-arm64 pkg-config-aarch64-linux-gnu bc

ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV ARCH=arm64

WORKDIR /data

# Build ARM Trusted Firmware from GitHub
FROM CROSS as ATF

RUN git clone https://github.com/ARM-software/arm-trusted-firmware.git

WORKDIR /data/arm-trusted-firmware

## swap the comments here to build the debug variant of ARM trusted firmware
## must match the copy lines in the UBOOT image below
# RUN make PLAT=sun50i_a64 DEBUG=1 bl31
RUN make PLAT=sun50i_a64 bl31


# Build u-boot from GitHub
FROM CROSS as UBOOT

RUN apt-get install -y python python-dev swig device-tree-compiler

ARG UBOOT_REPO=git://www.denx.de/git/u-boot.git
RUN git clone "${UBOOT_REPO}"

## match the debug/release selection from the ATF above
# COPY --from=ATF /data/arm-trusted-firmware/build/sun50i_a64/debug/bl31.bin /data/bl31.bin
COPY --from=ATF /data/arm-trusted-firmware/build/sun50i_a64/release/bl31.bin /data/bl31.bin

ENV BL31=/data/bl31.bin

WORKDIR /data/u-boot
RUN make nanopi_a64_defconfig
ARG NCPUS=4
RUN make -j ${NCPUS}


# Use the cross-compiler image to build the kernel
FROM CROSS as KERNEL

RUN apt-get update; apt-get install -y libssl-dev kmod

# Build the kernel as a non-root user
RUN useradd -u 1000 builder
RUN chown builder:builder /data
USER builder

# extract the linux source into /data/linux-source
ARG LINUX_SOURCE_TAR=linux-5.6.2.tar.xz
COPY ${LINUX_SOURCE_TAR} /data
RUN tar xf linux-* ; rm *.xz ; mv linux-* linux-source
WORKDIR /data/linux-source

# build and install the kernel image and modules
# config should be taken care of by the cross-compiler environment
RUN make defconfig
ARG NCPUS=4
RUN make -j ${NCPUS} Image
RUN make -j ${NCPUS} modules
RUN make modules_install INSTALL_MOD_PATH=/data/modules


# Create "IMAGES" intermediate for doing some data shuffling, creating initrd, etc.
FROM CROSS as IMAGES

RUN apt-get install -y cpio

COPY --from=KERNEL /data/modules /data/modules

RUN mkdir -p /data/initramfs/lib/modules
WORKDIR /data/initramfs
RUN find /data/modules -type f -iname '*.ko' -exec aarch64-linux-gnu-strip --strip-debug {} \;
RUN rm -rf /data/initramfs/lib/modules/* && mv /data/modules/lib/modules/* /data/initramfs/lib/modules/
RUN find . | cpio -H newc -o > /data/initramfs.cpio
WORKDIR /data
RUN cat initramfs.cpio | gzip > initramfs.igz


# Actual product is just a bare wrapper around all the build products we need
FROM alpine

WORKDIR /data
COPY --from=UBOOT /data/u-boot/u-boot-sunxi-with-spl.bin /data/
COPY --from=UBOOT /data/u-boot/arch/arm/dts/sun50i-a64-nanopi-a64.dtb /data/
COPY --from=KERNEL /data/linux-source/arch/arm64/boot/Image /data/
COPY --from=KERNEL /data/linux-source/vmlinux /data/
COPY --from=IMAGES /data/initramfs.igz ./
COPY --from=IMAGES /data/initramfs/lib/modules /data/modules

CMD ["/bin/echo", "No command"]
