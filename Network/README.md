# Network

本目录记录网络基础、远程访问、网络服务、边缘路由和跨网络连接方案。

## 当前内容

| 主题 | 入口 | 内容 |
|------|------|------|
| SSH | [SSH](SSH/README.md) | 登录、SCP 和端口转发 |
| Nginx | [Nginx](Nginx.md) | 静态服务、反向代理、负载均衡、TLS 与排障 |
| TLS | [SSL 证书配置](SSL证书配置.md) | HTTPS 证书部署 |
| NAT Traversal | [内网穿透](NAT-Traversal/README.md) | FRP 与 ZeroTier |
| OpenWrt | [路由器配置](OpenWrt/README.md) | 基础配置、多 WAN 和 IPv6 |
| File Sharing | [文件共享](File-Sharing/README.md) | Samba |
| VPS | [VPS 网络](VPS/README.md) | IPv6-only VPS 配置 |

## 推荐学习路径

1. TCP/IP、子网、路由、DNS 和端口。
2. SSH 登录、文件传输和隧道。
3. Nginx、TLS 和网络服务部署。
4. NAT、内网穿透、OpenWrt 和多出口网络。
5. 使用抓包、路由表和连接状态完成系统化排障。

## 未来扩展

- TCP/IP 分层、ARP/NDP、子网划分和路由选择。
- DNS、DHCP、IPv6、NAT 与 conntrack。
- nftables/firewalld、网络命名空间和策略路由。
- `ip`、`ss`、`dig`、`tcpdump`、`mtr` 排障方法。
- TLS/PKI、证书生命周期、反向代理与负载均衡。
- VPN、Overlay Network、零信任接入和网络安全。
