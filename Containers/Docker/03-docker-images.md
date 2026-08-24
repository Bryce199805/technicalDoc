# Docker 镜像管理

## 镜像基础概念

### 什么是镜像

Docker 镜像是一个只读的文件包，包含了运行应用所需的所有内容：代码、运行时、库、环境变量和配置文件。镜像是容器的基础，通过镜像可以创建多个容器实例。

### 镜像的分层结构

```
┌─────────────────────────────────────────────────────────┐
│                    Docker 镜像                          │
├─────────────────────────────────────────────────────────┤
│  Layer 4: 应用代码 (app.jar)                     [R/O]  │
├─────────────────────────────────────────────────────────┤
│  Layer 3: 应用配置 (application.yml)             [R/O]  │
├─────────────────────────────────────────────────────────┤
│  Layer 2: 运行时环境 (JDK 17)                    [R/O]  │
├─────────────────────────────────────────────────────────┤
│  Layer 1: 基础系统 (Ubuntu 22.04)                [R/O]  │
└─────────────────────────────────────────────────────────┘
```

#### 分层的优势

| 优势 | 说明 |
|------|------|
| **存储效率** | 相同层在本地只存储一份 |
| **传输效率** | 只传输本地不存在的层 |
| **构建效率** | 利用缓存加速构建 |
| **版本管理** | 便于追踪和回滚 |

### Union File System（联合文件系统）

```
┌─────────────────────────────────────────────────────────┐
│                      容器视图                           │
│                                                          │
│    /app/                                                 │
│    ├── config/                                          │
│    │   └── app.yml          ← Layer 3                   │
│    └── lib/                                             │
│        └── app.jar          ← Layer 4                   │
│    /usr/                                                 │
│    └── lib/jvm/            ← Layer 2                    │
│    /bin/, /etc/, ...       ← Layer 1                    │
│                                                          │
│    修改文件时 → 写时复制到容器层                           │
└─────────────────────────────────────────────────────────┘
```

---

## 镜像操作命令

### 1. 查看镜像

```bash
# 列出本地所有镜像
docker images

# 列出所有镜像（包括中间层镜像）
docker images -a

# 只显示镜像 ID
docker images -q

# 显示镜像摘要
docker images --digests

# 格式化输出
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# 过滤镜像
docker images --filter "dangling=true"      # 悬空镜像
docker images --filter "reference=nginx"    # 按名称过滤
docker images --filter "since=ubuntu:22.04" # 在某镜像之后构建的

# 按大小排序
docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | sort -k 2 -h
```

#### 输出字段说明

```
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         latest    605c77e624dd   2 weeks ago    141MB
ubuntu        22.04     ba6acccedd29   3 months ago   72.8MB

REPOSITORY: 仓库名称
TAG: 标签（版本）
IMAGE ID: 镜像唯一标识（SHA256 的前12位）
CREATED: 创建时间
SIZE: 镜像大小（所有层的虚拟大小之和）
```

### 2. 搜索镜像

```bash
# 在 Docker Hub 搜索镜像
docker search nginx

# 限制搜索结果数量
docker search --limit 5 nginx

# 只显示官方镜像
docker search --filter "is-official=true" nginx

# 搜索星标数超过 100 的镜像
docker search --filter "stars=100" nginx

# 格式化输出
docker search --format "table {{.Name}}\t{{.Stars}}\t{{.IsOfficial}}" nginx
```

#### 输出字段说明

```
NAME                              DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
nginx                             Official build of Nginx.                        18000     [OK]
jwilder/nginx-proxy               Automated Nginx reverse proxy...               2400                 [OK]

NAME: 镜像名称
DESCRIPTION: 描述
STARS: 星标数
OFFICIAL: 是否官方镜像 [OK]
AUTOMATED: 是否自动构建 [OK]
```

### 3. 拉取镜像

