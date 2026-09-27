# 使用 Disko 重装 VMware 虚拟机

本文说明如何从 NixOS 安装介质启动一台新的 VMware 虚拟机，使用
`hosts/nixos/disko-config.nix` 清空并初始化 64 GiB 虚拟磁盘，然后安装
`nixosConfigurations.nixos`。

> **警告：** Disko 的 `destroy,format,mount` 模式会清除配置中指定磁盘的分区表和
> 全部数据。不要在当前正在使用的系统盘上测试该命令。执行前必须单独核对目标磁盘
> 的设备路径、容量和型号。

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
    ├── /swap, 8 GiB swapfile              -> /.swapvol
    └── /root-blank, read-only snapshot     (not mounted)
```

Btrfs 子卷共享 `system` 分区的可用空间。每次启动时，initrd systemd 服务都会删除可写的
`/root` 子卷，并从只读的 `/root-blank` 快照重新创建它；`/home`、`/nix`、
`/persist` 和 swap 子卷不会被清除。

这是较保守的 Impermanence 布局：整个 `/home` 持久化，系统身份、SSH 主机密钥、
NetworkManager 连接、日志及少量系统状态通过 `/persist` 保存。以后若希望用户目录也
采用白名单模式，再单独拆分，不与首次重装同时进行。

## 安装前准备

### 仓库状态

开始安装前，在现有系统中确认以下内容已经提交并推送，或已复制到其他可靠介质：

- `disko` Flake input 及对应的 `flake.lock`；
- `disko.nixosModules.disko` 模块加载；
- `hosts/nixos/disko-config.nix`；
- `hosts/nixos/installer.nix` 和 `nixosConfigurations.nixos-installer` 输出；
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

当前单磁盘 VMware 配置默认使用 `/dev/sda`。为了后续命令清楚显示目标，可以设置变量：

```bash
INSTALL_DISK=/dev/sda
lsblk "$INSTALL_DISK"
```

输出必须仍然是约 64 GiB 的 VMware 磁盘，不能是安装介质。如果虚拟机拥有多块磁盘，
必须先修改 `hosts/nixos/disko-config.nix` 的 `device`，不能沿用默认值。

## 4. 检查独立安装配置

`nixosConfigurations.nixos-installer` 只导入 Disko 布局和最小 VMware 硬件信息，不会
加载当前旧虚拟机的 `hardware-configuration.nix`。因此格式化之前无需删除、替换或创建
占位硬件配置。

先确认安装输出能够求值：

```bash
nix eval .#nixosConfigurations.nixos-installer.config.system.build.toplevel.drvPath
```

该输出只用于准备磁盘，不是最终安装的桌面系统。

## 5. 生成并检查 Disko 操作

先使用 `--dry-run`。它只生成脚本路径，不执行磁盘修改：

```bash
sudo nix run github:nix-community/disko/latest#disko -- \
  --dry-run \
  --mode destroy,format,mount \
  --flake .#nixos-installer
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
  --flake .#nixos-installer
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

## 7. 创建空白根快照

根子卷回滚需要一个只读的 `root-blank` 快照。它必须在 Disko 创建并挂载文件系统之后、
`nixos-install` 写入系统之前创建：

```bash
BTRFS_DEVICE="$(findmnt -no SOURCE /mnt | sed 's/\[.*$//')"
sudo mkdir -p /tmp/btrfs-top
sudo mount -t btrfs -o subvolid=5 "$BTRFS_DEVICE" /tmp/btrfs-top
sudo btrfs subvolume snapshot -r \
  /tmp/btrfs-top/root \
  /tmp/btrfs-top/root-blank
sudo btrfs subvolume show /tmp/btrfs-top/root-blank
sudo umount /tmp/btrfs-top
```

如果最后的检查失败，不要继续安装。每次重新运行 Disko 的 `destroy,format,mount` 都会
清除该快照，之后必须重新执行本节。

## 8. 重新生成硬件配置

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

