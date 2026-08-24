# 03 虚拟网络管理

---

## 3.1 网络类型概览

| 网络类型 | 模式 | VM 访问外网 | 外部访问 VM | VM 间互通 | 安全等级 |
|----------|------|-----------|-----------|----------|---------|
| **NAT (default)** | `<forward mode='nat'/>` | 可以 | 不可以 | 可以 | ★★★ |
| **NAT + 隔离** | NAT + `<domain isolate='yes'/>` | 可以 | 不可以 | 不可以 | ★★★★ |
| **Isolated (隔离)** | 无 `<forward>` | 不可以 | 不可以 | 不可以 | ★★★★★ |
| **Bridge (桥接)** | `<forward mode='bridge'/>` | 可以 | 可以 | 取决于物理网络 | ★★ |

---

## 3.2 默认 NAT 网络

### 工作原理

```
外部网络 (Internet)
       │
       │ ← NAT (SNAT)，外部无法主动连入
       │
┌──────▼──────┐
│   virbr0     │  192.168.122.1 (仅宿主机可见)
│  NAT 网桥     │
├─────────────┤
│  dnsmasq     │  DHCP: 分配 192.168.122.2-254
│              │  DNS: 转发到宿主机 DNS
├─────────────┤
│  虚拟机1     │  192.168.122.x
│  虚拟机2     │  192.168.122.y
└─────────────┘
```

- libvirt 在宿主机创建 `virbr0` 网桥
- dnsmasq 提供 DHCP 和 DNS 服务
- iptables NAT 规则让虚拟机通过宿主机 IP 访问外网
- 外部网络无法主动连接虚拟机

### 安全特性

| 防护点 | 说明 |
|--------|------|
| NAT 隔离 | 虚拟机出站经 SNAT，外部只能看到宿主机 IP |
| virbr0 仅宿主机可见 | 网桥不桥接物理网卡，外部二层流量进不来 |
| 私有网段 | 192.168.122.0/24 是 RFC1918 私有地址，公网不可路由 |
| iptables 规则 | libvirt 自动添加规则，限制 virbr0 与其他接口的互访 |

查看自动生成的 iptables 规则：

```bash
sudo iptables -t nat -L -v -n | grep 192.168.122
sudo iptables -L -v -n | grep virbr
```

### 初始化默认网络

```bash
# 检查默认网络状态
virsh net-list --all

# 情况 1：default 已存在但未激活
sudo virsh net-start default
sudo virsh net-autostart default

# 情况 2：default 不存在，但 XML 文件在
sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default

# 情况 3：连 XML 文件都没有，手动创建
sudo tee /etc/libvirt/qemu/networks/default.xml > /dev/null << 'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default
```

### 验证默认网络

```bash
virsh net-list --all
# 期望输出:
#  Name      State    Autostart   Persistent
#  --------------------------------------------
#  default   active   yes         yes

virsh net-dumpxml default

# 检查 virbr0 接口
ip addr show virbr0
# 应看到 192.168.122.1/24
```

---

## 3.3 创建隔离网络

隔离网络适用于纯离线实验，虚拟机完全无法访问外网。

```bash
sudo tee /etc/libvirt/qemu/networks/isolated.xml > /dev/null << 'EOF'
<network>
  <name>isolated</name>
  <!-- 没有 forward 标签 = 完全隔离，无外网访问 -->
  <domain isolate='yes'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='192.168.150.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.150.2' end='192.168.150.254'/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh net-define /etc/libvirt/qemu/networks/isolated.xml
sudo virsh net-start isolated
sudo virsh net-autostart isolated
```

使用时在 VM 配置中指定：

```bash
--network network=isolated,model=virtio
```

---

## 3.4 禁止虚拟机之间通信

在默认 NAT 网络中，虚拟机之间默认可以互相通信。如果不需要：

```bash
virsh net-edit default
```

在 `<network>` 内添加 `<domain isolate='yes'/>`：

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

---

## 3.5 端口转发

如果需要从外部网络访问虚拟机的某个端口（如 SSH），可以配置端口转发。

### 方法一：iptables DNAT

