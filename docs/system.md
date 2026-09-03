# 系统与主机配置

## 基础系统

`modules/nixos/base.nix` 定义以下基础行为：

- 主机名为 `nixos`。
- 使用 NetworkManager 管理网络连接。
- 时区为 `Asia/Tokyo`。
- 默认 locale 为 `en_US.UTF-8`。
- 启用 Nix 新命令和 flakes：`nix-command`、`flakes`。
- 启用 Nix Store 自动优化，合并内容相同的 Store 文件以减少重复占用。
- 将 `/share/zsh` 暴露到系统环境，供 Home Manager 管理的 Zsh 使用系统包提供的补全定义。

## 用户

系统创建普通用户 `ryuk`，显示名称为 `Ryuk`：

- 家目录由默认规则确定为 `/home/ryuk`。
- 默认 shell 为 Zsh。
- 属于 `networkmanager` 组，可以管理网络。
- 属于 `wheel` 组，可以通过 sudo 执行管理员操作。

系统同时启用 Zsh 和 tmux。Zsh 的具体交互配置由 Home Manager 管理，参见 [Home Manager 用户环境](home-manager.md)。

## 启动与回滚

系统使用 systemd-boot：

- 允许修改 EFI 启动变量。
- 最多保留 5 个启动菜单配置项。

这意味着常规 `nixos-rebuild switch` 后仍可从启动菜单选择近期系统代际进行回滚，但更早的启动条目会被移出菜单。

## Nix Store 清理

系统每周自动运行 Nix 垃圾回收，并使用：

```text
--delete-older-than 14d
```

它会删除超过 14 天且已不可达的 Nix Store 路径和旧代际。仍被当前系统、用户环境或其他 GC Root 引用的路径不会删除。该策略与 Git 提交历史无关，不会清理仓库中的 commit。

## 硬件和存储

`hardware-configuration.nix` 由 `nixos-generate-config` 生成，不应作为日常手工编辑位置。

初始化阶段可用的主要内核模块包括：

- `ata_piix`
- `mptspi`
- `uhci_hcd`
- `ehci_pci`
- `ahci`
- `sd_mod`
- `sr_mod`

存储布局：

| 挂载点 | 文件系统 | 关键选项 |
| --- | --- | --- |
| `/` | Btrfs | `subvol=root`、`compress=zstd` |
| `/home` | Btrfs | `subvol=home`、`compress=zstd` |
| `/nix` | Btrfs | `subvol=nix`、`compress=zstd`、`noatime` |
| `/boot` | VFAT | `fmask=0077`、`dmask=0077` |

根目录、`/home` 与 `/nix` 使用同一个 Btrfs 文件系统的不同子卷。`/nix` 禁用 atime 更新以减少不必要写入。EFI 启动分区权限掩码限制普通用户访问。

系统还在 `/var/lib/swapfile` 配置了 8 GiB 交换文件。

## SSH 服务

OpenSSH 服务已启用，策略如下：

- 禁止 root 直接登录：`PermitRootLogin = "no"`。
- 允许普通用户密码认证：`PasswordAuthentication = true`。
- 禁用键盘交互认证：`KbdInteractiveAuthentication = false`。

因此远程管理应先登录普通用户，再通过 sudo 提权。当前配置允许密码认证，暴露到不可信网络前建议改为 SSH 公钥认证，并在确认公钥可用后关闭密码认证。

## VMware 客户机

`modules/nixos/optional/vmware-guest.nix` 当前由 flake 显式加载：

- 启用 VMware Guest 支持。
- `headless = false`，按带图形桌面的虚拟机配置。

如果未来把同一仓库用于实体机或其他虚拟化平台，应为不同主机建立独立输出，并只给 VMware 主机加载该模块。
