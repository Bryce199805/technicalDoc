# SSH Tunnel

### Local Forwarding

```shell
ssh -L [local_ip]:<local_port>:<target_ip>:<target_port> user@ssh_server_ip
```

- local_ip: 默认为localhost，可省略
- local_port: 本地访问端口
- target_ip/port: 目标ip地址/端口

隧道发起是本地客户端，此时ssh_server_ip应为跳板机zerotier ip

```shell
local_client(local_ip:local_port) --> ssh(zerotier) --> lab_server(target_ip:target_port)
```

### Remote Forwarding

```shell
ssh -R [remote_ip]:<remote_port>:<target_ip>:<target_port> user@ssh_server_ip
```

- remote_ip: 默认为localhost，仅本机可访问，0.0.0.0则可让其他机器访问
- remote_port 远端ssh服务器开放的端口
- target_ip/port: 目标ip地址/端口

此时隧道发起是远程ssh服务器，例如跳板机，ssh_server_ip应当为127.0.0.1

```shell
local_client --> ssh(zerotier_ip:remote_port) --> lab_server(target_ip:target_port)
```

### sshd config

```shell
GatewayPorts yes
```

如果需要配置systemd service启动，需要配置密钥登录，不然会卡密码导致报错
