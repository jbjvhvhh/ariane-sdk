# PZ-VU13P-KFB Buildroot 配置

本目录用于生成与 CVA6 仓库 `BOARD=pz_vu13p` FPGA bitstream 配套的
64 位 RISC-V Linux SD 卡镜像。

## 硬件对应关系

- CPU：CVA6 RV64，50 MHz，Sv39。
- 内存：DDR4 通道 0，地址 `0x80000000`，当前映射 1 GiB。
- 串口：NS16550，地址 `0x10000000`，115200 8N1。
- SD 卡：Xilinx SPI 控制器，地址 `0x20000000`。
- Ethernet MAC：lowRISC Ethernet，地址 `0x30000000`。
- Ethernet PHY：Realtek RTL8211FI，MDIO 地址 `1`。
- RGMII：`rgmii-rxid`，与厂家工程的 `tx_delay_en=0`、
  `rx_delay_en=1` 设置一致。
- GPIO：Xilinx GPIO，地址 `0x40000000`。

该配置只支持当前 PZ-VU13P 的 64 位 CVA6 设计，没有提供 32 位配置。

## 构建

Buildroot 镜像应在原生 Linux 或 WSL2 中构建：

```sh
git submodule sync --recursive
git submodule update --init --recursive
make XLEN=64 BOARD=pz_vu13p
```

主要输出：

```text
install64_pz_vu13p/
├── fw_payload.bin
├── fitImage.itb
├── Image.gz
├── rootfs.cpio.gz
└── sdcard.img
```

其中 `sdcard.img` 可直接写入 SD 卡。第一分区保存 OpenSBI 和 U-Boot，
第二分区保存由 Linux 内核、设备树和 initramfs 组成的 FIT 镜像。

## 首次启动检查

串口参数设置为 115200、8 数据位、1 停止位、无校验。系统启动后执行：

```sh
cat /proc/cpuinfo
free -h
dmesg | grep -Ei 'mmc|spi|lowrisc|eth|phy|realtek'
ls /sys/bus/mdio_bus/devices
ip link show
ethtool eth0
```

若网口没有 Link，先确认 MDIO 总线上能看到地址 `1`，然后核对 FPGA
bitstream 与本配置是否来自匹配的 PZ-VU13P 分支。
