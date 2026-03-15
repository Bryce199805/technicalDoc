# Docker Compose 完整指南

## 什么是 Docker Compose

Docker Compose 是一个用于定义和运行多容器 Docker 应用的工具。通过 Compose，您可以使用 YAML 文件来配置应用的服务、网络和数据卷，然后使用单个命令创建和启动所有服务。

### Compose 的优势

| 优势 | 说明 |
|------|------|
| 单文件配置 | 所有服务配置在一个 YAML 文件中 |
| 版本控制友好 | 配置文件可以纳入 Git 管理 |
| 环境一致性 | 开发、测试、生产环境配置一致 |
| 简化操作 | 一键启动、停止、重建所有服务 |
| 服务编排 | 支持服务依赖、网络、存储配置 |

---

## 安装 Docker Compose

### Docker Compose V2（推荐）

Docker Compose V2 已集成到 Docker CLI 中，作为插件安装。

```bash
# 检查是否已安装
docker compose version

# Docker Desktop 默认已安装
# Linux 安装（通常随 Docker 一起安装）
sudo apt-get install docker-compose-plugin
```

### 语法变化

```bash
# V1 (docker-compose)
docker-compose up -d
docker-compose down

# V2 (docker compose) - 推荐
docker compose up -d
docker compose down
```

---

## Compose 文件结构

### 基本结构

```yaml
# docker-compose.yml 基本结构

# Compose 文件版本
version: '3.8'

# 服务定义
services:
  webapp:
    image: nginx:latest
    ports:
      - "80:80"

  database:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root

# 网络定义
networks:
  app-network:
    driver: bridge

# 数据卷定义
volumes:
  app-data:
    driver: local
```

### 版本选择

| 版本 | Docker Engine | 说明 |
|------|---------------|------|
| `3.8` | 19.03.0+ | 最新功能，推荐使用 |
| `3.7` | 18.06.0+ | 支持 init、start_period |
| `3.6` | 18.02.0+ | 支持 tmpfs 配置 |
| `3.5` | 17.12.0+ | 支持 name 属性 |
| `3.4` | 17.09.0+ | 支持 cache_from、nvidia |
| `3.3` | 17.06.0+ | 支持 credential_spec |
| `3.2` | 17.04.0+ | 支持 extended ports/volumes |
| `3.0` | 1.13.0+ | 支持 deploy 配置 |
| `2.4` | 17.12.0+ | 支持 cgroup_parent |
| `2.3` | 17.06.0+ | 支持 init、scale |
| `2.2` | 17.04.0+ | 支持 userns_mode |

---

## Services 配置详解

### 基础配置

```yaml
services:
  webapp:
    # 使用镜像
    image: nginx:1.25-alpine

    # 构建配置
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        VERSION: 1.0.0

    # 容器名称
    container_name: my-webapp

    # 主机名
    hostname: webapp

    # 重启策略
    restart: always
```

### 构建配置（build）

```yaml
services:
  app:
    build:
      # 构建上下文路径
      context: ./app

      # Dockerfile 路径
      dockerfile: Dockerfile.prod

      # 构建参数
      args:
        BUILD_VERSION: 1.0.0
        DEBUG: "false"

      # 缓存来源镜像
      cache_from:
        - myapp:cache

      # 标签
      labels:
        - "com.example.description=My App"
        - "com.example.version=1.0.0"

      # 网络
      network: host

      # 目标阶段（多阶段构建）
      target: production

      # shm_size
      shm_size: 256m

      # 平台
      platforms:
        - linux/amd64
        - linux/arm64
```

### 端口映射（ports）

```yaml
services:
  webapp:
    # 短语法
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080/tcp"
      - "53:53/udp"
      - "127.0.0.1:3000:3000"
      - "3000-3005:3000-3005"

    # 长语法（v3.2+）
    ports:
      - target: 80        # 容器端口
        published: 8080   # 主机端口
        protocol: tcp     # 协议 tcp/udp
        mode: host        # host/ingress
```

### 数据卷（volumes）

