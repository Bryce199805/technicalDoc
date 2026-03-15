# Docker 容器管理

## 容器基础概念

### 什么是容器

容器是镜像的运行实例，是一个独立运行的软件单元。容器与镜像的关系类似于面向对象编程中对象与类的关系：镜像是静态的定义，容器是镜像运行时的实体。

### 容器的特点

| 特点 | 说明 |
|------|------|
| **隔离性** | 通过 Namespace 实现进程、网络、文件系统等隔离 |
| **轻量级** | 共享主机内核，启动速度快 |
| **可移植性** | 在任何 Docker 环境中运行一致 |
| **可扩展性** | 可以快速创建和销毁多个实例 |
| **资源限制** | 通过 CGroups 限制 CPU、内存等资源使用 |

---

## 容器生命周期

### 生命周期图

```
                    ┌──────────────┐
         ┌─────────▶│   Running    │◀─────────┐
         │          │   运行中      │          │
         │          └──────┬───────┘          │
         │                 │                  │
         │    docker stop  │  docker start    │
         │    docker kill  │                  │
         │                 ▼                  │
         │          ┌──────────────┐          │
         │          │   Stopped    │──────────┘
         │          │   已停止      │   docker restart
         │          └──────────────┘
         │                 │
         │                 │ docker rm
         │                 ▼
         │          ┌──────────────┐
         │          │   Deleted    │
         │          │   已删除      │
         │          └──────────────┘
         │
         │  docker unpause
         │
┌────────┴──────┐
│    Paused     │
│    已暂停      │◀─────── docker pause
└───────────────┘
```

### 容器状态

| 状态 | 说明 | 触发命令 |
|------|------|---------|
| `created` | 已创建但未启动 | `docker create` |
| `running` | 正在运行 | `docker start`, `docker run` |
| `paused` | 已暂停 | `docker pause` |
| `restarting` | 正在重启 | 重启策略触发 |
| `exited` | 已退出 | `docker stop`, `docker kill`, 进程结束 |
| `dead` | 已死亡 | 通常因磁盘空间不足 |
| `removing` | 正在删除 | `docker rm` |

---

## 容器操作命令

### 1. 创建容器

#### docker create（创建但不启动）

```bash
# 创建容器
docker create --name mynginx nginx:latest

# 创建并设置端口映射
docker create --name mynginx -p 80:80 nginx:latest

# 创建并挂载数据卷
docker create --name mynginx -v /data/nginx:/usr/share/nginx/html nginx:latest

# 创建后启动
docker start mynginx
```

#### docker run（创建并启动）

```bash
# 基本用法
docker run nginx:latest

# 后台运行
docker run -d nginx:latest

# 交互式运行
docker run -it ubuntu:22.04 /bin/bash

# 指定名称
docker run --name mynginx nginx:latest

# 设置端口映射
docker run -d -p 80:80 --name mynginx nginx:latest

# 设置环境变量
docker run -d -e MYSQL_ROOT_PASSWORD=root mysql:8.0

# 挂载数据卷
docker run -d -v /data/mysql:/var/lib/mysql mysql:8.0

# 设置重启策略
docker run -d --restart=always nginx:latest
```

### 2. docker run 参数详解

#### 运行模式参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-d` | 后台运行（守护式容器） | `docker run -d nginx` |
| `-i` | 保持 STDIN 打开 | `docker run -i ubuntu` |
| `-t` | 分配伪终端 | `docker run -t ubuntu` |
| `-it` | 交互式终端 | `docker run -it ubuntu bash` |
| `--rm` | 容器退出后自动删除 | `docker run --rm alpine echo hello` |
| `--detach-keys` | 指定脱离容器的按键 | `--detach-keys="ctrl-x"` |

#### 容器标识参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--name` | 容器名称 | `--name myapp` |
| `--hostname` | 容器主机名 | `--hostname web01` |
| `--domainname` | 容器域名 | `--domainname example.com` |
| `--mac-address` | MAC 地址 | `--mac-address 00:00:00:00:00:01` |

#### 网络参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-p` | 端口映射 | `-p 80:80`, `-p 8080:80` |
| `-P` | 随机端口映射 | `-P` |
| `--network` | 指定网络 | `--network bridge` |
| `--ip` | 指定 IP 地址 | `--ip 172.17.0.100` |
| `--dns` | DNS 服务器 | `--dns 8.8.8.8` |
| `--add-host` | 添加 hosts 记录 | `--add-host myhost:192.168.1.1` |
| `--expose` | 暴露端口（不映射） | `--expose 8080` |

