# 密钥管理

系统 secret 由 sops-nix 管理，加密使用单个 age 身份。

| 文件 | 内容 | 是否提交 |
| --- | --- | --- |
| `.sops.yaml` | age 公钥（接收者）与匹配规则 | 是 |
| `secrets/secrets.yaml` | sops 密文：登录密码哈希、GitHub SSH 私钥等 | 是 |
| `secrets/age-key.txt.age` | age 私钥的口令加密备份 | 是 |
| `.secrets/` | 人工恢复出的明文 | 否（整个目录被忽略） |
| `/persist/var/lib/sops-nix/key.txt` | 系统解密用的 age 私钥 | 不在仓库 |

age 私钥另有一份保存在 Bitwarden 安全笔记 `NixOS SOPS age private key`。

## 初始化（每套配置只做一次）

在可信系统中运行：

```bash
./scripts/bootstrap-secrets
```

脚本生成 age 身份、写入 `.sops.yaml`、要求设置备份口令和 `ryuk` 的登录密码。
随后把 `.secrets/age-key.txt` 存入 Bitwarden，确认后删除明文，再提交加密文件。
删除前可以先确认密码：

```bash
./scripts/verify-login-password
```

## 恢复

恢复 age 私钥（来源可选 Bitwarden 或 Git 备份，先试解 `secrets.yaml` 成功才落盘）：

```bash
./scripts/restore-age-key
```

恢复单个 secret（例如 GitHub SSH 私钥），在临时文件中解密并校验后再安装：

```bash
./scripts/restore-sops-secret
```

脚本依次查找 `/persist/var/lib/sops-nix/key.txt`、`.secrets/key.txt`、
`.secrets/age-key.txt`，也可以用 `SOPS_AGE_KEY_FILE` 指定。目标已存在且内容不同时，
SSH 私钥只显示指纹对比，确认后才覆盖。

## 修改登录密码

`users.mutableUsers = false`，`passwd` 的修改会在下次激活时被覆盖。生成新哈希并写入
sops：

```bash
mkpasswd --method=yescrypt
sops secrets/secrets.yaml   # 替换 users.ryuk-password
```

然后重新部署。

## 新增 secret

1. `sops secrets/secrets.yaml` 添加键值。
2. 在 `modules/core/default.nix` 的 `sops.secrets` 中声明，并设置 owner、mode、path。
3. 如需人工恢复，在 `scripts/restore-sops-secret` 顶部的并行数组中各追加一项（保持
   索引对齐）。

不要提交明文密码、Token、Cookie、私钥或应用认证文件。
