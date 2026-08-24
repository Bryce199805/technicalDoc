# 07 存储管理

---

## 7.1 存储池

libvirt 通过存储池（Storage Pool）管理磁盘镜像的存放位置。

### 默认存储池

安装 libvirt 后自动创建 `default` 存储池，指向 `/var/lib/libvirt/images/`：

```bash
# 查看存储池
virsh pool-list --all

# 输出示例：
#  Name     State    Autostart
# ------------------------------
#  default  active   yes

# 查看存储池详情
virsh pool-dumpxml default

# 查看存储池内的卷
virsh vol-list default

# 查看存储池容量
virsh pool-info default
```

### 创建存储池

```bash
# 创建目录类型的存储池
virsh pool-define-as <pool-name> dir - - - - "/path/to/dir"
virsh pool-build <pool-name>
virsh pool-start <pool-name>
virsh pool-autostart <pool-name>
```

### 存储池管理命令

```bash
# 列出
virsh pool-list --all

# 启动/停止
virsh pool-start <pool-name>
virsh pool-destroy <pool-name>

# 删除
virsh pool-undefine <pool-name>
virsh pool-delete <pool-name>   # 删除存储池目录及内容，慎用

# 刷新（扫描新文件）
virsh pool-refresh <pool-name>
```

---

## 7.2 磁盘格式

### qcow2 vs raw

| 特性 | qcow2 | raw |
|------|-------|-----|
| 精简分配 | 支持（初始只占实际使用量） | 不支持（立即占满分配大小） |
| 快照 | 支持 | 不支持 |
| 加密 | 支持（LUKS） | 不支持 |
| 压缩 | 支持 | 不支持 |
| 性能 | 接近原生（~1-3% 损耗） | 最优 |
| 适用场景 | 日常使用，推荐 | 极致 I/O 性能需求 |

### 创建磁盘

```bash
# 创建 qcow2 磁盘
qemu-img create -f qcow2 /path/to/disk.qcow2 80G

# 创建 raw 磁盘
qemu-img create -f raw /path/to/disk.raw 80G

# 创建带预分配的 qcow2（性能更好，但立即占满空间）
qemu-img create -f qcow2 -o preallocation=full /path/to/disk.qcow2 80G
```

### 查看磁盘信息

```bash
qemu-img info /path/to/disk.qcow2

# 输出示例：
# image: /var/lib/libvirt/images/kali.qcow2
# file format: qcow2
# virtual size: 80 GiB (85899345920 bytes)
# disk size: 4.2 GiB          ← 实际占用
# cluster_size: 65536
# Format specific information:
#     compat: 1.1
#     lazy refcounts: true
#     refcount bits: 16
#     corrupt: false
```

### 格式转换

```bash
# raw 转 qcow2
qemu-img convert -f raw -O qcow2 input.raw output.qcow2

# qcow2 转 raw
qemu-img convert -f qcow2 -O raw input.qcow2 output.raw

# 转换并压缩
qemu-img convert -f qcow2 -O qcow2 -c input.qcow2 output-compressed.qcow2
```

---

## 7.3 磁盘扩容

### 扩大虚拟磁盘

```bash
# 1. 关机
virsh shutdown <vm-name>

# 2. 扩容（只能扩大，不能缩小）
qemu-img resize /var/lib/libvirt/images/<vm-name>.qcow2 120G

# 3. 启动虚拟机
virsh start <vm-name>

# 4. 在虚拟机内扩展分区
# Linux:
sudo parted /dev/vda resizepart 1 100%
sudo resize2fs /dev/vda1          # ext4
# 或 sudo xfs_growfs /             # xfs
```

### 添加新磁盘

```bash
# 1. 创建新磁盘
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/<vm-name>-data.qcow2 200G

# 2. 在线附加
virsh attach-disk <vm-name> /var/lib/libvirt/images/<vm-name>-data.qcow2 vdb \
  --driver qemu --subdriver qcow2 --live --persistent

# 3. 在虚拟机内格式化和挂载
sudo mkfs.ext4 /dev/vdb
sudo mkdir -p /mnt/data
sudo mount /dev/vdb /mnt/data
```

### 卸载磁盘

```bash
# 在线卸载
virsh detach-disk <vm-name> vdb --live --persistent
```

---

## 7.4 磁盘备份

### 完整备份

```bash
# 关机后直接复制
virsh shutdown <vm-name>
sudo cp /var/lib/libvirt/images/<vm-name>.qcow2 /backup/<vm-name>-$(date +%Y%m%d).qcow2

# 使用 qemu-img 转换（合并快照，减小文件）
sudo qemu-img convert -f qcow2 -O qcow2 \
  /var/lib/libvirt/images/<vm-name>.qcow2 \
  /backup/<vm-name>-$(date +%Y%m%d).qcow2
```

### 增量备份

```bash
# 创建外部快照作为增量备份
virsh snapshot-create-as <vm-name> --name "backup-$(date +%Y%m%d)" \
  --disk-only --atomic --no-metadata

# 备份原始磁盘（此时原始磁盘是备份点）
# 新写入的数据会进入新的覆盖层
```
