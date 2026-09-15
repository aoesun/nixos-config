# NixOS Configuration

用于构建 `nixos` 主机及 `ryuk` 用户环境的声明式配置。

同时提供 NixOS 主机配置与可在其他 Linux 发行版独立激活的 Home Manager 用户环境。

## 配置结构

```text
.
├── flake.nix                         # 输入、构建函数和 flake 输出
├── hosts/
│   └── nixos/                        # 当前主机入口与硬件配置
├── modules/
│   ├── core/                         # 可跨主机复用的基础系统
│   ├── desktop/                      # Plasma、输入法和字体
│   ├── virtualization/               # 虚拟化平台专用能力
│   └── home-manager.nix              # Home Manager 的 NixOS 接入层
├── home/
│   ├── users/                        # 用户身份与兼容版本
│   ├── programs/                     # 具有实质配置的单项程序
│   └── profiles/                     # tools、gui 与完整组合
└── packages/                         # 独立导出的自定义软件包
```

模块的组合关系是：

```text
flake.nix
└── nixosConfigurations.nixos
    └── hosts/nixos
        ├── modules/core
        ├── modules/desktop
        ├── modules/home-manager.nix
        │   ├── home/users/ryuk.nix
        │   └── home/profiles/default.nix
        └── modules/virtualization/vmware-guest.nix

flake.nix
└── homeConfigurations.ryuk
    ├── home/users/ryuk.nix
    └── home/profiles/default.nix
```

## 模块边界

- `core` 只保存可跨当前和未来主机复用的系统基础，例如网络、SSH 服务、用户和登录 Shell。
- `desktop` 自身就是桌面组合入口，并将 Plasma、字体和输入法拆成有实质内容的模块。
- `virtualization` 保存由特定虚拟化平台选择的客户机能力。
- `home-manager.nix` 只负责把 Home Manager 接入 NixOS，不承载具体用户偏好。
- `home/programs` 只保存具有实质配置逻辑的个人程序。
- `home/profiles/tools.nix` 和 `gui.nix` 分别组合无桌面工具与个人 GUI 应用。
- `home/profiles/default.nix` 组合完整环境；`home/users` 只保存用户身份。
- `hosts` 是最终装配层，表达模块选择以及启动器、硬件和主机名等机器专属属性。

## 当前配置

基础系统包括：

- NetworkManager、OpenSSH 和 systemd-boot
- 普通用户 `ryuk` 和 Zsh
- 每周清理超过 14 天且不可达的 Nix Store 路径

NixOS 桌面 profile 包括：

- KDE Plasma 6（Wayland）
- Fcitx5、Rime 自然码双拼和 Mozc
- Fira Code Nerd Font

Home Manager 管理：

- Neovim、插件、Nix LSP 与来自 `~/dotfiles/nvim` 的 Lua 配置
- Git、LazyGit、Navi、tmux、Yazi、Zoxide、jq、tree 和 wget
- Zsh 交互体验和 Spaceship 提示符
- GitHub SSH 客户端配置
- Fastfetch
- Navi 个人 cheats 的本地符号链接
- Codex
- Chromium、Vimium、uBlock Origin Lite、Bitwarden 和 GoldenDict（仅完整 profile）
- 来自 `~/dotfiles/rime` 的 Rime 用户补丁（仅完整 profile；输入法框架仍由宿主管理）

## Flake 输出

当前提供以下主要输出：

```text
nixosConfigurations.nixos
homeConfigurations.ryuk
homeConfigurations.ryuk-tools
homeModules.default
homeModules.tools
homeModules.gui
packages.x86_64-linux.spotify-spiced
```

`spotify-spiced` 是独立软件包输出，不会因为执行 `nixos-rebuild` 而自动安装或升级。

## 检查与部署

仓库使用 `just` 为常用操作提供简短入口。查看所有 recipe：

```bash
just
```

常用流程可以简写为：

```bash
just check
just build
just diff
just test
just switch
```

`just` 只封装下方列出的 Nix 命令，不改变其行为；需要参数或排错时仍可直接运行原命令。

快速检查语法、模块和输出求值：

```bash
nix flake check --no-build
```

构建完整系统但不激活：

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

比较构建结果与当前系统：

```bash
nix store diff-closures /run/current-system ./result
```

临时激活进行测试，不设置为下次启动的默认系统：

```bash
sudo nixos-rebuild test --flake .#nixos
```

验证完成后正式切换：

```bash
sudo nixos-rebuild switch --flake .#nixos
```

输出名与当前主机名相同，因此在本机也可以简写为 `--flake .`。

## Spotify

构建自定义 Spotify：

```bash
nix build .#spotify-spiced
```

首次安装或升级通过 Nix profile 完成：

```bash
nix profile install .#spotify-spiced
nix profile upgrade spotify-spiced
```

具体 profile 名称以 `nix profile list` 的结果为准。通过 Spicetify Marketplace 手动安装的扩展属于用户运行时状态，不受本仓库声明式管理。

## 更新输入

```bash
nix flake update
nix flake check --no-build
```

更新后应检查 `flake.lock` 和系统闭包差异，再执行 `test` 或 `switch`。正常更新软件时不要修改 `system.stateVersion` 或 `home.stateVersion`。

## 增加主机或功能

新增主机时：

1. 创建 `hosts/<hostname>/default.nix` 和该机器自己的 `hardware-configuration.nix`。
2. 从 `core`、`profiles` 和 `features` 中选择需要的模块。
3. 在 `flake.nix` 中增加对应的 `nixosConfigurations.<hostname>` 输出。
4. 不要在不同机器间复制硬件配置。

新增配置时，优先根据作用域选择位置：

- 系统服务和全局默认值放入 NixOS 模块。
- 个人 Shell、编辑器和应用偏好放入 Home Manager。
- 可选能力独立为 feature，再由主机或 profile 组合。

## 非 NixOS 复用

在任意 x86_64 Linux 发行版安装 Nix、启用 flakes，并将 dotfiles 克隆到固定位置：

```bash
git clone https://github.com/aoesun/dotfiles ~/dotfiles
git clone https://github.com/aoesun/nixos-config ~/nixos-config
cd ~/nixos-config
nix run home-manager/release-26.05 -- switch --flake .#ryuk
```

无桌面环境使用只包含命令行工具的输出：

```bash
nix run home-manager/release-26.05 -- switch --flake .#ryuk-tools
```

该输出不会管理系统用户、登录 Shell、SSH 服务或桌面环境。宿主发行版仍需确保用户
`ryuk` 的 home 为 `/home/ryuk`，并将 Zsh 设置为登录 Shell。详细说明见
[Home Manager 用户环境](docs/home-manager.md)。

## 状态与敏感数据

配置仓库不管理以下运行时状态：

- SSH 私钥及其口令
- Codex、Bitwarden、GitHub 和 Spotify 的登录状态
- 浏览器个人资料
- Marketplace 手动安装的扩展
- Navi cheats 的实际内容
- Neovim Lua 配置
- Rime 静态用户补丁

不要提交明文密码、Token、Cookie、私钥或应用认证文件。如需声明式管理密钥，应使用 `sops-nix` 或 `agenix` 等加密方案。