#### 存储参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-v` | 挂载数据卷 | `-v /host:/container` |
| `--mount` | 挂载数据卷（更详细） | `--mount type=bind,src=/host,dst=/container` |
| `--tmpfs` | 挂载 tmpfs | `--tmpfs /tmp` |
| `-w` | 工作目录 | `-w /app` |

#### 资源限制参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-m, --memory` | 内存限制 | `-m 512m` |
| `--memory-swap` | 内存+交换分区限制 | `--memory-swap 1g` |
| `--memory-reservation` | 内存软限制 | `--memory-reservation 256m` |
| `--cpus` | CPU 核心数 | `--cpus 1.5` |
| `--cpu-shares` | CPU 权重 | `--cpu-shares 512` |
| `--cpuset-cpus` | 绑定 CPU 核心 | `--cpuset-cpus 0,1` |
| `--device` | 设备映射 | `--device /dev/sda:/dev/xvda` |
| `--ulimit` | Ulimit 配置 | `--ulimit nofile=65535:65535` |

#### 环境变量参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-e, --env` | 设置环境变量 | `-e MYSQL_ROOT_PASSWORD=root` |
| `--env-file` | 从文件读取环境变量 | `--env-file .env` |
| `--label` | 设置标签 | `--label app=web` |

#### 用户和权限参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-u, --user` | 运行用户 | `-u 1000:1000` |
| `--privileged` | 特权模式 | `--privileged` |
| `--cap-add` | 添加 Linux 能力 | `--cap-add NET_ADMIN` |
| `--cap-drop` | 删除 Linux 能力 | `--cap-drop ALL` |

#### 重启策略参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--restart no` | 不自动重启（默认） | `--restart no` |
| `--restart on-failure` | 非正常退出时重启 | `--restart on-failure:5` |
| `--restart always` | 总是重启 | `--restart always` |
| `--restart unless-stopped` | 除非手动停止否则重启 | `--restart unless-stopped` |

### 3. 启动和停止容器

```bash
# 启动已停止的容器
docker start mycontainer
docker start container_id

# 启动并附加到容器
docker start -a mycontainer

# 停止容器（发送 SIGTERM，等待 10 秒后发送 SIGKILL）
docker stop mycontainer

# 停止容器（指定等待时间）
docker stop -t 30 mycontainer

# 强制停止容器（发送 SIGKILL）
docker kill mycontainer

# 重启容器
docker restart mycontainer

# 暂停容器
docker pause mycontainer

# 恢复暂停的容器
docker unpause mycontainer

# 等待容器停止
docker wait mycontainer
```

### 4. 查看容器

```bash
# 列出运行中的容器
docker ps

# 列出所有容器（包括停止的）
docker ps -a

# 只显示容器 ID
docker ps -q

# 显示所有容器 ID
docker ps -aq

# 显示容器大小
docker ps -s

# 格式化输出
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

# 过滤容器
docker ps --filter "status=running"
docker ps --filter "name=nginx"
docker ps --filter "ancestor=nginx:latest"

# 显示最近创建的容器
docker ps -l
docker ps -n 5    # 显示最近 5 个

# 查看容器详情
docker inspect mycontainer

# 查看特定字段
docker inspect --format='{{.State.Status}}' mycontainer
docker inspect --format='{{.NetworkSettings.IPAddress}}' mycontainer
docker inspect --format='{{.HostConfig.Memory}}' mycontainer
```

### 5. 进入容器

#### docker exec（推荐）

```bash
# 在容器中执行命令
docker exec mycontainer ls /app

# 进入交互式终端
docker exec -it mycontainer /bin/bash
docker exec -it mycontainer sh

# 以指定用户执行
docker exec -u root mycontainer whoami

# 设置工作目录
docker exec -w /app mycontainer ls

# 设置环境变量
docker exec -e DEBUG=true mycontainer env

# 在后台执行
docker exec -d mycontainer touch /app/test.txt

# 保持 STDIN 打开
docker exec -i mycontainer cat < local_file.txt
```

#### docker attach（不推荐）

