# Docker 故障排查

本文档涵盖 Docker 常见问题、调试技巧和解决方案，帮助您快速定位和解决问题。

---

## 常见问题分类

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker 问题分类                               │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   安装问题   │  │   运行问题   │  │   网络问题   │            │
│  │             │  │             │  │             │            │
│  │ 服务启动失败 │  │ 容器启动失败 │  │ 容器间通信   │            │
│  │ 权限问题    │  │ 内存不足     │  │ 端口映射     │            │
│  │ 版本兼容    │  │ 磁盘空间     │  │ DNS 解析    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   存储问题   │  │   构建问题   │  │   性能问题   │            │
│  │             │  │             │  │             │            │
│  │ 数据卷挂载   │  │ 构建失败     │  │ CPU 占用高   │            │
│  │ 权限问题    │  │ 缓存问题     │  │ 内存泄漏     │            │
│  │ 磁盘清理    │  │ 网络超时     │  │ IO 瓶颈     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 诊断工具和命令

### 系统信息查看

```bash
# Docker 版本信息
docker version

# Docker 系统信息
docker info

# Docker 系统磁盘使用
docker system df
docker system df -v

# 查看 Docker 服务状态
systemctl status docker

# 查看 Docker 服务日志
journalctl -u docker.service
journalctl -u docker.service --since "1 hour ago"
```

### 容器诊断

```bash
# 查看容器状态
docker ps -a
docker inspect <container_id>

# 查看容器日志
docker logs <container_id>
docker logs -f --tail 100 <container_id>

# 查看容器资源使用
docker stats <container_id>
docker stats --no-stream

# 查看容器进程
docker top <container_id>

# 进入容器调试
docker exec -it <container_id> /bin/sh
docker exec -it <container_id> bash

# 查看容器文件变更
docker diff <container_id>

# 查看容器端口映射
docker port <container_id>

# 导出容器信息
docker export <container_id> | tar -tvf -
```

### 镜像诊断

```bash
# 查看镜像
docker images
docker images -a

# 查看镜像详情
docker inspect <image_id>

# 查看镜像历史
docker history <image_id>
docker history --no-trunc <image_id>

# 查看镜像层
docker save <image_id> | tar -tvf -
```

### 网络诊断

```bash
# 查看网络
docker network ls
docker network inspect <network_name>

# 查看 iptables 规则
iptables -t nat -L -n
iptables -t filter -L -n

# 查看网桥
brctl show
ip link show docker0

# 容器网络调试
docker run --rm -it --network container:<container_id> nicolaka/netshoot
```

### 存储诊断

```bash
# 查看数据卷
docker volume ls
docker volume inspect <volume_name>

# 查看存储驱动
docker info | grep "Storage Driver"

# 查看磁盘挂载
df -h | grep docker
mount | grep docker
```

---

## 安装和服务问题

### Docker 服务无法启动

```bash
# 检查服务状态
systemctl status docker

# 查看详细错误日志
journalctl -xeu docker.service

# 常见原因及解决方案

# 1. 配置文件错误
dockerd --validate
# 修复 /etc/docker/daemon.json 中的语法错误

# 2. 存储驱动问题
# 检查存储驱动
docker info | grep "Storage Driver"
# 修改存储驱动
vim /etc/docker/daemon.json
# {"storage-driver": "overlay2"}

# 3. SELinux 问题（RHEL/CentOS）
setenforce 0  # 临时关闭
# 永久关闭：编辑 /etc/selinux/config

# 4. 防火墙冲突
systemctl stop firewalld
systemctl disable firewalld

# 5. 重启服务
systemctl daemon-reload
systemctl restart docker
```

### 权限问题

```bash
# 错误: Got permission denied while trying to connect to the Docker daemon socket

# 解决方案 1：将用户加入 docker 组
sudo usermod -aG docker $USER
newgrp docker

# 解决方案 2：修改 socket 权限（不推荐）
sudo chmod 666 /var/run/docker.sock

# 解决方案 3：使用 sudo
sudo docker ps

# 验证用户组
groups $USER
id $USER
```