在 `hosts/nixos/default.nix` 的 `imports` 中加入正式磁盘布局：

```nix
./disko-config.nix
```

该导入必须在安装后继续保留，因为它同时提供正式系统的文件系统、swap、Impermanence
开关和 initrd 根子卷回滚服务。暂存安装阶段产生的修改：

```bash
git add hosts/nixos/default.nix hosts/nixos/hardware-configuration.nix
```

然后验证正式系统：

```bash
nix flake check --no-build
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

## 9. 安装 NixOS

执行安装：

```bash
sudo nixos-install --root /mnt --flake .#nixos
```

安装程序可能要求设置 root 密码。当前用户声明没有保存明文密码，因此安装完成后还应
为 `ryuk` 设置密码：

```bash
sudo nixos-enter --root /mnt -c 'passwd ryuk'
```

由于第一次启动前还没有运行 Impermanence 激活脚本，需要把刚设置的密码数据库主动放入
持久化源目录，否则第一次根子卷回滚会丢失密码：

```bash
sudo install -D -m 000 /mnt/etc/shadow /mnt/persist/etc/shadow
```

这里只持久化密码散列。`passwd`、`group` 等账户定义仍由 NixOS 配置在每次启动时生成，
不要持久化整个 `/etc`。

安装环境中的 `~/nixos-config` 位于 ISO 的临时文件系统，重启后会消失。将包含新硬件
配置的工作副本复制到目标系统，或者在重启前提交并推送到远端：

```bash
sudo cp -a ~/nixos-config /mnt/home/ryuk/nixos-config
sudo nixos-enter --root /mnt -c \
  'chown -R ryuk:users /home/ryuk/nixos-config'
```

如果 dotfiles 没有通过远端仓库恢复，也应在此时复制到 `/mnt/home/ryuk/dotfiles` 并
修正所有者。确认密码设置和配置保存都成功后再重启。

## 10. 重启并验证

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

验证 Impermanence 时，在临时根目录和持久化 home 中分别创建标记：

```bash
sudo touch /etc/impermanence-root-test
touch ~/impermanence-home-test
sudo reboot
```

重启后，`/etc/impermanence-root-test` 应消失，`~/impermanence-home-test` 应仍然存在；
`/etc/machine-id`、SSH 主机密钥和 NetworkManager 连接也应保持不变。

## 11. 安装后整理仓库

确认新系统稳定后，检查并提交安装阶段产生的配置变化：

```bash
git status
git diff --cached
```

重点检查：

- `disko-config.nix` 的设备路径是否应该进入仓库；
- 新生成的硬件模块是否只包含这台虚拟机的硬件信息；
- `hardware-configuration.nix` 不再包含重复的文件系统和 swap 声明；
- `hosts/nixos/default.nix` 继续导入 `disko-config.nix`；
- 没有临时密钥、密码或安装介质路径进入 Git。

当前仓库默认 `/dev/sda`，适合这里的单磁盘 VMware 虚拟机。如果以后用于多磁盘机器或
物理机，应改成已核对的稳定 `/dev/disk/by-id` 路径，或为不同主机分别覆盖该默认值。

## 故障处理原则

- Disko 失败后先查看 `lsblk`, `findmnt -R /mnt` 和完整错误日志，不要反复盲目重跑。
- 格式化完成但安装失败时，通常可以修正配置后重新运行 `nixos-install`，无需再次
  `destroy`。
- 需要重新挂载已有布局时只使用 Disko 的 `mount` 模式，不要使用 `destroy`。
- initrd 报告缺少 `root-blank` 时，从 ISO 启动并挂载 Btrfs 顶层，确认或重新创建快照；
  不要绕过检查后继续启动，以免误以为根目录仍受 Impermanence 管理。
- 系统无法启动时可从 ISO 进入，挂载已有布局后使用 `nixos-enter --root /mnt` 修复。
- VMware 快照可以辅助测试，但不代替仓库、用户文件和重要数据的外部备份。
