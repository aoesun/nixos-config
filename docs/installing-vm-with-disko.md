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
- 其余 NixOS、Home Manager 和 dotfiles 配置。

不要依赖待重装虚拟机磁盘中的唯一一份配置仓库。

### 重新开始失败的安装

如果此前的安装已经失败，最稳妥的做法是重新从 Minimal ISO 启动，再从本文第 1 步开始。
不需要手动删除旧分区、子卷或快照；第 6 步的 `destroy,format,mount` 会清除目标磁盘上的
旧安装并重新创建完整布局。重新执行前仍须再次核对 `/dev/sda`，因为该操作不可恢复。

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

### 可选：从宿主机通过 SSH 安装

在虚拟机控制台给安装环境的 `nixos` 用户设置临时密码，并启动 SSH：

```bash
sudo passwd nixos
sudo systemctl start sshd
ip -br address
```

在宿主机连接显示出的虚拟机地址：

```bash
ssh nixos@<虚拟机IP>
```

Ghostty 会传递 `TERM=xterm-ghostty`，而 Minimal ISO 可能没有对应 terminfo。出现
`unknown terminal type` 时，在 SSH 会话执行：

```bash
export TERM=xterm-256color
```

随后进入 root shell：

```bash
sudo -i
```

以下安装步骤均假定提示符为 `root@nixos`。已经是 root 时不要再使用 `sudo`，否则
`sudo` 可能清除后面设置的 `NIX_CONFIG` 环境变量。

## 2. 启用 Flakes 并取得配置仓库

Minimal ISO 默认可能未启用新式 Nix 命令和 Flakes。为当前 root shell 临时启用：

```bash
export NIX_CONFIG='experimental-features = nix-command flakes'
```

通过公开 HTTPS 地址克隆仓库，无需 GitHub 用户名或密码：

```bash
git clone https://github.com/aoesun/nixos-config.git /home/nixos/nixos-config
cd /home/nixos/nixos-config
```

也可以从只读共享目录或其他介质复制。私有仓库所需的临时凭据不要提交到仓库。

## 3. 确认目标磁盘

查看全部块设备：

```bash
lsblk -e7
```

`-e7` 只隐藏无关的 loop 设备。默认列已经包含设备名、容量、类型和挂载点，足以识别
这台固定为单块 64 GiB 磁盘的虚拟机；现有文件系统类型不影响 Disko 随后清空目标盘。

目标应是约 64 GiB 的 VMware 虚拟磁盘。`sr0` 通常是安装 ISO，不能作为目标。

当前单磁盘 VMware 配置默认使用 `/dev/sda`。为了后续命令清楚显示目标，可以设置变量：

```bash
INSTALL_DISK=/dev/sda
lsblk "$INSTALL_DISK"
```

输出必须仍然是约 64 GiB 的 VMware 磁盘，不能是安装介质。如果虚拟机拥有多块磁盘，
必须先修改 `hosts/nixos/disko-config.nix` 的 `device`，不能沿用默认值。

## 4. 准备 sops-nix 解密密钥

仓库只保存 `secrets/nixos.yaml` 中加密的用户密码哈希。对应的 age 私钥不能提交到 Git，
必须在废弃旧虚拟机前安全复制到宿主机或其他可信介质：

```text
~/.config/sops/age/keys.txt
```

将备份的私钥传入当前安装环境，并设置严格权限。例如先复制到 `/tmp/keys.txt`，再执行：

```bash
install -D -m 600 /tmp/keys.txt /root/.config/sops/age/keys.txt
```

验证它可以解密仓库中的密文，但不要打印解密内容：

```bash
SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
  nix shell nixpkgs#sops -c sops --decrypt secrets/nixos.yaml >/dev/null
```

安装命令会把该密钥复制到持久化的 `/persist/var/lib/sops-nix/key.txt`。初始用户密码为
`admin`；这是临时弱密码，首次登录后必须立即执行 `passwd` 修改。仓库中没有保存该明文，
只有它的随机加盐哈希经过 sops 加密后的密文。

## 5. 检查硬件和正式系统配置

`nixosConfigurations.nixos` 已直接导入 Disko 布局、sops-nix 以及这台 VMware 虚拟机生成的
`hardware-configuration.nix`，磁盘准备和最终安装使用同一个配置输出。当前硬件文件适用于
默认 VMware 虚拟硬件；如果重新创建虚拟机时更换了磁盘控制器等设备，先重新生成：

```bash
mkdir -p /tmp/nixos-hardware
nixos-generate-config --no-filesystems --root /tmp/nixos-hardware
cp /tmp/nixos-hardware/etc/nixos/hardware-configuration.nix \
  hosts/nixos/hardware-configuration.nix
```