### 版本兼容问题

```bash
# 查看 Docker 版本
docker version

# 查看 Compose 版本
docker compose version

# 检查内核版本
uname -r

# Docker 最低内核要求: 3.10+
# 某些功能需要更高版本内核

# 更新 Docker
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# CentOS/RHEL
sudo yum update docker-ce docker-ce-cli containerd.io
```

---

## 容器运行问题

### 容器无法启动

```bash
# 查看容器退出原因
docker inspect <container_id> --format='{{.State.ExitCode}}'
docker inspect <container_id> --format='{{.State.Error}}'
docker inspect <container_id> --format='{{.State.OOMKilled}}'

# 查看容器日志
docker logs <container_id>

# 常见退出码
# 0: 正常退出
# 1: 应用错误
# 137: 被 SIGKILL 杀死（通常是 OOM）
# 139: 段错误
# 143: 被 SIGTERM 终止

# 检查是否 OOM
docker inspect <container_id> --format='{{.State.OOMKilled}}'

# 查看系统日志中的 OOM 记录
dmesg | grep -i "out of memory"
grep -i "oom" /var/log/syslog
```

### 容器频繁重启

```bash
# 检查重启策略
docker inspect <container_id> --format='{{.HostConfig.RestartPolicy.Name}}'

# 查看重启次数
docker inspect <container_id> --format='{{.RestartCount}}'

# 常见原因
# 1. 应用崩溃 - 检查日志
docker logs --tail 100 <container_id>

# 2. 健康检查失败
docker inspect <container_id> --format='{{json .State.Health}}'

# 3. 资源不足
docker stats --no-stream <container_id>

# 临时禁用自动重启调试
docker update --restart=no <container_id>
```

### 容器内存不足 (OOM)

```bash
# 检查是否发生 OOM
docker inspect <container_id> --format='{{.State.OOMKilled}}'

# 查看内存限制
docker inspect <container_id> --format='{{.HostConfig.Memory}}'

# 查看内存使用
docker stats --no-stream <container_id>

# 解决方案

# 1. 增加内存限制
docker update --memory 1g <container_id>

# 2. 设置内存交换
docker update --memory-swap 2g <container_id>

# 3. 调整 OOM 优先级
docker update --oom-score-adj -500 <container_id>

# 4. 排查内存泄漏
docker exec <container_id> top
docker exec <container_id> free -m
```

### 磁盘空间不足

```bash
# 检查磁盘使用
df -h
docker system df -v

# 清理未使用的资源
# 清理停止的容器
docker container prune

# 清理未使用的镜像
docker image prune -a

# 清理未使用的数据卷
docker volume prune

# 清理未使用的网络
docker network prune

# 全面清理
docker system prune -a --volumes

# 删除悬空镜像
docker rmi $(docker images -f "dangling=true" -q)

# 查看占用空间的容器
docker ps -s --format "table {{.Names}}\t{{.Size}}"

# 查看日志文件大小
du -sh /var/lib/docker/containers/*/*-json.log
```

### 日志文件过大

```bash
# 查看容器日志大小
ls -lh /var/lib/docker/containers/*/*-json.log

# 清空日志文件（不删除）
truncate -s 0 /var/lib/docker/containers/*/*-json.log

# 配置日志限制
# 方法 1: daemon.json
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

# 方法 2: docker run 参数
docker run --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    nginx

# 方法 3: docker-compose
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

---

## 网络问题

### 容器无法访问外网

```bash
# 检查容器网络
docker exec <container_id> ping -c 4 8.8.8.8
docker exec <container_id> ping -c 4 google.com

# 检查 DNS
docker exec <container_id> cat /etc/resolv.conf

# 检查网桥
ip addr show docker0

# 检查 NAT 规则
iptables -t nat -L -n

# 检查 IP 转发
cat /proc/sys/net/ipv4/ip_forward
# 如果为 0，开启转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 检查 Docker 网络配置
docker network inspect bridge

