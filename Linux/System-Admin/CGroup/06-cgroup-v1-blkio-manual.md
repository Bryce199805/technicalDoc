# CGroup v1 blkio 手工限速

本篇专门记录 cgroup v1 的 `blkio` 控制器手工操作方法，适合维护历史系统、混合 cgroup 环境，或者临时把某个问题进程迁移到受限 IO 组中。

你提到的操作属于这一类：

```shell
sudo mkdir /sys/fs/cgroup/blkio/user.slice/io-limit
echo "253:0 30" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
echo "253:0 10" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_iops_device
echo 1450162 | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/cgroup.procs
```

核心含义是：创建一个 cgroup v1 `blkio` 子组，对指定块设备设置 IOPS 或带宽上限，然后把问题进程 PID 写入该组的 `cgroup.procs`，让内核对该进程组执行 IO 限速。

## 适用前提

这种方法只适用于 cgroup v1 的 `blkio` 控制器路径存在的系统。

检查路径：

```shell
mount | grep blkio
findmnt /sys/fs/cgroup/blkio
ls /sys/fs/cgroup/blkio
```

如果系统是纯 cgroup v2，通常不会有 `/sys/fs/cgroup/blkio`，而是使用 `/sys/fs/cgroup` 下的 `io.*` 文件，或通过 systemd 的 `IOReadBandwidthMax=`、`IOWriteBandwidthMax=`、`IOReadIOPSMax=`、`IOWriteIOPSMax=` 配置。

检查 cgroup 类型：

```shell
stat -fc %T /sys/fs/cgroup
```

常见结果：

| 输出 | 含义 |
|------|------|
| `cgroup2fs` | cgroup v2 统一层级，优先使用 `io.max` 或 systemd IO 参数 |
| `tmpfs` | 可能是 cgroup v1 或混合模式，需要继续查看 `mount` |

## blkio 控制器是什么

`blkio` 是 cgroup v1 中用于块设备 IO 控制的 controller。它可以对某个 cgroup 内的进程施加 IO 权重、IOPS 上限、读写带宽上限，并统计该组的块设备 IO 行为。

常见控制文件：

| 文件 | 作用 |
|------|------|
| `blkio.throttle.read_iops_device` | 限制指定设备读 IOPS |
| `blkio.throttle.write_iops_device` | 限制指定设备写 IOPS |
| `blkio.throttle.read_bps_device` | 限制指定设备读带宽，单位 B/s |
| `blkio.throttle.write_bps_device` | 限制指定设备写带宽，单位 B/s |
| `blkio.throttle.io_service_bytes` | 按设备统计实际读写字节 |
| `blkio.throttle.io_serviced` | 按设备统计实际 IO 次数 |
| `blkio.weight` | 设置该 cgroup 的相对 IO 权重 |
| `cgroup.procs` | 把进程迁入或查看当前进程 |
| `tasks` | 查看或迁移线程，v1 中常见 |

其中 `blkio.throttle.*` 是硬限速接口，适合临时约束异常程序。`blkio.weight` 是相对权重，只有在竞争时体现。

## 设备号的含义

`253:0 30` 中的 `253:0` 是块设备的主设备号和次设备号，`30` 是限制值。

格式是：

```text
<major>:<minor> <limit>
```

例如：

```text
253:0 30
```

表示对主设备号 `253`、次设备号 `0` 的块设备设置限制值 `30`。

不同文件中限制值单位不同：

| 文件 | limit 单位 | 示例含义 |
|------|------------|----------|
| `blkio.throttle.read_iops_device` | 次/秒 | `253:0 30` 表示读 IOPS 上限 30 |
| `blkio.throttle.write_iops_device` | 次/秒 | `253:0 10` 表示写 IOPS 上限 10 |
| `blkio.throttle.read_bps_device` | B/s | `253:0 2097152` 表示读带宽上限 2 MiB/s |
| `blkio.throttle.write_bps_device` | B/s | `253:0 1048576` 表示写带宽上限 1 MiB/s |

## 如何找到正确设备号

### 使用 lsblk

```shell
lsblk -o NAME,MAJ:MIN,SIZE,TYPE,MOUNTPOINTS
```

示例：

```text
NAME        MAJ:MIN SIZE TYPE MOUNTPOINTS
sda           8:0   200G disk
├─sda1        8:1   512M part /boot
└─sda2        8:2 199.5G part /
nvme0n1     259:0   1T disk
└─nvme0n1p1 259:1   1T part /data
dm-0        253:0   100G lvm  /var/lib/app
```

如果你的程序主要读写 `/var/lib/app`，而该目录挂载在 `dm-0`，那么对应设备号可能是 `253:0`。

