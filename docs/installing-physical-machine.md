# 在实体机上安装

本文说明如何在不影响现有 VMware 主机的情况下，将同一仓库用于新的 x86_64
实体机。示例输出名和主机名使用 `workstation`，实际使用时可以替换。

## 设计原则

- 所有主机使用同一个 Git `main` 分支，不为每台机器维护长期分支。
- 公共功能继续放在 `modules/nixos/`。
- 每台机器在 `hosts/<主机名>/` 中保存入口和硬件配置。
- 每台机器在 `flake.nix` 中有独立的 `nixosConfigurations` 输出。
- VMware 模块只由虚拟机入口导入。
- 实体机必须生成自己的硬件配置，不能复制虚拟机的磁盘 UUID 和驱动列表。

## 目标结构

```text
hosts/
├── nixos/
│   ├── default.nix
│   └── hardware-configuration.nix
└── workstation/
    ├── default.nix
    └── hardware-configuration.nix
```

现有 `hosts/nixos/` 继续代表 VMware 主机。实体机新增
`hosts/workstation/`，两台机器共享其他系统模块和 `ryuk` 的 Home Manager 配置。

## 安装前准备

1. 备份实体机的重要数据。
2. 确认安装目标仍是 `x86_64-linux`；其他架构需要扩展 `mkSystem` 的参数。
3. 规划磁盘、EFI 分区、Btrfs 子卷和交换空间。
4. 准备访问私有 GitHub 仓库的方式，例如临时 SSH 密钥、只读 deploy key，或从
   受信任介质复制仓库。
5. 不要把长期私钥或 passphrase 写入仓库、安装脚本或 shell 历史。

本文不提供可直接复制的分区命令，因为设备名和是否保留原系统因机器而异。确认
挂载结果正确后再运行安装命令。

## 从安装介质生成硬件配置

从 NixOS 安装介质启动，完成分区后把目标系统挂载到 `/mnt`。至少应正确挂载根
文件系统和 EFI 启动分区；如果使用独立 `/home`、`/nix` 或 Btrfs 子卷，也要按
计划挂载。

先让 NixOS 根据 `/mnt` 生成一份临时系统配置：

```bash
sudo nixos-generate-config --root /mnt
```

该命令检测实体机硬件和当前挂载布局，并写入
`/mnt/etc/nixos/hardware-configuration.nix`。检查其中的文件系统、UUID、交换设备
和启动模块是否符合实际规划。

将仓库放在安装环境可访问的位置后，创建实体机目录，并把生成的硬件文件复制到
仓库：

```bash
mkdir -p ~/nixos-config/hosts/workstation
cp /mnt/etc/nixos/hardware-configuration.nix \
  ~/nixos-config/hosts/workstation/hardware-configuration.nix
```

硬件配置由生成器维护；主机名、公共模块和额外功能放入下一节的主机入口。

## 创建实体机入口

创建 `hosts/workstation/default.nix`：

```nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/home-manager.nix
  ];

  networking.hostName = "workstation";

  # Use the NixOS release of this machine's initial installation.
  system.stateVersion = "26.05";
}
```

不要导入 `optional/vmware-guest.nix`。如果实体机需要专用显卡、蓝牙、电源管理、
固件或 CPU 微码设置，可以新增实体机专用模块，或直接在这个入口中声明后再逐步
拆分。

`system.stateVersion` 应记录这台实体机首次安装时采用的 NixOS 兼容版本。以后更新
nixpkgs 时不要顺手修改它。如果未来从比 26.05 更新的安装介质首次安装，应使用
该版本建议的初始值，而不是机械复制示例。

## 添加 flake 输出

在 `flake.nix` 的输出集中加入：

```nix
nixosConfigurations.workstation = mkSystem ./hosts/workstation;
```

保留现有虚拟机输出：

```nix
nixosConfigurations.nixos = mkSystem ./hosts/nixos;
```

此后两个输出分别是：

- `nixos`：现有 VMware 主机，包含 VMware Guest 支持。
- `workstation`：实体机，不包含 VMware Guest 支持。

## 安装前验证

新文件必须先加入 Git 暂存区，否则 flake 对未跟踪文件求值时可能看不到它们：

```bash
git add hosts/workstation flake.nix
```

检查全部输出：

```bash
nix flake check --no-build
```

也可以显式构建实体机系统闭包，以便在正式安装前发现构建问题：

```bash
nix build .#nixosConfigurations.workstation.config.system.build.toplevel
```

该构建会产生被 `.gitignore` 忽略的 `result` 链接，不会直接安装系统。

## 执行安装

确认仓库路径、输出名和 `/mnt` 挂载无误后执行：

```bash
sudo nixos-install --flake ~/nixos-config#workstation
```

安装完成并设置用户密码后重启。首次进入系统时，确认网络、图形、声音、输入法、
睡眠唤醒和 SSH 均正常，再提交实体机硬件配置和主机入口。

## 已安装 NixOS 的实体机

如果实体机已经安装并正在运行 NixOS，不需要执行 `nixos-install`。在该机器上克隆
仓库，生成或复制正确的硬件配置，新增 `workstation` 输出并检查后执行：

```bash
sudo nixos-rebuild test --flake ~/nixos-config#workstation
```

`test` 会临时激活配置但不设为下次启动默认项。验证网络和桌面后再执行：

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#workstation
```

## 安装后的核对清单

- `hostnamectl` 显示实体机主机名而不是 `nixos`。
- `findmnt` 中所有挂载点和 Btrfs 子卷正确。
- systemd-boot 能正常启动并显示合理的回滚条目。
- NetworkManager、Plasma Wayland、Fcitx5 和 Rime 正常。
- 实体机没有启动 VMware Guest 服务。
- `ryuk` 可以使用 sudo，但 SSH 仍禁止 root 登录。
- GitHub SSH 私钥只存在于实体机用户目录，未进入 Git 仓库或 Nix Store。
- `sudo nixos-rebuild switch --flake ~/nixos-config#workstation` 可以重复成功执行。
