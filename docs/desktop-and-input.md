# 桌面与输入法

## KDE Plasma

系统启用 KDE Plasma 6 桌面和 Plasma Login Manager。桌面会话以 Wayland 为主要环境，Fcitx5 也启用了 Wayland 前端。

从 Plasma 默认软件集合中排除了：

- Elisa 音乐播放器
- KHelpCenter 帮助中心
- KWin X11 会话组件

排除 `kwin-x11` 表明配置面向 Wayland，不提供 KWin 的 X11 会话。

## 字体和桌面软件

安装 Fira Code Nerd Font，用于终端、编辑器和提示符中的编程字符及图标。

系统级桌面软件包括：

- Bitwarden Desktop：密码管理客户端。
- Chromium：网页浏览器。
- Fastfetch：显示系统和硬件摘要。

安装软件并不代表其用户设置也是声明式的。例如 Bitwarden 的登录状态、自启动开关和 Chromium 的个人资料仍保存在用户目录中，不由本仓库管理。

## Fcitx5

系统输入法框架为 Fcitx5，并启用：

- Wayland 前端
- GTK 输入法支持
- Rime
- Mozc 日语输入法

默认输入法组名为 `Default`，键盘布局为 US，包含以下顺序：

1. `keyboard-us`
2. `rime`
3. `mozc`

组内默认输入法为 Rime。

## Rime 数据组合

配置通过 `pkgs.symlinkJoin` 创建 `rime-custom-data`，将两个自定义 YAML 补丁作为数据包交给 `fcitx5-rime`：

- `default.custom.yaml`
- `double_pinyin.custom.yaml`

该自定义包与 nixpkgs 的 `rime-data` 一起组成 Rime 数据来源，避免直接在用户目录中长期维护配置副本。

## 自然码双拼行为

Rime 方案列表只保留：

```text
double_pinyin
```

这是 Rime 自带的自然码双拼方案。当前补丁行为如下：

### 默认简体中文

`double_pinyin` 的第 3 个开关是 `simplification`。配置将其 reset 值设为 `1`，对应简体状态：

```text
switches/@2/reset = 1
```

Rime 默认按键绑定中的 `Ctrl+Shift+4` 仍可切换简体与繁体。

### 候选页大小

候选菜单每页显示 7 项。

### 双拼预编辑显示

`translator/preedit_format` 被设为空列表，因此输入自然码双拼时显示原始双拼编码，不再在预编辑区自动展开成全拼。

### 右 Shift 提交原始编码

右 Shift 的行为覆盖为 `commit_code`。例如：

1. 在自然码模式输入 `ha`。
2. 单独按右 Shift。
3. 输入框提交原始字母 `ha`，而不是候选汉字“哈”。

未覆盖左 Shift。左 Shift 由 Fcitx5 上层用于在 Rime 和英语键盘输入法之间切换，因此 Rime 的 Shift 配置无法稳定接收到该按键。右 Shift 则用于 Rime 自然码与 Latin 状态之间切换。

## Rime 配置生效

修改 Rime 数据后，先重建 NixOS：

```bash
sudo nixos-rebuild switch --flake ~/nixos-config
```

通常重新登录桌面或在 Fcitx5 菜单执行“重新部署”即可加载新配置。如果编译缓存没有更新，可先备份用户目录中的 Rime `build` 缓存，再重新启动 Fcitx5；不要删除词库数据库和同步目录。