# 设置 DNS
docker run --dns 8.8.8.8 --dns 8.8.4.4 <image>
```

### 容器间无法通信

```bash
# 检查是否在同一网络
docker network inspect <network_name>

# 检查容器 IP
docker inspect <container_id> --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

# 检查防火墙规则
iptables -L -n

# 检查 ICC 设置
docker network inspect bridge | grep com.docker.network.bridge.enable_icc

# 启用容器间通信
# 创建网络时
docker network create --opt com.docker.network.bridge.enable_icc=true mynet

# 使用自定义网络（推荐）
docker network create app-network
docker run --network app-network --name app1 <image>
docker run --network app-network --name app2 <image>

# 使用服务名通信
docker exec app1 ping app2
```

### 端口映射问题

```bash
# 查看端口映射
docker port <container_id>

# 检查端口是否被占用
netstat -tlnp | grep <port>
lsof -i :<port>
ss -tlnp | grep <port>

# 检查 NAT 规则
iptables -t nat -L -n | grep <port>

# 检查容器内服务是否监听
docker exec <container_id> netstat -tlnp

# 常见问题
# 1. 容器内服务未监听正确端口
# 2. 容器内服务只监听 127.0.0.1
# 3. 主机端口已被占用
# 4. 防火墙阻止访问

# 测试端口连通性
# 从主机访问容器
curl http://localhost:<mapped_port>

# 从外部访问
curl http://<host_ip>:<mapped_port>
```

### DNS 解析问题

```bash
# 检查容器 DNS 配置
docker exec <container_id> cat /etc/resolv.conf

# 测试 DNS 解析
docker exec <container_id> nslookup google.com
docker exec <container_id> dig google.com

# 设置自定义 DNS
docker run --dns 8.8.8.8 --dns 8.8.4.4 <image>

# 设置 DNS 搜索域
docker run --dns-search example.com <image>

# 添加 hosts 记录
docker run --add-host myhost:192.168.1.100 <image>

# 在 daemon.json 中设置默认 DNS
# /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

---

## 存储问题

### 数据卷挂载失败

```bash
# 检查挂载点
docker inspect <container_id> --format='{{json .Mounts}}' | jq

# 检查主机目录权限
ls -la /host/path

# 检查 SELinux 上下文（RHEL/CentOS）
ls -Z /host/path

# 解决 SELinux 问题
# 方法 1: 添加 :z 或 :Z 后缀
docker run -v /host/path:/container/path:z <image>

# 方法 2: 更改 SELinux 上下文
chcon -Rt svirt_sandbox_file_t /host/path

# 检查目录是否存在
docker run --rm -v /host/path:/data alpine ls /data
```

### 权限问题

```bash
# 检查容器内用户
docker exec <container_id> id

# 检查文件权限
docker exec <container_id> ls -la /app

# 解决方案

# 1. 使用 root 运行
docker exec -u root <container_id> chown -R app:app /app

# 2. 在 Dockerfile 中设置用户
USER appuser

# 3. 挂载时设置权限
# 确保主机目录权限正确
sudo chown -R 1000:1000 /host/path

# 4. 使用 Dockerfile 中的 USER 指令
RUN chown -R appuser:appuser /app
USER appuser
```

### 数据卷清理

```bash
# 列出所有数据卷
docker volume ls

# 查看数据卷使用情况
docker system df -v | grep -A 100 "Volumes space usage"

# 列出悬空卷
docker volume ls -f dangling=true

# 删除悬空卷
docker volume prune

# 查看哪些容器使用了数据卷
docker ps -a --filter volume=<volume_name>

# 强制删除数据卷（需要先停止容器）
docker volume rm -f <volume_name>
```

---

## 构建问题

### 构建失败

