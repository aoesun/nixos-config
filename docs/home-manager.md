# Home Manager 用户环境

## 集成方式

Home Manager 作为 NixOS 模块加载，而不是独立执行：

- 使用系统的全局 nixpkgs：`useGlobalPkgs = true`。
- 用户软件通过系统构建安装：`useUserPackages = true`。
- 若激活时遇到同名旧文件，备份扩展名为 `.hm-backup`。
- 用户 `ryuk` 的入口是 `home/ryuk/default.nix`。

用户信息：

- 用户名：`ryuk`
- 家目录：`/home/ryuk`
- Home Manager 状态版本：`26.05`
- 启用 XDG 基础目录支持。
- 启用 `home-manager` 命令本身。

## 通用工具

`home/ryuk/programs/tools.nix` 安装或启用：

| 工具 | 用途 |
| --- | --- |
| `tree` | 树形查看目录 |
| `wget` | 下载文件 |
| Codex | AI 编程 CLI |
| Git | 版本控制 |
| LazyGit | Git 终端界面 |
| OpenCode | AI 编程工具 |
| Navi | 交互式命令速查，并集成 Zsh |
| Zoxide | 基于使用频率的目录跳转，并集成 Zsh |

认证状态和服务商凭据明确保存在仓库外，不能加入 Nix 文件或 Git 提交。

## Vim

Vim 被设为默认编辑器，主要行为为：

- 使用空格代替 Tab。
- Tab 宽度和缩进宽度均为 2。
- 显示行号与当前行。
- 允许隐藏未保存缓冲区。
- 搜索默认忽略大小写；查询中包含大写字母时自动区分大小写。
- 启用语法、文件类型插件和自动缩进。
- 启用增量搜索与搜索高亮。
- 启用命令行补全菜单。
- 光标上下保留 4 行上下文。
- 始终显示 sign column，避免诊断标记出现时文本左右跳动。

## Yazi

Yazi 是终端文件管理器，并集成 Zsh。shell wrapper 名称为 `y`，可在退出 Yazi 后将 shell 切换到最后所在目录。

当前 nixpkgs 的 Yazi 包已在自身包装器中提供 `file`、`jq`、
`poppler-utils`、`7zz`、`ffmpeg-headless`、`fd`、`ripgrep`、`fzf`、
`zoxide`、ImageMagick、`chafa` 和 `resvg`，用于文件识别、预览、搜索、
筛选、归档处理及目录跳转，不需要在 Home Manager 中重复声明。

配置仅通过 `extraPackages` 额外加入 `wl-clipboard`，提供 Wayland 会话所需的
`wl-copy` 和 `wl-paste` 剪贴板命令。桌面模块安装的 Fira Code Nerd Font 则为
Yazi 界面提供图标字形。

界面设置：显示隐藏文件、自然排序、目录优先，并以文件大小作为列表行信息。

## Zsh

### 基础交互

- 启用补全。
- 输入目录名可直接切换目录（`autocd`）。
- 使用 Emacs 风格的常规行编辑键位；这不依赖 Emacs 编辑器。
- 常见终端模式下，右方向键按单词向前移动。

### 自动建议和高亮

自动建议只从历史记录生成，建议文字使用灰色。语法高亮启用 `main` 和 `brackets` 两类 highlighter，并为命令、路径、选项、字符串、注释、错误和不同层级括号设置颜色。

### Spaceship 提示符

直接加载 nixpkgs 提供的 Spaceship 主题，不使用额外 shell 框架。提示符使用紧凑的两行布局：

- 不在提示符前额外插入空行。
- 输入字符独占下一行。
- 目录为蓝色。
- Git 分支为黄色。
- Git 状态和失败提示为红色。
- 成功提示为绿色。

### 历史记录

- 内存和磁盘各保留 1000 条。
- 以空格开头的命令不保存。
- 多个 Zsh 会话共享历史。
- 保存时去除重复项。
- 启用历史子串搜索。

### 别名

| 别名 | 实际命令 | 用途 |
| --- | --- | --- |
| `l` | `ls -CF --color=auto` | 简洁彩色列表 |
| `la` | `ls -A --color=auto` | 包括隐藏文件 |
| `ll` | `ls -lah --color=auto` | 详细、人类可读列表 |
| `lg` | `lazygit` | 启动 LazyGit |
| `tree` | `tree -a -C` | 彩色显示包括隐藏文件的目录树 |
