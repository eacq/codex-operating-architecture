# Portable Path Configuration

Tracked documentation, knowledge records, and manifests use logical roots rather
than a specific user's drive or home directory.

| Logical root | Configure locally as |
|---|---|
| `$ARCHITECTURE_ROOT` | The cloned repository root |
| `$CODEX_HOME` | The recipient's Codex home directory |
| `$EXTERNAL_WORKSPACE` | A recipient-selected parent for other projects |
| `$SOFTWARE_ARCHIVE_ROOT` | Local installer archive directory |
| `$SOFTWARE_INSTALL_ROOT` | Local custom software install directory |
| `$IMAGE_QUARANTINE_ROOT` | Local image-backup quarantine directory |

Set provider and software choices through the local portable skill profile. The
software installer also accepts `SOFTWARE_ARCHIVE_ROOT` and
`SOFTWARE_INSTALL_ROOT`; image migration accepts `CODEX_IMAGE_QUARANTINE_ROOT`;
runtime helpers accept `CONDA_EXE`, `CODEX_PYTHON`, and
`CODEX_PORTABLE_SKILL_PROFILE`. These values are local configuration, not Git
data.

## 中文对照

受 Git 跟踪的文档、知识记录和清单使用逻辑根目录，不写入某个用户的盘符或主目录。`$ARCHITECTURE_ROOT` 指向克隆的仓库根目录，`$CODEX_HOME` 指向接收者的 Codex 主目录，其余逻辑根分别用于外部工作区、安装包归档、软件安装和图像隔离目录。

服务商与软件选择必须写入本地可移植 skill 配置。`SOFTWARE_ARCHIVE_ROOT`、`SOFTWARE_INSTALL_ROOT`、`CODEX_IMAGE_QUARANTINE_ROOT`、`CONDA_EXE`、`CODEX_PYTHON` 与 `CODEX_PORTABLE_SKILL_PROFILE` 都是本地配置，不能提交到 Git。
