# NixOS Configuration

`nixos` 主机（VMware 客户机）与用户 `ryuk` 的声明式配置。Home Manager 用户环境也可以在其他
x86_64 Linux 发行版上单独激活。

- 桌面：Niri + Noctalia shell，SDDM（SilentSDDM）；可通过 `desktop.session` 切换 Plasma 6
- 输入法：Fcitx5 + Rime（雾凇拼音数据，自然码双拼）+ Mozc
- 存储：Disko 声明的 Btrfs 子卷；impermanence 在每次启动时重置 `/`
- 密钥：sops-nix + age
- 可编辑的原生配置位于独立仓库 [`aoesun/dotfiles`](https://github.com/aoesun/dotfiles)，
  通过 Store 外符号链接接入

## 结构

```text
flake.nix          输入、mkSystem / mkHome、全部输出
hosts/nixos/       当前主机的装配层与 Disko 布局
modules/           core、desktop、virtualization、Home Manager 接入层
home/              users、programs、profiles、HM 辅助模块
packages/          按需安装的独立软件包
scripts/           安装与密钥恢复脚本
secrets/           sops 密文与加密的 age 备份
docs/              设计理由与操作流程
```

## Flake 输出

```text
nixosConfigurations.nixos
homeConfigurations.{ryuk, ryuk-tools}
homeModules.{default, gui, niri, tools}
packages.x86_64-linux.{goldendict-ng, spotify-spiced}
formatter / checks
```

## 常用命令

```bash
just              # 列出全部 recipe
just check        # 求值检查
just fmt          # 格式化
just diff         # 构建并与当前系统比较
just test         # 临时激活
just switch       # 激活并设为默认
just software list
```

## 文档

- [架构与设计理由](docs/architecture.md)
- [日常维护](docs/operations.md)
- [密钥管理](docs/secrets.md)
- [使用 Disko 安装 VMware 虚拟机](docs/installing-vm-with-disko.md)
- [在实体机上安装](docs/installing-physical-machine.md)
