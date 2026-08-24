# Docker 网络管理

## Docker 网络概述

Docker 网络是容器间通信以及容器与外部世界通信的基础。Docker 提供了多种网络驱动，支持不同的网络场景。

### 网络架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Docker Host                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Docker Network                         │   │
│  │                                                           │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐              │   │
│  │  │Container│    │Container│    │Container│              │   │
│  │  │   A     │───▶│   B     │◀───│   C     │              │   │
│  │  │172.17.0.│    │172.17.0.│    │172.17.0.│              │   │
│  │  └────┬────┘    └────┬────┘    └────┬────┘              │   │
│  │       │              │              │                    │   │
│  │       └──────────────┼──────────────┘                    │   │
│  │                      │                                   │   │
│  │              ┌───────┴───────┐                          │   │
│  │              │    docker0    │  ← Bridge (172.17.0.1)   │   │
│  │              │   网桥接口     │                          │   │
│  │              └───────┬───────┘                          │   │
│  └──────────────────────┼──────────────────────────────────┘   │
│                         │                                       │
│                   ┌─────┴─────┐                                │
│                   │  eth0     │  ← Host Network Interface       │
│                   │  物理网卡  │                                │
│                   └─────┬─────┘                                │
└─────────────────────────┼───────────────────────────────────────┘
                          │
                    外部网络
```

---

## 网络驱动类型

Docker 支持以下网络驱动：

| 驱动 | 说明 | 适用场景 |
|------|------|---------|
| `bridge` | 默认网络驱动，单主机通信 | 单机开发、测试 |
| `host` | 共享主机网络命名空间 | 需要高性能网络 |
| `overlay` | 跨主机网络，用于 Swarm | 集群部署 |
| `macvlan` | 容器拥有独立 MAC 地址 | 网络设备仿真 |
| `none` | 禁用网络 | 完全隔离的容器 |
| `ipvlan` | 类似 macvlan 但共享 MAC | 高级网络配置 |

---

## Bridge 网络

### 默认 Bridge 网络

Docker 安装时会自动创建一个名为 `bridge` 的默认网络。

```
┌─────────────────────────────────────────────────────────┐
│                    默认 Bridge 网络                      │
│                                                          │
│    宿主机 (172.17.0.1)                                   │
│         │                                                │
│    docker0 网桥                                          │
│    /    |    \                                           │
│   /     |     \                                          │
│ 容器1  容器2  容器3                                       │
│ .0.2   .0.3  .0.4                                        │
│                                                          │
│ 网段: 172.17.0.0/16                                      │
│ 网关: 172.17.0.1 (docker0)                               │
└─────────────────────────────────────────────────────────┘
```

```bash
# 查看默认网络
docker network ls

# 输出
NETWORK ID     NAME      DRIVER    SCOPE
abc123456789   bridge    bridge    local
def123456789   host      host      local
ghi123456789   none      null      local

# 查看网络详情
docker network inspect bridge

# 在默认 bridge 网络中运行容器
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# 容器间通信（使用 IP 地址）
docker exec web1 ping -c 3 172.17.0.3
```

### 默认 Bridge 的限制

| 限制 | 说明 |
|------|------|
| 不支持服务发现 | 容器间不能通过名称通信 |
| 需要使用 --link | 已废弃，不推荐 |
| 灵活性差 | 无法自定义网段 |

### 自定义 Bridge 网络（推荐）

```bash
# 创建自定义 bridge 网络
docker network create mynet

# 创建时指定网段
docker network create \
    --driver bridge \
    --subnet 172.20.0.0/16 \
    --gateway 172.20.0.1 \
    mynet

# 创建时指定 IP 范围
docker network create \
    --driver bridge \
    --subnet 172.20.0.0/16 \
    --ip-range 172.20.1.0/24 \
    --gateway 172.20.0.1 \
    mynet

# 将容器连接到自定义网络
docker run -d --name web1 --network mynet nginx
docker run -d --name web2 --network mynet nginx

# 容器间通信（可以使用容器名称）
docker exec web1 ping -c 3 web2

# 为容器指定静态 IP
docker run -d --name web3 \
    --network mynet \
    --ip 172.20.0.100 \
    nginx
