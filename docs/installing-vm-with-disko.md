# 使用 Disko 重装 VMware 虚拟机

本文说明如何从 NixOS 安装介质启动一台新的 VMware 虚拟机，使用
`hosts/nixos/disko-config.nix` 清空并初始化 64 GiB 虚拟磁盘，然后安装
`nixosConfigurations.nixos`。

> **警告：** Disko 的 `destroy,format,mount` 模式会清除配置中指定磁盘的分区表和
> 全部数据。不要在当前正在使用的系统盘上测试该命令。执行前必须单独核对目标磁盘
> 的容量、型号和 `/dev/disk/by-id` 路径。

## 目标布局

当前 Disko 配置将创建：

```text
64 GiB GPT disk
├── ESP       1 GiB, FAT32                 -> /boot
└── system    remaining space, Btrfs
    ├── /root                              -> /
    ├── /home                              -> /home
    ├── /nix                               -> /nix
    ├── /persist                           -> /persist
    └── /swap, 8 GiB swapfile              -> /.swapvol
```

Btrfs 子卷共享 `system` 分区的可用空间。`/persist` 为将来的 Impermanence
预留；首次安装时不会自动清空 `/root`。

## 安装前准备

### 仓库状态

开始安装前，在现有系统中确认以下内容已经提交并推送，或已复制到其他可靠介质：

- `disko` Flake input 及对应的 `flake.lock`；
- `disko.nixosModules.disko` 模块加载；
- `hosts/nixos/disko-config.nix`；
- 其余 NixOS、Home Manager 和 dotfiles 配置。

不要依赖待重装虚拟机磁盘中的唯一一份配置仓库。

### VMware 设置

建议的新虚拟机规格：

```text
Firmware: UEFI
Disk:     64 GiB
Memory:   8 GiB
CPU:      1 socket, 4 cores
ISO:      NixOS Minimal ISO
```

虚拟磁盘可以采用 VMware 默认推荐的 SCSI 控制器。安装完成前不要移除 ISO。

## 1. 从安装介质启动

启动 NixOS Minimal ISO，确认系统以 UEFI 模式启动：

```bash
test -d /sys/firmware/efi && echo UEFI
```

确认网络和时间正常：

```bash
ip address
timedatectl
```

如果需要 Wi-Fi，可使用安装环境提供的 NetworkManager 或 `nmtui` 连接。

## 2. 取得配置仓库

从远端克隆：

```bash
git clone <repository-url> ~/nixos-config
cd ~/nixos-config
```

也可以从只读共享目录或其他介质复制。私有仓库所需的临时凭据不要提交到仓库。

## 3. 确认目标磁盘

查看全部块设备：

```bash
lsblk -e7 -o NAME,PATH,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS
ls -l /dev/disk/by-id
```

目标应是约 64 GiB 的 VMware 虚拟磁盘。`sr0` 通常是安装 ISO，不能作为目标。

优先记录稳定的 `by-id` 路径，例如：

```text
/dev/disk/by-id/scsi-36000c29...
```

如果安装环境没有为虚拟磁盘提供 `by-id`，单磁盘虚拟机通常是 `/dev/sda`，但仍须
根据容量和型号再次核对。

为了后续命令清楚显示目标，可以设置变量：

```bash
INSTALL_DISK=/dev/disk/by-id/REPLACE_WITH_ACTUAL_ID
lsblk "$INSTALL_DISK"
```

不要在尚未替换占位路径时继续。

## 4. 切换主机配置到 Disko

仓库日常状态只加载 Disko 模块，不导入未来磁盘布局。安装时需要在工作副本中完成
以下变更。

在 `hosts/nixos/default.nix` 的 `imports` 中加入：

```nix
./disko-config.nix
```

从 `hosts/nixos/hardware-configuration.nix` 删除整个 `fileSystems` 和
`swapDevices` 定义，但保留下列硬件信息：

```nix
boot.initrd.availableKernelModules
boot.initrd.kernelModules
boot.kernelModules
boot.extraModulePackages
nixpkgs.hostPlatform
```

将 `hosts/nixos/disko-config.nix` 中的设备占位符换成刚才确认的目标：

```nix
device = lib.mkDefault "/dev/disk/by-id/REPLACE_WITH_ACTUAL_ID";
```

如果选择直接写 `/dev/sda`，执行 Disko 前必须再次检查它确实是 64 GiB 目标盘。

Flake 默认忽略未跟踪文件，因此先暂存安装所需改动：

```bash
git add flake.nix flake.lock hosts/nixos
nix flake check --no-build
```

暂存不等于提交；它只是让本地 Flake 求值能够看到新文件。

## 5. 生成并检查 Disko 操作

先使用 `--dry-run`。它只生成脚本路径，不执行磁盘修改：

```bash
sudo nix run github:nix-community/disko/latest#disko -- \
  --dry-run \
  --mode destroy,format,mount \
  --flake .#nixos
```

再次核对：

