# Static IP Address for Linux

首先先配置带有NAT的虚拟交换机。

## UBuntu

```shell
sudo vim /etc/netplan/00-installer-config.yaml
```

00-installer-config.yaml 文件的权限应为600

配置文件示例：

```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    eth0:
      dhcp4: false	# 关掉动态地址分配
      addresses: [172.16.1.100/24]	# 设置静态IP地址
      routes:	# 设置默认路由
        - to: default
          via: 172.16.1.1	# 设置网关，为虚拟交换机的IP地址
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]	# 设置DNS服务器
  version: 2
```

```shell
# 更新设置
sudo netplan apply

# 查看IP
ip add
```

