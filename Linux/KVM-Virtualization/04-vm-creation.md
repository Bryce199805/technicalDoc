# 04 创建虚拟机

---

## 4.1 准备工作

### 准备 ISO 镜像

```bash
# 创建 ISO 存放目录
sudo mkdir -p /var/lib/libvirt/iso

# 复制 ISO 到 libvirt 可访问的位置
# 重要：QEMU 进程以 libvirt-qemu 用户运行，无法读取 home 目录
sudo cp /path/to/your.iso /var/lib/libvirt/iso/

# 验证
ls -lh /var/lib/libvirt/iso/
```

### 创建虚拟磁盘

```bash
# 创建 qcow2 格式磁盘
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/<vm-name>.qcow2 80G

# 验证
sudo qemu-img info /var/lib/libvirt/images/<vm-name>.qcow2
```

参数说明：
- `-f qcow2`：指定 qcow2 格式（支持精简分配和快照）
- `80G`：虚拟机看到的磁盘大小，不是立即占用 80G
- 初始实际占用约 200KB，随使用增长

### 磁盘格式选择

| 格式 | 精简分配 | 快照 | 性能 | 适用场景 |
|------|---------|------|------|---------|
| **qcow2** | 支持 | 支持 | 接近原生（~1-3% 损耗） | 日常使用，推荐 |
| raw | 不支持 | 不支持 | 最优 | 极致 I/O 性能需求 |

### 资源规划建议

| 宿主机配置 | 建议分配 | 保留 |
|-----------|---------|------|
| 8 核 CPU | 2-4 vCPU | 4+ 核 |
| 16GB 内存 | 4-8GB | 8GB+ |
| 80GB 磁盘 | 40-60GB | 剩余空间 |

---

## 4.2 方式一：--cdrom 安装

### 适用场景

- 后续通过 VNC 完成安装
- 不需要串口控制台

### 命令

```bash
sudo virt-install \
  --name <vm-name> \
  --ram 4096 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/<vm-name>.qcow2,format=qcow2,bus=virtio \
  --cdrom /var/lib/libvirt/iso/<your.iso> \
  --os-variant debiantesting \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=5900 \
  --noautoconsole
```

### 限制

- **不支持 `--extra-args`**：无法传递 `console=ttyS0`，串口看不到安装界面
- 必须配合 VNC 或其他图形方式完成安装

### 参数详解

| 参数 | 说明 |
|------|------|
| `--name` | 虚拟机名称，virsh 管理时使用 |
| `--ram` | 内存大小（MB），如 4096 = 4GB |
| `--vcpus` | 虚拟 CPU 核数 |
| `--disk path=...` | 磁盘路径，`format=qcow2` 格式，`bus=virtio` 半虚拟化 |
| `--cdrom` | ISO 文件路径，作为光驱挂载 |
| `--os-variant` | 操作系统类型，优化时钟/ACPI 等行为 |
| `--network network=default` | 使用 default NAT 网络，`model=virtio` 半虚拟化网卡 |
| `--graphics vnc,...` | VNC 图形输出配置 |
| `--noautoconsole` | 不自动连接控制台 |

---

## 4.3 方式二：--location 安装（推荐，支持串口）

### 适用场景

- 无图形界面，需要串口终端完成安装
- 需要传递内核参数

### 步骤

**1. 挂载 ISO**

```bash
sudo mkdir -p /mnt/<vm-name>-iso
sudo mount -o loop /var/lib/libvirt/iso/<your.iso> /mnt/<vm-name>-iso
```

**2. 确认内核和 initrd 路径**

```bash
ls /mnt/<vm-name>-iso/
```

不同发行版的内核位置：

| 发行版 | 内核路径 | initrd 路径 |
|--------|---------|------------|
| Debian/Kali | `install.amd/vmlinuz` | `install.amd/initrd.gz` |
| Ubuntu (Server) | `casper/vmlinuz` | `casper/initrd` |
| CentOS/Rocky | `images/pxeboot/vmlinuz` | `images/pxeboot/initrd.img` |
| Fedora | `images/pxeboot/vmlinuz` | `images/pxeboot/initrd.img` |

**3. 创建虚拟机**

```bash
sudo virt-install \
  --name <vm-name> \
  --ram 4096 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/<vm-name>.qcow2,format=qcow2,bus=virtio \
  --disk /var/lib/libvirt/iso/<your.iso>,device=cdrom,bus=sata \
  --location /mnt/<vm-name>-iso,kernel=install.amd/vmlinuz,initrd=install.amd/initrd.gz \
  --os-variant debiantesting \
  --network network=default,model=virtio \
  --graphics none \
  --console pty,target_type=serial \
  --extra-args "console=ttyS0,115200n8"
```

