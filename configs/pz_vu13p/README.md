# PZ-VU13P-KFB Buildroot 配置

本目录用于生成与 CVA6 仓库 `BOARD=pz_vu13p` FPGA bitstream 配套的
64 位 RISC-V Linux SD 卡镜像。

## 硬件对应关系

- CPU：CVA6 RV64，50 MHz，Sv39。
- 内存：DDR0 从 `0x80000000` 起、DDR1 从 `0x280000000` 起，各 8 GiB，
  合计 16 GiB。必须使用配套的双 DDR FPGA bitstream，首次启动前确认两路校准，
  先在 U-Boot 检查高地址读写，再执行 Linux 大容量压力测试。
- 串口：NS16550，地址 `0x10000000`，115200 8N1。
- SD 卡：Xilinx SPI 控制器，地址 `0x20000000`。
- Ethernet MAC：lowRISC Ethernet，地址 `0x30000000`。
- Ethernet PHY：Realtek RTL8211FI，MDIO 地址 `1`。
- RGMII：`rgmii-txid`。厂家验证工程实际设置 `tx_delay_en=1`、
  `rx_delay_en=0`；Linux RTL8211F PHY 驱动会据此开启 TX 内部延时并
  关闭 RX 内部延时，避免与 FPGA 接收时钟路径重复增加 RX 延时。
- GPIO：Xilinx GPIO，地址 `0x40000000`；通道 2 的 GPIO 8 至 11
  对应 4 个低有效按键。
- I2C 0：Xilinx AXI IIC，地址 `0x50000000`，PLIC 中断 `8`，100 kHz。
- I2C 1：Xilinx AXI IIC，地址 `0x50010000`，PLIC 中断 `9`，100 kHz。

镜像内置 Xilinx IIC、GPIO 轮询按键驱动以及 `i2c-tools`、`evtest`、`memtester`。
内核启用 VFAT/NLS，支持挂载 SD 启动分区；版本后缀为 `-pz-vu13p-ddr16g`。
`post_build.sh` 自动生成 `/etc/cva6-image-release`，可用环境变量
`CVA6_IMAGE_BUILD_ID` 指定本次标识，否则按 UTC 构建时间生成。
由于板上 I2C 器件的实际地址受拨码和焊接配置影响，设备树不预先声明
具体从设备，首次启动时先扫描总线再决定是否添加对应器件节点。

该配置只支持当前 PZ-VU13P 的 64 位 CVA6 设计，没有提供 32 位配置。

## 构建

Buildroot 镜像应在原生 Linux 或 WSL2 中构建：

```sh
git submodule sync --recursive
git submodule update --init --recursive
make XLEN=64 BOARD=pz_vu13p
```

从旧 1 GiB 镜像升级时，先重建 U-Boot 与 OpenSBI，确保新补丁生效：

```sh
make -C buildroot BR2_EXTERNAL=../br2-ext-tree \
  BR2_DEFCONFIG=../configs/pz_vu13p/buildroot64_defconfig defconfig
make -C buildroot uboot-dirclean opensbi-dirclean
make -C buildroot BINARIES_DIR="$PWD/install64_pz_vu13p" linux-reconfigure
make XLEN=64 BOARD=pz_vu13p
```

U-Boot 配置为两个 DRAM bank，补丁 `0003-pz-vu13p-dual-ddr-memory.patch`
使总容量统计包含两路。自身重定位与 `bootm` 临时数据保留在低 1 GiB，
这不限制 Linux 可用内存。Boot ROM 设备树和 FIT 设备树必须描述相同的两路内存。
2026-09-13 配套镜像已完成实板启动及容量识别验证：U-Boot 显示 16 GiB，
Linux `free -h` 显示约 15.6 GiB，运行中的设备树包含两组各 8 GiB。
完整内存读写、地址别名和长期稳定性测试仍待完成，不能仅凭容量认定全部通过。

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
uname -r
cat /etc/cva6-image-release
grep -w vfat /proc/filesystems
cat /proc/cpuinfo
free -h
dmesg | grep -Ei 'mmc|spi|lowrisc|eth|phy|realtek'
ls /sys/bus/mdio_bus/devices
ip link show
ethtool eth0
i2cdetect -l
i2cdetect -y 0
i2cdetect -y 1
cat /proc/interrupts | grep -Ei 'i2c|xilinx'
ls -l /dev/input/event*
evtest
```

执行 `evtest` 后选择名称为 `keys` 的 GPIO 按键事件设备，依次按下 4 个
按键，应分别看到键值 `2`、`3`、`4`、`5` 的按下和释放事件。

I2C 扫描会发出探测事务，并非被动读取；先确认所连器件允许扫描，不要在确认
芯片型号和寄存器定义前使用 `i2cset` 写寄存器。若没有出现 `/dev/i2c-0` 和 `/dev/i2c-1`，先检查
`dmesg | grep -i i2c`，并确认 FPGA bitstream 包含两路 AXI IIC。

若网口没有 Link，先确认 MDIO 总线上能看到地址 `1`，然后核对 FPGA
bitstream 与本配置是否来自匹配的 PZ-VU13P 分支。
