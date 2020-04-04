# u-boot cross-compiler for nanopi A64

This docker-based build script wraps generating a new u-boot image for the the nanopi A64 with current sources and toolchains.

No more tracking down cross-compilation packages, flags, and environment variables.

## Upstream u-boot environment

```text
baudrate=115200
boot_fastboot=fastboot
boot_normal=fatload mmc 0:1 4007f800 boot.img;boota 4007f800
boot_recovery=sunxi_flash read 4007f800 recovery;boota 4007f800
bootcmd=run setargs_mmc boot_normal
bootdelay=1
cma=256M
console=ttyS0,115200
earlyprintk=sunxi-uart,0x01c28000
filesize=177038
init=/sbin/init
initcall_debug=0
loglevel=8
mmc_root=/dev/mmcblk0p2
nand_root=/dev/nandd
selinux=0
setargs_mmc=setenv bootargs selinux=${selinux} earlyprintk=${earlyprintk} initcall_debug=${initcall_debug} console=tty0 console=${console} no_console_suspend loglevel=${loglevel} root=${mmc_root} init=${init} partitions=${partitions} cma=${cma} rootwait sunxi_chipid=${sunxi_chipid}
sunxi_chipid=3c25028e-50344218-14004620-92c000ba
sunxi_serial=1400503442183c25028e
```
