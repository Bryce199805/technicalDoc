# NAT Traversal

本目录记录跨 NAT 访问、反向代理穿透和 Overlay Network 方案。

## 当前内容

| 文档 | 内容 |
|------|------|
| [FRP](FRP.md) | STCP、XTCP、服务配置和 systemd 运行 |
| [ZeroTier](ZeroTier.md) | 异地虚拟组网 |
| [frpc.toml](frpc.toml) | FRP 客户端配置样例 |
| [frps.toml](frps.toml) | FRP 服务端配置样例 |

## 推荐学习路径

先理解 NAT 类型、端口映射和中继，再比较 FRP 反向代理与 ZeroTier Overlay Network 的流量路径和安全边界。

## 未来扩展

- NAT 类型、STUN/TURN/ICE 和打洞原理。
- WireGuard、Tailscale、ZeroTier 与 FRP 对比。
- 身份认证、访问控制、TLS 和密钥轮换。
- 高可用、中继性能、监控和故障排查。
- 将不同角色的配置拆成独立、可验证示例。
