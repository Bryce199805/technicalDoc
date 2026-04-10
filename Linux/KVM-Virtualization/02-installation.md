# 02 环境安装与验证

---

## 2.1 硬件要求检查

### 检查 CPU 虚拟化支持

```bash
# 方法 1：检查 CPU 标志（结果 > 0 即支持）
egrep -c '(vmx|svm)' /proc/cpuinfo
# vmx = Intel VT-x
# svm = AMD-V

# 方法 2：安装检查工具
sudo apt install -y cpu-checker
kvm-ok
# 期望输出:
#   INFO: /dev/kvm exists
#   KVM acceleration can be used
```

### 检查 KVM 内核模块

```bash
lsmod | grep kvm
# 期望输出:
#   kvm_intel    364696  0
#   kvm         1056352  1 kvm_intel

# 如果没有输出，手动加载：
sudo modprobe kvm
sudo modprobe kvm_intel   # Intel CPU
sudo modprobe kvm_amd     # AMD CPU

# 设置开机自动加载
echo "kvm" | sudo tee /etc/modules-load.d/kvm.conf
echo "kvm_intel" | sudo tee -a /etc/modules-load.d/kvm.conf  # Intel
# 或 echo "kvm_amd" | sudo tee -a /etc/modules-load.d/kvm.conf  # AMD
```

### 检查 /dev/kvm 设备

```bash
ls -la /dev/kvm
# 期望输出: crw-rw---- 1 root kvm ...
```

---

## 2.2 安装软件包

### 核心组件

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst bridge-utils
```

各包详细说明：

| 包名 | 作用 | 安装的文件/命令 |
|------|------|---------------|
| `qemu-kvm` | QEMU + KVM 加速支持 | `/usr/bin/qemu-system-x86_64`，`/dev/kvm` 访问支持 |
| `libvirt-daemon-system` | libvirtd 守护进程 | `libvirtd.service`，`/etc/libvirt/`，`/var/lib/libvirt/` |
| `libvirt-clients` | 命令行管理工具 | `virsh` 命令 |
| `virtinst` | 虚拟机创建工具 | `virt-install` 命令 |
| `bridge-utils` | 网桥管理 | `brctl` 命令（高级网络配置时使用） |

### 可选组件

```bash
# 图形化管理工具（需要桌面环境）
sudo apt install -y virt-manager

# libvirt 的 Python 绑定（编程管理 VM）
sudo apt install -y python3-libvirt

# 虚拟机查看器（VNC/SPICE 客户端）
sudo apt install -y virt-viewer
```

---

## 2.3 用户权限配置

### 加入用户组

```bash
# 加入 libvirt 组（管理虚拟机的权限）
sudo usermod -aG libvirt $(whoami)

# 加入 kvm 组（访问 /dev/kvm 的权限）
sudo usermod -aG kvm $(whoami)

# 重新登录使组权限生效，或临时生效：
newgrp libvirt
```

### 组权限说明

| 组 | 作用 | 对应文件 |
|----|------|---------|
| `kvm` | 读写 `/dev/kvm` 设备 | `/dev/kvm` |
| `libvirt` | 通过 Unix socket 与 libvirtd 通信 | `/var/run/libvirt/libvirt-sock` |

### 验证组权限

```bash
# 查看当前用户所属组
groups
# 应包含 libvirt 和 kvm

# 测试 socket 访问
ls -la /var/run/libvirt/libvirt-sock
# 应显示组为 libvirt，且你有读写权限
```

---

## 2.4 设置默认连接 URI

### 为什么需要设置

`virsh` 默认连接 `qemu:///session`（会话实例），但我们日常使用系统实例。两个实例完全隔离：

- 会话实例里的 VM 在系统实例里看不到
- 系统实例里的网络在会话实例里不可用

### 设置方法

```bash
# 写入 shell 配置文件
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' >> ~/.zshrc
source ~/.zshrc

# 如果使用 bash
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' >> ~/.bashrc
source ~/.bashrc
```

### 验证

```bash
echo $LIBVIRT_DEFAULT_URI
# 应输出: qemu:///system

virsh nodeinfo
# 应能正常输出节点信息
```

### 不设置的替代方式

每次命令手动指定连接 URI：

```bash
virsh -c qemu:///system list --all
```

---

## 2.5 启动并验证 libvirtd 服务

### 服务管理

```bash
# 查看 服务状态
sudo systemctl status libvirtd

# 启动并设为开机自启
sudo systemctl enable --now libvirtd

# 重启服务
sudo systemctl restart libvirtd
```

### 验证安装完整性

```bash
# 1. 查看节点信息
virsh nodeinfo
# 输出示例：
#   CPU model:           x86_64
#   CPU(s):              8
#   CPU frequency:       3300 MHz
#   CPU socket(s):       1
#   Core(s) per socket:  4
#   Thread(s) per core:  2
#   Memory size:         16109636 KiB

# 2. 查看 KVM 加速能力
virsh capabilities | grep -i "kvm\|hvm"
# 应包含 <domain type='kvm'> 和 <feature name='vmx'/> 或 <feature name='svm'/>

# 3. 查看默认网络
virsh net-list --all
# 应看到 default 网络

# 4. 查看 QEMU 版本
virsh version
```

---

## 2.6 目录结构说明

安装完成后的关键目录：

```
/etc/libvirt/
├── libvirtd.conf              # libvirtd 主配置文件
├── qemu/
│   ├── <vm-name>.xml          # 虚拟机 XML 配置
│   └── networks/
│       ├── default.xml        # 默认 NAT 网络定义
│       └── <network>.xml      # 其他网络定义
└── qemu.conf                  # QEMU 驱动配置

/var/lib/libvirt/
├── images/                    # 默认磁盘镜像存放位置
│   └── <vm-name>.qcow2
├── iso/                       # ISO 镜像（需手动创建）
│   └── <os>.iso
├── boot/                      # 网络启动相关
├── dnsmasq/                   # DHCP 租约
│   └── default.leases
└── qemu/
    └── save/                  # VM 状态保存

/var/log/libvirt/
└── qemu/
    └── <vm-name>.log          # QEMU 日志
```

### 创建 ISO 存放目录

```bash
sudo mkdir -p /var/lib/libvirt/iso
```

> QEMU 进程以 `libvirt-qemu` 用户运行，无法读取 home 目录。ISO 文件应放在 `/var/lib/libvirt/iso/` 下。
