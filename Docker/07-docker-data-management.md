# Docker 数据管理

## 数据管理概述

Docker 容器的文件系统是临时的，容器删除后数据会丢失。为了持久化数据，Docker 提供了多种数据存储方式。

### 数据存储方式对比

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker 数据存储方式                           │
│                                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Volume        │  │  Bind Mount     │  │    tmpfs        │ │
│  │   数据卷         │  │  绑定挂载        │  │   临时文件系统   │ │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤ │
│  │ Docker 管理     │  │ 主机路径映射     │  │ 存储在内存中     │ │
│  │ /var/lib/docker │  │ 任意主机路径     │  │ 容器停止即删除   │ │
│  │ /volumes        │  │                 │  │                 │ │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤ │
│  │ ✓ 最佳选择      │  │ ✓ 开发环境      │  │ ✓ 敏感数据      │ │
│  │ ✓ 易于备份      │  │ ✓ 配置文件      │  │ ✓ 临时缓存      │ │
│  │ ✓ 跨平台兼容    │  │ ✓ 代码热更新    │  │ ✓ 高性能 IO     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Volume（数据卷）

### 什么是 Volume

Volume 是 Docker 管理的数据存储，存储在 `/var/lib/docker/volumes/` 目录下。Volume 是数据持久化的最佳选择。

### Volume 的特点

| 特点 | 说明 |
|------|------|
| Docker 管理 | 由 Docker 创建和管理 |
| 易于备份 | 使用标准工具即可备份 |
| 跨平台 | 在 Linux 和 Windows 上工作一致 |
| 安全共享 | 可以在多个容器间安全共享 |
| 性能优化 | 存储驱动优化 |

### Volume 操作命令

#### 创建 Volume

```bash
# 创建数据卷
docker volume create mydata

# 创建时指定驱动选项
docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m \
    mydata

# 创建时指定 NFS 存储
docker volume create --driver local \
    --opt type=nfs \
    --opt o=addr=192.168.1.100,rw \
    --opt device=:/export/data \
    nfs-volume
```

#### 查看 Volume

```bash
# 列出所有数据卷
docker volume ls

# 过滤数据卷
docker volume ls --filter name=mydata

# 格式化输出
docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}"

# 查看数据卷详情
docker volume inspect mydata

# 查看特定字段
docker volume inspect --format '{{.Mountpoint}}' mydata
```

#### 删除 Volume

```bash
# 删除指定数据卷（不能删除正在使用的）
docker volume rm mydata

# 删除所有未使用的数据卷
docker volume prune

# 强制删除
docker volume prune -f

# 删除超过 24 小时未使用的数据卷
docker volume prune --filter "until=24h"
```

### 使用 Volume

```bash
# 挂载数据卷
docker run -d --name mysql \
    -v mydata:/var/lib/mysql \
    mysql:8.0

# 使用 --mount 语法（推荐）
docker run -d --name mysql \
    --mount type=volume,src=mydata,dst=/var/lib/mysql \
    mysql:8.0

# 只读挂载
docker run -d --name app \
    --mount type=volume,src=config,dst=/etc/app,readonly \
    myapp

# 多数据卷
docker run -d --name app \
    -v data:/data \
    -v logs:/var/log/app \
    -v config:/etc/app \
    myapp

# 匿名卷（Docker 自动生成名称）
docker run -d -v /var/lib/mysql mysql:8.0
```

### -v vs --mount

| 特性 | -v | --mount |
|------|------|---------|
| 语法 | 简洁 | 详细 |
| 错误提示 | 静默处理 | 明确报错 |
| 推荐场景 | 单机开发 | 生产环境 |
| 功能 | 基本功能 | 完整功能 |

```bash
# -v 语法
docker run -v mydata:/var/lib/mysql mysql

# --mount 语法
docker run --mount type=volume,src=mydata,dst=/var/lib/mysql mysql

# --mount 详细选项
docker run --mount \
    type=volume, \
    src=mydata, \
    dst=/var/lib/mysql, \
    readonly, \
    volume-driver=local \
    mysql
```

---

## Bind Mount（绑定挂载）

### 什么是 Bind Mount

Bind Mount 将主机上的任意目录或文件直接挂载到容器中，完全依赖主机的文件系统结构。

### Bind Mount 的特点

| 优点 | 缺点 |
|------|------|
| 直接访问主机文件 | 依赖主机路径 |
| 实时同步 | 跨平台兼容性差 |
| 适合开发环境 | 安全性较低 |

### 使用 Bind Mount

```bash
# 使用 -v 语法
docker run -d --name nginx \
    -v /host/path:/container/path \
    nginx

# 使用 --mount 语法（推荐）
docker run -d --name nginx \
    --mount type=bind,src=/host/path,dst=/container/path \
    nginx

# 只读挂载
docker run -d --name nginx \
    --mount type=bind,src=/host/config,dst=/etc/nginx,readonly \
    nginx

# 挂载单个文件
docker run -d --name nginx \
    -v /host/nginx.conf:/etc/nginx/nginx.conf:ro \
    nginx

# 开发环境示例
docker run -it --rm \
    -v $(pwd):/app \
    -w /app \
    node:18 \
    npm run dev
```