```bash
# 拉取最新版本（latest 标签）
docker pull nginx

# 拉取指定标签
docker pull nginx:1.21-alpine
docker pull nginx:stable

# 拉取指定平台镜像
docker pull --platform linux/arm64 nginx:alpine

# 拉取指定摘要的镜像
docker pull nginx@sha256:abc123...

# 拉取所有标签
docker pull --all-tags nginx

# 使用代理拉取
docker pull dockerproxy.com/library/nginx:latest

# 查看拉取进度
docker pull -a nginx
```

### 4. 推送镜像

```bash
# 登录仓库
docker login
docker login registry.example.com -u username -p password

# 标记镜像（打标签）
docker tag nginx:latest myregistry.com/mynginx:v1.0

# 推送镜像
docker push myregistry.com/mynginx:v1.0

# 推送所有标签
docker push --all-tags myregistry.com/mynginx

# 登出仓库
docker logout myregistry.com
```

### 5. 删除镜像

```bash
# 删除指定镜像（需先删除使用该镜像的容器）
docker rmi nginx:latest
docker rmi 605c77e624dd

# 强制删除（即使有容器在使用）
docker rmi -f nginx:latest

# 删除所有镜像
docker rmi $(docker images -q)

# 删除悬空镜像（<none> 标签）
docker image prune

# 删除所有未使用的镜像
docker image prune -a

# 删除指定条件的镜像
docker rmi $(docker images --filter "dangling=true" -q)

# 配合 awk 批量删除
docker rmi $(docker images | grep "none" | awk '{print $3}')
docker rmi $(docker images | grep "v1.0" | awk '{print $3}')
```

### 6. 查看镜像详情

```bash
# 查看镜像详细信息
docker inspect nginx:latest

# 查看特定字段
docker inspect --format='{{.Architecture}}' nginx:latest
docker inspect --format='{{.Os}}' nginx:latest
docker inspect --format='{{.Size}}' nginx:latest
docker inspect --format='{{.Config.Cmd}}' nginx:latest
docker inspect --format='{{.RootFS.Layers}}' nginx:latest

# 查看镜像历史
docker history nginx:latest

# 查看镜像历史（不截断）
docker history --no-trunc nginx:latest

# 查看镜像分层
docker history nginx:latest --format "table {{.CreatedBy}}\t{{.Size}}"
```

---

## 镜像导入导出

### docker save / docker load

用于将镜像保存为 tar 文件，可以迁移到其他机器。

```bash
# 保存单个镜像
docker save -o nginx.tar nginx:latest

# 保存多个镜像到一个文件
docker save -o images.tar nginx:latest ubuntu:22.04

# 保存并压缩
docker save nginx:latest | gzip > nginx.tar.gz

# 从 tar 文件加载镜像
docker load -i nginx.tar

# 从压缩文件加载
docker load < nginx.tar.gz

# 查看导入的镜像
docker images
```

#### 使用场景

| 场景 | 推荐方式 |
|------|---------|
| 离线环境部署 | save/load |
| 快速迁移镜像 | save/load |
| 镜像备份 | save/load |
| 容器持久化 | commit + save |

### docker export / docker import

用于将容器导出为 tar 文件，然后导入为镜像。

```bash
# 导出容器（不包含数据卷）
docker export -o container.tar mycontainer

# 导出并压缩
docker export mycontainer | gzip > container.tar.gz

# 从 tar 文件导入为镜像
docker import container.tar myimage:v1.0

# 从 URL 导入
docker import http://example.com/image.tar myimage:v1.0

# 从 stdin 导入
cat container.tar | docker import - myimage:v1.0

# 导入时指定变更
docker import -c "ENV DEBUG=true" container.tar myimage:v1.0
```

### save/load vs export/import

| 特性 | save/load | export/import |
|------|-----------|---------------|
| 操作对象 | 镜像 | 容器 |
| 包含内容 | 完整镜像（所有层、元数据、历史） | 容器快照（单层） |
| 保留历史 | 是 | 否 |
| 保留元数据 | 是 | 部分丢失 |
| 文件大小 | 较大 | 较小 |
| 典型用途 | 镜像迁移、备份 | 容器快照、轻量迁移 |

### docker commit

将容器的修改保存为新的镜像。

