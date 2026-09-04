# 更新软件与内核

本仓库使用 Nix Flakes。软件、内核与 Home Manager 的准确版本由 `flake.lock`
锁定，因此普通的 `nixos-rebuild` 只重建当前锁定版本，不会主动追踪远端更新。

## 更新机制

```text
更新 flake.lock
    ↓
检查配置求值
    ↓
构建新的系统闭包
    ↓
比较新旧软件版本
    ↓
切换到新系统代际
    ↓
必要时重启进入新内核
    ↓
验证并提交 flake.lock
```

`flake.nix` 声明依赖的来源和发布分支，`flake.lock` 则记录实际使用的 Git
提交及内容哈希。恢复旧的 `flake.lock`，即可重新选择当时的软件集合。

## 更新前检查

进入仓库：

```bash
cd ~/nixos-config
```

确认工作区状态：

```bash
git status
```

建议在干净工作区开始更新。如果存在未提交改动，应先审阅并提交，或明确知道它们
会与本次更新一起参与构建。不要为了获得干净状态而随意丢弃改动。

查看当前系统代际：

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

确认当前运行内核：

```bash
uname -r
```

## 更新 Flake 输入

更新全部输入：

```bash
nix flake update
```

当前会更新：

- `nixpkgs`：NixOS、内核及大多数软件包。
- `home-manager`：用户环境管理模块。
- `dotfiles`：Home Manager 部署的原生用户配置和 Navi cheats。

Home Manager 的 nixpkgs 输入跟随系统 nixpkgs，确保系统与用户配置使用同一套
软件包集合。

如果有明确原因只更新 nixpkgs，可以执行：

```bash
nix flake update nixpkgs
```

通常建议一起更新全部输入，以保持相同发布分支上的兼容性。

如果只更新 dotfiles 仓库的锁定提交，可以执行：

```bash
nix flake update dotfiles
```

更新命令只修改 `flake.lock`，不会立即安装软件或改变当前系统。

## 审阅锁文件

查看变化：

```bash
git diff -- flake.lock
```

锁文件主要显示输入的 revision、时间和哈希，不会列出每个软件的版本变化。确认
输入仍指向预期项目和发布分支，且没有意外删除或新增依赖。

不要因为更新依赖而修改：

```nix
system.stateVersion
home.stateVersion
```

这两个字段是兼容性基准，不是当前 NixOS 或软件版本号。

## 检查配置

先进行求值检查：

```bash
nix flake check --no-build
```

它可以发现 Nix 语法错误、失效选项、模块冲突和不存在的软件包属性，但不会构建
完整系统。

## 构建但不切换

为当前虚拟机构建新的系统闭包：

```bash
sudo nixos-rebuild build --flake .#nixos
```

构建成功后，仓库中的 `result` 符号链接指向新系统。`result` 已被 `.gitignore`
排除，不应提交。

该步骤不会启动新服务，不会设置默认启动代际，也不会替换当前系统。

## 比较软件版本

比较当前系统与新构建结果：

```bash
nix store diff-closures /run/current-system ./result
```

输出会显示软件包的新增、移除及版本变化。重点查看：

- Linux 内核和内核模块。
- systemd、glibc 等基础组件。
- Plasma、显卡相关组件和显示管理器。
- Chromium、Bitwarden 等桌面软件。
- Fcitx5、Rime 和 Home Manager 管理的命令行程序。

大量版本变化在更新 nixpkgs 后是正常现象；意外移除关键软件时应先检查配置和上游
包名变化，不要立即切换。

## 临时测试

可以在不设置下次启动默认代际的情况下激活用户空间配置：

```bash
sudo nixos-rebuild test --flake .#nixos
```

适合观察服务、网络、SSH 和桌面配置是否能正常激活。如果重启，系统仍使用之前的
默认启动代际。

正在运行的 Linux 内核不能被 `test` 或 `switch` 原地替换。内核、initrd 和启动
阶段驱动只能在重启后完整验证。

## 正式切换

确认构建和差异正常后：

```bash
sudo nixos-rebuild switch --flake .#nixos
```

当前 hostname 与 flake 输出都叫 `nixos`，因此也可以简写：

```bash
sudo nixos-rebuild switch --flake .
```

`switch` 会创建并激活新系统代际、更新默认启动项、重启或重载可在线切换的服务，
并同时激活集成的 Home Manager 用户配置。

## 判断是否需要重启

以下更新后建议重启：

- Linux 内核或 initrd。
- 显卡、VMware 或其他内核模块。
- systemd、glibc 等核心运行组件发生重要变化。
- 重建输出明确提示需要重启。

执行：

```bash
sudo reboot
```

重启后检查实际运行内核：

```bash
uname -r
```

仅更新普通命令行软件或桌面应用时通常不必重启，关闭并重新打开相关程序即可。

## 验证更新

至少检查：

- 系统能正常启动。
- 网络和 DNS 正常。
- Plasma Wayland 会话可以登录。
- Fcitx5 与 Rime 输入正常。
- SSH 服务和 GitHub SSH agent 正常。
- 常用软件可以启动。

查看失败的 systemd 单元：

```bash
systemctl --failed
```

查看本次启动的高优先级错误：

```bash
journalctl -b -p err
```

日志中的错误不一定由本次更新引起，应结合时间、服务名称和实际功能判断。

## 回滚

如果切换后出现问题，可回到上一系统代际：

```bash
sudo nixos-rebuild switch --rollback
```

如果新内核无法正常启动，在 systemd-boot 菜单中选择较早的 NixOS 代际。当前启动
菜单最多保留 5 个配置项。

回滚系统后，还应恢复仓库中的锁文件，避免下一次重建再次选择有问题的版本：

```bash
git restore flake.lock
```

`git restore` 会丢弃尚未提交的锁文件更新，因此执行前必须确认其中没有需要保留的
其他变化。如果更新已经提交，应使用正常的 Git revert 或恢复对应旧提交，而不是
直接改写共享历史。

## 提交更新

验证正常后，使用 Git 或 LazyGit提交 `flake.lock`。推荐摘要：

```text
Update Nix flake inputs
```

如果为适配上游变更同时修改了 Nix 配置，应在 commit description 中说明兼容性
调整和验证结果。

推送前再次确认：

```bash
git status
```

不要提交 `result`、日志、应用缓存、认证信息或私钥。

## 建议频率

桌面系统可以每一到四周更新一次。安全修复或浏览器更新需要时可提前更新。相比长
时间不更新后一次跨越大量变化，规律的小步更新更容易审阅、验证和回滚。
