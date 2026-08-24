# Linux System Administration

本目录记录 Linux 用户权限、Shell 环境、计划任务、systemd 服务和资源控制。

## 当前内容

| 文档 | 内容 |
|------|------|
| [Shell 配置指南](shell-configuration-guide.md) | bash、zsh、环境变量和配置组织 |
| [用户与用户组](User-Group.md) | 用户和组的创建、修改与删除 |
| [su 与 sudo](Root-Permission.md) | 权限提升 |
| [cron](cron.md) | 定时任务 |
| [systemd unit](systemd-unit.md) | 服务单元配置 |
| [shutdown](shutdown.md) | 关机和重启 |
| [CGroup 与 Systemd Slice](CGroup/README.md) | 资源控制与观测 |

## 推荐学习路径

用户与权限 → Shell 环境 → systemd 服务 → 日志与计划任务 → CGroup 资源控制。

## 未来扩展

- 软件包管理、内核升级、启动流程与故障恢复。
- journal、日志轮转、审计和时间同步。
- 磁盘、文件系统、LVM、配额和备份恢复。
- PAM、ACL、Capabilities、SELinux/AppArmor。
- 系统性能基线、容量规划和自动化运维。
