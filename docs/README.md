# 配置文档

文档只记录设计理由和操作流程；具体启用了什么、取什么值，以 Nix 源码为准。修改结构、
流程或约定时，在同一个提交中同步更新这里。

- [架构与设计理由](architecture.md)：两个仓库的分工、分层、`desktop.session`、
  impermanence、哪些状态不受管理。
- [日常维护](operations.md)：just 命令、修改流程、dotfiles、更新与回滚、在其他发行版使用。
- [密钥管理](secrets.md)：sops-nix 与 age 的初始化、恢复、改密码、新增 secret。
- [使用 Disko 安装 VMware 虚拟机](installing-vm-with-disko.md)：从 Minimal ISO 重装当前主机。
- [在实体机上安装](installing-physical-machine.md)：新增主机输出并安装。
