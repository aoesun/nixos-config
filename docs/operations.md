# 日常维护

配置仓库位于 `~/nixos-config`，可编辑的原生配置位于 `~/dotfiles`。不要再编辑
`/etc/nixos`。

## 命令入口

在仓库内运行 `just` 查看全部 recipe。常用：

| Recipe | 用途 |
| --- | --- |
| `just check` | 求值全部 flake 输出，不构建（每次修改后的最低验证） |
| `just check-all` | 构建全部 checks：两个 HM profile 与 Nix 格式检查 |
| `just fmt` | 用 nixfmt 格式化 Nix 文件（跳过生成的硬件配置） |
| `just build` / `just diff` | 构建系统到 `result-system` / 并与当前系统比较闭包 |
| `just home [ryuk-tools]` | 构建 standalone HM profile |
| `just test` | 临时激活，重启后回到原默认世代 |
| `just switch` / `just boot` | 激活并设为默认 / 只设为下次启动默认 |
| `just update` / `just update-input <name>` | 更新全部 / 单个 flake 输入 |
| `just history` | 查看系统世代 |
| `just clean` / `just clean-all` | 删除 7 天前 / 全部非当前世代并回收 Store |
| `just software list` | 列出独立安装的软件包（`goldendict-ng`、`spotify`） |

`packages/` 中的软件不会随 rebuild 安装，需要 `just software <name>`。

## 修改流程

1. 编辑 Nix 文件；新增的 `.nix` 文件先 `git add`，否则 flake 看不到。
2. 如改动了结构、流程或约定，同步更新 `docs/`。
3. `just fmt`、`just check`，必要时 `just diff` 查看闭包变化。
4. `just test` 验证，再 `just switch`。
5. 审阅 diff 后提交。

## 修改 dotfiles

已链接文件保存即生效，不需要 rebuild：

- niri：修改后运行 `niri validate`，niri 自动重载。
- Noctalia：热重载 `config.toml`。
- Rime：在 Fcitx5 菜单执行“重新部署”。若缓存未更新，可备份后清理 Rime 的
  `build/`，不要删除用户词库和同步目录。
- Neovim：重启 Neovim。使用新插件前先把它加入 `home/programs/neovim.nix`。

新增需要部署到其他位置的文件时，才需要在 Nix 中用 `config.lib.dotfiles.link` 增加链接
并 rebuild。`nvim/lua/` 和 `navi/` 是整个目录链接，其中新增文件无需改 Nix。

## 更新软件与内核

```bash
git status                    # 最好从干净工作区开始
just update                   # 只修改 flake.lock
git diff -- flake.lock        # 确认输入仍指向预期分支
just check && just diff       # 重点看内核、systemd、显卡/VMware、桌面组件
just test                     # 观察服务、网络与桌面
just switch
```

内核、initrd、内核模块或 systemd/glibc 有重要变化时需要重启，并用 `uname -r` 确认。
验证 `systemctl --failed` 与 `journalctl -b -p err` 后提交 `flake.lock`。
建议每一到四周小步更新一次。

## 回滚

```bash
sudo nixos-rebuild switch --rollback
```

或在 systemd-boot 菜单中选择旧世代（最多保留 5 项）。回滚后若问题来自依赖更新，用
`git restore flake.lock`（未提交时）或 `git revert`（已提交时）恢复锁文件，避免下次
重建再次选中问题版本。

## 在其他发行版使用用户环境

安装 Nix 并启用 flakes，先克隆两个仓库到固定位置：

```bash
git clone https://github.com/aoesun/dotfiles ~/dotfiles
git clone https://github.com/aoesun/nixos-config ~/nixos-config
cd ~/nixos-config
nix run home-manager/release-26.05 -- switch --flake .#ryuk        # 或 .#ryuk-tools
```

standalone HM 不创建系统用户、不修改 `/etc/shells`，也不安装桌面和输入法框架：宿主需
自备 `ryuk` 用户、Zsh 登录 Shell，以及图形会话和 Fcitx5 Rime（若使用 GUI profile）。
首次激活若目标路径已有普通文件，先迁移，避免与 HM 链接冲突。

## 手动步骤

以下设置无法声明式完成，新环境需手动处理：

- Chromium 扩展的“允许在无痕模式下运行”：在 `chrome://extensions` 中逐个开启。
  桌面入口默认以无痕模式启动，不开启则扩展不生效。
- 新 GitHub SSH 公钥需添加到 GitHub 账户（私钥由 sops-nix 部署到 `~/.ssh/id_ed25519`）。