### Bind Mount 应用场景

```bash
# 1. 开发环境（代码热更新）
docker run -d --name app \
    -v /home/user/project:/app \
    -w /app \
    node:18 npm run dev

# 2. 配置文件挂载
docker run -d --name nginx \
    -v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
    -v /etc/nginx/conf.d:/etc/nginx/conf.d:ro \
    nginx

# 3. 日志收集
docker run -d --name app \
    -v /var/log/app:/var/log/app \
    myapp

# 4. SSH 密钥
docker run -it --rm \
    -v ~/.ssh:/root/.ssh:ro \
    alpine ssh user@host
```

---

## tmpfs（临时文件系统）

### 什么是 tmpfs

tmpfs 将数据存储在内存中，容器停止后数据消失，适合存储敏感数据或临时缓存。

### tmpfs 的特点

| 特点 | 说明 |
|------|------|
| 存储位置 | 内存（不占用磁盘） |
| 性能 | 极高（内存速度） |
| 持久性 | 容器停止后数据丢失 |
| 安全性 | 适合存储敏感信息 |

### 使用 tmpfs

```bash
# 使用 --tmpfs
docker run -d --name app \
    --tmpfs /tmp \
    --tmpfs /var/cache \
    myapp

# 使用 --mount 语法
docker run -d --name app \
    --mount type=tmpfs,dst=/tmp \
    --mount type=tmpfs,dst=/var/cache \
    myapp

# 设置大小限制
docker run -d --name app \
    --mount type=tmpfs,dst=/tmp,tmpfs-size=100m \
    myapp

# 禁止执行（安全选项）
docker run -d --name app \
    --mount type=tmpfs,dst=/tmp,tmpfs-mode=1770 \
    myapp
```

### tmpfs 应用场景

```bash
# 1. 敏感数据
docker run -d --name app \
    --tmpfs /run/secrets \
    myapp

# 2. 临时缓存
docker run -d --name redis \
    --mount type=tmpfs,dst=/data,tmpfs-size=512m \
    redis

# 3. 安全临时文件
docker run -d --name nginx \
    --tmpfs /var/cache/nginx \
    --tmpfs /var/run \
    nginx
```

---

## 数据卷容器

### 什么是数据卷容器

数据卷容器是专门用于存储数据的容器，其他容器可以通过 `--volumes-from` 共享其数据卷。

### 创建数据卷容器

```bash
# 创建数据卷容器
docker create --name data-container \
    -v /data/mysql:/var/lib/mysql \
    -v /data/logs:/var/log/app \
    busybox

# 其他容器共享数据卷
docker run -d --name mysql \
    --volumes-from data-container \
    mysql:8.0

docker run -d --name backup \
    --volumes-from data-container \
    alpine tar czf /backup/mysql.tar.gz /var/lib/mysql
```

### 数据卷容器应用场景

```yaml
# docker-compose.yml
version: '3.8'

services:
  # 数据卷容器
  data:
    image: busybox
    volumes:
      - mysql-data:/var/lib/mysql
      - app-logs:/var/log/app
    command: "true"

  mysql:
    image: mysql:8.0
    volumes_from:
      - data

  app:
    image: myapp
    volumes_from:
      - data

volumes:
  mysql-data:
  app-logs:
```

---

## 数据备份与恢复

### 备份 Volume 数据

```bash
# 方法一：使用临时容器备份
docker run --rm \
    -v mydata:/data \
    -v $(pwd)/backup:/backup \
    alpine tar czf /backup/mydata-backup-$(date +%Y%m%d).tar.gz /data

# 方法二：备份到标准输出
docker run --rm \
    -v mydata:/data \
    alpine tar czf - /data > mydata-backup.tar.gz

# 方法三：使用数据卷容器备份
docker run --rm \
    --volumes-from data-container \
    -v $(pwd)/backup:/backup \
    alpine tar czf /backup/data-backup.tar.gz /var/lib/mysql

# 备份多个卷
docker run --rm \
    -v data1:/data1 \
    -v data2:/data2 \
    -v $(pwd)/backup:/backup \
    alpine tar czf /backup/all-data.tar.gz /data1 /data2
```

### 恢复 Volume 数据

```bash
# 方法一：从备份文件恢复
docker volume create mydata-restored
docker run --rm \
    -v mydata-restored:/data \
    -v $(pwd)/backup:/backup \
    alpine sh -c "cd / && tar xzf /backup/mydata-backup.tar.gz"

# 方法二：恢复到新容器
docker run -d --name mysql-restored \
    -v mydata-restored:/var/lib/mysql \
    mysql:8.0

# 方法三：从标准输入恢复
docker volume create mydata-restored
cat mydata-backup.tar.gz | docker run --rm -i \
    -v mydata-restored:/data \
    alpine tar xzf - -C /
```

### 自动化备份脚本