```yaml
services:
  webapp:
    # 短语法
    volumes:
      - /var/lib/mysql              # 匿名卷
      - mydata:/var/lib/mysql       # 命名卷
      - ./data:/app/data            # bind mount
      - ./config:/etc/app:ro        # 只读
      - ~/configs:/etc/configs      # 用户目录

    # 长语法（v3.2+）
    volumes:
      - type: volume
        source: mydata
        target: /var/lib/mysql
        read_only: false
        volume:
          nocopy: true

      - type: bind
        source: ./app
        target: /app
        bind:
          create_host_path: true

      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100m
```

### 网络配置（networks）

```yaml
services:
  webapp:
    networks:
      - frontend
      - backend

    # 高级配置
    networks:
      frontend:
        aliases:
          - web
        ipv4_address: 172.20.0.100
      backend:
        aliases:
          - app

networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
  backend:
    internal: true  # 禁止外部访问
```

### 环境变量（environment / env_file）

```yaml
services:
  webapp:
    # 环境变量 - 列表格式
    environment:
      - MYSQL_HOST=db
      - MYSQL_PORT=3306
      - DEBUG=false

    # 环境变量 - 字典格式
    environment:
      MYSQL_HOST: db
      MYSQL_PORT: 3306
      DEBUG: "false"

    # 从文件加载
    env_file:
      - .env
      - .env.prod
      - ./config/app.env
```

### 依赖关系（depends_on）

```yaml
services:
  web:
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  db:
    image: mysql:8.0
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
```

### 健康检查（healthcheck）

```yaml
services:
  webapp:
    image: nginx:alpine
    healthcheck:
      # 检查命令
      test: ["CMD", "curl", "-f", "http://localhost/"]

      # 检查间隔
      interval: 30s

      # 超时时间
      timeout: 10s

      # 重试次数
      retries: 3

      # 启动等待时间
      start_period: 40s

      # 禁用健康检查
      # disable: true
```

### 资源限制（deploy）

```yaml
services:
  webapp:
    deploy:
      # 副本数
      replicas: 3

      # 资源限制
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

      # 重启策略
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

      # 更新策略
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        order: start-first

      # 回滚配置
      rollback_config:
        parallelism: 0
        order: stop-first
```

### 命令配置（command / entrypoint）

```yaml
services:
  webapp:
    # 覆盖默认命令
    command: nginx -g "daemon off;"

    # 数组格式
    command: ["nginx", "-g", "daemon off;"]

    # 覆盖入口点
    entrypoint: /app/start.sh

    # 数组格式
    entrypoint: ["/app/start.sh"]
```

### 用户和权限

```yaml
services:
  webapp:
    # 运行用户
    user: 1000:1000
    user: appuser

    # 特权模式
    privileged: false

    # 能力设置
    cap_add:
      - NET_ADMIN
    cap_drop:
      - ALL

    # 安全选项
    security_opt:
      - no-new-privileges:true
```

### 日志配置（logging）

```yaml
services:
  webapp:
    logging:
      # 日志驱动
      driver: json-file

      # 日志选项
      options:
        max-size: "10m"
        max-file: "3"
        labels: "production"
        tag: "{{.Name}}/{{.ID}}"

    # 其他日志驱动
    # driver: syslog
    # options:
    #   syslog-address: "tcp://192.168.0.42:123"
    # driver: journald
    # driver: none
```

### 其他配置

```yaml
services:
  webapp:
    # 工作目录
    working_dir: /app

    # 域名
    domainname: example.com

    # DNS 配置
    dns:
      - 8.8.8.8
      - 8.8.4.4
    dns_search:
      - example.com

    # hosts 映射
    extra_hosts:
      - "myhost:192.168.1.100"
      - "db:172.20.0.10"

    # 暴露端口（不映射到主机）
    expose:
      - "3000"
      - "8000"

    # 设备映射
    devices:
      - "/dev/ttyUSB0:/dev/ttyUSB0"

    # tmpfs 挂载
    tmpfs:
      - /tmp
      - /run

    # 标签
    labels:
      - "com.example.description=My App"
      - "com.example.version=1.0.0"

    # 停止信号
    stop_signal: SIGTERM

    # 停止等待时间
    stop_grace_period: 30s

    # 共享进程命名空间
    pid: "host"

    # IPC 命名空间
    ipc: "host"

    # Ulimits
    ulimits:
      nproc: 65535
      nofile:
        soft: 20000
        hard: 40000

    # 初始化
    init: true

    # 只读文件系统
    read_only: true
```

