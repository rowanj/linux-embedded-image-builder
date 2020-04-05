# Linux image builder for NanoPi

This repository builds and enumerates the requirements for creating a bootable Micro SD card for running Linux on an ARM embedded board.

Specifically, it presently builds Void Linux for the FriendlyARM NanoPi A64 - but the steps (and code!) should be fairly transferrable to other platforms and distributions depending on their support of your environment.

It builds the requirements from first-party/mainline sources because I have trust issues with blobs and images which don't come with clear reproduction instructions.

To this end, it uses source tarballs for the Linux Kernel and Root filesystem for whatever distro you are using.

No more tracking down cross-compilation packages, flags, and environment variables; here's what happens:

## Steps

The process is divided into two major stages, one which builds all the resources and templates, and one which applies the built resources to your Micro SD/EMMC card etc.

This separation allows easier tweaking of the built resources as-needed to fine-tune specifics of your install.

### Build Installer

Run the `./build-installer.sh` script to use Docker to create the resources for installing.

The break-down of this process is:

1. Creates a cross-compilation environment suitable for building for the target platform (i.e. ARM aarch64)
1. Builds [ARM Trusted Firmware](https://www.trustedfirmware.org/) from their [GitHub mirror](https://github.com/ARM-software/arm-trusted-firmware)

   As I understand, this needs to be embedded in the `u-boot` image to fully initialise the processor for early boot support.

1. Builds [`Das U-Boot`](https://www.denx.de/wiki/U-Boot) from source.

   I think the u-boot/u-boot repository on GItHub is also reliable, but it doesn't appear to be canonical and might need the dependencies swapped for python3

1. Builds the Linux kernel from a local tarball (i.e. `linux-5.6.2.tar.xz` downloaded from [kernel.org](https://www.kernel.org/))

1. Strips the debug symbols from the kernel modules and builds an `initrd` image

This should create an `installer/` subdirectory containing the next phase.

### Install

Enter the `installer/` directory and examine the `install.sh` script there.

Documentation and interface cleanup TBD but particularly check the content of `install.sh` before running it; and if you're not comfortable you understand it enough to not destroy your system please don't run it.  That's on you.  It does what *I* need it to and hasn't wiped *my* workstation's hard drive yet.
