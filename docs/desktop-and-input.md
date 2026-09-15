# 桌面与输入法

## KDE Plasma

系统启用 KDE Plasma 6 桌面和 Plasma Login Manager。桌面会话以 Wayland 为主要环境，Fcitx5 也启用了 Wayland 前端。

从 Plasma 默认软件集合中排除了：

- Ark 压缩包管理器
- Discover 软件中心
- Elisa 音乐播放器
- KHelpCenter 帮助中心
- KWin X11 会话组件
- Okular 文档查看器
- QRca 二维码工具

排除 `kwin-x11` 表明配置面向 Wayland，不提供 KWin 的 X11 会话。

Kate 和 KWrite 由同一个 `kate` 软件包提供，无法在软件包层面只安装其中一个，当前两者都予以保留。

## 字体和桌面软件

安装 Fira Code Nerd Font，用于终端、编辑器和提示符中的编程字符及图标。

Home Manager 的 GUI profile 安装：

- Bitwarden Desktop：密码管理客户端。
- Chromium：网页浏览器。
- GoldenDict-ng：支持多种离线辞书格式的 Qt6 词典查询工具。

Chromium 通过 Home Manager 配置以下扩展：

- Vimium：使用类似 Vim 的键盘操作浏览网页。
- uBlock Origin Lite：适用于 Chromium Manifest V3 的广告和跟踪内容拦截器。

配置锁定的是扩展 ID，而不是 Chrome Web Store 中的扩展版本；Chromium 启动后
联网下载和更新扩展。受浏览器安全限制，系统策略不能替用户启用“允许在无痕模式下
运行”。首次安装后需要分别进入 `chrome://extensions`，打开扩展详情并手动启用
该选项。扩展自身的用户设置仍保存在 Chromium 用户资料中，除非扩展明确提供可用
的 managed-storage 策略。

安装软件并不代表其用户设置也是声明式的。例如 Bitwarden 的登录状态、自启动开关和 Chromium 的个人资料仍保存在用户目录中，不由本仓库管理。

GoldenDict-ng 的界面偏好和辞书路径属于小型配置，后续可根据修改频率选择 Home
Manager 的 Store 内文件或 `mkOutOfStoreSymlink`。辞书本体通常体积较大，并且
可能受再分发许可或版权约束，不放入公开的 dotfiles 仓库；应保存在独立数据目录，
通过合法下载来源、私人备份或单独的数据同步方案恢复。

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

## Rime 数据与用户配置

NixOS 将锁定版本的 `rime-ice` 安装为 Rime 的共享基础数据。四个用户补丁保存在
`~/dotfiles/rime`，Home Manager 将它们逐个链接到
`~/.local/share/fcitx5/rime/`：

- `default.custom.yaml`
- `double_pinyin.custom.yaml`
- `melt_eng.custom.yaml`
- `radical_pinyin.custom.yaml`

只链接静态配置文件，不链接整个 Rime 用户目录。`build/`、`sync/`、`*.userdb/`、
`installation.yaml` 和 `user.yaml` 是 Rime 需要写入的运行时状态，不进入 Git。

## 自然码双拼行为

Rime 方案列表只保留：

```text
double_pinyin
```

这是 Rime 自带的自然码双拼方案。当前补丁行为如下：

### 默认简体中文

`double_pinyin` 的第 3 个开关是 `simplification`。配置将其 reset 值设为 `0`：

```text
switches/@2/reset = 0
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

修改 `~/dotfiles/rime/*.custom.yaml` 后不需要重建 NixOS，但需要在 Fcitx5 菜单执行
“重新部署”，让 librime 重新合并并编译配置。也可以重启 Fcitx5 后再执行部署。

如果编译缓存没有更新，可先备份用户目录中的 Rime `build` 缓存，再重新部署；不要
删除词库数据库和同步目录。更新 `rime-ice` 的锁定版本或输入法软件本身时，才需要
重建 NixOS。

在其他发行版复用这些补丁时，宿主仍需安装并启用 Rime 前端（例如 `fcitx5-rime`），
同时提供兼容的 `rime-ice` 基础数据。Home Manager 的 GUI profile 只部署用户补丁，
不负责完成发行版的输入法框架和桌面会话集成。