---

## Networks 配置详解

```yaml
networks:
  # 简单定义
  app-network:

  # 完整配置
  frontend:
    # 网络驱动
    driver: bridge

    # 驱动选项
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
      com.docker.network.driver.mtu: 1400

    # IP 地址管理
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
          ip_range: 172.20.1.0/24
          aux_addresses:
            host1: 172.20.1.10
            host2: 172.20.1.11

    # 标签
    labels:
      - "com.example.network=frontend"

    # 是否允许外部容器连接
    attachable: true

    # 内部网络（禁止外部访问）
    internal: false

    # 是否启用 IPv6
    enable_ipv6: false

    # 使用外部网络
    external: true
    name: my-external-network
```

---

## Volumes 配置详解

```yaml
volumes:
  # 简单定义
  app-data:

  # 完整配置
  mysql-data:
    # 存储驱动
    driver: local

    # 驱动选项
    driver_opts:
      type: nfs
      o: addr=192.168.1.100,rw
      device: ":/export/mysql"

    # 标签
    labels:
      - "com.example.volume=mysql-data"

    # 使用外部卷
    external: true
    name: my-external-volume

  # tmpfs 卷
  cache:
    driver: local
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: "size=1g,uid=1000"
```

---

## Compose 命令

### 服务生命周期

```bash
# 启动服务
docker compose up

# 后台启动
docker compose up -d

# 重新构建并启动
docker compose up --build

# 强制重新创建容器
docker compose up --force-recreate

# 不启动依赖服务
docker compose up --no-deps webapp

# 指定服务启动
docker compose up webapp db

# 停止服务
docker compose stop

# 停止并删除容器、网络
docker compose down

# 停止并删除容器、网络、镜像
docker compose down --rmi all

# 停止并删除容器、网络、数据卷
docker compose down -v

# 暂停/恢复
docker compose pause
docker compose unpause

# 重启服务
docker compose restart

# 重启指定服务
docker compose restart webapp
```

### 服务管理

```bash
# 查看服务状态
docker compose ps

# 查看服务日志
docker compose logs
docker compose logs -f webapp
docker compose logs --tail 100

# 查看服务进程
docker compose top

# 查看服务端口
docker compose port webapp 80

# 查看服务配置
docker compose config
docker compose config --services
docker compose config --volumes
```

### 服务操作

```bash
# 在服务中执行命令
docker compose exec webapp bash
docker compose exec -u root webapp bash

# 运行一次性命令
docker compose run --rm webapp npm install
docker compose run --rm webapp python manage.py migrate

# 拉取镜像
docker compose pull

# 推送镜像
docker compose push

# 构建镜像
docker compose build
docker compose build --no-cache webapp

# 创建服务（不启动）
docker compose create

# 启动已创建的服务
docker compose start
```

### 扩展和复制

```bash
# 扩展服务副本数
docker compose up -d --scale webapp=3

# 扩展多个服务
docker compose up -d --scale webapp=3 --scale worker=5
```

---

## 多环境配置

### 使用多个 Compose 文件

```bash
# 目录结构
├── docker-compose.yml          # 基础配置
├── docker-compose.override.yml # 本地开发覆盖（自动加载）
├── docker-compose.prod.yml     # 生产环境
├── docker-compose.staging.yml  # 预发布环境
└── docker-compose.test.yml     # 测试环境

# 基础配置 - docker-compose.yml
version: '3.8'
services:
  webapp:
    image: myapp
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development

# 开发环境覆盖 - docker-compose.override.yml
version: '3.8'
services:
  webapp:
    build: ./app
    volumes:
      - ./app:/app
    environment:
      DEBUG: "true"

# 生产环境 - docker-compose.prod.yml
version: '3.8'
services:
  webapp:
    image: myapp:1.0.0
    restart: always
    environment:
      NODE_ENV: production
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1'
          memory: 512M
```