```bash
# 将宿主机的 2222 端口转发到虚拟机的 22 端口
sudo iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.122.x:22
sudo iptables -I FORWARD -p tcp -d 192.168.122.x --dport 22 -j ACCEPT

# 持久化规则
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

### 方法二：libvirt 网络钩子（自动管理）

```bash
sudo tee /etc/libvirt/hooks/qemu > /dev/null << 'HOOK'
#!/bin/bash
# 端口转发钩子
# 用法: 在 VM 的 XML 中添加 <metadata> 标记

GUEST_NAME="$1"
OPERATION="$2"

if [ "$GUEST_NAME" = "kali" ] && [ "$OPERATION" = "start" ]; then
    # 获取 VM IP
    GUEST_IP=$(virsh domifaddr kali | grep -oE '192\.168\.122\.[0-9]+')
    # 转发 SSH
    iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination $GUEST_IP:22
    iptables -I FORWARD -p tcp -d $GUEST_IP --dport 22 -j ACCEPT
fi

if [ "$GUEST_NAME" = "kali" ] && [ "$OPERATION" = "stopped" ]; then
    iptables -t nat -D PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.122.0/22:22 2>/dev/null
fi
HOOK

sudo chmod +x /etc/libvirt/hooks/qemu
```

---

## 3.6 桥接网络

桥接网络让虚拟机直接获得物理网络的 IP，外部可以直接访问。

### 创建桥接

```bash
# 修改 netplan 配置
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp3s0:
      dhcp4: false
  bridges:
    br0:
      interfaces: [enp3s0]
      dhcp4: true
```

```bash
sudo netplan apply
```

### 定义桥接网络

```bash
sudo tee /etc/libvirt/qemu/networks/bridged.xml > /dev/null << 'EOF'
<network>
  <name>bridged</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOF

sudo virsh net-define /etc/libvirt/qemu/networks/bridged.xml
sudo virsh net-start bridged
sudo virsh net-autostart bridged
```

使用：

```bash
--network network=bridged,model=virtio
```

---

## 3.7 双网卡配置

虚拟机可以同时挂两块网卡，一块 NAT 上网，一块隔离做实验：

```bash
--network network=default,model=virtio \
--network network=isolated,model=virtio \
```

---

## 3.8 网络管理命令

```bash
# 列出所有网络
virsh net-list --all

# 查看网络详情
virsh net-dumpxml default

# 启动/停止网络
virsh net-start <network>
virsh net-destroy <network>

# 编辑网络配置（关机状态编辑）
virsh net-edit <network>

# 删除网络
virsh net-undefine <network>

# 查看 VM 的网络接口
virsh domiflist <vm-name>

# 查看 VM 的 IP 地址
virsh domifaddr <vm-name>

# 查看 DHCP 租约
sudo cat /var/lib/libvirt/dnsmasq/default.leases
```

---

## 3.9 Docker 与 libvirt 网络冲突

### 问题

Docker 容器直接继承 `/run/systemd/resolve/resolv.conf`，如果宿主机有多个 DNS（如 DHCP 下发了内网 DNS），容器可能优先使用不可达的 DNS，导致解析失败。

### 原因

```
宿主机应用 → systemd-resolved (127.0.0.53) → 智能选择可用 DNS ✅
Docker 容器 → 直接读 resolv.conf → 按顺序尝试 → 第一个超时才用第二个 ❌
```

### 诊断

```bash
# 查看宿主机的 DNS 配置
resolvectl status

# 查看容器内的 DNS
docker run --rm alpine cat /etc/resolv.conf

# 测试容器 DNS 解析
docker run --rm alpine nslookup google.com
```

### 解决方案

**方案 A：给 Docker 指定固定 DNS（推荐，不影响其他组件）**

```bash
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "dns": ["192.168.1.1", "8.8.8.8"]
}
EOF

sudo systemctl restart docker
```

**方案 B：从 systemd-resolved 移除不可达的 DNS**

```bash
sudo resolvectl dns enp3s0 192.168.1.1
```

**方案 C：netplan 指定 DNS（最彻底）**

```yaml
# /etc/netplan/00-installer-config.yaml
network:
  ethernets:
    enp3s0:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8]
  version: 2
```

```bash
sudo netplan apply
```
