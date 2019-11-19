FROM ubuntu:bionic as BASE

RUN apt-get update
RUN apt-get install -y apt-utils

FROM BASE as REQUIREMENTS

RUN apt-get install -y build-essential flex bison git

FROM REQUIREMENTS as CROSS

RUN apt-get install -y crossbuild-essential-arm64 pkg-config-aarch64-linux-gnu
ENV CROSS_COMPILE=aarch64-linux-gnu-

FROM CROSS as ATF

WORKDIR /data
RUN git clone https://github.com/ARM-software/arm-trusted-firmware.git
WORKDIR /data/arm-trusted-firmware
# RUN make PLAT=sun50i_a64 DEBUG=1 bl31
RUN make PLAT=sun50i_a64 bl31

FROM CROSS

RUN apt-get install -y python3 python3-distutils python3-dev swig bc device-tree-compiler

WORKDIR /data
RUN git clone https://github.com/u-boot/u-boot.git

# COPY --from=ATF /data/arm-trusted-firmware/build/sun50i_a64/debug/bl31.bin /data/bl31.bin
COPY --from=ATF /data/arm-trusted-firmware/build/sun50i_a64/release/bl31.bin /data/bl31.bin

ENV BL31=/data/bl31.bin

WORKDIR /data/u-boot
RUN make nanopi_a64_defconfig
RUN make -j 16
