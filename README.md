# NixOS Configuration

用于构建 `nixos` 主机及 `ryuk` 用户环境的声明式配置。

当前以 NixOS 为主要目标，并通过作为 NixOS 模块集成的 Home Manager 管理用户配置。

## 配置结构

```text
.
├── flake.nix                         # 输入、构建函数和 flake 输出
├── hosts/
│   └── nixos/                        # 当前主机入口与硬件配置
├── modules/
│   ├── core/                         # 每台主机都应具备的基础系统
│   ├── features/                     # 可选的单项系统功能
│   ├── profiles/                     # 多项 feature 的组合
│   └── integrations/                 # Home Manager 等外部模块集成
├── home/
│   ├── ryuk/                         # ryuk 的默认 Home Manager 配置
│   └── features/                     # 可按主机选择的用户功能
└── packages/                         # 独立导出的自定义软件包
```

模块的组合关系是：

```text
flake.nix
└── nixosConfigurations.nixos
    └── hosts/nixos
        ├── modules/core
        ├── modules/profiles/desktop.nix
        ├── modules/integrations/home-manager.nix
        │   └── home/ryuk
        │       └── home/features
        ├── modules/features/development/opencode.nix
        └── modules/features/virtualization/vmware-guest.nix
```

## 模块边界

- `core` 保存没有桌面环境也应存在的系统能力，例如网络、SSH、用户、Zsh 和基础工具。
- `features` 保存可由不同主机独立选择的功能，例如浏览器、桌面环境和虚拟化支持。
- `profiles` 只负责组合 feature；当前 `desktop` profile 组合 Plasma、字体、输入法、浏览器和 GUI 软件。
- `integrations` 负责把外部模块体系接入 NixOS，不承载具体用户偏好。
- `home/ryuk` 保存 ryuk 默认需要的用户配置。
- `home/features` 保存由主机决定是否启用的用户功能，例如 Codex 和 GoldenDict。
- `hosts` 是最终装配层，只表达一台机器选择了哪些模块以及它自己的硬件和主机属性。

## 当前配置

基础系统包括：

- NetworkManager、OpenSSH 和 systemd-boot
- 普通用户 `ryuk` 和 Zsh
- Git、LazyGit、Navi、Neovim、tmux、Yazi、Zoxide
- jq、tree、wget 和 Wayland 剪贴板工具
- 每周清理超过 14 天且不可达的 Nix Store 路径

桌面 profile 包括：

- KDE Plasma 6（Wayland）
- Fcitx5、Rime 自然码双拼和 Mozc
- Fira Code Nerd Font
- Chromium、Vimium 和 uBlock Origin Lite
- Bitwarden Desktop

Home Manager 管理：

- ryuk 的 Zsh 交互体验和 Spaceship 提示符
- GitHub SSH 客户端配置
- Fastfetch
- Navi 个人 cheats 的本地符号链接
- 当前主机选择的 Codex 和 GoldenDict

OpenCode 具有系统级开关，但当前设置为禁用。

## Flake 输出

当前提供两个主要输出：

```text
nixosConfigurations.nixos
packages.x86_64-linux.spotify-spiced
```

`spotify-spiced` 是独立软件包输出，不会因为执行 `nixos-rebuild` 而自动安装或升级。

## 检查与部署

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

`home/` 下的 Home Manager 模块可以作为未来跨发行版复用的基础，但当前 flake 尚未提供独立的 `homeConfigurations` 输出。其他发行版暂时不能直接通过本仓库执行 `home-manager switch --flake`。

真正需要在非 NixOS 系统部署时，可以增加独立 Home Manager 输出，并补充由 NixOS `core` 当前提供的用户工具。Den 等组织框架不会改变 NixOS 模块与 Home Manager 模块的作用域边界。

## 状态与敏感数据

配置仓库不管理以下运行时状态：

- SSH 私钥及其口令
- Codex、Bitwarden、GitHub 和 Spotify 的登录状态
- 浏览器个人资料
- Marketplace 手动安装的扩展
- Navi cheats 的实际内容

不要提交明文密码、Token、Cookie、私钥或应用认证文件。如需声明式管理密钥，应使用 `sops-nix` 或 `agenix` 等加密方案。
