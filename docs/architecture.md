# 架构与模块关系

## Flake 输入

根目录的 `flake.nix` 使用两个输入：

- `nixpkgs`：跟踪 `NixOS/nixpkgs` 的 `nixos-26.05` 分支。
- `home-manager`：跟踪 `nix-community/home-manager` 的 `release-26.05` 分支，并让其 `nixpkgs` 输入跟随系统的 nixpkgs，避免两套软件包版本不一致。

精确修订记录在 `flake.lock` 中，因此日常重建具有可重复性。只有执行 `nix flake update` 或显式更新某个输入时，锁定版本才会变化。

## 系统输出

flake 只定义一个 NixOS 输出：

```text
nixosConfigurations.nixos
```

目标平台为 `x86_64-linux`。输出名称与主机名相同，因此在仓库目录中执行 `nixos-rebuild switch --flake .` 时，Nix 可以自动选择正确配置。

## 模块加载关系

```text
flake.nix
├── home-manager.nixosModules.home-manager
├── hosts/nixos/default.nix
│   ├── hosts/nixos/hardware-configuration.nix
│   ├── modules/nixos/base.nix
│   ├── modules/nixos/boot.nix
│   ├── modules/nixos/desktop.nix
│   ├── modules/nixos/ssh.nix
│   └── modules/nixos/home-manager.nix
│       └── home/ryuk/default.nix
│           ├── home/ryuk/programs/tools.nix
│           ├── home/ryuk/programs/vim.nix
│           ├── home/ryuk/programs/yazi.nix
│           └── home/ryuk/programs/zsh.nix
└── modules/nixos/optional/vmware-guest.nix
```

`mkSystem` 接受额外模块列表。当前 `nixos` 输出始终加入 `vmware-guest.nix`，所以这台主机被明确视为 VMware 图形客户机；该模块虽位于 `optional/`，目前并不是未启用状态。

## 配置职责

- `hosts/` 保存与某台机器直接相关的入口和硬件信息。
- `modules/nixos/` 保存系统级功能，可供未来其他主机复用。
- `home/` 保存用户级配置，由 Home Manager 管理。
- `docs/` 保存与上述配置同步的说明文档。

系统软件应根据作用域放置：所有用户或系统桌面需要的软件放入 NixOS 模块；只属于 `ryuk` 的命令行工具和配置优先放入 Home Manager。

## 版本字段

当前有两个状态版本：

- `system.stateVersion = "26.05"`
- `home.stateVersion = "26.05"`

它们表示首次采用配置时所依据的兼容行为，不是当前安装的软件版本。正常升级 nixpkgs 或 Home Manager 时不应随意修改；只有明确理解迁移影响时才调整。
