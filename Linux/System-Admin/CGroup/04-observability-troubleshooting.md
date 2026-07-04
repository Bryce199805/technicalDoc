# 观测与故障排查

cgroup 和 systemd slice 配置完成后，最重要的是确认限制是否真的生效，以及在出现性能问题时能定位是 CPU、内存、IO、进程数还是配置层级导致。

## 快速检查清单

遇到资源问题时，按下面顺序检查：

1. 确认系统是 cgroup v1、v2 还是混合模式。
2. 确认服务当前属于哪个 slice 和 cgroup。
3. 查看 systemd 最终生效配置，而不是只看 unit 文件。
4. 查看 cgroup 统计文件，例如 `cpu.stat`、`memory.events`、`io.stat`、`pids.current`。
5. 查看 journal 中是否有 OOM、restart、permission、limit 相关日志。
6. 确认父级 slice 是否设置了更严格的限制。
7. 区分“资源不足”和“资源被限制”。

## 判断 cgroup 版本

```shell
stat -fc %T /sys/fs/cgroup
```

结果解释：

| 输出 | 含义 |
|------|------|
| `cgroup2fs` | cgroup v2 |
| `tmpfs` | cgroup v1 或混合模式，需要继续查看挂载 |

进一步查看：

```shell
findmnt -T /sys/fs/cgroup
mount | grep cgroup
cat /proc/cgroups
```

## 查看服务所在 cgroup

```shell
systemctl show nginx.service -p Slice -p ControlGroup
```

输出示例：

```text
Slice=apps-web.slice
ControlGroup=/apps.slice/apps-web.slice/nginx.service
```

查看进程：

```shell
systemctl status nginx.service
systemd-cgls /apps.slice/apps-web.slice/nginx.service
```

通过 PID 反查：

```shell
cat /proc/<PID>/cgroup
systemctl status <PID>
```

## 查看最终 systemd 配置

查看 unit 文件和所有 drop-in：

```shell
systemctl cat nginx.service
```

查看关键资源属性：

```shell
systemctl show nginx.service \
  -p Slice \
  -p ControlGroup \
  -p CPUAccounting \
  -p CPUWeight \
  -p CPUQuotaPerSecUSec \
  -p MemoryAccounting \
  -p MemoryCurrent \
  -p MemoryPeak \
  -p MemoryHigh \
  -p MemoryMax \
  -p IOAccounting \
  -p IOWeight \
  -p TasksAccounting \
  -p TasksCurrent \
  -p TasksMax
```

注意：不同 systemd 版本支持的属性略有差异。如果某个属性为空或不存在，需要查看本机 `man systemd.resource-control`。

## 查看 cgroup 底层统计

先取得 cgroup 路径：

```shell
CGROUP=$(systemctl show nginx.service -p ControlGroup --value)
cd /sys/fs/cgroup"$CGROUP"
```

### CPU

```shell
cat cpu.stat
cat cpu.weight
cat cpu.max
```

`cpu.stat` 常见字段：

| 字段 | 含义 |
|------|------|
| `usage_usec` | CPU 总使用时间，微秒 |
| `user_usec` | 用户态 CPU 时间 |
| `system_usec` | 内核态 CPU 时间 |
| `nr_periods` | CPU quota 周期数 |
| `nr_throttled` | 被 CPU quota 限流的周期数 |
| `throttled_usec` | 被限流的总时间 |

判断 CPUQuota 是否造成瓶颈：

- `nr_throttled` 持续增长。
- `throttled_usec` 持续增长。
- 服务延迟升高但整机 CPU 仍有空闲。
- 配置了较低 `CPUQuota`。

### 内存

```shell
cat memory.current
cat memory.peak
cat memory.high
cat memory.max
cat memory.events
cat memory.stat
```

`memory.events` 常见字段：

| 字段 | 含义 |
|------|------|
| `low` | 低内存保护相关事件 |
| `high` | 超过 `memory.high` 的次数 |
| `max` | 达到 `memory.max` 的次数 |
| `oom` | cgroup 内 OOM 次数 |
| `oom_kill` | OOM kill 次数 |

判断 MemoryHigh 是否太低：

- `memory.events` 中 `high` 持续增长。
- 服务 CPU 没满但延迟升高。
- `memory.current` 长期贴近 `memory.high`。

判断 MemoryMax 是否导致 OOM：

- `memory.events` 中 `oom` 或 `oom_kill` 增长。
- `journalctl -u <service> -b` 出现 killed process 或 OOM 信息。
- `systemctl status` 显示服务异常退出后重启。

### IO

```shell
cat io.stat
cat io.weight
cat io.max
```

`io.stat` 示例字段：

| 字段 | 含义 |
|------|------|
| `rbytes` | 读取字节数 |
| `wbytes` | 写入字节数 |
| `rios` | 读 IO 次数 |
| `wios` | 写 IO 次数 |
| `dbytes` | discard 字节数 |
| `dios` | discard IO 次数 |

如果配置了 `IOReadBandwidthMax` 或 `IOWriteBandwidthMax`，要确认 `io.max` 是否写入了对应设备限制。

### PID

```shell
cat pids.current
cat pids.max
cat pids.events
```

如果 `pids.current` 接近 `pids.max`，服务可能出现：