```

### 自定义 Bridge 的优势

```bash
# 1. 支持服务发现（DNS 解析）
docker run -d --name db --network mynet mysql
docker run -d --name app --network mynet myapp
# app 容器可以通过 "db" 主机名连接数据库

# 2. 容器可以动态加入/离开网络
docker network connect mynet existing_container
docker network disconnect mynet existing_container

# 3. 更好的隔离性
docker network create frontend
docker network create backend
docker run -d --name web --network frontend nginx
docker run -d --name api --network frontend --network backend myapi
docker run -d --name db --network backend mysql
```

---

## Host 网络

Host 模式下，容器与宿主机共享网络命名空间，容器没有独立的网络栈。

```
┌─────────────────────────────────────────────────────────┐
│                    Host 网络模式                         │
│                                                          │
│    宿主机网络栈                                           │
│    ┌─────────────────────────────────────────────┐      │
│    │ eth0: 192.168.1.100                         │      │
│    │ 端口: 22, 80, 443, ...                      │      │
│    └─────────────────────────────────────────────┘      │
│                    ▲                                     │
│                    │ 共享                                 │
│    ┌───────────────┴───────────────────────────┐        │
│    │              Container                     │        │
│    │   直接使用宿主机网络                        │        │
│    │   无独立 IP                                │        │
│    │   无需端口映射                             │        │
│    └────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

### 使用方式

```bash
# 使用 host 网络模式运行容器
docker run -d --name nginx-host --network host nginx

# 容器直接监听宿主机端口
# 无需 -p 参数
curl http://localhost:80

# 查看容器网络
docker inspect nginx-host --format='{{.HostConfig.NetworkMode}}'
# 输出: host
```

### Host 模式的特点

| 优点 | 缺点 |
|------|------|
| 网络性能最高 | 端口冲突风险 |
| 无需端口映射 | 网络隔离性差 |
| 适合网络密集型应用 | 容器间端口可能冲突 |

### 适用场景

```bash
# 1. 高性能网络应用
docker run -d --network host nginx

# 2. 需要访问宿主机网络接口
docker run -d --network host --cap-add NET_ADMIN myvpn

# 3. 网络监控工具
docker run -d --network host prom/node-exporter
```

---

## Container 网络模式

Container 模式让一个容器与另一个容器共享网络命名空间。

```
┌─────────────────────────────────────────────────────────┐
│                  Container 网络模式                      │
│                                                          │
│    ┌─────────────────────────────────────────────────┐  │
│    │              共享网络命名空间                     │  │
│    │                                                  │  │
│    │  ┌─────────────┐    ┌─────────────┐            │  │
│    │  │ Container A │    │ Container B │            │  │
│    │  │   (主容器)   │◀───│ (共享网络)  │            │  │
│    │  │ 172.17.0.2  │    │ 同一 IP     │            │  │
│    │  └─────────────┘    └─────────────┘            │  │
│    │                                                  │  │
│    │  共享: IP、端口、路由、iptables、DNS             │  │
│    └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 使用方式

```bash
# 创建主容器
docker run -d --name web nginx

# 创建共享网络的容器
docker run -d --name sidecar \
    --network container:web \
    alpine sleep 3600

# sidecar 容器可以通过 localhost 访问 web 容器
docker exec sidecar wget -qO- http://localhost:80
```

### 适用场景

```bash
# 1. Sidecar 模式（日志收集）
docker run -d --name app myapp
docker run -d --name log-collector \
    --network container:app \
    -v /var/log/app:/logs \
    log-collector

# 2. 调试容器网络
docker run -it --rm \
    --network container:target_container \
    nicolaka/netshoot
```

---

## None 网络

None 模式完全禁用容器网络，容器只有 loopback 接口。

```
┌─────────────────────────────────────────────────────────┐
│                    None 网络模式                         │
│                                                          │
│    ┌─────────────────────────────────────────────────┐  │
│    │                  Container                       │  │
│    │                                                  │  │
│    │         网络接口: lo (127.0.0.1)                 │  │
│    │                                                  │  │
│    │         无外部网络访问                           │  │
│    │         无其他网络接口                           │  │
│    └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 使用方式

