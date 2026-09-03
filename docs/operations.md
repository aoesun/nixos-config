# 日常维护与部署

## 工作目录

正式配置仓库位于：

```text
/home/ryuk/nixos-config
```

日常修改应只在该仓库中进行。原 `/etc/nixos` 若仍保留，应视为旧备份，不要同时编辑两份配置。

## 修改流程

推荐每次修改遵循以下顺序：

1. 在 `~/nixos-config` 编辑 Nix 文件。
2. 更新对应的 `docs/` 文档。
3. 查看 Git diff，确认没有意外文件或敏感信息。
4. 对 flake 做求值检查。
5. 构建并切换系统。
6. 验证功能正常。
7. 使用 Git 提交并推送。

## 检查配置

在仓库目录执行：

```bash
nix flake check --no-build
```

该命令检查 flake 输出能否求值，但不构建完整系统。它适合在提交前快速发现语法错误、缺少模块和不存在的软件包属性。

## 应用配置

```bash
sudo nixos-rebuild switch --flake ~/nixos-config
```

`switch` 会构建新系统、设置为默认启动代际，并立即激活可以在线切换的服务和用户环境。Home Manager 已集成到 NixOS，因此无需再单独执行 `home-manager switch`。

当前 flake 只有 `nixos` 一个输出，也可以显式指定：

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#nixos
```

增加实体机输出后，建议始终写明 `#主机输出名`，避免对错误机器应用配置。

## 测试而不设为默认启动项

```bash
sudo nixos-rebuild test --flake ~/nixos-config
```

`test` 会激活配置，但不把它设为下次启动的默认代际。它适合测试可能影响网络、SSH 或桌面的改动；重启后会回到先前默认配置。

## 更新依赖

更新全部 flake 输入：

```bash
nix flake update
```

更新后应审阅 `flake.lock` 的差异，再运行检查和重建。不要因为更新 nixpkgs 就修改 `system.stateVersion` 或 `home.stateVersion`。

完整的更新前检查、版本比较、内核重启和故障回滚流程见
[更新软件与内核](updating.md)。

## 回滚

若刚切换的配置有问题，可以回滚到上一个系统代际：

```bash
sudo nixos-rebuild switch --rollback
```

也可以重启，在 systemd-boot 菜单中选择近期旧代际。启动菜单最多保留 5 项，并且系统每周清理超过 14 天的不可达旧路径，因此 Git 历史仍是长期追踪配置变化的主要依据。

## Git 与 LazyGit

远端仓库为私有 GitHub 仓库，`origin` 使用 SSH：

```text
git@github.com:aoesun/nixos-config.git
```

LazyGit 常用键：

- `Space`：暂存或取消暂存当前文件。
- `a`：暂存或取消暂存全部文件。
- `c`：创建提交。
- `p`：拉取。
- `P`：推送。
- `?`：显示当前面板帮助。

提交前不要只看文件名，还应查看实际 diff。提交摘要使用祈使语气并说明目的；复杂变更可在 description 中解释原因和约束。

## 敏感信息

不要提交以下内容：

- 密码、API Token 和 Cookie。
- SSH、age、PGP 等私钥。
- `.env` 和应用登录状态。
- Bitwarden 数据目录。
- Codex、OpenCode 或 GitHub 的认证文件。

`.gitignore` 只能防止常见误提交，不能替代提交前审阅。如果未来需要声明式密钥管理，可引入 `sops-nix` 或 `agenix`，只提交加密后的密文和允许公开的公钥。

## 文档同步规则

当配置发生以下变化时，应更新对应文档：

- 修改 flake 输入或模块关系：更新 `architecture.md`。
- 修改网络、用户、磁盘、启动、SSH 或虚拟化：更新 `system.md`。
- 修改 Plasma、软件、字体或输入法：更新 `desktop-and-input.md`。
- 修改用户程序和 shell：更新 `home-manager.md`。
- 修改部署、更新或维护流程：更新本文件。
- 修改软件和内核更新流程：更新 `updating.md`。
- 修改实体机安装和新增主机流程：更新 `installing-physical-machine.md`。
