# IPv6 Only Vps Configuration

## 两元神机系列

### IPv6 ONLY 转双栈

为了使IPv6 ONLY的主机能访问IPv4的资源，使用Warp将其转为双栈网络，依赖于WireGuard

[ref 1](https://www.moeelf.com/archives/299.html)	[ref 2](https://support.huaweicloud.com/hce_faq/hce_03_0006.html)

```shell
# 查看内核版本
uname -a

# 依赖于wireGuard  Kernel Version >= 5.6 内核集成了该模块可忽略
# 理论性能 内核集成 >= 内核模块 >= wireguard-go

# plan 1 升级内核 (debian)
apt update && apt upgrade
apt install lsb-release -y

# 添加backports源
echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | tee /etc/apt/sources.list.d/backports.list
apt update
# 查看可安装的内核版本
apt search linux-image
# 安装合适的版本并更新引导项
apt -t buster-backports install linux-image-amd64
apt -t buster-backports install linux-headers-amd64
update-grub
# 重启vps
reboot
```

两元神机不是用grup引导的，非常遗憾这条路走不通。

```shell
# plan 2 安装 wireguard 内核模块
apt install wireguard-dkms -y
# 亲测这一条并不好用，但会帮你扫清许多依赖的问题，转到手动编译
# 下载并解压wireguard-tools源码并解压
wget https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-1.0.20210914.tar.xz
tar -xf wireguard-tools-1.0.20210914.tar.xz
# 手动编译其源码
cd wireguard-tools-1.0.20210914/src
make && make install
# 验证是否安装成功
wg -h
wg-quick -h

# wireguard-go (这一步应该是不必要的，具体没测试，直接重启好用就不必进行)
# 下载二进制文件
wget -P /usr/bin https://github.com/bernardkkt/wg-go-builder/releases/latest/download/wireguard-go
# 添加执行权
chmod +x /usr/bin/wireguard-go
# 测试
wireguard-go

# 重启vps
reboot
```

执行WARP一键操作脚本：

[GitHub Addr](https://github.com/fscarmen/warp-sh)

```shell
wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
```

操作菜单选择将vps转为双栈网络

```shell
# 若提示找不到warp.conf
touch /etc/wireguard/warp.conf
```

### 协议一键部署

依赖于Sing-Box全家桶：

[GitHub Addr](https://github.com/fscarmen/sing-box)

```shell
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh)
```

```shell
# 支持的协议
# XTLS + reality 直连鉴定为垃圾
# hysteria2  神！
# vmess + ws 直连鉴定为垃圾
# vless + ws + tls  直连鉴定为垃圾
# 以下暂未测试 CDN暂未测试
# tuic 
# ShadowTLS 
# shadowsocks 
# trojan 
# H2 + reality 
# gRPC + reality
```