如果程序读写的是普通磁盘 `/dev/sda`，设备号可能是 `8:0`。

### 使用 findmnt 定位路径所在设备

```shell
findmnt -T /path/to/problem/data -o TARGET,SOURCE,FSTYPE,OPTIONS
```

然后再用：

```shell
lsblk -o NAME,MAJ:MIN,SIZE,TYPE,MOUNTPOINTS
```

确认 `SOURCE` 对应的 `MAJ:MIN`。

### 使用 stat 查看设备号

```shell
stat -c '%D %d %n' /path/to/problem/data
```

这个输出更偏底层，不如 `findmnt` 和 `lsblk` 直观。日常维护推荐优先用 `findmnt -T` 加 `lsblk`。

## 253:0 与 8:0 的常见含义

| 设备号 | 常见设备类型 | 说明 |
|--------|--------------|------|
| `8:0` | `/dev/sda` | 第一块 SCSI/SATA/SAS 磁盘，也可能是虚拟磁盘 |
| `8:16` | `/dev/sdb` | 第二块 SCSI/SATA/SAS 磁盘 |
| `253:0` | `/dev/dm-0` | device-mapper 设备，常见于 LVM、dm-crypt、multipath |
| `259:0` | `/dev/nvme0n1` | NVMe 设备常见主设备号，具体以本机为准 |

设备号不是固定业务语义，必须以当前机器 `lsblk` 输出为准。

## IOPS 限制与带宽限制

### IOPS 限制

IOPS 限制控制每秒 IO 请求次数。

```shell
echo "253:0 30" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
echo "253:0 10" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_iops_device
```

含义：

- 对设备 `253:0`，读请求最多约 `30` 次/秒。
- 对设备 `253:0`，写请求最多约 `10` 次/秒。

适合场景：

- 小块随机读写过多。
- 某个进程产生大量 metadata IO。
- 限制恶意或异常程序频繁触发磁盘请求。

### BPS 限制

BPS 限制控制每秒字节数。

```shell
echo "253:0 2097152" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_bps_device
echo "253:0 1048576" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_bps_device
```

含义：

- `2097152` B/s 等于 `2 MiB/s`。
- `1048576` B/s 等于 `1 MiB/s`。

适合场景：

- 大文件扫描、备份、压缩、归档。
- 顺序读写吞吐过大影响业务。
- 希望限制总体磁盘带宽，而不是 IO 次数。

## IOPS 与 BPS 怎么选

| 问题类型 | 优先限制 | 原因 |
|----------|----------|------|
| 小文件随机读写多 | IOPS | 请求次数才是主要压力 |
| 大文件连续读写 | BPS | 吞吐量才是主要压力 |
| 备份、拷贝、压缩 | BPS | 通常是顺序大吞吐 |
| 数据库随机 IO 冲击 | IOPS 或权重 | 随机 IO 受 IOPS 影响明显 |
| 无法判断 | 同时观察 `io_serviced` 和 `io_service_bytes` | 先看实际行为再限制 |

实际维护中可以先设置温和的 BPS 上限，再根据 `blkio.throttle.io_serviced` 判断是否需要 IOPS 限制。

## 多设备限制

如果程序可能访问多个设备，需要分别写入多行限制。例如同时限制 `253:0` 和 `8:0`：

```shell
echo "253:0 30" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
echo "8:0 30" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
```

写入后查看：

```shell
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
```

注意：不同内核版本对同一文件重复写入的行为可能表现为追加、替换同设备限制或更新同设备限制。维护时不要假设写入成功等于规则最终符合预期，必须 `cat` 回读确认。

## 创建限速 cgroup

路径选择要有明确目的。你的示例：

```text
/sys/fs/cgroup/blkio/user.slice/io-limit
```

表示在 v1 `blkio` 控制器下、`user.slice` 对应层级中创建 `io-limit` 子组。

创建：

```shell
sudo mkdir /sys/fs/cgroup/blkio/user.slice/io-limit
```

如果只是临时隔离某个用户会话中的问题程序，这样放在 `user.slice` 下是合理的。

如果是系统服务进程，更建议找到它当前在 `blkio` controller 下的位置，然后在对应父级下创建子组，避免和 systemd 的层级管理冲突。

## 把进程迁入 cgroup

将 PID 写入 `cgroup.procs`：

```shell
echo 1450162 | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/cgroup.procs
```

含义：把 PID `1450162` 对应进程迁入该 `blkio` cgroup。迁入后，该进程及其后续子进程通常会继承该 cgroup 的 IO 限制。

确认：

```shell
cat /proc/1450162/cgroup
cat /sys/fs/cgroup/blkio/user.slice/io-limit/cgroup.procs
```

注意：

