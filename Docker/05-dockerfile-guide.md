# Dockerfile 编写指南

## 什么是 Dockerfile

Dockerfile 是一个文本文件，包含了构建 Docker 镜像的所有指令。Docker 通过读取 Dockerfile 中的指令自动构建镜像。

### Dockerfile 基本结构

```dockerfile
# 注释
INSTRUCTION arguments

# 典型结构
FROM base_image              # 基础镜像
LABEL maintainer="..."       # 元数据
RUN command                  # 构建时执行
COPY src dest                # 复制文件
WORKDIR /app                 # 设置工作目录
ENV KEY=value                # 环境变量
EXPOSE 80                    # 暴露端口
CMD ["executable"]           # 容器启动命令
```

---

## Dockerfile 指令详解

### FROM - 指定基础镜像

FROM 是 Dockerfile 的第一条指令，指定构建镜像的基础。

```dockerfile
# 使用官方镜像
FROM nginx:latest
FROM ubuntu:22.04
FROM alpine:3.18

# 使用特定平台镜像
FROM --platform=linux/arm64 alpine:3.18

# 使用多阶段构建中的阶段
FROM node:18-alpine AS builder

# 使用 scratch（空镜像）
FROM scratch
```

#### 常用基础镜像选择

| 镜像 | 大小 | 适用场景 |
|------|------|---------|
| `scratch` | 0 MB | 静态编译的 Go/Rust 程序 |
| `alpine` | ~5 MB | 最小化 Linux 环境 |
| `busybox` | ~1 MB | 极简工具集 |
| `debian:slim` | ~80 MB | Debian 精简版 |
| `ubuntu:22.04` | ~77 MB | Ubuntu 环境 |
| `centos:stream9` | ~150 MB | 企业级 Linux |

### LABEL - 添加元数据

```dockerfile
# 添加标签
LABEL maintainer="admin@example.com"
LABEL version="1.0.0"
LABEL description="My custom application"

# 多标签写法
LABEL maintainer="admin@example.com" \
      version="1.0.0" \
      description="My application"

# 推荐标签规范
LABEL org.opencontainers.image.title="MyApp"
LABEL org.opencontainers.image.description="Application description"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="author@example.com"
LABEL org.opencontainers.image.source="https://github.com/user/repo"
```

### RUN - 执行命令

RUN 指令在构建镜像时执行命令，并创建新的镜像层。

```dockerfile
# shell 格式
RUN apt-get update
RUN apt-get install -y nginx

# exec 格式（推荐）
RUN ["apt-get", "install", "-y", "nginx"]

# 多命令合并（减少层数）
RUN apt-get update && \
    apt-get install -y \
        nginx \
        curl \
        vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 使用反斜杠换行
RUN apt-get update \
    && apt-get install -y nginx \
    && apt-get clean

# 执行脚本
RUN chmod +x /app/start.sh

# 创建目录和文件
RUN mkdir -p /app/logs \
    && touch /app/logs/app.log
```

#### RUN 最佳实践

```dockerfile
# 不推荐：多条 RUN 指令
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get install -y curl
RUN apt-get clean

# 推荐：合并命令
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### CMD - 容器启动命令

CMD 指定容器启动时默认执行的命令。每个 Dockerfile 只能有一个 CMD，如果有多个则只有最后一个生效。

```dockerfile
# exec 格式（推荐，JSON 数组）
CMD ["nginx", "-g", "daemon off;"]
CMD ["node", "app.js"]
CMD ["java", "-jar", "app.jar"]

# shell 格式
CMD nginx -g "daemon off;"

# 作为 ENTRYPOINT 的默认参数
CMD ["--port", "8080"]
```

### ENTRYPOINT - 入口点

ENTRYPOINT 配置容器为可执行程序，允许容器作为命令行工具使用。

```dockerfile
# exec 格式（推荐）
ENTRYPOINT ["nginx"]
ENTRYPOINT ["docker-entrypoint.sh"]

# shell 格式
ENTRYPOINT nginx

# 与 CMD 配合使用
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]

