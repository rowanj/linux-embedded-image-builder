FROM ubuntu:bionic as BASE

RUN apt-get update
RUN apt-get install -y apt-utils

FROM BASE as REQUIREMENTS

RUN apt-get install -y build-essential flex bison git

FROM REQUIREMENTS as CROSS

RUN apt-get install -y crossbuild-essential-arm64 pkg-config-aarch64-linux-gnu bc
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV ARCH=arm64

FROM CROSS as ATF

WORKDIR /data
RUN git clone https://github.com/ARM-software/arm-trusted-firmware.git

WORKDIR /data/arm-trusted-firmware
# RUN make PLAT=sun50i_a64 DEBUG=1 bl31
RUN make PLAT=sun50i_a64 bl31

FROM CROSS as UBOOT

RUN apt-get install -y python3 python3-distutils python3-dev swig device-tree-compiler

WORKDIR /data
RUN git clone https://github.com/u-boot/u-boot.git

# COPY --from=ATF /data/arm-trusted-firmware/build/sun50i_a64/debug/bl31.bin /data/bl31.bin
COPY --from=ATF /data/arm-trusted-firmware/build/sun50i_a64/release/bl31.bin /data/bl31.bin

ENV BL31=/data/bl31.bin

WORKDIR /data/u-boot
RUN make nanopi_a64_defconfig
RUN cat .config
RUN make -j 16

FROM CROSS as KERNEL

RUN useradd -u 1000 builder

WORKDIR /data
RUN chown builder:builder /data

USER builder
COPY linux-5.6.2.tar.xz /data
RUN tar Jxf linux-* ; rm *.xz ; mv linux-* linux-source
WORKDIR /data/linux-source

USER root
RUN apt-get update; apt-get install -y libssl-dev kmod

USER builder
RUN make defconfig
RUN make -j16 Image
RUN make -j16 modules
RUN make modules_install INSTALL_MOD_PATH=/data/modules

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

FROM alpine

WORKDIR /data
COPY --from=UBOOT /data/u-boot/u-boot-sunxi-with-spl.bin /data/
COPY --from=UBOOT /data/u-boot/arch/arm/dts/sun50i-a64-nanopi-a64.dtb /data/
COPY --from=KERNEL /data/linux-source/arch/arm64/boot/Image /data/
COPY --from=KERNEL /data/linux-source/vmlinux /data/
COPY --from=IMAGES /data/initramfs.igz ./
COPY --from=IMAGES /data/initramfs/lib/modules /data/modules

CMD ["/bin/echo", "No command"]