确认硬件文件没有重复声明 Disko 管理的文件系统或 swap，并检查正式系统：

```bash
grep -E 'fileSystems|swapDevices' hosts/nixos/hardware-configuration.nix
nix flake check --no-build
nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
```

第一条命令应没有输出。该文件已经由 Git 追踪，因此本地修改会直接参与 Flake 求值，无需
为了构建而先执行 `git add`。

## 6. 预演 disko-install

`disko-install` 会在一次操作中完成磁盘格式化、挂载、系统安装和 bootloader 安装。
先执行 dry-run；它只构建并显示将运行的脚本，不会修改磁盘。当前版本的 dry-run 不会
真正创建默认挂载目录，却仍会解析该目录，因此先准备一个临时目录：

```bash
mkdir -p /tmp/disko-install-dry-run
nix run github:nix-community/disko/latest#disko-install -- \
  --dry-run \
  --mode format \
  --mount-point /tmp/disko-install-dry-run \
  --write-efi-boot-entries \
  --flake .#nixos \
  --disk system /dev/sda \
  --extra-files /root/.config/sops/age/keys.txt \
    /persist/var/lib/sops-nix/key.txt
```

`system` 是 `disko.devices.disk.system` 的磁盘名称；`--disk` 会明确把它映射到已经核对的
`/dev/sda`。再次运行 `lsblk -e7` 确认设备后才能继续。

## 7. 安装 NixOS

执行与预演相同但不带 `--dry-run` 的命令：

```bash
nix run github:nix-community/disko/latest#disko-install -- \
  --mode format \
  --write-efi-boot-entries \
  --flake .#nixos \
  --disk system /dev/sda \
  --extra-files /root/.config/sops/age/keys.txt \
    /persist/var/lib/sops-nix/key.txt
```

`format` 模式会清除目标盘上的旧安装并重建声明的布局。Disko 的 `postCreateHook` 会在写入
系统前自动创建只读 `root-blank`，随后 `disko-install` 安装已经构建好的正式系统。
sops-nix 会在创建用户前解密密码哈希，因此整个过程不需要运行 `passwd`、复制 `/etc/shadow`
或手动调用 `nixos-install`。

命令显示 `disko-install succeeded` 后即可重启；工具退出时会自动卸载它使用的临时安装目录。

## 8. 重启并验证

```bash
reboot
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
sudo btrfs subvolume list -r / | grep 'path root-blank$'
```

`swapon --show` 应同时显示高优先级 zram 和较低优先级的 Btrfs swapfile。还应检查：

- systemd-boot 可以启动，并显示受 `configurationLimit` 限制的世代；
- NetworkManager、Niri、SDDM 和输入法正常；
- VMware 图形、剪贴板和自动分辨率支持正常；
- `ryuk` 可以登录并使用 sudo；
- `nix flake check --no-build` 和 `nixos-rebuild switch` 可以重复成功执行。

使用临时密码 `admin` 首次登录后立即修改密码：

```bash
passwd
```

当前配置保留 NixOS 默认的可变用户密码，并通过 Impermanence 持久化 `/etc/shadow`，因此
`passwd` 设置的新密码会跨重启和普通 rebuild 保留。加密哈希主要负责首次创建账户；仍建议
随后使用 `sops secrets/nixos.yaml` 更新仓库中的恢复基线，不能长期把 `admin` 当作初始密码。

验证 Impermanence 时，在临时根目录和持久化 home 中分别创建标记：

```bash
sudo touch /etc/impermanence-root-test
touch ~/impermanence-home-test
sudo reboot
```

重启后，`/etc/impermanence-root-test` 应消失，`~/impermanence-home-test` 应仍然存在；
`/etc/machine-id`、SSH 主机密钥和 NetworkManager 连接也应保持不变。

## 9. 恢复配置仓库并整理

安装介质中的克隆位于临时文件系统，不会自动复制进新系统。联网后重新克隆：

```bash
git clone https://github.com/aoesun/nixos-config.git ~/nixos-config
```

确认新系统稳定后，检查并提交安装阶段产生的配置变化：

```bash
git status
git diff
```

重点检查：

- `disko-config.nix` 的设备路径是否应该进入仓库；
- 新生成的硬件模块是否只包含这台虚拟机的硬件信息；
- `hardware-configuration.nix` 不再包含重复的文件系统和 swap 声明；
- `hosts/nixos/default.nix` 继续导入 `disko-config.nix`；
- 没有临时密钥、密码或安装介质路径进入 Git。

如果只有经过检查的硬件配置发生变化，可以提交并推送：

```bash
git add hosts/nixos/hardware-configuration.nix
git commit -m "hardware: update configuration for the new VM"
git push origin main
```

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