```bash
# 查看详细构建日志
docker build --progress=plain -t myapp .

# 不使用缓存构建
docker build --no-cache -t myapp .

# 查看构建历史
docker history myapp

# 常见构建错误

# 1. 网络问题 - 无法下载依赖
# 解决方案：配置代理
docker build --build-arg HTTP_PROXY=http://proxy:port .

# 2. 磁盘空间不足
# 解决方案：清理空间
docker system prune -a

# 3. 上下文过大
# 解决方案：使用 .dockerignore
echo "node_modules" >> .dockerignore
echo ".git" >> .dockerignore

# 4. COPY/ADD 失败
# 检查文件是否存在
ls -la ./file_to_copy
```

### 镜像拉取失败

```bash
# 检查网络连接
ping -c 4 hub.docker.com

# 检查 Docker 登录状态
cat ~/.docker/config.json

# 使用镜像加速
# /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com"
  ]
}

# 配置代理
# /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://proxy:port"
Environment="HTTPS_PROXY=http://proxy:port"

# 重启 Docker
systemctl daemon-reload
systemctl restart docker

# 手动指定镜像仓库
docker pull dockerproxy.com/library/nginx:latest
```

### 构建缓存问题

```bash
# 清除构建缓存
docker builder prune

# 清除所有构建缓存
docker builder prune -a

# 不使用缓存构建
docker build --no-cache -t myapp .

# 查看构建缓存
docker buildx du

# 使用特定缓存来源
docker build --cache-from myapp:previous .
```

---

## 性能问题

### CPU 占用过高

```bash
# 查看容器 CPU 使用
docker stats --no-stream

# 查看容器内进程
docker top <container_id>

# 限制 CPU 使用
docker run --cpus 1.0 <image>
docker update --cpus 1.0 <container_id>

# 绑定 CPU 核心
docker run --cpuset-cpus 0,1 <image>

# 设置 CPU 权重
docker run --cpu-shares 512 <image>

# 使用 cgroups 查看
cat /sys/fs/cgroup/cpu/docker/<container_id>/cpuacct.usage
```

### 内存占用过高

```bash
# 查看内存使用
docker stats --no-stream <container_id>

# 限制内存使用
docker run --memory 512m <image>
docker update --memory 512m <container_id>

# 设置内存交换限制
docker run --memory 512m --memory-swap 1g <image>

# 查看容器内存详情
docker exec <container_id> cat /proc/meminfo

# 内存分析工具
docker run --rm -it --pid=container:<container_id> \
    --cap-add SYS_PTRACE \
    -v /usr/lib:/usr/lib:ro \
    -v /usr/bin:/usr/bin:ro \
    memcached top
```

### IO 性能问题

```bash
# 查看磁盘 IO
docker stats --no-stream

# 使用 host 网络提高网络 IO
docker run --network host <image>

# 使用 tmpfs 提高临时文件 IO
docker run --tmpfs /tmp <image>
docker run --mount type=tmpfs,destination=/tmp,tmpfs-size=1g <image>

# 限制 IO
docker run --device-read-bps /dev/sda:10mb <image>
docker run --device-write-bps /dev/sda:10mb <image>

# 查看存储驱动
docker info | grep "Storage Driver"

# 更换存储驱动为 overlay2（推荐）
# /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
```

---

## 调试技巧

### 使用调试容器

```bash
# 网络调试容器
docker run --rm -it nicolaka/netshoot bash

# 常用工具
# 网络诊断
ping, traceroute, mtr, dig, nslookup, curl, wget, nc, ss, netstat
# 抓包分析
tcpdump -i eth0 -nn -vv
# HTTP 调试
curl -v http://service:port

# 进入容器网络命名空间调试
docker run --rm -it --network container:<target_container> nicolaka/netshoot

# 进程调试容器
docker run --rm -it --pid container:<target_container> alpine ps aux

# 文件系统调试
docker run --rm -it --volumes-from <target_container> alpine sh
```

### 日志分析