- 如果进程已经退出，写入会失败。
- 如果权限不足，写入会失败。
- 如果目标 cgroup 不存在，写入会失败。
- 如果进程属于 systemd 管理的服务，systemd 在重启或重新加载时可能把进程重新放回 unit 对应 cgroup。
- 只迁移某一个 PID 可能不够，问题程序如果有多个 worker 或线程，需要确认整个进程树。

## cgroup.procs 与 tasks 的区别

在 cgroup v1 中常见两个文件：

| 文件 | 作用 |
|------|------|
| `cgroup.procs` | 按进程迁移或查看进程组 ID |
| `tasks` | 按线程迁移或查看 task ID |

日常维护优先使用 `cgroup.procs`，因为你通常想移动整个进程，而不是只移动某个线程。

如果一个多线程程序的线程没有完全受限，可以检查：

```shell
cat /sys/fs/cgroup/blkio/user.slice/io-limit/tasks
```

但不要随意按线程拆分 IO 限制，否则排障会变得非常困难。

## 查看限制是否写入成功

```shell
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_iops_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_bps_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_bps_device
```

预期能看到类似：

```text
253:0 30
8:0 30
```

如果没有输出，说明该文件当前没有对应限制。

## 查看限速效果

### 查看 blkio 统计

```shell
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.io_service_bytes
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.io_serviced
```

常见字段含义：

| 字段 | 含义 |
|------|------|
| `Read` | 读方向统计 |
| `Write` | 写方向统计 |
| `Sync` | 同步 IO |
| `Async` | 异步 IO |
| `Total` | 总计 |

### 查看进程 IO

```shell
pidstat -d -p 1450162 1
iotop -p 1450162
cat /proc/1450162/io
```

如果系统没有这些工具，可以先用 `/proc/<PID>/io` 和 cgroup 的 `blkio.throttle.*` 统计文件排查。

### 查看设备总体压力

```shell
iostat -xz 1
lsblk -o NAME,MAJ:MIN,SIZE,TYPE,MOUNTPOINTS
```

重点关注：

- `r/s`、`w/s` 是否下降。
- `rkB/s`、`wkB/s` 是否下降。
- `await` 是否改善。
- `%util` 是否下降。
- 业务服务延迟是否恢复。

## 修改限制

对同一设备再次写入通常用于更新限制：

```shell
echo "253:0 60" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
```

写完必须回读确认：

```shell
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
```

## 删除限制

cgroup v1 `blkio.throttle.*` 的删除方式因内核版本和接口而异，常见方式是对同一设备写入 `0` 表示取消限制：

```shell
echo "253:0 0" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
echo "253:0 0" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_iops_device
echo "253:0 0" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_bps_device
echo "253:0 0" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_bps_device
```

然后回读确认：

```shell
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_iops_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_bps_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_bps_device
```

如果写 `0` 不被当前内核接受，可以创建新的 cgroup，把进程迁出旧组，再删除旧 cgroup。

## 迁出进程与删除 cgroup

先把进程迁回父级：

```shell
echo 1450162 | sudo tee /sys/fs/cgroup/blkio/user.slice/cgroup.procs
```

确认限速组为空：

```shell
cat /sys/fs/cgroup/blkio/user.slice/io-limit/cgroup.procs
cat /sys/fs/cgroup/blkio/user.slice/io-limit/tasks
```

删除：

```shell
sudo rmdir /sys/fs/cgroup/blkio/user.slice/io-limit
```

如果 `rmdir` 失败，通常说明还有进程或子 cgroup 未迁出。

## 与 systemd 的关系

在 systemd 系统中，`user.slice`、`system.slice` 等目录通常由 systemd 创建。你手工在其中创建 `io-limit` 子 cgroup，属于直接操作底层 cgroup 文件。

优点：

- 立即生效。
- 适合临时处理问题进程。
- 不需要改 service 文件或重启服务。
- 可以精确迁移某个 PID。

风险：

- 不持久，重启后消失。
- systemd 可能在服务重启时重新组织进程。
- 手工迁移 systemd service 的进程可能让 `systemctl status`、资源统计和清理行为变得不直观。
- cgroup v1 各 controller 独立层级，迁移 `blkio` 只影响 IO controller，不等于也迁移了 CPU、memory controller。

如果需要长期维护，优先使用 systemd unit 或 slice 的 IO 参数：

```ini
[Service]
IOReadIOPSMax=/dev/dm-0 30
IOWriteIOPSMax=/dev/dm-0 10
IOReadBandwidthMax=/dev/dm-0 2M
IOWriteBandwidthMax=/dev/dm-0 1M
```

如果只是处理正在失控的问题 PID，手工 v1 `blkio` 限速是有效的应急手段。