```bash
# 基本用法
docker commit mycontainer myimage:v1.0

# 添加作者信息
docker commit -a "author@example.com" mycontainer myimage:v1.0

# 添加说明信息
docker commit -m "Added custom configuration" mycontainer myimage:v1.0

# 暂停容器再提交（默认）
docker commit --pause=true mycontainer myimage:v1.0

# 修改启动命令
docker commit --change='CMD ["nginx", "-g", "daemon off;"]' mycontainer myimage:v1.0

# 添加环境变量
docker commit --change='ENV APP_ENV=production' mycontainer myimage:v1.0

# 暴露端口
docker commit --change='EXPOSE 8080' mycontainer myimage:v1.0
```

#### commit 示例

```bash
# 1. 启动一个容器并修改
docker run -it --name test ubuntu:22.04 /bin/bash

# 在容器内执行
apt-get update
apt-get install -y nginx
echo "Hello Docker" > /var/www/html/index.html
exit

# 2. 提交修改
docker commit -a "admin@example.com" -m "Ubuntu with nginx installed" test my-ubuntu-nginx:v1.0

# 3. 查看新镜像
docker images my-ubuntu-nginx

# 4. 使用新镜像
docker run -d -p 80:80 my-ubuntu-nginx:v1.0 nginx -g "daemon off;"
```

---

## 镜像仓库操作

### Docker Hub 操作

```bash
# 登录 Docker Hub
docker login

# 查看登录状态
cat ~/.docker/config.json

# 标记镜像
docker tag myapp:v1.0 username/myapp:v1.0

# 推送到 Docker Hub
docker push username/myapp:v1.0

# 拉取自己的镜像
docker pull username/myapp:v1.0

# 登出
docker logout
```

### 私有仓库操作

```bash
# 启动本地仓库
docker run -d -p 5000:5000 --name registry registry:2

# 标记镜像
docker tag myapp:v1.0 localhost:5000/myapp:v1.0

# 推送到本地仓库
docker push localhost:5000/myapp:v1.0

# 拉取
docker pull localhost:5000/myapp:v1.0

# 查看仓库中的镜像
curl -X GET http://localhost:5000/v2/_catalog

# 查看镜像的标签
curl -X GET http://localhost:5000/v2/myapp/tags/list
```

### 配置私有仓库（不验证证书）

```bash
# 编辑 daemon.json
sudo vim /etc/docker/daemon.json
```

```json
{
    "insecure-registries": ["registry.example.com:5000", "192.168.1.100:5000"]
}
```

```bash
# 重启 Docker
sudo systemctl restart docker
```

---

## 镜像构建

### 使用 Dockerfile 构建

```bash
# 基本构建
docker build -t myapp:v1.0 .

# 指定 Dockerfile 路径
docker build -t myapp:v1.0 -f /path/to/Dockerfile .

# 指定构建上下文
docker build -t myapp:v1.0 /path/to/context

# 传递构建参数
docker build -t myapp:v1.0 --build-arg VERSION=1.0.0 .

# 不使用缓存构建
docker build -t myapp:v1.0 --no-cache .

# 指定平台构建
docker build -t myapp:v1.0 --platform linux/arm64 .

# 指定目标阶段（多阶段构建）
docker build -t myapp:v1.0 --target builder .

# 添加标签
docker build -t myapp:v1.0 -t myapp:latest .

# 查看构建过程
docker build -t myapp:v1.0 --progress=plain .
```

### 使用 docker buildx（多平台构建）

```bash
# 创建 buildx 实例
docker buildx create --name mybuilder --use

# 启动构建器
docker buildx inspect mybuilder --bootstrap

# 构建多平台镜像
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:v1.0 .

# 构建并推送到仓库
docker buildx build --platform linux/amd64,linux/arm64 -t myregistry.com/myapp:v1.0 --push .

# 查看支持的平台
docker buildx inspect --bootstrap
```

---

## 镜像最佳实践

### 1. 选择合适的基础镜像

