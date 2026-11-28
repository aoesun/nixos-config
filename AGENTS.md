# AGENTS.md

只记录读代码看不出来的东西：结构与边界、约定、踩过的坑、未决事项。实现细节以 Nix 源码为准；`docs/` 部分过时，冲突时以代码为准。

## 环境

- 单主机 flake：`nixosConfigurations.nixos`（hostname 同名，`--flake .` 即可），VMware 客户机，用户 `ryuk`，登录 Shell 为 zsh（保持 emacs keymap，不切 vi 模式；长命令用 `Ctrl+X Ctrl+E` 进 nvim 编辑），终端为 Ghostty。
- 跟随 `nixos-unstable` 和 Home Manager `master`；`stateVersion` 仍是 `26.05`，不要改。
- 桌面：只有 niri + Noctalia（KDE/Plasma 已彻底移除，不再保留桌面切换）。登录界面是 greetd + Noctalia Greeter，本机用软件渲染变通（见“踩过的坑”）。**只用 Wayland，不要提 X11 方案。**
- `EDITOR` / `VISUAL` 为 `nvim`；GUI 编辑器是 Zed（命令 `zeditor`）。
- 两个仓库：`~/nixos-config`（Nix）和 `~/dotfiles`（频繁编辑的原生配置，经 Home Manager 链接）。

## 目录结构与模块边界

```text
flake.nix                # inputs、overlay、mkSystem / mkHome、全部输出
hosts/<host>/            # 装配层：模块选择 + 机器专属设置（硬件、disko、boot、zram、显示管理器变通）
modules/core/            # 跨主机复用的系统基础（用户、网络、nix、ssh、sops、impermanence 清单）
modules/desktop/         # 桌面：niri.nix、greeter.nix（登录界面）、input-method.nix；字体、LocalSend
modules/services/        # 可选系统服务（mihomo、samba），由 host 逐个导入
modules/virtualization/  # 平台专用模块，由 host 显式导入
modules/home-manager.nix # 只负责把 HM 接入 NixOS，不放用户偏好
home/users/              # 只放用户身份与 stateVersion
home/modules/            # HM 辅助模块（dotfiles.nix：dotfiles.path 与链接函数）
home/programs/<名字>.nix # 有实质配置的单个程序，由 profiles/gui.nix 或 tools.nix 导入
home/profiles/           # 组合：tools（无 GUI）、gui、niri、default = tools + gui
packages/                # 只放有定制的自有包（目前仅 spotify-spiced），经 overlay 以 pkgs.<名字> 引用
software.just            # `just software <name>`：按需装进 nix profile 的软件与 coding agents
scripts/                 # 交互式安装 / 密钥脚本，需用户在终端运行
secrets/                 # sops 密文与加密的 age 备份；.secrets/ 为明文（gitignored）
```

- 机器专属的东西只放 `hosts/<host>`，不进 `core`。
- `home/` 要能脱离 NixOS 使用（`homeConfigurations.ryuk` / `ryuk-tools`），不能依赖 NixOS 选项。
- 只定义一次的值：用户名是 `flake.nix` 的 `username`（经 specialArgs 传入，路径从 `config.users.users.${username}.home` 推导）；dotfiles 路径是 HM 选项 `dotfiles.path`；unfree 白名单是 `nixpkgsConfig`；`overlay`（上游 flake 包 + `packages/` 自有包）同时用于 standalone `pkgs` 和 `mkSystem`。四者都是 NixOS 与 standalone 共用，改的时候两边一起生效。
- specialArgs：`nixpkgsInput`、`noctalia`、`rimeIce`、`username`（名字与 input 名不同）。
- `flake.nix` 的 `let` 里改已有定义（如 `pkgs`）时要替换原定义，不能新增同名项，否则报 `attribute already defined`。

## dotfiles 链接机制

