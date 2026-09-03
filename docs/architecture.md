# 架构与模块关系

## Flake 输入

根目录的 `flake.nix` 使用两个输入：

- `nixpkgs`：跟踪 `NixOS/nixpkgs` 的 `nixos-26.05` 分支。
- `home-manager`：跟踪 `nix-community/home-manager` 的 `release-26.05` 分支，并让其 `nixpkgs` 输入跟随系统的 nixpkgs，避免两套软件包版本不一致。

精确修订记录在 `flake.lock` 中，因此日常重建具有可重复性。只有执行 `nix flake update` 或显式更新某个输入时，锁定版本才会变化。

## 系统输出

flake 当前定义一个 NixOS 输出：

```text
nixosConfigurations.nixos
```

目标平台为 `x86_64-linux`。`mkSystem` 接收一个主机模块，将 Home Manager 的
NixOS 模块与该主机入口组合起来。输出名称与主机名相同，因此在仓库目录中执行
`nixos-rebuild switch --flake .` 时，Nix 可以自动选择当前唯一配置。

## 模块加载关系

```text
flake.nix
├── home-manager.nixosModules.home-manager
└── hosts/nixos/default.nix
    ├── hosts/nixos/hardware-configuration.nix
    ├── modules/nixos/base.nix
    ├── modules/nixos/boot.nix
    ├── modules/nixos/desktop.nix
    ├── modules/nixos/ssh.nix
    ├── modules/nixos/optional/vmware-guest.nix
    └── modules/nixos/home-manager.nix
        └── home/ryuk/default.nix
            ├── home/ryuk/programs/tools.nix
            ├── home/ryuk/programs/vim.nix
            ├── home/ryuk/programs/yazi.nix
            └── home/ryuk/programs/zsh.nix
```

`vmware-guest.nix` 由 `hosts/nixos/default.nix` 导入，因此 VMware 支持只属于
当前主机，不会隐式影响未来的实体机。该模块虽位于 `optional/`，对当前 `nixos`
主机仍是启用状态。

未来增加实体机时，应新建独立的 `hosts/<主机名>/`，并在 flake 中新增输出：

```nix
nixosConfigurations.workstation = mkSystem ./hosts/workstation;
```

实体机入口可以复用 `base.nix`、`boot.nix`、`desktop.nix`、`ssh.nix` 和
`home-manager.nix`，但不得导入 VMware 模块，也不得复用虚拟机的
`hardware-configuration.nix`。完整流程见[在实体机上安装](installing-physical-machine.md)。

## 配置职责

- `hosts/` 保存与某台机器直接相关的主机名、入口、硬件信息和主机专用模块。
- `modules/nixos/` 保存系统级功能，可供未来其他主机复用。
- `home/` 保存用户级配置，由 Home Manager 管理。
- `docs/` 保存与上述配置同步的说明文档。

系统软件应根据作用域放置：所有用户或系统桌面需要的软件放入 NixOS 模块；只属于 `ryuk` 的命令行工具和配置优先放入 Home Manager。

## 版本字段

当前有两个状态版本：

- `system.stateVersion = "26.05"`
- `home.stateVersion = "26.05"`

它们表示首次采用配置时所依据的兼容行为，不是当前安装的软件版本。正常升级 nixpkgs 或 Home Manager 时不应随意修改；只有明确理解迁移影响时才调整。
