# 09 安全加固

---

## 9.1 libvirt 默认安全机制

| 机制 | 说明 | 默认状态 |
|------|------|---------|
| NAT 网络隔离 | 外部无法主动连接虚拟机 | 启用 |
| seccomp 沙箱 | 限制 QEMU 进程可用的系统调用，减少 VM 逃逸攻击面 | 启用 |
| AppArmor | 自动为每个 VM 生成隔离 profile | 启用 |
| 私有网段 | 192.168.122.0/24 是 RFC1918 私有地址 | 启用 |
| iptables 规则 | 自动限制 virbr0 与其他接口的互访 | 启用 |

验证 AppArmor：

```bash
# 查看 QEMU 进程的 AppArmor profile
sudo aa-status | grep qemu

# 查看 VM 的 AppArmor 配置
ls /etc/apparmor.d/libvirt/
```

验证 seccomp：

```bash
# 查看 QEMU 进程的 seccomp 状态
virsh dumpxml <vm-name> | grep seccomp
```

---

## 9.2 网络隔离

### 选择合适的网络类型

```
安全等级    配置方式                    适用场景
─────────────────────────────────────────────────────
  ★★★      默认 NAT                    日常使用，虚拟机需要上网
  ★★★★     NAT + domain isolate=yes    多 VM 但不需要互通
  ★★★★★   isolated 隔离网络           纯离线实验，最高安全
```

### 禁止 VM 之间通信

```bash
virsh net-edit default
```

添加 `<domain isolate='yes'/>`：

```xml
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <domain isolate='yes'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

### 限制宿主机到 VM 的访问

默认宿主机可以通过 192.168.122.1 访问 VM 的所有端口。限制只允许 SSH：

```bash
sudo iptables -I FORWARD -i virbr0 -o virbr0 -j DROP
sudo iptables -I FORWARD -i virbr0 -o virbr0 -p tcp --dport 22 -j ACCEPT
```

---

## 9.3 QEMU 沙箱强化

### 修改 seccomp 策略

```bash
virsh edit <vm-name>
```

在 `<domain>` 下添加：

```xml
<qemu:commandline xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0">
  <qemu:arg value='-sandbox'/>
  <qemu:arg value='on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny'/>
</qemu:commandline>
```

各选项说明：

| 选项 | 作用 |
|------|------|
| `obsolete=deny` | 禁止已废弃的系统调用 |
| `elevateprivileges=deny` | 禁止提权操作 |
| `spawn=deny` | 禁止创建新进程 |
| `resourcecontrol=deny` | 禁止资源控制操作 |

---

## 9.4 禁用不必要的设备

### 禁用 USB

```xml
<!-- 删除或注释 USB 控制器 -->
<!-- <controller type='usb' index='0'/> -->

<!-- 或明确禁用 -->
<controller type='usb' index='0' model='none'/>
```

### 禁用内存气球（如不需要动态调整内存）

```xml
<!-- 删除 -->
<!-- <memballoon model='virtio'/> -->
```

---

## 9.5 VM 内部安全

### 更新系统

```bash
# 在虚拟机内
sudo apt update && sudo apt upgrade -y
```

### 安装 qemu-guest-agent

```bash
# 在虚拟机内
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

作用：
- 让宿主机能正常发送 shutdown 信号
- 提供更准确的 VM 内部信息（IP 地址、文件系统等）

### SSH 加固

```bash
# 在虚拟机内修改 /etc/ssh/sshd_config
PermitRootLogin no              # 禁止 root 登录
PasswordAuthentication no       # 禁用密码登录，仅用密钥
MaxAuthTries 3                  # 最大尝试次数
```

### 安装 fail2ban

```bash
# 在虚拟机内
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
```

---

## 9.6 宿主机安全

### 限制 libvirt 远程访问

```bash
# 查看 libvirtd 监听状态
sudo ss -tlnp | grep libvirtd

# 默认只监听 UNIX socket，不监听 TCP
# 如果不需要远程管理，确保 /etc/libvirt/libvirtd.conf 中：
listen_tls = 0
listen_tcp = 0
```

### 定期审计

```bash
# 查看运行中的 VM
virsh list

# 查看网络
virsh net-list

# 查看 iptables 规则
sudo iptables -L -v -n | grep virbr

# 查看 AppArmor 状态
sudo aa-status | grep qemu
```

---

## 9.7 安全检查清单

```
[ ] 使用 NAT 或隔离网络，不使用桥接（除非必须）
[ ] 多 VM 场景启用 domain isolate
[ ] seccomp 沙箱已启用
[ ] AppArmor 已启用
[ ] 禁用不需要的 USB/设备
[ ] VM 内禁止 root SSH 登录
[ ] VM 内使用密钥认证
[ ] VM 内安装了 qemu-guest-agent
[ ] 宿主机 libvirtd 不监听 TCP
[ ] VNC 通过 SSH 隧道访问，不直接暴露
[ ] 定期更新宿主机和 VM
```