- 用 `config.lib.dotfiles.link "<相对路径>"` 链接；用到它的文件要导入 `home/modules/dotfiles.nix`（重复导入自动去重）。
- 只改已链接文件 → 保存即生效，不用 rebuild。新增需要部署的文件 → 在 Nix 中加链接再 rebuild（`nvim/lua/`、`navi/` 是整目录链接，例外）。
- 新增的被链接文件必须**加入 dotfiles 的 git**，否则重新克隆后链接断掉（mpv 曾因此出过问题）。
- HM 里一旦写了某程序的 `settings` / `keymap` 等选项，就会生成同名文件，与 dotfiles 链接冲突——要么整块迁到 dotfiles，要么整块留在 Nix。
- `~/.config/mimeapps.list` 保持可变，不进 dotfiles（GLib 写入会替换符号链接），也不用 `xdg.mimeApps`。
- Neovim 插件、LSP、treesitter 语法由 Nix 安装：Lua 里用新插件前先改 `home/programs/neovim.nix`。
- 改完 niri 配置运行 `niri validate`；快捷键要带 `hotkey-overlay-title` 才会出现在提示里（已开 `hide-not-bound`）。

## 系统状态、服务与密钥

- Impermanence 由 host 显式开启（`environment.persistence."/persist".enable = true`），回滚服务在 `modules/core/impermanence.nix`，按 Btrfs label `nixos` 找盘；只有 Disko 布局提供 `root-blank` 快照的主机才能开启。`/` 每次启动重置，需要跨重启的系统状态要加进持久化清单；`/home`、`/nix` 本身持久。
- 新增服务时检查它在 `/var/lib` 下的状态。通用的放进 core 的清单；只属于某个服务的，在该服务模块里追加 `environment.persistence."/persist".directories`（参考 `samba.nix`）。`DynamicUser` 服务的状态在 `/var/lib/private` 里，已整体持久化。
- 新加的持久化目录在激活时会被 `/persist` 里的空目录覆盖，现有数据会被隐藏。要保留现有状态，先 `sudo cp -a` 到 `/persist`，再用 `just boot` 加重启生效，不要用 `just test`。
- `users.mutableUsers = false`：改登录密码走 sops，`passwd` 无效。
- 新增 secret：`sops secrets/secrets.yaml` → 在 `modules/core/default.nix` 的 `sops.secrets` 声明 → 扩展 `scripts/restore-sops-secret` 顶部的并行数组。
- 不读、不打印、不提交 `.secrets/` 下的私钥，也不解密输出 `secrets/`。（用户明确指定的非密钥文件除外。）
- mihomo：
  - `configFile` 必须是**字符串**路径（Nix 路径字面量会被复制进 store）。配置文件在仓库外，含订阅和 secret，不进 git。
  - 无头运行，不接管系统流量，也没有 TUN；程序需要自己设置代理 `socks5h://127.0.0.1:7890`。面板在 `http://127.0.0.1:9090/ui`。规则模式下 `MATCH,PROXY` 已经让流量全走代理，不要切“全局”。
  - 开机不自启。不要把免费节点放进日常配置。
  - 换节点后用 `curl -x socks5h://127.0.0.1:7890 https://ipinfo.io` 核对出口。
- 端口占用：9090 mihomo、9091 Fragments（transmission）。新增服务前先查冲突。

## 构建与校验

```bash
just fmt                # nixfmt-tree，跳过 hardware-configuration.nix
just check              # nix flake check --no-build，每次修改后的最低验证
just check-all          # 构建两个 HM profile + nixfmt 检查
just build / just diff  # 构建系统 / 并与当前系统比较闭包
just home [ryuk-tools]  # 构建 standalone HM profile
```

- 标准流程：`just fmt` → `just check` → `just test`（临时激活，重启回旧世代）→ 满意再 `just switch`。`test` / `switch` / `boot` / `clean*` 交给用户执行。
- 新建的 `.nix` 文件先 `git add`，否则 flake 看不到。
- 纯重构用 `nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath` 前后对比，drvPath 不变即行为不变。
- 核实选项是否存在：`nix eval .#nixosConfigurations.nixos.options.<路径>.description`；包名先 `nix search` 确认。

## 协作约定

