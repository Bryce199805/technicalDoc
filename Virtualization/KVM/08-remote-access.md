# 08 远程访问

---

## 8.1 访问方式概览

| 方式 | 需要图形环境 | 用途 | 推荐度 |
|------|------------|------|-------|
| **SSH** | 不需要 | 日常命令行操作 | ★★★★★ |
| **串口控制台** | 不需要 | 应急访问、安装时使用 | ★★★ |
| **VNC** | 客户端需要 | 图形界面操作 | ★★★ |
| **SSH X11 转发** | 客户端需要 | 单个图形程序 | ★★★★ |

---

## 8.2 SSH 访问（推荐日常使用）

### 前提

虚拟机内已安装并启动 SSH 服务：

```bash
# 在虚拟机内执行
sudo apt install -y openssh-server   # 如果没装
sudo systemctl enable --now ssh
```

### 从宿主机连接

```bash
# 查看虚拟机 IP
virsh domifaddr <vm-name>

# 如果 domifaddr 没输出，查 DHCP 租约
sudo cat /var/lib/libvirt/dnsmasq/default.leases

# SSH 连接
ssh <username>@192.168.122.x
```

### SSH 密钥认证（免密码）

```bash
# 在宿主机上生成密钥（如果还没有）
ssh-keygen -t ed25519

# 将公钥复制到虚拟机
ssh-copy-id <username>@192.168.122.x

# 之后直接连接，无需密码
ssh <username>@192.168.122.x
```

### SSH 配置优化

在宿主机 `~/.ssh/config` 中添加：

```
Host kali
    HostName 192.168.122.x
    User <username>
    IdentityFile ~/.ssh/id_ed25519
```

之后直接 `ssh kali` 即可连接。

---

## 8.3 串口控制台

### 原理

串口控制台通过 `virsh console` 连接，不需要网络，不需要虚拟机内开任何服务。适合应急访问。

### 安装时使用串口

通过 `--location` + `--extra-args "console=ttyS0"` 实现，详见 [04-vm-creation.md](04-vm-creation.md)。

### 安装后配置串口

安装时的 `console=ttyS0` 只对安装内核生效。要让系统永久使用串口，需修改 VM 内的 GRUB 配置：

```bash
# 在虚拟机内执行
sudo nano /etc/default/grub

# 修改以下行：
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8"

# 也可以同时保留 VGA 输出：
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8"

# 更新 GRUB
sudo update-grub

# 重启
sudo reboot
```

> **注意**：不能在 VM 的 XML 配置中使用 `<cmdline>console=ttyS0</cmdline>`，因为 `<cmdline>` 只有配合 `<kernel>` 标签（手动指定内核）时才有效，从硬盘正常启动时会报错 `-append only allowed with -kernel option`。

### 连接与退出

```bash
# 连接串口控制台
virsh console <vm-name>

# 退出：按 Ctrl + ]
# 如果 Ctrl + ] 不生效，试试 Ctrl + 5
```

### 启用串口登录提示

如果串口连接后没有登录提示，需要配置 agetty：

```bash
# 在虚拟机内执行
sudo systemctl enable serial-getty@ttyS0.service
sudo systemctl start serial-getty@ttyS0.service
```

---

## 8.4 VNC 远程图形访问

### 安装时使用 VNC

创建 VM 时指定 VNC 输出：

```bash
sudo virt-install \
  --name <vm-name> \
  ... \
  --graphics vnc,listen=0.0.0.0,port=5900 \
  --noautoconsole
```

然后用 VNC 客户端连接 `<宿主机IP>:5900`。

### 运行中的 VM 添加 VNC

```bash
# 关机
virsh shutdown <vm-name>

# 编辑配置
virsh edit <vm-name>

# 找到 <graphics> 标签，修改为：
<graphics type='vnc' port='5900' autoport='no' listen='0.0.0.0'>
  <listen type='address' address='0.0.0.0'/>
</graphics>

# 启动
virsh start <vm-name>
```

> 如果 XML 中没有 `<graphics>` 标签，在 `<devices>` 内添加。

### VNC 安全

VNC 默认不加密，建议通过 SSH 隧道访问：

```bash
# 在客户端机器上建立 SSH 隧道
ssh -L 5900:localhost:5900 <user>@<宿主机IP>

# 然后连接 VNC: localhost:5900
```

### 限制 VNC 监听地址

如果只从宿主机本地访问：

```xml
<graphics type='vnc' port='5900' autoport='no' listen='127.0.0.1'>
  <listen type='address' address='127.0.0.1'/>
</graphics>
```

### 设置 VNC 密码

```xml
<graphics type='vnc' port='5900' autoport='no' listen='0.0.0.0' passwd='your-password'>
  <listen type='address' address='0.0.0.0'/>
</graphics>
```

### VNC 客户端

| 平台 | 推荐 |
|------|------|
| Windows | TightVNC Viewer, RealVNC |
| macOS | Screen Sharing (内置), TigerVNC |
| Linux | TigerVNC, Remmina |
| iOS/Android | VNC Viewer (RealVNC) |

---

## 8.5 SSH X11 转发

适合只需要运行单个图形程序的场景（如 Wireshark、Burp Suite）。

### 客户端配置

```bash
# 宿主机安装 X11 转发支持
sudo apt install -y xauth xclip

# 连接时启用 X11 转发
ssh -X <username>@192.168.122.x

# 或在 ~/.ssh/config 中配置
Host kali
    HostName 192.168.122.x
    User <username>
    ForwardX11 yes
```

### 虚拟机内配置

```bash
# 确保 X11 转发已开启
sudo grep X11Forwarding /etc/ssh/sshd_config
# 应输出: X11Forwarding yes

# 安装 xauth
sudo apt install -y xauth
```

### 使用

```bash
# SSH 连接后直接运行图形程序
ssh -X <username>@192.168.122.x
wireshark &       # 在本地显示 Wireshark 窗口
burpsuite &       # 在本地显示 Burp Suite 窗口
```

---

## 8.6 访问方式选择流程

```
你需要什么？
│
├─ 命令行操作 → SSH（最简单最常用）
│
├─ 单个图形程序 → SSH X11 转发
│
├─ 完整桌面环境 → VNC
│
└─ 应急/网络不通 → 串口控制台
```