```bash
#!/bin/bash
# backup-docker-volumes.sh

BACKUP_DIR="/backup/docker-volumes"
DATE=$(date +%Y%m%d_%H%M%S)
VOLUMES=$(docker volume ls -q)

mkdir -p $BACKUP_DIR

for volume in $VOLUMES; do
    echo "Backing up volume: $volume"
    docker run --rm \
        -v $volume:/data \
        -v $BACKUP_DIR:/backup \
        alpine tar czf /backup/${volume}_${DATE}.tar.gz /data
done

# 删除超过 7 天的备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed!"
```

### 数据迁移

```bash
# 1. 导出数据
docker run --rm \
    -v mydata:/data \
    -v $(pwd):/backup \
    alpine tar czf /backup/data.tar.gz -C /data .

# 2. 传输到目标主机
scp data.tar.gz target-host:/tmp/

# 3. 在目标主机导入
docker volume create mydata
docker run --rm \
    -v mydata:/data \
    -v /tmp:/backup \
    alpine tar xzf /backup/data.tar.gz -C /data
```

---

## 数据共享

### 容器间共享数据

```bash
# 方法一：共享同一个 Volume
docker run -d --name writer -v shared-data:/data myapp
docker run -d --name reader -v shared-data:/data:ro myapp

# 方法二：使用数据卷容器
docker create --name data-container -v /shared busybox
docker run -d --name app1 --volumes-from data-container myapp
docker run -d --name app2 --volumes-from data-container myapp

# 方法三：使用 --volumes-from 读写分离
docker run -d --name app-read --volumes-from data-container:ro myapp
```

### Docker Compose 数据共享

```yaml
version: '3.8'

volumes:
  shared-data:
  config-data:

services:
  # 数据生产者
  producer:
    image: producer-app
    volumes:
      - shared-data:/data
      - config-data:/config:ro

  # 数据消费者
  consumer:
    image: consumer-app
    volumes:
      - shared-data:/data:ro

  # 日志收集
  log-collector:
    image: log-collector
    volumes:
      - shared-data:/logs:ro
```

---

## 存储驱动

### 存储驱动类型

| 驱动 | 说明 | 适用场景 |
|------|------|---------|
| `overlay2` | 当前推荐驱动 | 所有 Linux 发行版 |
| `aufs` | 早期默认驱动 | Ubuntu 14.04 |
| `btrfs` | Btrfs 文件系统 | 需要快照功能 |
| `devicemapper` | 块存储 | RHEL/CentOS |
| `vfs` | 兼容性驱动 | 特殊场景 |
| `zfs` | ZFS 文件系统 | 需要高级存储功能 |

### 查看存储驱动

```bash
# 查看当前存储驱动
docker info | grep "Storage Driver"

# 查看详细存储信息
docker info | grep -A 10 "Storage Driver"

# 修改存储驱动（需要修改 daemon.json）
# /etc/docker/daemon.json
{
    "storage-driver": "overlay2"
}
```

---

## 数据管理最佳实践

### 1. 选择正确的存储类型

| 场景 | 推荐存储类型 |
|------|-------------|
| 数据库数据 | Volume |
| 应用配置 | Bind Mount |
| 开发代码 | Bind Mount |
| 敏感数据 | tmpfs |
| 临时缓存 | tmpfs |
| 日志文件 | Volume 或 Bind Mount |

### 2. 命名规范

```bash
# 推荐命名格式
project_service_type

# 示例
webapp_mysql_data
webapp_nginx_logs
webapp_app_config
```

### 3. 数据安全

```bash
# 定期备份
0 2 * * * /path/to/backup-script.sh

# 只读挂载配置
docker run -v config:/etc/app:ro myapp

# 限制数据卷大小
docker run --storage-opt size=10g myapp
```

### 4. 清理策略

```bash
# 定期清理未使用的数据卷
docker volume prune -f

# 查看数据卷使用情况
docker system df -v

# 删除悬空卷
docker volume rm $(docker volume ls -qf dangling=true)
```

### 5. 性能优化

```bash
# 对于高性能需求，使用 tmpfs
docker run --mount type=tmpfs,dst=/cache,tmpfs-size=1g myapp

# 避免在 bind mount 中进行大量小文件操作
# 使用 volume 替代

# 使用 volume 选项优化性能
docker run --mount type=volume,src=mydata,dst=/data,volume-nocopy=true myapp
```

---

## 命令速查表

| 命令 | 说明 |
|------|------|
| `docker volume create` | 创建数据卷 |
| `docker volume ls` | 列出数据卷 |
| `docker volume inspect` | 查看数据卷详情 |
| `docker volume rm` | 删除数据卷 |
| `docker volume prune` | 删除未使用的数据卷 |
| `docker run -v` | 挂载数据卷 |
| `docker run --mount` | 挂载数据卷（详细语法） |
| `docker run --tmpfs` | 挂载 tmpfs |
| `docker run --volumes-from` | 从容器共享数据卷 |

---

## 参考链接

- [Docker 存储文档](https://docs.docker.com/storage/)
- [Volumes](https://docs.docker.com/storage/volumes/)
- [Bind mounts](https://docs.docker.com/storage/bind-mounts/)
- [tmpfs](https://docs.docker.com/storage/tmpfs/)
- [Storage drivers](https://docs.docker.com/storage/storagedriver/)
