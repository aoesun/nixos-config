# 架构与模块关系

## Flake 输入

根目录的 `flake.nix` 使用四个输入：

- `nixpkgs`：跟踪 `NixOS/nixpkgs` 的 `nixos-26.05` 分支。
- `home-manager`：跟踪 `nix-community/home-manager` 的 `release-26.05` 分支，并让其 `nixpkgs` 输入跟随系统的 nixpkgs，避免两套软件包版本不一致。
- `spicetify-nix`：构建独立的定制 Spotify 软件包。
- `rime-ice`：提供固定版本的 Rime 雾凇拼音数据。

精确修订记录在 `flake.lock` 中，因此日常重建具有可重复性。只有执行 `nix flake update` 或显式更新某个输入时，锁定版本才会变化。

频繁编辑的 Neovim Lua 和 Navi cheats 位于独立的 `~/dotfiles` Git 仓库，并通过
Store 外符号链接部署。Nix 管理程序及依赖，dotfiles 的 Git 历史管理原生配置内容。

## 系统输出

flake 当前定义一个 NixOS 输出：

```text
nixosConfigurations.nixos
```

目标平台为 `x86_64-linux`。`mkSystem` 生成 NixOS 配置；`mkHome` 将同一用户身份与
不同 profile 组合为完整的 `ryuk` 和无 GUI 的 `ryuk-tools`，因此 NixOS 集成与其他
发行版不会维护两份偏好。

## 模块加载关系

```text
flake.nix
├── home-manager.nixosModules.home-manager
└── hosts/nixos/default.nix
    ├── hosts/nixos/hardware-configuration.nix
    ├── modules/core/default.nix
    ├── modules/desktop/default.nix
    ├── modules/virtualization/vmware-guest.nix
    └── modules/home-manager.nix
        ├── home/users/ryuk.nix
        └── home/profiles/default.nix
            ├── home/profiles/tools.nix
            ├── home/profiles/gui.nix
            └── home/programs/*.nix

homeConfigurations.ryuk
├── home/users/ryuk.nix
└── home/profiles/default.nix
```

`vmware-guest.nix` 由 `hosts/nixos/default.nix` 导入，因此 VMware 支持只属于
当前主机，不会隐式影响未来的实体机。

未来增加实体机时，应新建独立的 `hosts/<主机名>/`，并在 flake 中新增输出：

```nix
nixosConfigurations.workstation = mkSystem ./hosts/workstation;
```

实体机入口可以复用 `modules/core`、`modules/desktop` 和
`modules/home-manager.nix`，但不得导入 VMware 模块，也不得复用虚拟机的
`hardware-configuration.nix`。完整流程见[在实体机上安装](installing-physical-machine.md)。

## 配置职责

- `hosts/` 保存与某台机器直接相关的主机名、入口、硬件信息和主机专用模块。
- `modules/core/` 保存可跨主机复用的系统基础；`desktop/` 本身是桌面组合入口；
  `virtualization/` 保存平台专用模块。
- `home/programs/` 保存具有实质配置的程序，`home/profiles/` 负责组合，`home/users/` 只定义身份。
- `docs/` 保存与上述配置同步的说明文档。

系统软件应根据作用域放置：所有用户或系统桌面需要的软件放入 NixOS 模块；只属于 `ryuk` 的命令行工具和配置优先放入 Home Manager。

## 版本字段

当前有两个状态版本：

- `system.stateVersion = "26.05"`
- `home.stateVersion = "26.05"`

它们表示首次采用配置时所依据的兼容行为，不是当前安装的软件版本。正常升级 nixpkgs 或 Home Manager 时不应随意修改；只有明确理解迁移影响时才调整。
