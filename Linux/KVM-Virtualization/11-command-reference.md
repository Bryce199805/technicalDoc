# 11 命令速查表

---

## 虚拟机生命周期

```bash
virsh start <vm>                        # 启动
virsh start <vm> --console              # 启动并连接控制台
virsh shutdown <vm>                     # 优雅关机
virsh destroy <vm>                      # 强制关机
virsh reboot <vm>                       # 重启
virsh suspend <vm>                      # 暂停
virsh resume <vm>                       # 恢复
virsh save <vm> <file>                  # 保存状态到文件
virsh restore <file>                    # 从文件恢复状态
```

## 查看 VM 信息

```bash
virsh list --all                        # 列出所有 VM
virsh domstate <vm>                     # 查看 VM 状态
virsh dominfo <vm>                      # 查看 VM 详细信息
virsh domblklist <vm>                   # 查看块设备
virsh domiflist <vm>                    # 查看网络接口
virsh domifaddr <vm>                    # 查看 IP 地址
virsh vncdisplay <vm>                   # 查看 VNC 端口
virsh cpu-stats <vm>                    # 查看 CPU 使用
virsh dommemstat <vm>                   # 查看内存使用
virsh dumpxml <vm>                      # 查看 XML 配置
virsh dumpxml <vm> --inactive           # 查看持久化配置
```

## 配置管理

```bash
virsh edit <vm>                         # 编辑 VM 配置
virsh autostart <vm>                    # 设置开机自启
virsh autostart <vm> --disable          # 取消开机自启
virsh undefine <vm>                     # 删除 VM 定义
virsh undefine <vm> --remove-all-storage # 删除 VM 和磁盘
virsh define <file.xml>                 # 从 XML 定义 VM
```

## 网络管理

```bash
virsh net-list --all                    # 列出所有网络
virsh net-start <net>                   # 启动网络
virsh net-destroy <net>                 # 停止网络
virsh net-edit <net>                    # 编辑网络配置
virsh net-dumpxml <net>                 # 查看网络配置
virsh net-define <file.xml>             # 从 XML 定义网络
virsh net-undefine <net>                # 删除网络
virsh net-autostart <net>               # 设置网络自动启动
```

## 快照管理

```bash
virsh snapshot-create-as <vm> --name <name> --description <desc>  # 创建快照
virsh snapshot-create <vm>              # 创建自动命名快照
virsh snapshot-list <vm>                # 列出快照
virsh snapshot-info <vm> --snapshotname <name>  # 查看快照详情
virsh snapshot-revert <vm> --snapshotname <name> # 恢复快照
virsh snapshot-delete <vm> --snapshotname <name> # 删除快照
virsh snapshot-current <vm>             # 查看当前快照
```

## 存储管理

```bash
virsh pool-list --all                   # 列出存储池
virsh pool-info <pool>                  # 查看存储池信息
virsh pool-start <pool>                 # 启动存储池
virsh pool-destroy <pool>               # 停止存储池
virsh vol-list <pool>                   # 列出存储卷
qemu-img info <disk>                    # 查看磁盘信息
qemu-img create -f qcow2 <disk> <size>  # 创建磁盘
qemu-img resize <disk> <size>           # 扩容磁盘
qemu-img check <disk>                   # 检查磁盘完整性
qemu-img convert -f qcow2 -O qcow2 <in> <out>  # 转换格式
```

## 磁盘与介质

```bash
virsh attach-disk <vm> <path> <target>  # 附加磁盘
virsh detach-disk <vm> <target>         # 卸载磁盘
virsh change-media <vm> <dev> --eject --config  # 弹出光驱
virsh change-media <vm> <dev> --source <iso> --config  # 插入光驱
```

## 访问

```bash
virsh console <vm>                      # 串口控制台（退出: Ctrl+]）
ssh <user>@<vm-ip>                      # SSH 连接
ssh -X <user>@<vm-ip>                   # SSH + X11 转发
```

## 诊断

```bash
sudo journalctl -u libvirtd -f          # 实时 libvirtd 日志
sudo cat /var/log/libvirt/qemu/<vm>.log # QEMU 日志
ps aux | grep qemu                      # QEMU 进程
sudo iptables -t nat -L -v -n           # NAT 规则
sudo iptables -L FORWARD -v -n          # 转发规则
sudo cat /var/lib/libvirt/dnsmasq/default.leases  # DHCP 租约
```

## 创建虚拟机模板

### --location 方式（支持串口）

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

### --cdrom + VNC 方式

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