```bash
# 使用 none 网络模式
docker run -d --name isolated --network none alpine sleep 3600

# 验证网络
docker exec isolated ip addr
# 只显示 lo 接口
```

### 适用场景

```bash
# 1. 安全敏感的处理任务
docker run --rm --network none my-security-app

# 2. 离线数据处理
docker run --rm --network none -v /data:/data my-processor

# 3. 测试环境
docker run --rm --network none my-test-app
```

---

## 网络操作命令

### 创建网络

```bash
# 创建基本网络
docker network create mynet

# 创建 bridge 网络
docker network create --driver bridge mynet

# 创建时指定子网
docker network create \
    --driver bridge \
    --subnet 192.168.100.0/24 \
    --gateway 192.168.100.1 \
    mynet

# 创建时指定多个子网
docker network create \
    --driver bridge \
    --subnet 192.168.100.0/24 \
    --subnet 192.168.200.0/24 \
    mynet

# 创建时设置 IP 范围
docker network create \
    --subnet 192.168.100.0/24 \
    --ip-range 192.168.100.128/25 \
    mynet

# 创建时设置辅助 IP
docker network create \
    --subnet 192.168.100.0/24 \
    --aux-address "host1=192.168.100.10" \
    --aux-address "host2=192.168.100.11" \
    mynet

# 设置 MTU
docker network create --opt com.docker.network.driver.mtu=1400 mynet

# 禁用 ICC（容器间通信）
docker network create --opt com.docker.network.bridge.enable_icc=false mynet
```

### 查看网络

```bash
# 列出所有网络
docker network ls

# 过滤网络
docker network ls --filter driver=bridge
docker network ls --filter name=my

# 格式化输出
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

# 查看网络详情
docker network inspect mynet

# 查看特定字段
docker network inspect mynet --format='{{.IPAM.Config}}'
docker network inspect mynet --format='{{range .Containers}}{{.Name}} {{end}}'
```

### 连接/断开网络

```bash
# 将运行中的容器连接到网络
docker network connect mynet mycontainer

# 连接时指定 IP
docker network connect --ip 192.168.100.50 mynet mycontainer

# 连接时设置别名
docker network connect --alias db mynet mycontainer

# 断开网络连接
docker network disconnect mynet mycontainer

# 强制断开
docker network disconnect -f mynet mycontainer
```

### 删除网络

```bash
# 删除网络（需要先断开所有容器）
docker network rm mynet

# 删除所有未使用的网络
docker network prune

# 删除超过 24 小时未使用的网络
docker network prune --filter "until=24h"
```

---

## 端口映射

### 端口映射类型

```
┌─────────────────────────────────────────────────────────┐
│                      端口映射                           │
│                                                          │
│    宿主机                      容器                      │
│    ┌──────────┐              ┌──────────┐              │
│    │   eth0   │              │ Container│              │
│    │:80 ──────┼─────────────▶│ :80      │  单端口映射  │
│    │          │              │          │              │
│    │:8080─────┼─────────────▶│ :80      │  不同端口    │
│    │          │              │          │              │
│    │:8081─────┼─────────────▶│ :8080    │  多端口映射  │
│    │:8082─────┼─────────────▶│ :8081    │              │
│    │          │              │          │              │
│    │:32768────┼─────────────▶│ :80      │  随机端口    │
│    └──────────┘              └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

### 端口映射命令

```bash
# 映射指定端口
docker run -d -p 80:80 nginx
docker run -d -p 8080:80 nginx

# 映射多个端口
docker run -d -p 80:80 -p 443:443 nginx

# 指定协议
docker run -d -p 53:53/udp dns-server

# 绑定到特定 IP
docker run -d -p 127.0.0.1:8080:80 nginx
docker run -d -p 192.168.1.100:80:80 nginx

# 随机端口映射
docker run -d -P nginx

# 映射端口范围
docker run -d -p 8080-8085:8080-8085 myapp

# 查看端口映射
docker port mycontainer
docker port mycontainer 80
```

---

## DNS 配置

### 容器 DNS 配置

```bash
# 设置自定义 DNS 服务器
docker run -d --dns 8.8.8.8 --dns 8.8.4.4 nginx