```bash
grep -n 'device =' hosts/nixos/disko-config.nix
lsblk -e7 -o NAME,PATH,SIZE,MODEL,TYPE,FSTYPE,MOUNTPOINTS
```

## 6. 清空、格式化并挂载目标盘

只有确认目标正确后，才能执行：

```bash
sudo nix run github:nix-community/disko/latest#disko -- \
  --mode destroy,format,mount \
  --flake .#nixos
```

Disko 默认挂载到 `/mnt`。完成后检查：

```bash
findmnt -R /mnt
lsblk -f
swapon --show
```

预期至少包含：

```text
/mnt
/mnt/boot
/mnt/home
/mnt/nix
/mnt/persist
/mnt/.swapvol
```

如果挂载结果不符合预期，不要运行 `nixos-install`。

## 7. 重新生成硬件配置

为这台新虚拟机生成硬件信息，但不要重新生成文件系统定义：

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix \
  hosts/nixos/hardware-configuration.nix
git add hosts/nixos/hardware-configuration.nix
```

检查生成文件没有 `fileSystems` 或 `swapDevices`，磁盘挂载仍应完全由 Disko 管理：

```bash
grep -E 'fileSystems|swapDevices' hosts/nixos/hardware-configuration.nix
```

该命令没有输出才符合预期。然后再次验证：

```bash
nix flake check --no-build
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

## 8. 安装 NixOS

执行安装：

```bash
sudo nixos-install --root /mnt --flake .#nixos
```

安装程序可能要求设置 root 密码。当前用户声明没有保存明文密码，因此安装完成后还应
为 `ryuk` 设置密码：

```bash
sudo nixos-enter --root /mnt -c 'passwd ryuk'
```

安装环境中的 `~/nixos-config` 位于 ISO 的临时文件系统，重启后会消失。将包含新硬件
配置的工作副本复制到目标系统，或者在重启前提交并推送到远端：

```bash
sudo cp -a ~/nixos-config /mnt/home/ryuk/nixos-config
sudo nixos-enter --root /mnt -c \
  'chown -R ryuk:users /home/ryuk/nixos-config'
```

如果 dotfiles 没有通过远端仓库恢复，也应在此时复制到 `/mnt/home/ryuk/dotfiles` 并
修正所有者。确认密码设置和配置保存都成功后再重启。

## 9. 重启并验证

```bash
sudo reboot
```

在 VMware 中断开安装 ISO，确保虚拟机从虚拟磁盘启动。

进入系统后检查：

```bash
findmnt /
findmnt /boot
findmnt /home
findmnt /nix
findmnt /persist
swapon --show
zramctl
lsblk -f
```

`swapon --show` 应同时显示高优先级 zram 和较低优先级的 Btrfs swapfile。还应检查：

- systemd-boot 可以启动，并显示受 `configurationLimit` 限制的世代；
- NetworkManager、Niri、SDDM 和输入法正常；
- VMware 图形、剪贴板和自动分辨率支持正常；
- `ryuk` 可以登录并使用 sudo；
- `nix flake check --no-build` 和 `nixos-rebuild switch` 可以重复成功执行。

## 10. 安装后整理仓库

确认新系统稳定后，检查并提交安装阶段产生的配置变化：

```bash
git status
git diff --cached
```

重点检查：

- `disko-config.nix` 的设备路径是否应该进入仓库；
- 新生成的硬件模块是否只包含这台虚拟机的硬件信息；
- `hardware-configuration.nix` 不再包含重复的文件系统和 swap 声明；
- 没有临时密钥、密码或安装介质路径进入 Git。

如果不希望把某台虚拟机的磁盘 ID 固定进仓库，可以继续保留
`lib.mkDefault` 占位符，并在安装时使用临时工作副本替换它。

## 以后加入 Impermanence

首次安装先保持所有子卷正常持久化。确认磁盘和系统安装稳定后，再单独完成：

1. 加入 Impermanence input 和 NixOS/Home Manager 模块；
2. 声明 `/persist` 中的系统与用户白名单；
3. 实现启动阶段重建 `/root`；
4. 测试密码、SSH、NetworkManager、日志和用户应用状态；
5. 最后决定是否取消整个 `/home` 子卷的永久挂载。

不要在首次 Disko 安装中同时启用根子卷自动清空，以免把分区、启动与持久化问题混在
一次调试中。

## 故障处理原则

- Disko 失败后先查看 `lsblk`, `findmnt -R /mnt` 和完整错误日志，不要反复盲目重跑。
- 格式化完成但安装失败时，通常可以修正配置后重新运行 `nixos-install`，无需再次
  `destroy`。
- 需要重新挂载已有布局时只使用 Disko 的 `mount` 模式，不要使用 `destroy`。
- 系统无法启动时可从 ISO 进入，挂载已有布局后使用 `nixos-enter --root /mnt` 修复。
- VMware 快照可以辅助测试，但不代替仓库、用户文件和重要数据的外部备份。