### 关键点

- **`--location` 指向挂载目录**，配合 `kernel=` 和 `initrd=` 指定内核文件（逗号分隔，不加空格）
- **必须额外用 `--disk` 挂载 ISO 作为 cdrom**，否则安装程序会报 "installation media couldn't be mounted"
- `--extra-args "console=ttyS0,115200n8"` 将内核输出重定向到串口
- `--graphics none` 不使用图形显示
- `--console pty,target_type=serial` 配置串口终端

### --cdrom 与 --location 对比

| | --cdrom | --location |
|---|---|---|
| 串口控制台 | 不可用 | 可用 |
| --extra-args | 不支持 | 支持 |
| ISO 挂载 | 自动 | 需手动加 --disk cdrom |
| 需要先挂载 ISO | 不需要 | 需要 |
| 适用场景 | 配合 VNC | 串口终端 |

---

## 4.4 os-variant 常用值

```bash
# 查看所有支持的值
osinfo-query os | less
```

常用值：

| 系统 | os-variant 值 |
|------|--------------|
| Kali Linux | `debiantesting` |
| Debian 11 | `debian11` |
| Debian 12 | `debian12` |
| Ubuntu 22.04 | `ubuntu22.04` |
| Ubuntu 24.04 | `ubuntu24.04` |
| CentOS 7 | `centos7.0` |
| Rocky 9 | `rocky9` |
| Windows 10 | `win10` |
| Windows 11 | `win11` |
| Fedora 37 | `fedora37` |

---

## 4.5 安装后清理

### 卸载安装介质

```bash
# 查看块设备，确认光驱设备名
virsh domblklist <vm-name>
# 输出示例：
#  Target   Source
#  vda      /var/lib/libvirt/images/kali.qcow2
#  sda      /var/lib/libvirt/iso/kali-linux-2026.1-installer-amd64.iso

# 弹出光驱（设备名取决于 domblklist 输出，常见 sda/hda）
sudo virsh change-media <vm-name> sda --eject --config

# 重启
sudo virsh reboot <vm-name>
```

### 卸载 ISO 挂载

```bash
sudo umount /mnt/<vm-name>-iso
```

### 开启 SSH

安装完成后，虚拟机默认没有开启 SSH 服务。需要通过串口或 VNC 进入系统后开启：

```bash
# 在虚拟机内执行
sudo systemctl enable --now ssh
```

之后即可从宿主机 SSH 连接：

```bash
# 查看虚拟机 IP
virsh domifaddr <vm-name>

# SSH 连接
ssh <username>@192.168.122.x
```

---

## 4.6 常见安装问题

### Permission denied 读取 ISO

```
error: Could not open '/home/user/xxx.iso': Permission denied
```

原因：QEMU 进程以 `libvirt-qemu` 用户运行，无法读取 home 目录。

解决：复制 ISO 到 `/var/lib/libvirt/iso/`。

### unrecognized arguments: --kernel

```
virt-install: error: unrecognized arguments: --kernel
```

原因：`virt-install` 没有 `--kernel` 参数。

解决：将 kernel 和 initrd 路径写在 `--location` 参数内，用逗号分隔：

```bash
--location /mnt/iso,kernel=install.amd/vmlinuz,initrd=install.amd/initrd.gz
```

### --extra-args 与 --cdrom 不兼容

```
ERROR: Kernel arguments are only supported with location or kernel installs.
```

原因：`--cdrom` 模式下无法传内核参数。

解决：改用 `--location` 模式。

### 安装后找不到安装介质

```
Your installation media couldn't be mounted.
```

原因：`--location` 只加载了内核，没有把 ISO 作为光驱挂载。

解决：额外添加 `--disk /path/to/file.iso,device=cdrom,bus=sata`。

### 串口控制台无输出

原因：安装完成后系统没有配置串口输出（安装时的 `console=ttyS0` 只对安装内核生效）。

解决：在 VM 内修改 GRUB 配置，参见 [08-remote-access.md](08-remote-access.md)。

### 串口终端乱码

原因：安装程序的文本界面在串口下渲染有问题。

解决：使用 `--location` + `--extra-args "console=ttyS0"` 方式安装，或改用 VNC。
