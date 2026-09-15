# Home Manager 用户环境

## 结构

Home Manager 配置分成三层：

```text
home/
├── users/ryuk.nix          # 用户名、home 路径、stateVersion
├── programs/               # 具有实质配置逻辑的单项程序
└── profiles/
    ├── tools.nix           # 无桌面环境也适用
    ├── gui.nix             # 与 KDE、GNOME、Niri 无关的 GUI 应用
    └── default.nix         # tools + gui
```

只有一行启用配置的软件直接写在 profile 中，不为“可选性”创建空壳模块。需要停用时，
从 profile 的程序或软件包列表中移除即可。程序出现独立配置、资源文件或复杂依赖后，
再提取到 `home/programs/`。

## 输出与激活

完整桌面用户环境：

```bash
nix run home-manager/release-26.05 -- switch --flake .#ryuk
```

无 GUI 的服务器、容器或发行版环境：

```bash
nix run home-manager/release-26.05 -- switch --flake .#ryuk-tools
```

当前 NixOS 主机通过 `modules/home-manager.nix` 组合
`home/users/ryuk.nix` 与 `home/profiles/default.nix`。两个 standalone 输出复用相同
模块，不维护第二套用户偏好。

Home Manager 不负责在其他发行版安装完整桌面环境。宿主应先提供 KDE、GNOME、
Niri 或其他可用图形会话；GUI profile 只安装 Chromium、Bitwarden、GoldenDict 等
桌面无关的个人应用。

standalone Home Manager 也不创建系统用户或修改 `/etc/shells`。宿主应已有 `ryuk`
用户和 `/home/ryuk`，并自行将 Zsh 注册为登录 Shell。

## Tools profile

`tools.nix` 直接启用或安装：

- Codex、Fastfetch、Git、LazyGit、tmux；
- jq、tree、wget；
- 并导入 Zsh、SSH、Navi、Neovim、Yazi 的实质配置模块。

Yazi 和 Zoxide 的 Zsh 集成由 Home Manager生成。Yazi 的 `y` wrapper 会在退出后将
Shell 切换到最终目录。Wayland 剪贴板只由 GUI profile 加入，因此 `ryuk-tools`
不会携带图形环境依赖。

## GUI profile

`gui.nix` 提供：

- Chromium，以及 Vimium 和 uBlock Origin Lite；
- Bitwarden Desktop；
- GoldenDict-ng；
- Yazi 的 `wl-clipboard` 支持；
- 从 `~/dotfiles/rime` 链接到 Fcitx5 Rime 用户目录的静态补丁。

这些应用不要求特定桌面实现，但运行时需要宿主已有图形会话。浏览器资料、Cookie、
Bitwarden 登录状态和其他运行数据不进入 Git。

Rime 前端、rime-ice 基础数据、桌面会话集成和重新部署由宿主负责，因此这部分链接
只有在宿主已经配置好 Rime 时才会生效。Rime 的 `build/`、用户词库和同步状态不由
Home Manager 管理。

## Neovim 与 dotfiles

职责按内容类型拆分：

- `home/programs/neovim.nix` 管理 Neovim、插件、Treesitter grammars、`nixd` 和 `nixfmt`；
- `~/dotfiles/nvim` 管理原生 Lua 配置；
- 仓库根目录 `.nvim.lua` 只补充本仓库特有的 nixd flake option 表达式。

Home Manager 生成最小 `init.lua` 来调用 `~/dotfiles/nvim/init.lua`，并实时链接其
`lua/` 子目录。Lua 保存后无需重建；版本控制和回滚由 dotfiles 仓库负责。新机器
激活前必须先克隆：

```bash
git clone https://github.com/aoesun/dotfiles ~/dotfiles
```

## 状态和密钥

以下内容不进入配置仓库：

- SSH 私钥与 passphrase；
- Codex、GitHub 等认证信息；
- 浏览器和桌面应用资料；
- `~/dotfiles` 的未提交状态。

NixOS 集成设置 `backupFileExtension = "hm-backup"`。standalone 首次激活时若目标
路径已有普通文件，应先检查并迁移，以免与 Home Manager 管理的链接冲突。
