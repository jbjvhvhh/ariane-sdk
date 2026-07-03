# ATK KU040 board config

This board config adapts the CVA6 SDK image to the ATK KU040 board setup used in
`d:\demo\cva6\corev_apu\fpga`.

What is different from `genesys2`:

- Linux lowRISC Ethernet driver uses `PHY_INTERFACE_MODE_RGMII`
- Linux lowRISC Ethernet driver scans only PHY address `0x07`
- FIT/U-Boot DTB points `lowrisc-eth@30000000` to:
  - `phy-mode = "rgmii"`
  - `phy-handle = <&phy0>`
  - `phy0: ethernet-phy@7`

Build command (run in Linux / WSL):

```powershell
git submodule update --init --recursive
make XLEN=64 BOARD=atk_ku040
```

Expected output:

- `install64_atk_ku040\\sdcard.img`

Recommended usage:

1. Flash `sdcard.img` to a spare SD card.
2. Boot the KU040 with the latest FPGA bitstream that already routes:
   - `GE_1 / GE2 / PHY2 / addr 0x07`
3. In Linux, verify:

```sh
dmesg | grep -i -e eth -e phy -e mdio
ls /sys/bus/mdio_bus/devices
cat /sys/bus/mdio_bus/devices/*/phy_id
ifconfig -a
```