### 启动不同环境

```bash
# 开发环境（自动合并 docker-compose.yml 和 docker-compose.override.yml）
docker compose up -d

# 生产环境
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 测试环境
docker compose -f docker-compose.yml -f docker-compose.test.yml up -d

# 使用环境变量
export COMPOSE_FILE=docker-compose.yml:docker-compose.prod.yml
docker compose up -d
```

### 使用环境变量文件

```bash
# .env 文件
COMPOSE_PROJECT_NAME=myapp
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=mydb
MYSQL_USER=user
MYSQL_PASSWORD=password

# docker-compose.yml 中引用
version: '3.8'
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

---

## 完整示例

### Web 应用示例

```yaml
version: '3.8'

services:
  # Nginx 反向代理
  nginx:
    image: nginx:1.25-alpine
    container_name: myapp-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./certs:/etc/nginx/certs:ro
      - nginx-logs:/var/log/nginx
    depends_on:
      - webapp
    networks:
      - frontend

  # Web 应用
  webapp:
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        NODE_ENV: production
    container_name: myapp-web
    restart: always
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://user:password@db:5432/mydb
      REDIS_URL: redis://redis:6379
    volumes:
      - app-uploads:/app/uploads
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # PostgreSQL 数据库
  db:
    image: postgres:15-alpine
    container_name: myapp-db
    restart: always
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d:ro
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis 缓存
  redis:
    image: redis:7-alpine
    container_name: myapp-redis
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  postgres-data:
    driver: local
  redis-data:
    driver: local
  app-uploads:
    driver: local
  nginx-logs:
    driver: local
```

### 微服务架构示例

```yaml
version: '3.8'

services:
  # API 网关
  api-gateway:
    build: ./api-gateway
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
    depends_on:
      - user-service
      - order-service
      - product-service
    networks:
      - frontend
      - backend

  # 用户服务
  user-service:
    build: ./user-service
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - DB_HOST=user-db
    depends_on:
      user-db:
        condition: service_healthy
    networks:
      - backend
    deploy:
      replicas: 2

  # 订单服务
  order-service:
    build: ./order-service
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - DB_HOST=order-db
      - KAFKA_BROKERS=kafka:9092
    depends_on:
      - order-db
      - kafka
    networks:
      - backend

  # 商品服务
  product-service:
    build: ./product-service
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - DB_HOST=product-db
      - REDIS_HOST=redis
    depends_on:
      - product-db
      - redis
    networks:
      - backend

  # 数据库
  user-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: userdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - user-db-data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5

  order-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: orderdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - order-db-data:/var/lib/postgresql/data
    networks:
      - backend

  product-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: productdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - product-db-data:/var/lib/postgresql/data
    networks:
      - backend

  # Kafka
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - backend

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    networks:
      - backend

  # Redis
  redis:
    image: redis:7-alpine
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  user-db-data:
  order-db-data:
  product-db-data:
```

---

## 命令速查表

| 命令 | 说明 |
|------|------|
| `docker compose up` | 创建并启动服务 |
| `docker compose up -d` | 后台启动 |
| `docker compose down` | 停止并删除服务 |
| `docker compose start` | 启动服务 |
| `docker compose stop` | 停止服务 |
| `docker compose restart` | 重启服务 |
| `docker compose ps` | 查看服务状态 |
| `docker compose logs` | 查看日志 |
| `docker compose exec` | 执行命令 |
| `docker compose run` | 运行一次性命令 |
| `docker compose build` | 构建镜像 |
| `docker compose pull` | 拉取镜像 |
| `docker compose push` | 推送镜像 |
| `docker compose config` | 验证配置 |
| `docker compose scale` | 扩展服务 |

---

## 参考链接

- [Docker Compose 官方文档](https://docs.docker.com/compose/)
- [Compose file version 3](https://docs.docker.com/compose/compose-file/compose-file-v3/)
- [Compose file version 2](https://docs.docker.com/compose/compose-file/compose-file-v2/)
- [Environment variables in Compose](https://docs.docker.com/compose/environment-variables/)
- [Multiple Compose files](https://docs.docker.com/compose/extends/)