- 无法创建线程。
- `fork: Resource temporarily unavailable`。
- Java 或 Go 运行时报线程创建失败。
- Nginx、数据库、队列 worker 无法扩容进程。

## systemd-cgtop

`systemd-cgtop` 可以按 cgroup 查看实时资源使用。

```shell
systemd-cgtop
```

常用操作：

| 按键 | 作用 |
|------|------|
| `P` | 按 CPU 排序 |
| `M` | 按内存排序 |
| `I` | 按 IO 排序 |
| `T` | 按 task 数排序 |
| `q` | 退出 |

它适合快速观察，但不替代监控系统。生产环境仍应接入 Prometheus、node_exporter、cAdvisor 或 systemd exporter 等工具。

## journalctl 排查

查看服务日志：

```shell
journalctl -u nginx.service -b
```

查看内核日志：

```shell
journalctl -k -b
```

搜索 OOM：

```shell
journalctl -k -b | grep -i oom
journalctl -b | grep -i "memory\|oom\|killed"
```

如果避免使用 `grep`，也可以使用 journalctl 的匹配能力或在日志系统中检索关键字。

## 常见故障场景

### 场景一：服务 CPU 没用满但延迟很高

可能原因：

- `CPUQuota` 限制过低。
- 父级 slice 有 CPU quota。
- 服务被固定到少数 CPU 核。
- 内存高水位触发回收，表现为 CPU 不高但请求慢。
- IO 限制导致线程等待。

检查：

```shell
systemctl show example.service -p CPUQuotaPerSecUSec -p AllowedCPUs -p Slice -p ControlGroup
cat /sys/fs/cgroup/<path>/cpu.stat
cat /sys/fs/cgroup/<path>/memory.events
cat /sys/fs/cgroup/<path>/io.stat
```

重点看 `nr_throttled` 和 `throttled_usec` 是否增长。

### 场景二：服务频繁重启

可能原因：

- `MemoryMax` 太低导致 cgroup OOM。
- `TasksMax` 太低导致无法创建线程。
- `Restart=always` 掩盖了资源限制问题。
- 服务自身 bug 导致内存泄漏。

检查：

```shell
systemctl status example.service
journalctl -u example.service -b
journalctl -k -b | grep -i oom
systemctl show example.service -p MemoryCurrent -p MemoryPeak -p MemoryMax -p TasksCurrent -p TasksMax
cat /sys/fs/cgroup/<path>/memory.events
cat /sys/fs/cgroup/<path>/pids.events
```

### 场景三：设置了 IOWeight 但看不出效果

可能原因：

- 当前没有 IO 竞争。
- 设备或调度器对权重支持有限。
- 实际瓶颈在网络、远端存储或应用锁，而不是本地块设备。
- 服务写的是不同挂载点或不同设备。

检查：

```shell
findmnt /var/lib/example
lsblk
cat /sys/fs/cgroup/<path>/io.weight
cat /sys/fs/cgroup/<path>/io.stat
```

### 场景四：服务没有进入指定 slice

可能原因：

- 修改了 unit 但没有 `systemctl daemon-reload`。
- 修改了 `Slice=` 但没有重启服务。
- drop-in 写错 section，例如把 `Slice=` 写到 `[Unit]`。
- unit 名称或实例服务名称写错。

检查：

```shell
systemctl cat example.service
systemctl show example.service -p FragmentPath -p DropInPaths -p Slice -p ControlGroup
systemctl restart example.service
```

### 场景五：父 slice 限制导致子服务异常

可能原因：

- 父 slice 的 `MemoryMax`、`CPUQuota`、`TasksMax` 更严格。
- 多个服务共享父 slice，总量达到限制。
- 只检查了 service，没有检查父级。

检查父级链路：

```shell
systemctl show example.service -p Slice -p ControlGroup
systemctl show apps.slice -p CPUQuotaPerSecUSec -p MemoryCurrent -p MemoryMax -p TasksCurrent -p TasksMax
systemctl show apps-web.slice -p CPUQuotaPerSecUSec -p MemoryCurrent -p MemoryMax -p TasksCurrent -p TasksMax
```

## 变更前后记录模板

每次修改资源限制前后建议记录：

```shell
date
hostname
systemctl cat example.service
systemctl show example.service \
  -p Slice \
  -p ControlGroup \
  -p CPUWeight \
  -p CPUQuotaPerSecUSec \
  -p MemoryCurrent \
  -p MemoryPeak \
  -p MemoryHigh \
  -p MemoryMax \
  -p IOWeight \
  -p TasksCurrent \
  -p TasksMax
systemd-cgls example.service
journalctl -u example.service -b --no-pager
```

## 排障思路总结

| 症状 | 优先检查 |
|------|----------|
| 延迟高但 CPU 不满 | `cpu.stat`、`memory.events`、IO 等待、父级 quota |
| 服务被杀 | `memory.events`、`journalctl -k`、`OOMPolicy` |
| 无法创建线程 | `pids.current`、`pids.max`、`TasksMax` |
| 后台任务影响业务 | slice 分层、`CPUWeight`、`IOWeight`、`CPUQuota` |
| 限制没生效 | `systemctl cat`、`systemctl show`、是否重启服务 |
| 只有部分服务异常 | 父 slice 总限制、兄弟服务资源竞争 |

## 下一步

继续阅读 [生产实践手册](05-production-playbook.md)，把排障和配置知识整理成可执行的生产流程。
