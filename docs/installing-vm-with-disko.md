# 使用 Disko 安装 VMware 虚拟机

本配置用于从 NixOS Minimal ISO 将 `nixosConfigurations.nixos` 安装到一块 64 GiB 的
VMware 虚拟磁盘。安装脚本会检查 UEFI、要求再次确认目标磁盘，再调用 Disko 创建 Btrfs
布局、准备两个配置仓库并安装完整系统。

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

连接后进入 root shell：

```bash
sudo -i
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

## 4. 初始化密钥（每套配置只执行一次）

第一次使用这套配置安装前，在可信系统中运行：

```bash
./scripts/bootstrap-secrets
```

脚本会依次要求设置 age 私钥备份口令和 `ryuk` 的登录密码，并生成可提交的
`secrets/age-key.txt.age`、`secrets/secrets.yaml` 以及含公开接收者的 `.sops.yaml`。
将 `.secrets/age-key.txt` 保存到 Bitwarden，验证备份后删除该明文文件，再提交并推送加密文件。
以后重装不再执行此步骤。

删除明文私钥前，可以在不显示密码哈希的情况下确认登录密码：

```bash
./scripts/verify-login-password
```

需要从 Bitwarden 或 Git 口令备份恢复 age 私钥时，运行交互式恢复脚本：

```bash
./scripts/restore-age-key
```

脚本会先用恢复出的私钥试解 `secrets/secrets.yaml`，验证成功后才将其安装到当前系统、
`/mnt` 安装目标、Git 忽略的 `secrets/key.txt` 或指定的绝对路径。sops-nix 的系统密钥
路径仍固定为 `/persist/var/lib/sops-nix/key.txt`。

## 5. 安装

脚本会从配置求值目标磁盘、显示 `lsblk` 信息，并要求输入完整设备路径后才会清盘：

```bash
./scripts/install-nixos
```

脚本会自动完成：

1. 清空并格式化 `/dev/sda`；
2. 创建并挂载 Btrfs 子卷；
3. 创建只读 `root-blank` 快照；
4. 提示输入 age 私钥备份口令，并将私钥直接解密到新系统的 `/persist`；
5. 克隆可直接编辑的 `dotfiles` 工作仓库；
6. 将本次实际使用的 NixOS 配置工作树复制到新系统；
7. 由 sops-nix 解密用户密码哈希并安装 NixOS；
8. 修正两个工作仓库的所有权并安装 systemd-boot。

看到 `Installation completed successfully.` 后重启：

```bash
reboot
```

断开安装 ISO，让虚拟机从硬盘启动。

## 6. 首次登录

使用以下账户登录：

```text
Username: ryuk
Password: bootstrap-secrets 中设置的密码
```

用户数据库会在每次激活时由 NixOS 声明式生成，密码哈希由 sops-nix 提供。两个工作仓库
已经位于 `~/nixos-config` 和 `~/dotfiles`，无需再次克隆。GitHub SSH 私钥也会由 sops-nix
安装到 `~/.ssh/id_ed25519`，因此公钥添加到 GitHub 账户后即可直接使用 `git pull` 和
`git push`。

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

- 如果 Disko 完成后 `nixos-install` 失败，不要立刻再次运行完整脚本。修正问题后，可在仍然
  挂载的 `/mnt` 上单独重试 `nixos-install`。
- 如果安装失败并决定从头重来，重新从 UEFI 模式的 ISO 启动并再次执行脚本即可。
- 脚本采用 `disko.devices.disk.system.device` 声明的设备。更换磁盘路径时必须先修改并检查
  `hosts/nixos/disko-config.nix`，不能只在命令行临时替换。
- `users.mutableUsers = false`，因此 `passwd` 的修改不会作为配置来源保留；需要更换登录密码时，
  应编辑 `secrets/secrets.yaml` 中的哈希并重新部署。
