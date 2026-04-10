# 05 虚拟机管理

---

## 5.1 生命周期管理

### 启动

```bash
virsh start <vm-name>

# 启动并连接控制台
virsh start <vm-name> --console

# 启动并暂停（调试用）
virsh start <vm-name> --paused
```

### 关机

```bash
# 优雅关机（需要 VM 内安装了 acpid 或 qemu-guest-agent）
virsh shutdown <vm-name>

# 指定超时时间（秒）
virsh shutdown <vm-name> --timeout 60

# 强制关机（相当于拔电源，可能丢失数据）
virsh destroy <vm-name>
```

> 优先使用 `shutdown`，只有 VM 无响应时才用 `destroy`。

### 重启

```bash
virsh reboot <vm-name>
```

### 暂停与恢复

```bash
# 暂停（VM 状态保存在内存中，不释放资源）
virsh suspend <vm-name>

# 恢复
virsh resume <vm-name>
```

### 保存与恢复状态

```bash
# 保存 VM 状态到文件（VM 被完全停止，释放资源）
virsh save <vm-name> /var/lib/libvirt/qemu/save/<vm-name>.save

# 从保存文件恢复
virsh restore /var/lib/libvirt/qemu/save/<vm-name>.save
```

---

## 5.2 查看信息

### 列表与状态

```bash
# 列出所有虚拟机
virsh list --all

# 输出示例：
#  Id   Name   State
# --------------------
#  1    kali   running
#  -    win11  shut off

# 查看单个 VM 状态
virsh domstate <vm-name>

# 查看详细信息
virsh dominfo <vm-name>

# 查看 VM 的 UUID
virsh domuuid <vm-name>
```

### 资源使用

```bash
# 查看 CPU 使用率
virsh cpu-stats <vm-name>

# 查看内存使用
virsh dommemstat <vm-name>

# 查看块设备（磁盘）
virsh domblklist <vm-name>

# 查看网络接口
virsh domiflist <vm-name>

# 查看 VNC 端口
virsh vncdisplay <vm-name>
```

---

## 5.3 开机自启

```bash
# 设置开机自启
virsh autostart <vm-name>

# 取消开机自启
virsh autostart <vm-name> --disable

# 查看自启状态
virsh dominfo <vm-name> | grep "Autostart"
```

---

## 5.4 修改配置

### 编辑 XML 配置

```bash
# 编辑配置（需要关机状态）
virsh edit <vm-name>

# 查看当前运行时配置
virsh dumpxml <vm-name>

# 查看持久化配置（非运行时）
virsh dumpxml <vm-name> --inactive
```

### 常见配置修改

**修改内存**：

```xml
<!-- 修改 <memory>（最大值）和 <currentMemory>（当前值），单位 KiB -->
<memory unit='KiB'>8388608</memory>      <!-- 8GB -->
<currentMemory unit='KiB'>4194304</currentMemory>  <!-- 4GB -->
```

**修改 vCPU**：

```xml
<vcpu placement='static'>4</vcpu>
```

**添加磁盘**：

```xml
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2'/>
  <source file='/var/lib/libvirt/images/<vm-name>-data.qcow2'/>
  <target dev='vdb' bus='virtio'/>
</disk>
```

**添加网卡**：

```xml
<interface type='network'>
  <source network='isolated'/>
  <model type='virtio'/>
</interface>
```

### 在线调整

```bash
# 在线调整内存（不能超过 <memory> 最大值）
virsh setmem <vm-name> 4G

# 在线添加 CPU（不能超过 <vcpu> 最大值）
virsh setvcpus <vm-name> 4

# 在线附加磁盘
virsh attach-disk <vm-name> /var/lib/libvirt/images/data.qcow2 vdb --live --persistent

# 在线卸载磁盘
virsh detach-disk <vm-name> vdb --live --persistent
```

---

## 5.5 删除虚拟机

```bash
# 1. 关机
virsh destroy <vm-name>

# 2. 取消定义（只删除 XML 配置）
virsh undefine <vm-name>

# 3. 同时删除磁盘文件
virsh undefine <vm-name> --remove-all-storage

# 4. 删除带 UEFI/NVRAM 的 VM
virsh undefine <vm-name> --nvram

# 5. 删除有快照的 VM（需先删除快照或加 --snapshots-metadata）
virsh undefine <vm-name> --snapshots-metadata
```

---

## 5.6 克隆虚拟机

```bash
# 需要安装 virtinst
sudo apt install -y virtinst

# 克隆（源 VM 必须关机）
sudo virt-clone \
  --original <source-vm> \
  --name <new-vm> \
  --file /var/lib/libvirt/images/<new-vm>.qcow2
```

克隆特点：
- 生成新的 UUID 和 MAC 地址
- 磁盘完整复制
- 需要在新 VM 内修改 hostname 和 IP 配置

---

## 5.7 迁移虚拟机

### 离线迁移

```bash
# 导出 VM 配置
virsh dumpxml <vm-name> > <vm-name>.xml

# 复制磁盘和配置到目标主机
scp /var/lib/libvirt/images/<vm-name>.qcow2 target-host:/var/lib/libvirt/images/
scp <vm-name>.xml target-host:~

# 在目标主机上定义 VM
virsh define <vm-name>.xml
```

### 在线迁移

需要共享存储（如 NFS、Ceph），且两端 libvirt 版本兼容：

```bash
virsh migrate --live <vm-name> qemu+ssh://target-host/system
```