```bash
# Docker 服务日志
journalctl -u docker.service -f

# 容器日志
docker logs -f --tail 100 <container_id>

# 容器日志文件位置
ls -la /var/lib/docker/containers/*/

# 使用 grep 过滤日志
docker logs <container_id> | grep -i error
docker logs <container_id> | grep -i "exception\|error" --color

# 使用 jq 解析 JSON 日志
docker logs <container_id> 2>&1 | jq .

# 导出到文件分析
docker logs <container_id> > container.log 2>&1
```

### 进入容器调试

```bash
# 进入容器 Shell
docker exec -it <container_id> /bin/sh
docker exec -it <container_id> bash

# 以 root 用户进入
docker exec -u root -it <container_id> /bin/sh

# 执行单条命令
docker exec <container_id> ps aux
docker exec <container_id> netstat -tlnp

# 复制文件出来分析
docker cp <container_id>:/app/logs/error.log ./

# 如果没有 shell，使用 nsenter
PID=$(docker inspect --format {{.State.Pid}} <container_id>)
nsenter -t $PID -m -u -i -n sh

# 使用 debug 镜像
docker run --rm -it --pid container:<container_id> alpine sh
```

---

## 常用诊断脚本

### 快速诊断脚本

```bash
#!/bin/bash
# docker-diagnose.sh

echo "========== Docker 系统信息 =========="
docker info 2>/dev/null | grep -E "Server Version|Storage Driver|Cgroup|Kernel|Operating System|Total Memory|CPUs"

echo ""
echo "========== 磁盘使用情况 =========="
docker system df

echo ""
echo "========== 容器状态 =========="
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "========== 重启的容器 =========="
docker ps -a --filter "status=restarting" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "========== 退出的容器 =========="
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "========== 资源使用 TOP 5 =========="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6

echo ""
echo "========== 网络列表 =========="
docker network ls

echo ""
echo "========== 数据卷列表 =========="
docker volume ls
```

### 容器健康检查脚本

```bash
#!/bin/bash
# check-container-health.sh

CONTAINER=$1

if [ -z "$CONTAINER" ]; then
    echo "Usage: $0 <container_name_or_id>"
    exit 1
fi

echo "检查容器: $CONTAINER"
echo ""

# 检查容器状态
STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "错误: 容器不存在"
    exit 1
fi
echo "状态: $STATUS"

# 检查健康状态
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER 2>/dev/null)
if [ "$HEALTH" != "" ]; then
    echo "健康状态: $HEALTH"

    if [ "$HEALTH" != "healthy" ]; then
        echo ""
        echo "健康检查日志:"
        docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' $CONTAINER
    fi
fi

# 检查 OOM
OOM=$(docker inspect --format='{{.State.OOMKilled}}' $CONTAINER)
echo "OOM Killed: $OOM"

# 检查退出码
EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' $CONTAINER)
echo "退出码: $EXIT_CODE"

# 检查重启次数
RESTART_COUNT=$(docker inspect --format='{{.RestartCount}}' $CONTAINER)
echo "重启次数: $RESTART_COUNT"

# 显示最近日志
echo ""
echo "最近日志 (最后 10 行):"
docker logs --tail 10 $CONTAINER
```

---

## 命令速查表

| 问题类型 | 诊断命令 |
|---------|---------|
| 服务状态 | `systemctl status docker` |
| 磁盘使用 | `docker system df -v` |
| 容器日志 | `docker logs -f --tail 100 <container>` |
| 容器详情 | `docker inspect <container>` |
| 资源使用 | `docker stats --no-stream` |
| 网络检查 | `docker network inspect <network>` |
| 端口检查 | `docker port <container>` |
| 进入容器 | `docker exec -it <container> sh` |
| 清理资源 | `docker system prune -a --volumes` |

---

## 参考链接

- [Docker 故障排除文档](https://docs.docker.com/engine/troubleshooting/)
- [Docker 日志查看](https://docs.docker.com/config/containers/logging/)
- [Docker 网络故障排除](https://docs.docker.com/network/troubleshoot/)
- [Docker 存储故障排除](https://docs.docker.com/storage/troubleshooting/)