```dockerfile
# 不推荐：使用大镜像
FROM ubuntu:latest              # ~77 MB
FROM node:latest                # ~1 GB

# 推荐：使用精简镜像
FROM ubuntu:22.04               # ~77 MB，指定版本
FROM node:18-alpine             # ~50 MB，Alpine 版本
FROM alpine:3.18                # ~5 MB，最小化

# 生产环境推荐
FROM nginx:1.25-alpine          # Nginx Alpine 版本
FROM openjdk:17-jdk-slim        # Java 精简版
FROM python:3.11-slim           # Python 精简版
```

### 2. 多阶段构建

```dockerfile
# 构建阶段
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# 运行阶段
FROM alpine:3.18

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app
COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]
```

### 3. 优化镜像层

```dockerfile
# 不推荐：多层分散
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get install -y curl
RUN apt-get clean

# 推荐：合并层数
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### 4. 使用 .dockerignore

```
# .dockerignore 示例

# Git
.git
.gitignore

# 文档
README.md
docs/

# 测试
tests/
*.test.js
coverage/

# 依赖目录（构建时会安装）
node_modules/
vendor/

# 构建输出
dist/
build/
target/

# 日志
*.log
logs/

# IDE
.idea/
.vscode/
*.swp

# 环境文件
.env
.env.local
*.env

# 临时文件
tmp/
temp/
*.tmp
*.bak
```

### 5. 镜像标签规范

```bash
# 生产环境
myapp:1.0.0
myapp:1.0.0-alpine

# 开发环境
myapp:dev
myapp:feature-123

# 测试环境
myapp:staging
myapp:rc-1.0.0

# 使用 Git 提交哈希
myapp:1.0.0-abc123

# 使用构建时间
myapp:1.0.0-20231215
```

---

## 镜像清理

```bash
# 查看镜像磁盘使用
docker system df
docker system df -v

# 删除悬空镜像（<none>）
docker image prune

# 删除所有未使用的镜像
docker image prune -a

# 删除超过 24 小时未使用的镜像
docker image prune -a --filter "until=24h"

# 强制删除（不提示确认）
docker image prune -a -f

# 完整清理（包括容器、网络、镜像、构建缓存）
docker system prune -a

# 清理所有内容（包括数据卷）
docker system prune -a --volumes
```

---

## 镜像安全

### 1. 镜像扫描

```bash
# 使用 docker scout 扫描
docker scout cves nginx:latest

# 使用 trivy 扫描
trivy image nginx:latest

# 使用 docker scan（需要安装插件）
docker scan nginx:latest
```

### 2. 安全最佳实践

```dockerfile
# 使用特定版本，不使用 latest
FROM nginx:1.25.3-alpine

# 不使用 root 用户
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser
USER appuser

# 设置只读文件系统
# docker run --read-only myapp

# 限制容器能力
# docker run --cap-drop ALL --cap-add NET_BIND_SERVICE myapp

# 使用 secrets 管理敏感信息
# docker run --secret db_password myapp

# 扫描镜像漏洞
# trivy image myapp:v1.0
```

---

## 命令速查表

| 命令 | 说明 |
|------|------|
| `docker images` | 列出本地镜像 |
| `docker search` | 搜索镜像 |
| `docker pull` | 拉取镜像 |
| `docker push` | 推送镜像 |
| `docker rmi` | 删除镜像 |
| `docker tag` | 标记镜像 |
| `docker build` | 构建镜像 |
| `docker save` | 导出镜像到 tar 文件 |
| `docker load` | 从 tar 文件导入镜像 |
| `docker export` | 导出容器到 tar 文件 |
| `docker import` | 从 tar 文件导入为镜像 |
| `docker commit` | 将容器保存为镜像 |
| `docker inspect` | 查看镜像详情 |
| `docker history` | 查看镜像历史 |
| `docker image prune` | 删除未使用的镜像 |
| `docker system df` | 查看磁盘使用情况 |

---

## 参考链接

- [Docker 镜像文档](https://docs.docker.com/engine/reference/commandline/image/)
- [Docker Hub](https://hub.docker.com/)
- [Best practices for Dockerfile](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