```bash
# 附加到容器的 STDIN/STDOUT/STDERR
docker attach mycontainer

# 使用 detach-keys 退出而不停止容器
docker attach --detach-keys="ctrl-x" mycontainer
```

#### exec vs attach

| 特性 | exec | attach |
|------|------|--------|
| 创建新进程 | 是 | 否 |
| 适用场景 | 执行命令、调试 | 查看容器输出 |
| 退出方式 | exit 退出 | Ctrl+C 可能停止容器 |
| 多终端支持 | 支持 | 不支持 |

### 6. 查看日志

```bash
# 查看日志
docker logs mycontainer

# 实时查看日志
docker logs -f mycontainer

# 查看最后 N 行日志
docker logs --tail 100 mycontainer

# 查看指定时间范围的日志
docker logs --since 2023-01-01 mycontainer
docker logs --since 1h mycontainer
docker logs --until 2023-12-31 mycontainer

# 显示时间戳
docker logs -t mycontainer

# 查看详细日志信息
docker logs --details mycontainer

# 组合使用
docker logs -f --tail 100 --since 1h mycontainer
```

### 7. 查看容器资源使用

```bash
# 查看所有容器资源使用
docker stats

# 查看指定容器
docker stats mycontainer

# 不实时刷新（只显示一次）
docker stats --no-stream

# 格式化输出
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# 查看容器进程
docker top mycontainer

# 查看容器端口映射
docker port mycontainer
```

### 8. 容器与主机文件传输

```bash
# 从主机复制文件到容器
docker cp /host/path/file.txt mycontainer:/container/path/

# 从容器复制文件到主机
docker cp mycontainer:/container/path/file.txt /host/path/

# 复制目录
docker cp /host/data mycontainer:/app/

# 使用容器 ID 复制（适用于停止的容器）
docker cp container_id:/app/logs/ ./logs/
```

### 9. 删除容器

```bash
# 删除已停止的容器
docker rm mycontainer

# 强制删除运行中的容器
docker rm -f mycontainer

# 删除所有容器
docker rm $(docker ps -aq)

# 删除所有已停止的容器
docker container prune

# 删除时删除关联的数据卷
docker rm -v mycontainer

# 删除超过 24 小时前创建的已停止容器
docker container prune --filter "until=24h"
```

---

## 资源限制详解

### 内存限制

```bash
# 设置内存限制
docker run -d -m 512m nginx

# 设置内存和交换分区限制
docker run -d -m 512m --memory-swap 1g nginx

# 设置内存软限制
docker run -d -m 512m --memory-reservation 256m nginx

# 禁止使用交换分区
docker run -d -m 512m --memory-swap 512m nginx

# 设置 OOM 优先级（-1000 到 1000，越小越不容易被杀死）
docker run -d --oom-score-adj -500 nginx
```

### CPU 限制

```bash
# 设置 CPU 核心数
docker run -d --cpus 1.5 nginx

# 设置 CPU 权重（默认 1024）
docker run -d --cpu-shares 512 nginx

# 绑定 CPU 核心
docker run -d --cpuset-cpus 0,1 nginx

# 设置 CPU 周期和配额
docker run -d --cpu-period 100000 --cpu-quota 50000 nginx
```

### IO 限制

```bash
# 设置 IO 权重（10-1000）
docker run -d --blkio-weight 500 nginx

# 限制读速度
docker run -d --device-read-bps /dev/sda:10mb nginx

# 限制写速度
docker run -d --device-write-bps /dev/sda:10mb nginx

# 限制读 IOPS
docker run -d --device-read-iops /dev/sda:1000 nginx

# 限制写 IOPS
docker run -d --device-write-iops /dev/sda:1000 nginx
```

### 组合示例

```bash
# 综合资源限制
docker run -d \
    --name myapp \
    -m 1g \
    --memory-swap 2g \
    --cpus 2 \
    --cpu-shares 1024 \
    --cpuset-cpus 0,1 \
    --device-read-bps /dev/sda:50mb \
    --device-write-bps /dev/sda:50mb \
    --ulimit nofile=65535:65535 \
    nginx:latest
```

---

## 健康检查

### 在容器运行时设置健康检查

```bash
# 使用 docker run 设置健康检查
docker run -d \
    --name mynginx \
    --health-cmd "curl -f http://localhost/ || exit 1" \
    --health-interval 30s \
    --health-timeout 5s \
    --health-retries 3 \
    --health-start-period 10s \
    nginx:latest
```

