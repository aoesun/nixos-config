# 配置文档

本目录记录 `nixos` 主机当前实际启用的 NixOS 与 Home Manager 配置。文档以仓库中的 Nix 文件为准；修改配置时，应在同一个 Git 提交中同步更新相关文档。

## 快速导航

- [架构与模块关系](architecture.md)：flake 输入、系统输出、模块加载顺序和版本约定。
- [系统与主机配置](system.md)：网络、用户、启动、文件系统、垃圾回收、SSH 和 VMware 客户机支持。
- [桌面与输入法](desktop-and-input.md)：KDE Plasma、桌面软件、字体、Fcitx5 和 Rime 自然码设置。
- [Home Manager 用户环境](home-manager.md)：用户级软件、Vim、Yazi、Zsh 和命令行体验。
- [日常维护与部署](operations.md)：检查、重建、更新、回滚和 Git 工作流。

## 配置文件索引

| 文件 | 作用 | 详细说明 |
| --- | --- | --- |
| `flake.nix` | 定义 nixpkgs、Home Manager 和 `nixos` 系统输出 | [架构](architecture.md) |
| `hosts/nixos/default.nix` | 汇总当前主机的系统模块 | [架构](architecture.md) |
| `hosts/nixos/hardware-configuration.nix` | 内核、磁盘、文件系统和交换文件 | [系统](system.md) |
| `modules/nixos/base.nix` | 主机名、网络、区域、用户和 Nix 基础设置 | [系统](system.md) |
| `modules/nixos/boot.nix` | systemd-boot 和 Nix Store 自动清理 | [系统](system.md) |
| `modules/nixos/desktop.nix` | Plasma、Fcitx5、Rime、字体和桌面软件 | [桌面与输入法](desktop-and-input.md) |
| `modules/nixos/home-manager.nix` | 将 Home Manager 集成到 NixOS | [Home Manager](home-manager.md) |
| `modules/nixos/ssh.nix` | OpenSSH 服务及登录策略 | [系统](system.md) |
| `modules/nixos/optional/vmware-guest.nix` | VMware 图形客户机集成 | [系统](system.md) |
| `home/ryuk/default.nix` | 用户配置入口和 Home Manager 版本 | [Home Manager](home-manager.md) |
| `home/ryuk/programs/tools.nix` | 常用命令行程序 | [Home Manager](home-manager.md) |
| `home/ryuk/programs/vim.nix` | Vim 编辑器设置 | [Home Manager](home-manager.md) |
| `home/ryuk/programs/yazi.nix` | Yazi 文件管理器及辅助工具 | [Home Manager](home-manager.md) |
| `home/ryuk/programs/zsh.nix` | Zsh、历史、提示符、补全和别名 | [Home Manager](home-manager.md) |

## 当前系统摘要

- 架构：`x86_64-linux`
- 主机名：`nixos`
- 时区：`Asia/Tokyo`
- 默认区域：`en_US.UTF-8`
- 桌面：KDE Plasma 6（Wayland）
- 输入法：Fcitx5，默认 Rime 自然码双拼
- 用户：`ryuk`
- 系统与 Home Manager 状态版本：`26.05`
- 虚拟化环境：启用 VMware 图形客户机支持

> 文档描述的是声明式配置，不包含 Bitwarden、GitHub、Codex 等程序在用户目录中自行保存的登录状态与运行时数据。
