# 06 快照管理

---

## 6.1 快照原理

快照保存虚拟机在某一时刻的完整状态（磁盘 + 可选的内存），可随时回滚。

### 快照类型

| 类型 | 保存内容 | 需要关机 | 性能影响 |
|------|---------|---------|---------|
| **内部快照** | 磁盘 + 内存 | 不需要（推荐关机） | 较大，存储在 qcow2 文件内 |
| **外部快照** | 新建覆盖层 | 不需要 | 较小，创建覆盖文件 |

> 日常使用内部快照即可，外部快照管理更复杂。

### 快照的限制

- 仅 `qcow2` 格式支持快照，`raw` 格式不支持
- 快照不是备份——如果 qcow2 文件损坏，所有快照都不可用
- 长链快照会降低性能，建议定期合并

---

## 6.2 快照操作

### 创建快照

```bash
# 创建带名称和描述的快照
virsh snapshot-create-as <vm-name> \
  --name "snapshot-name" \
  --description "安装完系统，SSH 已开启"

# 创建自动命名的快照（用时间戳命名）
virsh snapshot-create <vm-name>
```

> 建议在关机状态下创建快照，避免内存状态不一致。

### 查看快照

```bash
# 列出所有快照
virsh snapshot-list <vm-name>

# 输出示例：
#  Name               Creation Time               State
#  -----------------------------------------------------------
#  fresh-install       2026-04-10 15:30:00 +0800   shutoff
#  before-update       2026-04-10 16:00:00 +0800   shutoff

# 查看快照详情
virsh snapshot-info <vm-name> --snapshotname "snapshot-name"

# 查看当前快照
virsh snapshot-current <vm-name>

# 查看快照的 XML 配置
virsh snapshot-dumpxml <vm-name> --snapshotname "snapshot-name"
```

### 恢复快照

```bash
# 恢复到指定快照（VM 必须关机）
virsh snapshot-revert <vm-name> --snapshotname "snapshot-name"

# 恢复到当前快照
virsh snapshot-revert <vm-name> --current
```

### 删除快照

```bash
# 删除指定快照
virsh snapshot-delete <vm-name> --snapshotname "snapshot-name"

# 删除当前快照
virsh snapshot-delete <vm-name> --current
```

---

## 6.3 快照最佳实践

### 推荐的快照策略

```
安装完成 → snapshot: "fresh-install"     ← 必做
开启 SSH → snapshot: "ssh-ready"         ← 建议做
安装工具 → snapshot: "tools-installed"   ← 按需做
重大变更 → snapshot: "before-xxx"        ← 变更前做
```

### 命名建议

```
<状态描述>-<日期>
如: fresh-install-20260410
如: before-kernel-upgrade-20260410
```

### 注意事项

1. **关机后创建快照**：避免内存状态不一致
2. **不要过度依赖快照**：快照不是备份，定期做完整备份
3. **及时清理旧快照**：长链快照影响性能
4. **重要操作前创建快照**：如系统升级、安装可疑软件
5. **快照链过长时合并**：

```bash
# 合并快照（blockcommit），将中间层合并到基盘
virsh blockcommit <vm-name> vda --pivot
```

---

## 6.4 快照与备份的区别

| | 快照 | 备份 |
|---|---|---|
| 位置 | 同一个 qcow2 文件 | 独立存储 |
| 依赖 | 依赖原始磁盘文件 | 独立完整 |
| 速度 | 秒级创建/恢复 | 较慢 |
| 安全性 | 磁盘损坏则全部丢失 | 独立存储，互不影响 |
| 用途 | 短期回滚 | 长期保存 |

### 做完整备份

```bash
# 关机后复制磁盘文件
virsh shutdown <vm-name>
sudo cp /var/lib/libvirt/images/<vm-name>.qcow2 /backup/<vm-name>-$(date +%Y%m%d).qcow2

# 或使用 qemu-img 转换（可去除快照，减小文件）
sudo qemu-img convert -f qcow2 -O qcow2 \
  /var/lib/libvirt/images/<vm-name>.qcow2 \
  /backup/<vm-name>-$(date +%Y%m%d).qcow2
```
