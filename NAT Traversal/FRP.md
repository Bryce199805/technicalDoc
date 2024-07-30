# Fast Reverse Proxy

[FRP Github Addr](https://github.com/fatedier/frp)

[Refs Doc](https://gofrp.org/zh-cn/docs/overview/)

## 安全地暴露内网服务 STCP

frps.toml服务端配置


```toml
bindPort = 7000
auth.token = "secret token 1"
```

frpc.toml被访问端配置

```toml
serverAddr = "x.x.x.x"
serverPort = 7000
auth.token = "secret token 1"

[[proxies]]
name = "secret-ssh"
type = "stcp"
secretKey = "secret token 2"
localIP = "127.0.0.1"
localPort = 22

[[proxies]]
name = "remote-desktop"
type = "sucp"
secretKey = "secret token 3"
localIP = "127.0.0.1"
localPort = 3389

```

frpc.toml访问端配置

```toml
serverAddr = "x.x.x.x"
serverPort = 7000
auth.token = "secret token 1"

[[visitors]]
name = "ssh-visitor"
type = "stcp"
serverName = "secret-ssh"
secretKey = "secret token 2"
bindAddr = "127.0.0.1"
bindPort = 6000

[[visitors]]
name = "remote-visitor"
type = "stcp"	# 远程桌面不支持sudp
serverName = "remote-desktop"
secretKey = "secret token 3"
bindAddr = "127.0.0.1"
bindPort = 6001
```

连接

```shell
# ssh 
ssh username@127.0.0.1:6000
# remote connect 
127.0.0.1:6001
```

## 点对点内网穿透 XTCP

frps.toml服务端配置

```toml
bindPort = 7000
auth.token = "secret token 1"
```

frpc.toml被访问端配置

```toml
serverAddr = "x.x.x.x"
serverPort = 7000
auth.token = "secret token 1"

[[proxies]]
name = "stcp-ssh"
type = "stcp"
secretKey = "secret token 2"
localIP = "127.0.0.1"
localPort = 22

[[proxies]]
name = "p2p_ssh"
type = "xtcp"
secretKey = "secret token 3"
localIP = "127.0.0.1"
localPort = 22

[[proxies]]
name = "stcp-remote-desktop"
type = "stcp"
secretKey = "secret token 4"
localIP = "127.0.0.1"
localPort = 3389

[[proxies]]
name = "p2p_remote-desktop"
type = "xtcp"
secretKey = "secret token 5"
localIP = "127.0.0.1"
localPort = 3389
```

frpc.toml访问端配置

与 stcp 类似，使用 xtcp 需要在两端都部署 frpc 以建立**直接连接**。

需要注意的是，xtcp 并不适用于所有类型的 NAT 设备，如果穿透失败，可以尝试使用 stcp 代理

可以通过配置 fallback 到 stcp visitor 实现在打洞失败时，回退到 stcp 建立连接

```toml
serverAddr = "x.x.x.x"
serverPort = 7000
auth.token = "secret token 1"

[[visitors]]
name = "stcp-ssh-visitor"
type = "stcp"
serverName = "stcp-ssh"
secretKey = "secret token 2"
bindAddr = "127.0.0.1"
bindPort = -1

[[visitors]]
name = "p2p_ssh-visitor"
type = "xtcp"
serverName = "p2p_ssh"
secretKey = "secret token 3"
bindAddr = "127.0.0.1"
bindPort = 6000
fallbackTo = "stcp-ssh-visitor"
fallbackTimeoutMs = 200

[[visitors]]
name = "stcp-remote-visitor"
type = "stcp"
serverName = "stcp-remote-desktop"
secretKey = "secret token 4"
bindAddr = "127.0.0.1"
bindPort = -1

[[visitors]]
name = "p2p_remote-visitor"
type = "xtcp"
serverName = "p2p_remote-desktop"
secretKey = "secret token 5"
bindAddr = "127.0.0.1"
bindPort = 6001
fallbackTo = "stcp-remote-visitor"
fallbackTimeoutMs = 200

```

连接

```shell
# ssh 
ssh username@127.0.0.1:6000
# remote connect 
127.0.0.1:6001
```

## 

## 一般访问 

frps.toml服务端配置

```toml
bindPort = 7000
token = "secret token 1"
```

frpc.toml被访问端配置

```toml
serverAddr = "x.x.x.x"
serverPort = 7000
auth.token = "secret token 1"

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000
```

连接

```shell
ssh username@x.x.x.x:6000
```



## 开机自启

### Windows

设置计划任务程序

```shell
[path to frp root dir]\frpc.exe
# 参数
-c [path to frp root dir]\frpc.toml
```

### Linux

```shell
vim /etc/systemd/system/frpc.service

# 输入内容如下：
[Unit]
Description=Frp client
After=network.target

[Service]
Type=simple
ExecStart=[path to frp root dir]/frpc -c [path to frp root dir]/frpc.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```