# 相当于执行：nginx -g "daemon off;"
```

#### ENTRYPOINT vs CMD

| 特性 | ENTRYPOINT | CMD |
|------|-----------|-----|
| 可被覆盖 | 需要 `--entrypoint` | 直接传递参数 |
| 用途 | 定义可执行程序 | 定义默认参数/命令 |
| 组合使用 | 作为主命令 | 作为默认参数 |

```dockerfile
# 示例：灵活的启动配置
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
CMD ["--spring.profiles.active=prod"]

# 运行时覆盖 CMD
docker run myapp --spring.profiles.active=dev

# 运行时覆盖 ENTRYPOINT
docker run --entrypoint /bin/bash -it myapp
```

### COPY - 复制文件

```dockerfile
# 复制文件
COPY app.jar /app/app.jar

# 复制目录
COPY src/ /app/src/

# 使用相对路径
COPY . /app/

# 多源复制
COPY file1.txt file2.txt /app/

# 使用通配符
COPY *.jar /app/
COPY config/*.yml /app/config/

# 复制并设置权限
COPY --chmod=755 start.sh /app/start.sh

# 从其他阶段复制（多阶段构建）
COPY --from=builder /app/target/app.jar /app/

# 从其他镜像复制
COPY --from=nginx:latest /etc/nginx/nginx.conf /etc/nginx/nginx.conf
```

### ADD - 添加文件

ADD 比 COPY 功能更多，支持 URL 和自动解压 tar 文件。

```dockerfile
# 复制本地文件（与 COPY 相同）
ADD app.jar /app/

# 从 URL 下载文件
ADD https://example.com/file.tar.gz /tmp/

# 自动解压 tar 文件
ADD archive.tar.gz /app/

# 添加目录
ADD src/ /app/src/
```

#### COPY vs ADD

| 特性 | COPY | ADD |
|------|------|-----|
| 复制本地文件 | ✓ | ✓ |
| 从 URL 下载 | ✗ | ✓ |
| 自动解压 tar | ✗ | ✓ |
| 推荐使用 | ✓ | 仅在需要解压/下载时 |

```dockerfile
# 推荐：使用 COPY 复制本地文件
COPY app.jar /app/

# 使用 ADD 解压文件
ADD archive.tar.gz /app/

# 不推荐：使用 ADD 下载（应在 RUN 中使用 curl/wget）
# ADD https://example.com/file.tar.gz /tmp/
RUN curl -fsSL https://example.com/file.tar.gz | tar xz -C /tmp/
```

### WORKDIR - 工作目录

```dockerfile
# 设置工作目录
WORKDIR /app

# 后续指令在 /app 下执行
RUN pwd  # 输出 /app
COPY . .

# 相对路径（基于上一个 WORKDIR）
WORKDIR src
RUN pwd  # 输出 /app/src

# 如果目录不存在会自动创建
WORKDIR /path/to/app

# 多次使用
WORKDIR /app
WORKDIR src
WORKDIR test
RUN pwd  # 输出 /app/src/test
```

### ENV - 环境变量

```dockerfile
# 设置环境变量
ENV APP_ENV=production
ENV JAVA_HOME=/usr/lib/jvm/java-17

# 多变量设置
ENV APP_ENV=production \
    LOG_LEVEL=info \
    PORT=8080

# 在后续指令中使用
ENV APP_DIR=/app
WORKDIR $APP_DIR
COPY app.jar $APP_DIR/

# 运行时覆盖
# docker run -e APP_ENV=development myapp
```

### ARG - 构建参数

ARG 定义构建时的变量，仅在构建过程中有效。

```dockerfile
# 定义构建参数
ARG VERSION=1.0.0
ARG BUILD_DATE

# 使用构建参数
FROM nginx:${VERSION}

# 构建时传递参数
# docker build --build-arg VERSION=2.0.0 --build-arg BUILD_DATE=$(date +%Y-%m-%d) .

# ARG 的作用域
ARG GLOBAL_ARG=global
FROM alpine
ARG GLOBAL_ARG  # 需要重新声明
RUN echo $GLOBAL_ARG

# ARG 与 ENV 的区别
ARG BUILD_VERSION=1.0    # 构建时有效
ENV APP_VERSION=1.0      # 运行时有效
```

### EXPOSE - 暴露端口

```dockerfile
# 暴露端口
EXPOSE 80
EXPOSE 443

# 指定协议
EXPOSE 80/tcp
EXPOSE 53/udp

# 暴露多个端口
EXPOSE 80 443 8080

# 说明：EXPOSE 只是声明，实际端口映射需要 -p 参数
```

### VOLUME - 数据卷

```dockerfile
# 创建匿名卷
VOLUME /data
VOLUME /var/log

# 创建多个卷
VOLUME ["/data", "/var/log"]

# 说明：VOLUME 声明的目录会在容器运行时自动挂载
# 可以通过 docker run -v 覆盖挂载位置
```

### USER - 运行用户

```dockerfile
# 切换用户
USER nginx
USER 1000
USER 1000:1000

# 创建用户并切换
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# 后续命令以该用户执行
WORKDIR /app
RUN chown -R appuser:appuser /app
USER appuser
CMD ["node", "app.js"]
```

### HEALTHCHECK - 健康检查

```dockerfile
# 设置健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# 参数说明
# --interval: 检查间隔（默认 30s）
# --timeout: 超时时间（默认 30s）
# --start-period: 启动等待时间（默认 0s）
# --retries: 连续失败次数（默认 3）

# 禁用健康检查
HEALTHCHECK NONE

# 健康检查示例
HEALTHCHECK --interval=5m --timeout=3s \
    CMD curl -f http://localhost:8080/health || exit 1

# MySQL 健康检查
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
    CMD mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD}
```

### ONBUILD - 构建触发器

ONBUILD 指令创建一个触发器，当该镜像作为其他镜像的基础镜像时执行。

```dockerfile
# 父镜像 Dockerfile
FROM node:18-alpine
WORKDIR /app
ONBUILD COPY package*.json ./
ONBUILD RUN npm install
ONBUILD COPY . .
CMD ["npm", "start"]

# 子镜像 Dockerfile（会自动执行父镜像的 ONBUILD 指令）
FROM my-node-base
# 自动执行：
# COPY package*.json ./
# RUN npm install
# COPY . .
```

### STOPSIGNAL - 停止信号

```dockerfile
# 设置停止信号
STOPSIGNAL SIGTERM
STOPSIGNAL SIGINT
STOPSIGNAL SIGQUIT

# 使用信号编号
STOPSIGNAL 15  # SIGTERM
```

### SHELL - 指定 Shell

```dockerfile
# 在 Windows 上切换 shell
SHELL ["powershell", "-command"]

# 使用 bash
SHELL ["/bin/bash", "-c"]

# 后续 RUN 指令使用新 shell
RUN echo "Hello"
```

---

## 多阶段构建

多阶段构建允许在一个 Dockerfile 中使用多个 FROM 指令，最终生成一个精简的生产镜像。

```dockerfile
# 阶段 1: 构建阶段
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# 阶段 2: 运行阶段
FROM alpine:3.18

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app
COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]
```

### 多阶段构建示例

#### Java 应用

```dockerfile
# 构建阶段
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn package -DskipTests

# 运行阶段
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Node.js 应用

```dockerfile
# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# 运行阶段
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### 命名阶段引用

```dockerfile
FROM alpine:3.18 AS base
RUN apk add --no-cache curl

FROM base AS builder
WORKDIR /app
COPY . .

FROM base AS runtime
COPY --from=builder /app/dist /app
CMD ["./app"]
```

---

## Dockerfile 最佳实践

### 1. 选择合适的基础镜像

```dockerfile
# 不推荐
FROM ubuntu:latest
FROM node:latest

# 推荐
FROM ubuntu:22.04
FROM node:18-alpine
```

### 2. 减少镜像层数

```dockerfile
# 不推荐：多个 RUN 指令
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get install -y curl

# 推荐：合并指令
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        curl \
    && rm -rf /var/lib/apt/lists/*
```

### 3. 利用构建缓存

```dockerfile
# 把不常变化的指令放前面
FROM node:18-alpine
WORKDIR /app

# 先复制依赖文件
COPY package*.json ./
RUN npm ci

# 再复制源代码（经常变化）
COPY . .
RUN npm run build
```

### 4. 使用 .dockerignore

```
# .dockerignore
node_modules
npm-debug.log
Dockerfile
.dockerignore
.git
.gitignore
README.md
.env
*.log
dist
build
```

### 5. 安全配置

```dockerfile
# 不以 root 运行
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# 设置只读文件系统（运行时）
# docker run --read-only myapp

# 限制能力（运行时）
# docker run --cap-drop ALL myapp
```

### 6. 使用特定版本

```dockerfile
# 不推荐
FROM nginx:latest
RUN npm install

# 推荐
FROM nginx:1.25.3-alpine
RUN npm ci
```

### 7. 清理缓存

```dockerfile
# Alpine
RUN apk add --no-cache nginx

# Debian/Ubuntu
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# npm
RUN npm ci --only=production && npm cache clean --force

# pip
RUN pip install --no-cache-dir -r requirements.txt
```

---

## 完整示例

### Spring Boot 应用

```dockerfile
# 构建阶段
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app
COPY gradlew build.gradle settings.gradle ./
COPY gradle ./gradle
RUN ./gradlew dependencies --no-daemon

COPY src ./src
RUN ./gradlew build --no-daemon -x test

# 运行阶段
FROM eclipse-temurin:17-jre-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV SPRING_PROFILES_ACTIVE="prod"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### Python 应用

```dockerfile
FROM python:3.11-slim AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-slim

WORKDIR /app

RUN useradd --create-home appuser
USER appuser

COPY --from=builder /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH

COPY . .

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

### Nginx + 静态应用

```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.25-alpine

# 删除默认配置
RUN rm /etc/nginx/conf.d/default.conf

# 复制自定义配置
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app/dist /usr/share/nginx/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
```

---

## 构建命令

```bash
# 基本构建
docker build -t myapp:v1.0 .

# 指定 Dockerfile
docker build -t myapp:v1.0 -f Dockerfile.prod .

# 传递构建参数
docker build -t myapp:v1.0 --build-arg VERSION=1.0.0 .

# 不使用缓存
docker build -t myapp:v1.0 --no-cache .

# 指定平台
docker build -t myapp:v1.0 --platform linux/amd64 .

# 指定目标阶段
docker build -t myapp:v1.0 --target builder .

# 多标签
docker build -t myapp:v1.0 -t myapp:latest .

# 查看构建过程
docker build -t myapp:v1.0 --progress=plain .

# 构建缓存来源
docker build -t myapp:v1.0 --cache-from myapp:v0.9 .
```

---

## 指令速查表

| 指令 | 说明 | 格式 |
|------|------|------|
| `FROM` | 基础镜像 | `FROM image:tag` |
| `LABEL` | 元数据 | `LABEL key=value` |
| `RUN` | 构建时执行命令 | `RUN command` |
| `CMD` | 容器启动命令 | `CMD ["cmd"]` |
| `ENTRYPOINT` | 入口点 | `ENTRYPOINT ["cmd"]` |
| `COPY` | 复制文件 | `COPY src dest` |
| `ADD` | 添加文件 | `ADD src dest` |
| `WORKDIR` | 工作目录 | `WORKDIR /path` |
| `ENV` | 环境变量 | `ENV key=value` |
| `ARG` | 构建参数 | `ARG name=default` |
| `EXPOSE` | 暴露端口 | `EXPOSE port` |
| `VOLUME` | 数据卷 | `VOLUME /path` |
| `USER` | 运行用户 | `USER username` |
| `HEALTHCHECK` | 健康检查 | `HEALTHCHECK CMD ...` |
| `ONBUILD` | 构建触发器 | `ONBUILD INSTRUCTION` |
| `STOPSIGNAL` | 停止信号 | `STOPSIGNAL signal` |
| `SHELL` | 指定 Shell | `SHELL ["shell"]` |

---

## 参考链接

- [Dockerfile 官方文档](https://docs.docker.com/engine/reference/builder/)
- [Best practices for Dockerfile](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Build images with Dockerfile](https://docs.docker.com/build/building/packaging/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