## cgroup v1 blkio 与 cgroup v2 io 对照

| 目标 | cgroup v1 blkio | cgroup v2 io | systemd 参数 |
|------|-----------------|--------------|--------------|
| 读 IOPS | `blkio.throttle.read_iops_device` | `io.max` | `IOReadIOPSMax=` |
| 写 IOPS | `blkio.throttle.write_iops_device` | `io.max` | `IOWriteIOPSMax=` |
| 读带宽 | `blkio.throttle.read_bps_device` | `io.max` | `IOReadBandwidthMax=` |
| 写带宽 | `blkio.throttle.write_bps_device` | `io.max` | `IOWriteBandwidthMax=` |
| IO 权重 | `blkio.weight` | `io.weight` | `IOWeight=` |
| 迁移进程 | `cgroup.procs` | `cgroup.procs` | `Slice=` 或 systemd scope/service |

cgroup v2 的 `io.max` 示例：

```shell
echo "253:0 rbps=2097152 wbps=1048576 riops=30 wiops=10" | sudo tee /sys/fs/cgroup/<group>/io.max
```

但在 systemd 管理的系统上，长期配置仍建议写入 unit 或 slice。

## 应急操作 runbook

### 1. 确认问题进程

```shell
ps -fp 1450162
cat /proc/1450162/cgroup
cat /proc/1450162/io
```

### 2. 确认问题数据路径和设备号

```shell
findmnt -T /path/to/problem/data
lsblk -o NAME,MAJ:MIN,SIZE,TYPE,MOUNTPOINTS
```

### 3. 创建限速组

```shell
sudo mkdir /sys/fs/cgroup/blkio/user.slice/io-limit
```

### 4. 设置限速

```shell
echo "253:0 30" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
echo "253:0 10" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_iops_device
echo "253:0 2097152" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_bps_device
echo "253:0 1048576" | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_bps_device
```

### 5. 迁移进程

```shell
echo 1450162 | sudo tee /sys/fs/cgroup/blkio/user.slice/io-limit/cgroup.procs
```

### 6. 验证

```shell
cat /proc/1450162/cgroup
cat /sys/fs/cgroup/blkio/user.slice/io-limit/cgroup.procs
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.read_iops_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.write_iops_device
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.io_service_bytes
cat /sys/fs/cgroup/blkio/user.slice/io-limit/blkio.throttle.io_serviced
```

### 7. 观察影响

```shell
cat /proc/1450162/io
iostat -xz 1
systemd-cgtop
```

### 8. 撤销

```shell
echo 1450162 | sudo tee /sys/fs/cgroup/blkio/user.slice/cgroup.procs
sudo rmdir /sys/fs/cgroup/blkio/user.slice/io-limit
```

## 常见错误

### 写错设备号

限制写入成功，但问题程序实际访问的是另一个设备，导致看起来“不生效”。先用 `findmnt -T` 确认路径，再用 `lsblk` 查 `MAJ:MIN`。

### 只限制了物理盘，没有限制 dm 设备

如果业务路径在 LVM 或 dm-crypt 上，可能需要限制 `/dev/dm-*` 对应的 `253:*`，而不是底层 `/dev/sd*`。具体行为和内核、栈结构有关，必须实测。

### 只迁移了父进程，没有迁移实际 worker

很多程序主进程不直接做 IO，实际 IO 来自子进程。要用 `pstree -p <PID>` 或 `ps --ppid` 找到实际 worker，并确认 `cgroup.procs` 中包含相关进程。

### 限制太低导致程序假死

过低的 IOPS 或 BPS 会让程序长时间阻塞在 IO 上，看起来像假死。建议从温和限制开始，再逐步收紧。

### 期望限制网络 IO

`blkio` 限制的是块设备 IO，不限制网络带宽。如果问题来自 NFS、对象存储、HTTP 下载或数据库网络请求，`blkio` 不一定能解决。

### 忽略 page cache

Linux 文件 IO 会经过 page cache。读请求如果命中缓存，可能不触发底层块设备读 IO，因此看起来不受 `blkio` 读限制影响。写入也可能先进入缓存，之后由内核回写线程刷盘，表现会更复杂。

## 维护建议

- 把手工限速视为应急措施，不要当成长期配置管理方案。
- 每次操作记录 PID、设备号、限制值、时间、撤销方式。
- 操作前先确认进程和设备路径，避免限制错对象。
- 对 systemd service 的长期 IO 限制，优先使用 `systemctl edit` 配置 systemd IO 参数。
- 对一次性问题进程，使用手工 `blkio` cgroup 可以快速止血。
- 操作后必须回读 `blkio.throttle.*` 文件和 `cgroup.procs` 确认状态。
