# 架构与设计理由

本文只解释“为什么这样组织”。具体启用了哪些软件、选项取什么值，以 Nix 源码为准。

## 两个仓库

| 仓库 | 职责 |
| --- | --- |
| `~/nixos-config` | 安装程序与依赖、系统服务、用户环境的组合方式 |
| `~/dotfiles` | 频繁编辑的原生配置（Neovim Lua、niri、Noctalia、Ghostty、Rime 补丁、navi cheats）和壁纸 |

dotfiles 由 Home Manager 通过 Store 外符号链接接入（`home/modules/dotfiles.nix` 中的
`config.lib.dotfiles.link`）。保存后立即生效，不必为改一个键位创建新世代；版本控制和
回滚交给 dotfiles 自己的 Git 历史。代价是这些文件不在 Nix 闭包里，新机器激活前必须先
克隆 `~/dotfiles`（`scripts/install-nixos` 会自动完成）。

## 分层

```text
flake.nix                 输入、mkSystem / mkHome、输出
└── hosts/<host>          装配层：选择模块 + 机器专属设置
    ├── modules/core      任何主机都需要的系统基础
    ├── modules/desktop   桌面组合入口
    ├── modules/virtualization/*  平台模块，由 host 显式导入
    └── modules/home-manager.nix  把 HM 接入 NixOS
        └── home/users + home/profiles/* → home/programs/*
```

- **host 是唯一表达“这台机器”的地方**。VMware 支持、SDDM 改走 Xorg 的变通、zram、
  Disko 布局、是否启用 impermanence 都写在 `hosts/nixos/`，`core` 不做任何机器假设。
- **`desktop.session`**（`plasma` | `niri` | `both`）是唯一的桌面开关。它同时决定加载
  哪个桌面模块、SDDM 列出哪些会话，以及 HM 是否导入 `home/profiles/niri.nix`。
- **Home Manager 分三层**：`users/` 只放身份，`programs/` 放有实质配置的单个程序，
  `profiles/` 负责组合。只有一行 `enable` 的程序直接写在 profile 里，不建空壳模块。
- **同一套 HM 模块两种用法**：NixOS 集成，以及 standalone 的 `homeConfigurations.ryuk`、
  `ryuk-tools`。因此 `home/` 下不能依赖 NixOS 选项。

## 只定义一次的值

- 用户名：`flake.nix` 的 `username`，经 specialArgs 传给 NixOS 模块；路径从
  `config.users.users.${username}.home` 推导。
- dotfiles 路径：HM 选项 `dotfiles.path`，默认 `~/dotfiles`。
- nixpkgs 配置（unfree 白名单）：`flake.nix` 的 `nixpkgsConfig`，NixOS 与 standalone
  输出共用，避免同一个 profile 在两个入口求值结果不同。

## 存储与 impermanence

磁盘由 `hosts/nixos/disko-config.nix` 声明：Btrfs 子卷 `root`、`home`、`nix`、`persist`、
`swap`，以及创建时生成的只读快照 `root-blank`。

- `hosts/<host>` 中设置 `environment.persistence."/persist".enable = true` 后，
  `modules/core/impermanence.nix` 会在 initrd 中把 `root` 恢复为 `root-blank`，
  **`/` 每次启动都是空的**。
- 需要跨重启的系统状态必须加入该模块的持久化清单；`/home`、`/nix` 是独立子卷，
  天然持久。
- 回滚服务按 Btrfs label `nixos` 查找设备，与 Disko 布局约定一致。

选择“只清空 `/`、整个 `/home` 持久”是保守取舍：系统漂移可以消除，用户数据不需要逐项
声明。

## 状态版本

`system.stateVersion` 和 `home.stateVersion` 表示首次安装时的兼容基准，不是当前软件
版本。更新 nixpkgs 时不要修改。

## 不由仓库管理的状态

- 浏览器资料、Bitwarden / Codex / GitHub / Spotify 登录状态
- Spicetify Marketplace 手动安装的扩展、GoldenDict-ng 辞书与界面状态
- Rime 的 `build/`、用户词库与同步目录
- Noctalia 通过 GUI 写入 XDG state 的临时覆盖

系统 secret 见[密钥管理](secrets.md)。