- **默认直接写进 Nix 配置**。只有用户说“先试用”时才用 `nix profile add`；长期使用的应用要进 `home.packages` 或系统配置（`nix profile` 里的应用不会登记进 `mimeinfo.cache`）。
- 系统级 → `modules/`；个人程序 → `home/`；机器专属 → `hosts/<host>`；频繁编辑的原生配置 → dotfiles。
- 实验性改动用临时分支（`git switch -c try-xxx`），不满意就删掉。
- 提交顺序：**先 dotfiles，再 nixos-config**，因为后者的链接指向前者的文件。
- Commit message：英文 Conventional Commits，`type(scope): 祈使句`，主题行不超过 72 字符，正文写动机。不加任何 AI 署名。
- 用户在 lazygit 里操作 git：给出要暂存的范围（按文件或按行），并附命令行等价写法。不擅自 commit / push，除非用户明确要求；不丢弃用户未提交的改动。
- 不修改 `stateVersion`；不手改 `hardware-configuration.nix`；新增主机时不复用其他机器的硬件配置，也不导入 VMware 模块。
- Nix 注释用英文、写“为什么”；`docs/` 用中文，只写理由和流程，不复述配置值。修改结构、流程或约定时同步 `docs/`。

## 回答风格

- 回复用中文，技术术语保留英文；优先给 NixOS 声明式写法。
- 不确定就明确说“我没有核实”，附上验证命令，不凭记忆下结论。包名、选项名、版本差异尤其要先查。
- 修改已有定义时写明替换哪一段，并给出替换后的完整上下文；涉及 dotfiles 的改动要说明是否需要 rebuild。
- 改动后给出验证方法，并说明失败时该看什么输出。
- 给用户粘贴的 zsh 命令：URL 里的 `?` 要加引号，命令中间不要夹 `#` 注释。

## 踩过的坑

- **xdg-open**：niri 下它找不到默认应用时会退到浏览器。已用 `xdg.portal.xdgOpenUsePortal = true` 改成走 OpenURI portal。
- **portal 的 Open With 选择器**：
  - 候选只来自 `mimeinfo.cache`，没有“显示全部应用”，也没有“总是使用”开关。但同一类型连续 3 次选同一个应用后，portal 会记住并不再弹出（源码 `open-uri.c` 的 `DEFAULT_THRESHOLD`）。记录在 `~/.local/share/flatpak/db/desktop-used-apps`，不在 `mimeapps.list`，`xdg-mime query default` 查不到。
  - `Terminal=true` 的应用（如 `nvim.desktop`）选了也打不开，所以不要把终端程序设为默认应用。
  - 改用 `AppChooser = "gtk"` 试过，没有改善，已撤销。
- **yazi**：内置的 `open` 和 `play` 都调用 `xdg-open`，未关联的类型会弹 portal 选择器。音视频不再单独配 mpv opener：选 3 次 mpv 后 portal 就记住了，`mpv.desktop` 自带 `--player-operation-mode=pseudo-gui`。
- **会话环境变量**：要重新登录才会进入新会话，且常驻进程保留启动时的环境。Luvus server 不随注销退出，需要在新开的 Ghostty 里运行 `luvus server restart`（会结束所有 pane）。
- **核实环境变量**：`grep -r /etc` 会跳过符号链接，直接看 `/etc/set-environment`，或者用 `tr '\0' '\n' < /proc/$(pgrep -x niri)/environ`。
- **xdg-mime**：`xdg-mime query default` 的参数是 MIME 类型，不是文件名。系统里没有 `gio`，需要时用 `nix shell nixpkgs#glib -c gio mime <类型>`。
- **登录界面（Noctalia Greeter）**：
  - 在 vmwgfx 上，greeter 自带的 wlroots 合成器无法关闭 dmabuf 句柄（`drmCloseBufferHandle failed: Invalid argument`），随后 greeter 因 Wayland 协议错误退出，greetd 连续重启 5 次后放弃，结果是黑屏。`WLR_DRM_NO_MODIFIERS=1` 无效；`WLR_RENDERER=pixman` 加 `LIBGL_ALWAYS_SOFTWARE=1` 有效。这个变通写在 `hosts/nixos`，实体机不需要。
  - greetd 以空环境启动 greeter，环境变量要在 `default_session.command` 里用 `env` 传。排查时设 `NOCTALIA_GREETER_LOG=stderr`、`WLR_LOG=info`，日志看 `journalctl -b -u greetd` 和 `grep noctalia-greeter`。
  - 外观由 Noctalia 同步（设置 → Security → Noctalia Greeter，可开 Auto-Sync），同步结果写到 `/var/lib/noctalia-greeter`（已持久化）。Nix 的 `settings` 会生成 `greeter.toml`，其中的外观项优先级高于同步结果，所以外观相关的键不要写进 `settings`。
  - 换显示管理器不要用 `just test`（会结束当前会话），改用 `just boot` 加重启；失败时按 `Ctrl+Alt+F2` 或在启动菜单选上一个世代。
