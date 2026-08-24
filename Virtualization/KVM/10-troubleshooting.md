# 10 故障排查

---

## 10.1 常见问题速查

| 问题 | 原因 | 解决 |
|------|------|------|
| Permission denied 读取 ISO | QEMU 进程无法读 home 目录 | 复制 ISO 到 `/var/lib/libvirt/iso/` |
| `unrecognized arguments: --kernel` | virt-install 无此参数 | 用 `--location` 的逗号语法 |
| `--extra-args` 与 `--cdrom` 不兼容 | cdrom 模式无法传内核参数 | 改用 `--location` |
| 安装后找不到安装介质 | `--location` 没挂 ISO 作为 cdrom | 加 `--disk xxx,device=cdrom` |
| 串口控制台无输出 | 系统没配串口输出 | 在 VM 内修改 GRUB 加 `console=ttyS0` |
| `-append only allowed with -kernel` | `<cmdline>` 只配合 `<kernel>` 使用 | 在 VM 内修改 GRUB，不用 XML cmdline |
| virsh list 看不到 VM | 连接的是会话实例 | 检查 `LIBVIRT_DEFAULT_URI` |
| VM 定义丢失 | undefine 后未重新定义 | 磁盘还在的话重新 `virsh define` |
| 串口终端乱码 | 安装界面在串口下渲染异常 | 改用 VNC 安装 |
| Docker DNS 解析失败 | 多 DNS 时容器用了不可达的 DNS | 配置 Docker 固定 DNS |
| Could not open ISO: Permission denied | ISO 在 home 目录下 | 移到 `/var/lib/libvirt/iso/` |

---

## 10.2 诊断命令

### 虚拟机状态

```bash
# 查看 VM 状态
virsh domstate <vm-name>
virsh dominfo <vm-name>

# 查看所有 VM
virsh list --all

# 查看 VM 的块设备
virsh domblklist <vm-name>

# 查看 VM 的网络接口
virsh domiflist <vm-name>

# 查看 VM 的 IP 地址
virsh domifaddr <vm-name>

# 查看 VNC 端口
virsh vncdisplay <vm-name>
```

### 日志

```bash
# libvirtd 日志
sudo journalctl -u libvirtd --since "1 hour ago"

# QEMU 日志
sudo cat /var/log/libvirt/qemu/<vm-name>.log

# 实时跟踪日志
sudo journalctl -u libvirtd -f
```

### 进程

```bash
# 查看 QEMU 进程
ps aux | grep qemu

# 查看 QEMU 进程的命令行参数
cat /proc/$(pgrep -f "qemu-system.*<vm-name>")/cmdline | tr '\0' '\n'
```

### 网络

```bash
# 查看虚拟网桥
ip addr show virbr0

# 查看路由
ip route show

# 查看 iptables NAT 规则
sudo iptables -t nat -L -v -n

# 查看 iptables FORWARD 规则
sudo iptables -L FORWARD -v -n

# 查看 DHCP 租约
sudo cat /var/lib/libvirt/dnsmasq/default.leases

# 测试虚拟机网络连通性
ping 192.168.122.x
```

### 存储

```bash
# 查看磁盘信息
qemu-img info /var/lib/libvirt/images/<vm-name>.qcow2

# 检查磁盘完整性
qemu-img check /var/lib/libvirt/images/<vm-name>.qcow2

# 查看存储池
virsh pool-list --all
virsh pool-info default
```

---

## 10.3 libvirtd 连接问题

### Permission denied 连接 socket

```
error: Failed to connect socket to '/var/run/libvirt/libvirt-sock': Permission denied
```

排查：

```bash
# 1. 检查用户组
groups
# 应包含 libvirt

# 2. 检查 LIBVIRT_DEFAULT_URI
echo $LIBVIRT_DEFAULT_URI
# 应输出: qemu:///system

# 3. 检查 socket 权限
ls -la /var/run/libvirt/libvirt-sock
# 组应为 libvirt

# 4. 重新登录使组权限生效
newgrp libvirt
```

### virsh list 看不到系统实例的 VM

```bash
# 确认连接的是系统实例
echo $LIBVIRT_DEFAULT_URI

# 手动指定连接
virsh -c qemu:///system list --all

# 如果能看到，设置默认 URI
export LIBVIRT_DEFAULT_URI=qemu:///system
```

---

## 10.4 网络问题

### 虚拟机无法获取 IP

```bash
# 检查默认网络是否运行
virsh net-list --all

# 检查 dnsmasq 是否在运行
ps aux | grep dnsmasq

# 检查 virbr0 接口
ip addr show virbr0

# 重启默认网络
virsh net-destroy default
virsh net-start default
```

### 虚拟机无法访问外网

```bash
# 检查 NAT 规则
sudo iptables -t nat -L -v -n | grep 192.168.122

# 检查 ip_forward
cat /proc/sys/net/ipv4/ip_forward
# 应为 1

# 如果为 0，开启
sudo sysctl -w net.ipv4.ip_forward=1
```

### 虚拟机无法 SSH

```bash
# 1. 确认 VM 的 IP
virsh domifaddr <vm-name>

# 2. 从宿主机 ping
ping 192.168.122.x

# 3. 检查 VM 内 SSH 服务
# 通过串口控制台进入
virsh console <vm-name>
sudo systemctl status ssh

# 4. 检查防火墙
sudo iptables -L -v -n | grep virbr
```

---

## 10.5 磁盘问题

### 磁盘空间不足

```bash
# 查看磁盘实际占用
qemu-img info /var/lib/libvirt/images/<vm-name>.qcow2

# 扩容（见 07-storage.md）

# 检查宿主机磁盘空间
df -h /var/lib/libvirt/
```

### 磁盘损坏

```bash
# 检查磁盘完整性
qemu-img check /var/lib/libvirt/images/<vm-name>.qcow2

# 修复（尝试）
qemu-img check -r all /var/lib/libvirt/images/<vm-name>.qcow2
```

---

## 10.6 性能问题

### 虚拟机运行缓慢

排查方向：

1. **CPU 不足**：增加 vCPU
2. **内存不足**：增加 RAM
3. **磁盘 I/O 慢**：确认使用了 `bus=virtio`
4. **网络慢**：确认使用了 `model=virtio`
5. **快照链过长**：合并快照

```bash
# 查看 VM 资源配置
virsh dominfo <vm-name>

# 查看 CPU 使用
virsh cpu-stats <vm-name>

# 查看内存使用
virsh dommemstat <vm-name>

# 确认使用了 virtio
virsh dumpxml <vm-name> | grep -i virtio
```
