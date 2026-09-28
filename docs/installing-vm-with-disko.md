# 使用 Disko 安装 VMware 虚拟机

本配置用于从 NixOS Minimal ISO 将 `nixosConfigurations.nixos` 安装到一块 64 GiB 的
VMware 虚拟磁盘。Disko 会清空 `/dev/sda`，创建 Btrfs 子卷、Impermanence 空白根快照和
swapfile，然后由 `disko-install` 直接安装完整系统。

> **警告：** 最后的安装命令会不可恢复地清除 `/dev/sda`。执行前必须确认它确实是目标盘。

## 磁盘布局

当前 Disko 配置会创建以下布局：

```text
/dev/sda (64 GiB, GPT)
├── ESP       1 GiB, FAT32                         -> /boot
└── system    剩余空间, Btrfs, label=nixos
    ├── root                                          -> /
    ├── home                                          -> /home
    ├── nix                                           -> /nix
    ├── persist                                       -> /persist
    ├── swap     8 GiB swapfile                       -> /.swapvol
    └── root-blank  root 的只读空白快照                 不挂载
```

所有 Btrfs 子卷共享 `system` 分区的可用空间，并没有预先划分固定容量。`root` 是会被
Impermanence 重置的系统根目录；`home`、`nix`、`persist` 和 `swap` 会长期保留。

每次启动时，initrd 会删除可写的 `root` 子卷，再从只读 `root-blank` 创建新的根子卷。
需要跨重启保留的系统状态通过 `/persist` 管理，而整个 `/home` 当前作为独立子卷持久化。

## 安装前

建议的虚拟机配置：

```text
Firmware: UEFI
Disk:     64 GiB
Memory:   8 GiB
CPU:      1 socket, 4 cores
ISO:      NixOS Minimal ISO
```

## 1. 进入安装环境

从 Minimal ISO 启动。如果通过 SSH 安装，先在虚拟机控制台执行：

```bash
sudo passwd nixos
sudo systemctl start sshd
ip -br address
```

连接后进入 root shell，并临时启用 Flakes：

```bash
sudo -i
export NIX_CONFIG='experimental-features = nix-command flakes'
```

如果 SSH 提示 `xterm-ghostty: unknown terminal type`，执行：

```bash
export TERM=xterm-256color
```

## 2. 克隆配置

```bash
git clone https://github.com/aoesun/nixos-config.git /home/nixos/nixos-config
cd /home/nixos/nixos-config
```

## 3. 确认磁盘并更新硬件配置

```bash
lsblk -e7
```

确认 `/dev/sda` 是约 64 GiB 的 VMware 虚拟磁盘；`sr0` 是安装 ISO，不能选错。

根据当前虚拟机重新生成不含文件系统定义的硬件配置：

```bash
mkdir -p /tmp/nixos-hardware
nixos-generate-config --no-filesystems --root /tmp/nixos-hardware
cp /tmp/nixos-hardware/etc/nixos/hardware-configuration.nix \
  hosts/nixos/hardware-configuration.nix
```

`hardware-configuration.nix` 已被 Git 追踪，所以无需 `git add` 就会参与本地 Flake 构建。
Disko 单独负责文件系统和 swap 定义。

## 4. 安装

再次确认目标磁盘后执行：

```bash
nix run github:nix-community/disko/latest#disko-install -- \
  --mode format \
  --write-efi-boot-entries \
  --flake .#nixos \
  --disk system /dev/sda
```

这条命令会自动完成：

1. 清空并格式化 `/dev/sda`；
2. 创建并挂载 Btrfs 子卷；
3. 创建只读 `root-blank` 快照；
4. 构建并安装 NixOS；
5. 安装 systemd-boot 并写入 EFI 启动项。

看到 `disko-install succeeded` 后重启：

```bash
reboot
```

断开安装 ISO，让虚拟机从硬盘启动。

## 5. 首次登录

使用以下账户登录：

```text
Username: ryuk
Password: admin
```

立即修改临时密码：

```bash
passwd
```

`/etc/shadow` 已由 Impermanence 持久化，因此新密码会跨重启保留。随后重新克隆工作仓库：

```bash
git clone https://github.com/aoesun/nixos-config.git ~/nixos-config
```

## 简单验证

```bash
findmnt /
findmnt /home
findmnt /nix
findmnt /persist
swapon --show
zramctl
sudo btrfs subvolume list -r / | grep 'path root-blank$'
```

若这些命令符合预期，安装即完成。可以用下面的方法确认临时根目录会回滚，而 home 会保留：

```bash
sudo touch /etc/impermanence-root-test
touch ~/impermanence-home-test
sudo reboot
```

重启后，`/etc/impermanence-root-test` 应消失，`~/impermanence-home-test` 应仍然存在。

## 注意事项

- 如果安装失败并决定从头重来，重新从 ISO 启动并再次执行安装命令即可；`format` 模式会
  清除之前的失败安装。
- 如果只是修复已有系统，应使用 `disko-install --mode mount`，不要使用 `format`。
- 当前磁盘名 `system` 对应 `disko.devices.disk.system`，`--disk system /dev/sda` 会覆盖
  配置中的默认设备路径。
- 初始密码 `admin` 只用于首次登录。系统安装完成后必须立即运行 `passwd` 修改密码。