- **字体**：没有一款字体能同时把中日英都显示对，因为中日共用汉字码位但字形不同。现在的分工是：monospace 用 Maple Mono NF CN（汉字是中文字形）；界面和正文用 Noto Sans CJK SC，Noctalia 也用它；标了 `lang=ja` 的内容由 `fontconfig.localConf` 改用 Noto Sans CJK JP。终端分辨不出语言，日文仍会显示中文字形。验证用 `fc-match "sans-serif:lang=ja"`。
- **tmux-which-key**（tmux 目前已从配置移除，以后再用时参考）：在 Nix 下跑不起来。原因是每次启动都会重新生成只读的 `init.tmux`，或者尝试往 store 里写文件。备选方案是用 tmux 自带的 `display-menu` 写菜单，放进 dotfiles。
- **Luvus 更新**：不要用 `luvus update`，改用 `just update-input luvus`。保留 `inputs.nixpkgs.follows`（用户已决定）：上游没有二进制缓存，反正都要本地编译，跟随系统 nixpkgs 可以共用 Rust 工具链；代价是每次更新 nixpkgs 后会重新编译一次。

## 未决与待办

- **还在 `nix profile` 里的长期依赖**：warpd（niri 键位）、Helix（`hx`，yazi opener）、qBittorrent（yazi opener）。按约定应固化进配置。
- **统一主题（Stylix）**：以后集中找时间做，不要零散引入。
  - 它主要统一配色。即使只管字体也必须设置 `base16Scheme` 或 `image`；`stylix.fonts` 不能按语言选字体，日文规则仍要自己写。
  - 默认 `autoEnable = true`，会给已安装应用写 HM 配置，可能和 dotfiles 链接冲突，也会和 Noctalia 自己的配色重复。引入时设 `stylix.autoEnable = false`，逐个开启 target，每开一个都核对它生成哪些文件。
  - 跟随 master 分支（对应 unstable）。没有 niri 的 target。
- **nirius**：scratchpad 已启用（unstable 中为 0.10，已有 `list-scratchpad`）。待做：写 scratchpad 选择器脚本（`list-scratchpad` 的输出格式需要先实测）。工作区切换已改用 niri 原生动作，原来的 `focus-workspace-cycle` 脚本已删除。
- **unfree 白名单**：固化 `claude-code` 之前，要先把它加进 `nixpkgsConfig`。
- **`docs/` 过时**：没有覆盖 unstable 渠道、`modules/services/`、luvus、mpv、yazi 等。
- **`run-vmblock-fuse.mount` 启动失败**：属于 open-vm-tools 的上游问题（正在从 fuse 迁移到 fuse3），等上游发布修复，不在本地处理。影响的是 VMware 宿主机和虚拟机之间拖放文件。
- **以后可能做的**：音乐播放器（mpv 不支持滚动歌词）、Satty 标注、Snipaste 类截图工具、`xdg.mime.defaultApplications`。

## 维护本文件

修改目录结构或模块划分、改动构建 / 校验命令、做出决策、踩到新坑或与用户达成新约定时，在同一次改动中更新本文件；待办完成后删除对应条目。保持精炼，只写读代码看不出来的东西。

本文件和 `CLAUDE.md` 随仓库提交，换机器时随 clone 一起到位；更新本文件时与相关代码放在同一次提交。仓库是 public，不要写入密钥、订阅链接等敏感信息。