### 健康检查参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--health-cmd` | 健康检查命令 | 无 |
| `--health-interval` | 检查间隔 | 30s |
| `--health-timeout` | 命令超时时间 | 30s |
| `--health-retries` | 连续失败次数标记为不健康 | 3 |
| `--health-start-period` | 启动等待时间 | 0s |

### 查看健康状态

```bash
# 查看容器健康状态
docker inspect --format='{{.State.Health.Status}}' mynginx

# 查看健康检查详情
docker inspect --format='{{json .State.Health}}' mynginx | jq

# 禁用健康检查
docker run -d --no-healthcheck nginx
```

---

## 容器监控与调试

### 查看容器事件

```bash
# 实时查看容器事件
docker events

# 过滤事件
docker events --filter container=mycontainer
docker events --filter event=start
docker events --filter event=stop

# 查看指定时间范围的事件
docker events --since 1h
docker events --since 2023-01-01 --until 2023-12-31
```

### 查看容器变更

```bash
# 查看容器文件系统变更
docker diff mycontainer

# 输出说明
# A - Added（添加）
# D - Deleted（删除）
# C - Changed（修改）
```

### 查看容器端口

```bash
# 查看端口映射
docker port mycontainer

# 查看指定端口
docker port mycontainer 80
```

### 导出容器

```bash
# 导出容器文件系统
docker export mycontainer > mycontainer.tar

# 导出到压缩文件
docker export mycontainer | gzip > mycontainer.tar.gz
```

---

## 批量操作

```bash
# 停止所有运行中的容器
docker stop $(docker ps -q)

# 删除所有已停止的容器
docker rm $(docker ps -aq -f status=exited)

# 删除所有容器
docker rm -f $(docker ps -aq)

# 删除所有镜像为 nginx 的容器
docker rm $(docker ps -aq --filter ancestor=nginx)

# 批量重启容器
docker restart $(docker ps -q)

# 按名称模式删除容器
docker rm $(docker ps -a | grep "test_" | awk '{print $1}')
```

---

## 最佳实践

### 1. 容器命名规范

```bash
# 推荐命名格式
project_service_index

# 示例
webapp_nginx_1
webapp_mysql_1
webapp_redis_1
```

### 2. 资源限制

```bash
# 始终设置资源限制
docker run -d \
    --name myapp \
    -m 512m \
    --cpus 0.5 \
    --restart unless-stopped \
    myapp:latest
```

### 3. 日志管理

```bash
# 配置日志驱动和限制
docker run -d \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    nginx
```

### 4. 安全配置

```bash
# 安全运行容器
docker run -d \
    --user 1000:1000 \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    --read-only \
    --tmpfs /tmp \
    --security-opt no-new-privileges \
    nginx
```

### 5. 使用标签

```bash
# 添加标签便于管理
docker run -d \
    --label app=webapp \
    --label env=production \
    --label version=1.0.0 \
    nginx
```

---

## 命令速查表

| 命令 | 说明 |
|------|------|
| `docker run` | 创建并启动容器 |
| `docker create` | 创建容器 |
| `docker start` | 启动容器 |
| `docker stop` | 停止容器 |
| `docker restart` | 重启容器 |
| `docker kill` | 强制停止容器 |
| `docker pause` | 暂停容器 |
| `docker unpause` | 恢复容器 |
| `docker rm` | 删除容器 |
| `docker ps` | 列出容器 |
| `docker inspect` | 查看容器详情 |
| `docker logs` | 查看日志 |
| `docker exec` | 在容器中执行命令 |
| `docker attach` | 附加到容器 |
| `docker cp` | 复制文件 |
| `docker stats` | 查看资源使用 |
| `docker top` | 查看容器进程 |
| `docker port` | 查看端口映射 |
| `docker diff` | 查看文件变更 |
| `docker events` | 查看事件 |
| `docker export` | 导出容器 |
| `docker wait` | 等待容器停止 |

---

## 参考链接

- [Docker 容器文档](https://docs.docker.com/engine/reference/commandline/container/)
- [Docker run 参考](https://docs.docker.com/engine/reference/run/)
- [Resource constraints](https://docs.docker.com/config/containers/resource_constraints/)
- [Healthcheck](https://docs.docker.com/engine/reference/builder/#healthcheck)