# 设置 DNS 搜索域
docker run -d --dns-search example.com nginx

# 添加 hosts 记录
docker run -d --add-host myhost:192.168.1.100 nginx
docker run -d --add-host myhost:192.168.1.100 --add-host db:192.168.1.101 nginx

# 使用自定义 hosts 文件
docker run -d -v /etc/hosts:/etc/hosts:ro nginx
```

### Docker 默认 DNS

```
容器 DNS 解析流程:
1. 检查 /etc/hosts 文件
2. 使用 Docker 内置 DNS 服务器 (127.0.0.11)
3. 内置 DNS 转发到宿主机 DNS
4. 宿主机 DNS 完成最终解析
```

---

## 网络调试

### 常用调试命令

```bash
# 查看容器网络配置
docker inspect mycontainer --format='{{json .NetworkSettings}}' | jq

# 查看容器 IP 地址
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mycontainer

# 查看容器网关
docker inspect -f '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' mycontainer

# 查看端口映射
docker port mycontainer

# 进入容器调试网络
docker exec -it mycontainer sh -c "ip addr"
docker exec -it mycontainer sh -c "netstat -tlnp"
docker exec -it mycontainer sh -c "cat /etc/resolv.conf"

# 使用网络调试容器
docker run -it --rm --network container:mycontainer nicolaka/netshoot

# 常用调试工具
docker run -it --rm nicolaka/netshoot ping google.com
docker run -it --rm nicolaka/netshoot dig google.com
docker run -it --rm nicolaka/netshoot curl ifconfig.me
```

### 网络问题排查

```bash
# 1. 检查网络配置
docker network inspect mynet

# 2. 检查 iptables 规则
sudo iptables -t nat -L -n
sudo iptables -t filter -L -n

# 3. 检查网桥配置
brctl show
ip link show docker0

# 4. 检查容器网络命名空间
# 找到容器网络命名空间
ls -la /var/run/docker/netns
# 进入网络命名空间
nsenter -t <pid> -n ip addr

# 5. 抓包分析
tcpdump -i docker0 -nn -vv
tcpdump -i eth0 port 80 -nn
```

---

## 网络最佳实践

### 1. 使用自定义网络

```bash
# 不推荐：使用默认 bridge
docker run -d --name app myapp
docker run -d --name db mysql
# 需要使用 IP 通信

# 推荐：使用自定义网络
docker network create mynet
docker run -d --name app --network mynet myapp
docker run -d --name db --network mynet mysql
# 可以使用服务名通信
```

### 2. 网络隔离

```yaml
# 分层网络设计
version: '3.8'

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # 禁止外部访问

services:
  nginx:
    image: nginx
    networks:
      - frontend
      - backend

  app:
    image: myapp
    networks:
      - backend

  db:
    image: mysql
    networks:
      - backend
```

### 3. 容器间通信安全

```bash
# 使用 internal 网络
docker network create --internal internal-net

# 限制容器只能访问特定网络
docker run -d --network internal-net myapp
```

### 4. 固定 IP 地址

```bash
# 创建网络时规划 IP 段
docker network create \
    --subnet 172.28.0.0/16 \
    --gateway 172.28.0.1 \
    mynet

# 为关键服务分配固定 IP
docker run -d --name db \
    --network mynet \
    --ip 172.28.1.10 \
    mysql
```

---

## 命令速查表

| 命令 | 说明 |
|------|------|
| `docker network ls` | 列出网络 |
| `docker network create` | 创建网络 |
| `docker network rm` | 删除网络 |
| `docker network inspect` | 查看网络详情 |
| `docker network connect` | 连接容器到网络 |
| `docker network disconnect` | 断开容器与网络 |
| `docker network prune` | 删除未使用的网络 |
| `docker port` | 查看端口映射 |

---

## 参考链接

- [Docker 网络文档](https://docs.docker.com/network/)
- [Networking overview](https://docs.docker.com/network/#network-drivers)
- [Bridge network](https://docs.docker.com/network/drivers/bridge/)
- [Host network](https://docs.docker.com/network/drivers/host/)
- [Overlay network](https://docs.docker.com/network/drivers/overlay/)
