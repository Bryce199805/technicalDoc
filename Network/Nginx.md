# Nginx 完全指南

## 目录

- [1. Nginx 是什么](#1-nginx-是什么)
- [2. 核心概念](#2-核心概念)
- [3. 安装与目录结构](#3-安装与目录结构)
- [4. 配置文件结构](#4-配置文件结构)
- [5. 静态文件服务](#5-静态文件服务)
- [6. 反向代理](#6-反向代理)
- [7. 负载均衡](#7-负载均衡)
- [8. HTTPS/SSL 配置](#8-httpsssl-配置)
- [9. 虚拟主机（多域名）](#9-虚拟主机多域名)
- [10. location 匹配规则](#10-location-匹配规则)
- [11. rewrite 与重定向](#11-rewrite-与重定向)
- [12. gzip 压缩](#12-gzip-压缩)
- [13. 缓存策略](#13-缓存策略)
- [14. 日志与调试](#14-日志与调试)
- [15. 安全配置](#15-安全配置)
- [16. WebSocket 代理](#16-websocket-代理)
- [17. SPA 应用的 Nginx 配置](#17-spa-应用的-nginx-配置)
- [18. Docker 中使用 Nginx](#18-docker-中使用-nginx)
- [19. 常见问题与排查](#19-常见问题与排查)
- [20. 常用配置模板](#20-常用配置模板)

---

## 1. Nginx 是什么

Nginx（发音 "engine-x"）是一个高性能的 HTTP 和反向代理服务器，同时也是一个 IMAP/POP3/SMTP 代理服务器。

### 核心能力

| 功能 | 说明 |
|------|------|
| **Web 服务器** | 直接提供静态文件（HTML/CSS/JS/图片），性能远超 Apache |
| **反向代理** | 接收客户端请求，转发给后端服务，再把响应返回客户端 |
| **负载均衡** | 将请求分发到多个后端服务器，提高可用性 |
| **HTTPS 终端** | 在 Nginx 层处理 SSL/TLS，后端服务只需跑 HTTP |
| **缓存** | 缓存后端响应，减轻后端压力 |

### 正向代理 vs 反向代理

```
正向代理（代理客户端）：
  客户端 → [代理服务器] → 互联网 → 目标服务器
  例：VPN、科学上网，服务器不知道真实客户端是谁

反向代理（代理服务端）：
  客户端 → 互联网 → [Nginx] → 后端服务器
  例：Nginx 把请求转发给 Go/Node/Python 服务，客户端不知道后端是谁
```

### 为什么需要反向代理？

1. **统一入口**：多个服务跑在不同端口，Nginx 统一监听 80/443，按域名分发
2. **SSL 卸载**：在 Nginx 处理 HTTPS，后端只跑 HTTP，简化后端配置
3. **安全隔离**：后端服务不直接暴露，Nginx 充当防火墙
4. **负载均衡**：多实例后端轮询分发
5. **静态文件加速**：Nginx 处理静态文件比应用服务器快得多

---

## 2. 核心概念

### 事件驱动架构

Nginx 采用**异步非阻塞**的事件驱动模型，一个 worker 进程可以同时处理数千个连接：

```
Apache（线程模型）：每个连接一个线程，1000 连接 = 1000 线程 = 大量内存
Nginx（事件模型）：每个 worker 一个事件循环，1000 连接 = 1 个线程 + 事件轮询
```

### 进程模型

```
Master 进程
  ├── Worker 进程 1  ← 处理实际请求
  ├── Worker 进程 2
  ├── Worker 进程 3
  └── Worker 进程 4

Cache Manager  ← 管理缓存索引
Cache Loader   ← 加载缓存元数据
```

- **Master**：读取配置、管理 worker、平滑重启
- **Worker**：处理客户端请求，数量通常设为 CPU 核心数

### 请求处理流程

```
客户端请求
  → Nginx 监听端口接收
  → 选择 server block（按域名匹配）
  → 选择 location block（按 URI 匹配）
  → 执行 location 内的指令（代理/静态文件/重定向等）
  → 返回响应给客户端
```

---

## 3. 安装与目录结构

### 安装方式

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx

# macOS
brew install nginx

# Docker（推荐）
docker run -d --name nginx -p 80:80 -p 443:443 \
  -v ./nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  -v ./ssl:/etc/nginx/ssl:ro \
  nginx:alpine
```

### 目录结构（Ubuntu/Debian）

```
/etc/nginx/
├── nginx.conf              ← 主配置文件
├── conf.d/                 ← 额外配置（推荐放这里）
│   └── default.conf        ← 默认站点配置
├── sites-available/        ← 可用站点配置
├── sites-enabled/          ← 已启用站点（软链接）
├── snippets/               ← 可复用的配置片段
├── modules-available/      ← 可用模块
└── modules-enabled/        ← 已启用模块

/var/log/nginx/
├── access.log              ← 访问日志
└── error.log               ← 错误日志

/var/www/html/              ← 默认网站根目录
/usr/sbin/nginx             ← 可执行文件
```

### 常用命令

```bash
# 启动
nginx
sudo systemctl start nginx

# 停止
nginx -s stop              # 立即停止
nginx -s quit              # 优雅停止（处理完当前请求）

# 重新加载配置（不中断服务）
nginx -s reload
sudo systemctl reload nginx

# 测试配置语法
nginx -t

# 查看版本和编译参数
nginx -V

# 查看进程
ps aux | grep nginx
```

---

## 4. 配置文件结构

Nginx 配置是**声明式**的，由一系列指令（directive）组成，采用嵌套的块结构。

### 基本结构

```nginx
# 全局块 - 影响 Nginx 整体
user nginx;
worker_processes auto;      # worker 数量，auto = CPU 核心数
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# events 块 - 影响连接处理
events {
    worker_connections 1024;  # 每个 worker 最大连接数
    multi_accept on;          # 一次接受所有新连接
    use epoll;                # Linux 下使用 epoll
}

# http 块 - HTTP 服务器相关
http {
    include       mime.types;          # MIME 类型映射
    default_type  application/octet-stream;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent"';

    access_log /var/log/nginx/access.log main;

    sendfile    on;     # 零拷贝发送文件
    tcp_nopush  on;     # 优化数据包发送
    tcp_nodelay on;     # 禁用 Nagle 算法，低延迟

    keepalive_timeout 65;  # 长连接超时

    # gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json;

    # server 块 - 一个虚拟主机
    server {
        listen 80;
        server_name example.com;
        # ...
    }

    # 另一个 server 块 - 另一个虚拟主机
    server {
        listen 80;
        server_name another.com;
        # ...
    }
}
```

### 配置继承规则

Nginx 配置是**向下继承**的：

```nginx
http {
    gzip on;           # http 级别设置 gzip

    server {
        # 继承 http 的 gzip on

        location / {
            # 继承 server 的配置，也继承 http 的 gzip on
        }

        location /api/ {
            gzip off;  # 可以覆盖，这个 location 关闭 gzip
        }
    }
}
```

### include 机制

大型配置可以拆分到多个文件：

```nginx
http {
    include /etc/nginx/mime.types;
    include /etc/nginx/conf.d/*.conf;      # 包含 conf.d 下所有 .conf 文件
}
```

Docker 场景下通常只挂载一个配置文件：

```bash
-v /home/bryce/app/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

注意：`conf.d/default.conf` 是被 `nginx.conf` 的 http 块 include 进去的，所以你写的配置**不需要写 http 块**，直接写 server 块即可。

---

## 5. 静态文件服务

Nginx 最基本的功能：直接提供静态文件。

### 基础配置

```nginx
server {
    listen 80;
    server_name static.example.com;
    root /var/www/html;      # 文件根目录
    index index.html;        # 默认首页

    location / {
        try_files $uri $uri/ /index.html;  # 找不到文件时的回退
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### 关键指令

| 指令 | 说明 | 示例 |
|------|------|------|
| `root` | 设置根目录，URI 拼接到 root 后面 | `root /var/www;` 请求 `/img/a.png` → `/var/www/img/a.png` |
| `alias` | 设置别名，URI 替换 location 路径 | `alias /data/images/;` 请求 `/img/a.png` → `/data/images/a.png` |
| `index` | 默认首页文件 | `index index.html index.htm;` |
| `try_files` | 按顺序查找文件 | `try_files $uri $uri/ =404;` |
| `autoindex` | 目录列表 | `autoindex on;` |

### root vs alias

```nginx
# root：URI 拼接到 root 后
location /images/ {
    root /data/www;
}
# 请求 /images/logo.png → /data/www/images/logo.png

# alias：URI 中 location 部分被替换
location /images/ {
    alias /data/pictures/;
}
# 请求 /images/logo.png → /data/pictures/logo.png
```

**注意**：alias 路径必须以 `/` 结尾，root 不需要。

---

## 6. 反向代理

反向代理是 Nginx 最常用的功能之一。

### 基础配置

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;  # 后端服务地址
    }
}
```

### 完整代理配置

```nginx
location / {
    proxy_pass http://backend:3000;

    # 传递客户端真实信息
    proxy_set_header Host              $host;           # 原始域名
    proxy_set_header X-Real-IP         $remote_addr;    # 客户端真实 IP
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;  # IP 链
    proxy_set_header X-Forwarded-Proto $scheme;         # http 或 https

    # 超时设置
    proxy_connect_timeout 60s;   # 连接后端超时
    proxy_send_timeout    60s;   # 发送请求超时
    proxy_read_timeout    60s;   # 读取响应超时

    # 缓冲设置
    proxy_buffering on;          # 开启缓冲
    proxy_buffer_size 4k;        # 缓冲区大小
}
```

### 为什么需要 proxy_set_header？

当 Nginx 反向代理时，后端服务看到的请求信息都是 Nginx 的：

```
没有 proxy_set_header：
  后端看到 → 来源 IP = 172.17.0.1（Docker 网桥 IP）
             Host = backend:3000
             协议 = http

有了 proxy_set_header：
  后端看到 → 来源 IP = 客户端真实 IP
             Host = api.example.com
             协议 = https
```

### proxy_pass 的 URL 尾部斜杠

这是一个**非常容易出错**的地方：

```nginx
# 情况1：proxy_pass 有 URI（带尾部 / 或路径）
location /api/ {
    proxy_pass http://backend:3000/v1/;
}
# 请求 /api/users → 转发为 /v1/users（/api/ 被替换为 /v1/）

# 情况2：proxy_pass 没有 URI（无尾部 /）
location /api/ {
    proxy_pass http://backend:3000;
}
# 请求 /api/users → 转发为 /api/users（原样转发）
```

**规则**：`proxy_pass` 后面有 URI（包括 `/`），location 匹配的部分会被替换；没有 URI 则原样转发。

---

## 7. 负载均衡

### 轮询（默认）

```nginx
upstream backend {
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
    server 192.168.1.12:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

### 权重

```nginx
upstream backend {
    server 192.168.1.10:3000 weight=3;   # 3/5 的请求
    server 192.168.1.11:3000 weight=2;   # 2/5 的请求
}
```

### 其他策略

```nginx
# IP 哈希：同一 IP 始终分配到同一后端（会话保持）
upstream backend {
    ip_hash;
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
}

# 最少连接：优先分配给当前连接数最少的服务器
upstream backend {
    least_conn;
    server 192.168.1.10:3000;
    server 192.168.1.11:3000;
}

# 健康检查
upstream backend {
    server 192.168.1.10:3000 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:3000 backup;  # 备用，其他都挂了才启用
}
```

---

## 8. HTTPS/SSL 配置

### 基础 HTTPS

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate     /etc/nginx/ssl/example.com.pem;   # 证书
    ssl_certificate_key /etc/nginx/ssl/example.com.key;   # 私钥

    # SSL 协议和加密套件
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://backend:3000;
    }
}
```

### HTTP 自动跳转 HTTPS

```nginx
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
```

### SSL 安全加固

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate     /etc/nginx/ssl/example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;         # 只允许 TLS 1.2+
    ssl_ciphers HIGH:!aNULL:!MD5:!RC4;     # 排除弱加密
    ssl_prefer_server_ciphers off;

    # SSL 会话复用（避免每次握手）
    ssl_session_cache   shared:SSL:10m;    # 10MB 缓存，约 4 万个会话
    ssl_session_timeout 1d;                # 会话有效期 1 天

    # HSTS（强制浏览器使用 HTTPS）
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # OCSP Stapling（加速证书验证）
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
}
```

### 多域名 HTTPS（SNI）

Nginx 支持在同一个 IP 上为多个域名配置不同的证书，依靠 TLS SNI（Server Name Indication）：

```nginx
# 域名 A
server {
    listen 443 ssl;
    server_name api.example.com;
    ssl_certificate     /etc/nginx/ssl/api.example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/api.example.com.key;
    # ...
}

# 域名 B（同一个 443 端口，不同证书）
server {
    listen 443 ssl;
    server_name www.example.com;
    ssl_certificate     /etc/nginx/ssl/www.example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/www.example.com.key;
    # ...
}
```

浏览器在 TLS 握手时发送 SNI 字段告知要访问的域名，Nginx 据此选择对应的证书。

---

## 9. 虚拟主机（多域名）

Nginx 通过 `server_name` 区分不同域名，实现在同一台服务器上运行多个网站。

### 配置方式

```nginx
http {
    # 站点 1
    server {
        listen 80;
        server_name blog.example.com;
        root /var/www/blog;
    }

    # 站点 2
    server {
        listen 80;
        server_name docs.example.com;
        root /var/www/docs;
    }

    # 站点 3 - 反向代理到后端服务
    server {
        listen 80;
        server_name api.example.com;
        location / {
            proxy_pass http://127.0.0.1:3000;
        }
    }
}
```

### server_name 匹配规则

```nginx
# 精确匹配
server_name example.com;

# 通配符（只能在开头或结尾）
server_name *.example.com;     # 匹配 www.example.com, api.example.com
server_name example.*;         # 匹配 example.com, example.org

# 正则表达式
server_name ~^(www\.)?example\.com$;

# 默认服务器（没有匹配时的兜底）
server {
    listen 80 default_server;
    server_name _;
    return 444;  # 直接关闭连接
}
```

### 匹配优先级

1. 精确匹配 `server_name example.com;`
2. 前缀通配符 `server_name *.example.com;`
3. 后缀通配符 `server_name example.*;`
4. 正则表达式 `server_name ~^www\.example\.com$;`
5. `default_server`

---

## 10. location 匹配规则

`location` 决定了不同 URI 路径如何处理，是 Nginx 配置的核心。

### 语法

```nginx
location [修饰符] /uri/ {
    # ...
}
```

### 四种修饰符

| 修饰符 | 说明 | 示例 |
|--------|------|------|
| `=` | 精确匹配，最高优先级 | `location = / { }` |
| `^~` | 前缀匹配，匹配后不再检查正则 | `location ^~ /images/ { }` |
| `~` | 区分大小写的正则匹配 | `location ~ \.php$ { }` |
| `~*` | 不区分大小写的正则匹配 | `location ~* \.(js\|css)$ { }` |
| 无 | 普通前缀匹配 | `location /api/ { }` |

### 匹配优先级

```
1. = 精确匹配（最高优先级，匹配则立即使用）
2. ^~ 前缀匹配（匹配则不再检查正则）
3. ~ / ~* 正则匹配（按配置文件中的顺序，先匹配到的生效）
4. 普通前缀匹配（最长匹配生效）
```

### 示例

```nginx
server {
    listen 80;

    # 精确匹配：只有请求正好是 / 才匹配
    location = / {
        root /var/www/html;
        index index.html;
    }

    # 前缀匹配：匹配 /images/ 开头的路径，不再检查正则
    location ^~ /images/ {
        root /data;
        expires 30d;
    }

    # 正则匹配：匹配 .php 结尾的请求
    location ~ \.php$ {
        proxy_pass http://php-fpm:9000;
    }

    # 正则匹配（不区分大小写）：匹配静态资源
    location ~* \.(js|css|png|jpg|ico|svg)$ {
        root /var/www/static;
        expires 7d;
    }

    # 普通前缀匹配：所有 /api/ 开头的请求
    location /api/ {
        proxy_pass http://backend:3000/;
    }

    # 兜底：匹配所有未匹配的请求
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 常见陷阱

```nginx
# 错误：期望 /api 转发到后端，但实际匹配了 location /
location /api {
    proxy_pass http://backend:3000;
}
# 注意：/api 也会匹配 /api/users、/api2、/api-xxx 等
# 应该写 /api/ 加斜杠

# 正确
location /api/ {
    proxy_pass http://backend:3000/;
}
```

---

## 11. rewrite 与重定向

### return 指令（推荐，简单高效）

```nginx
# 301 永久重定向（搜索引擎会更新索引）
return 301 https://$server_name$request_uri;

# 302 临时重定向
return 302 https://$server_name$request_uri;

# 返回状态码和内容
return 403 "Forbidden";
return 200 "OK";
```

### rewrite 指令

```nginx
# 语法：rewrite regex replacement [flag]
rewrite ^/old-path/(.*)$ /new-path/$1 permanent;  # 301
rewrite ^/old-path/(.*)$ /new-path/$1 redirect;   # 302
rewrite ^/old-path/(.*)$ /new-path/$1 last;       # 重新匹配 location
rewrite ^/old-path/(.*)$ /new-path/$1 break;      # 不再匹配，在当前 location 继续处理
```

### flag 的区别

| flag | 说明 |
|------|------|
| `last` | 停止当前 rewrite，重新从 location 开始匹配 |
| `break` | 停止当前 rewrite，在当前 location 内继续处理 |
| `redirect` | 返回 302 临时重定向 |
| `permanent` | 返回 301 永久重定向 |

### 常见场景

```nginx
# 强制 HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}

# www 跳转非 www
server {
    listen 80;
    server_name www.example.com;
    return 301 http://example.com$request_uri;
}

# 旧 URL 迁移
rewrite ^/blog/(.*)$ https://blog.example.com/$1 permanent;
```

---

## 12. gzip 压缩

开启 gzip 可以大幅减少传输体积，通常能压缩 60-80%。

```nginx
http {
    # 开启 gzip
    gzip on;

    # 最小压缩阈值（小于此大小不压缩）
    gzip_min_length 1k;

    # 压缩级别（1-9，越高越压缩但越耗 CPU，推荐 4-6）
    gzip_comp_level 6;

    # 需要压缩的 MIME 类型
    gzip_types
        text/plain
        text/css
        text/javascript
        application/javascript
        application/json
        application/xml
        image/svg+xml;

    # 对代理请求也压缩
    gzip_vary on;

    # 代理场景下的压缩策略
    gzip_proxied any;

    # 压缩缓冲区
    gzip_buffers 16 8k;
}
```

### 注意事项

- 图片（JPEG/PNG）已经是压缩格式，不要对图片做 gzip
- gzip_comp_level 不是越高越好，6 以上收益递减但 CPU 开销显著增加
- 对于已压缩的文件（.gz/.br），Nginx 不会重复压缩

---

## 13. 缓存策略

### 浏览器缓存

```nginx
location ~* \.(js|css)$ {
    expires 7d;                                        # 7 天后过期
    add_header Cache-Control "public, max-age=604800";
}

location ~* \.(png|jpg|jpeg|gif|ico|svg|woff2?)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";      # immutable：浏览器不发送条件请求
}

location ~* \.(html)$ {
    add_header Cache-Control "no-cache";               # 每次都验证
}
```

### 代理缓存

```nginx
# 在 http 块中定义缓存区
http {
    proxy_cache_path /var/cache/nginx
                     levels=1:2
                     keys_zone=api_cache:10m
                     max_size=1g
                     inactive=60m;
}

server {
    location /api/ {
        proxy_pass http://backend:3000;
        proxy_cache api_cache;                # 使用上面定义的缓存区
        proxy_cache_valid 200 10m;            # 200 响应缓存 10 分钟
        proxy_cache_valid 404 1m;             # 404 缓存 1 分钟
        proxy_cache_use_stale error timeout;  # 后端出错时返回过期缓存
        add_header X-Cache-Status $upstream_cache_status;  # 调试用
    }
}
```

---

## 14. 日志与调试

### 日志类型

```nginx
# 访问日志
access_log /var/log/nginx/access.log;

# 错误日志（级别：debug | info | notice | warn | error | crit）
error_log /var/log/nginx/error.log warn;

# 关闭访问日志（高流量场景减少 IO）
access_log off;
```

### 自定义日志格式

```nginx
log_format detailed '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    '"$http_x_forwarded_for" '
                    'rt=$request_time';    # 请求耗时

access_log /var/log/nginx/access.log detailed;
```

### 常用内置变量

| 变量 | 说明 |
|------|------|
| `$remote_addr` | 客户端 IP |
| `$http_x_forwarded_for` | 代理链中的真实 IP |
| `$host` | 请求的 Host 头（域名） |
| `$server_name` | 匹配的 server_name |
| `$request_uri` | 完整请求 URI（含参数） |
| `$uri` | 不含参数的 URI |
| `$args` | URL 参数部分 |
| `$scheme` | http 或 https |
| `$request_method` | GET/POST/PUT 等 |
| `$request_time` | 请求处理耗时（秒） |
| `$status` | 响应状态码 |
| `$body_bytes_sent` | 响应体大小 |

### 调试技巧

```nginx
# 在响应头中添加调试信息
add_header X-Debug-Host $host;
add_header X-Debug-URI $uri;

# 临时返回特定内容来排查问题
location /debug {
    return 200 "host=$host, uri=$uri, remote=$remote_addr";
    add_header Content-Type text/plain;
}
```

---

## 15. 安全配置

### 隐藏版本号

```nginx
http {
    server_tokens off;  # 隐藏 Nginx 版本号
}
```

### 安全响应头

```nginx
server {
    # 防止点击劫持
    add_header X-Frame-Options "SAMEORIGIN" always;

    # 防止 MIME 嗅探
    add_header X-Content-Type-Options "nosniff" always;

    # XSS 防护
    add_header X-XSS-Protection "1; mode=block" always;

    # HSTS（强制 HTTPS）
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # CSP（内容安全策略）
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'" always;

    # Referrer 策略
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

### 限制访问

```nginx
# IP 白名单
location /admin/ {
    allow 192.168.1.0/24;
    allow 10.0.0.1;
    deny all;
}

# HTTP Basic Auth
location /admin/ {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}

# 限制请求速率（防 DDoS）
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location /api/ {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://backend:3000;
}

# 限制连接数
limit_conn_zone $binary_remote_addr zone=connlimit:10m;

location /download/ {
    limit_conn connlimit 5;  # 每个 IP 最多 5 个连接
}
```

---

## 16. WebSocket 代理

WebSocket 需要特殊的代理配置来处理协议升级：

```nginx
location /ws/ {
    proxy_pass http://backend:3000;

    # WebSocket 必需的头部
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    # 超时要设长一些
    proxy_read_timeout 86400s;
    proxy_send_timeout 86400s;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

---

## 17. SPA 应用的 Nginx 配置

React/Vue/Angular 等 SPA 的关键问题：所有路由都应由前端处理，返回 `index.html`。

### 标准配置

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /var/www/app;
    index index.html;

    # SPA 核心：所有未匹配的路径都返回 index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 静态资源长缓存（Vite/Webpack 构建时文件名带 hash）
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # favicon 等不常变的资源
    location ~* \.(ico|svg|png|jpg|jpeg)$ {
        expires 30d;
    }

    # API 请求代理到后端
    location /api/ {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SPA 的常见问题

```
问题：刷新页面 404
原因：Nginx 去找 /dashboard 对应的文件，找不到就 404
解决：try_files $uri $uri/ /index.html; 让所有路径都回退到 index.html

问题：JS/CSS 更新后浏览器还显示旧版
原因：浏览器缓存
解决：1. 构建工具给文件名加 hash（Vite 默认会做）
      2. 对 /assets/ 设置长缓存 + immutable
      3. index.html 设置 no-cache

问题：API 请求跨域
解决：让 API 和前端同域，用 Nginx 代理 /api/ 到后端
```

---

## 18. Docker 中使用 Nginx

### 单服务模式

```yaml
# docker-compose.yml
services:
  app:
    build: .
    expose:
      - "3000"          # 只在 Docker 网络内暴露

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - app
```

### 多服务共享 Nginx

```yaml
# docker-compose.yml - 多个服务共享一个 Nginx
services:
  service-a:
    expose:
      - "3000"
    networks:
      - web-network

  service-b:
    expose:
      - "8080"
    networks:
      - web-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - web-network

networks:
  web-network:
    driver: bridge
```

对应的 Nginx 配置：

```nginx
# 服务 A
server {
    listen 80;
    server_name a.example.com;
    location / {
        proxy_pass http://service-a:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 服务 B
server {
    listen 80;
    server_name b.example.com;
    location / {
        proxy_pass http://service-b:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 跨 Docker Compose 项目共享网络

当一个 Nginx 容器需要代理多个不同 docker-compose 项目的服务时：

```yaml
# 项目 A 的 docker-compose.yml
services:
  service-a:
    expose:
      - "3000"
    networks:
      - shared-network

networks:
  shared-network:
    external: true
    name: nginx_shared-network   # 指向 Nginx 项目创建的网络
```

```yaml
# Nginx 项目的 docker-compose.yml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - shared-network

networks:
  shared-network:
    name: nginx_shared-network   # 给网络一个明确的名字
```

### Docker 中 Nginx 的注意事项

1. **容器名称即主机名**：`proxy_pass http://service-a:3000` 中的 `service-a` 就是容器名
2. **expose vs ports**：`expose` 只在 Docker 网络内可达，`ports` 映射到宿主机。反向代理场景下后端用 `expose` 即可
3. **配置热重载**：`docker exec nginx-container nginx -s reload`
4. **挂载为只读**：`-v ./nginx.conf:/etc/nginx/conf.d/default.conf:ro`，防止容器意外修改配置
5. **Alpine 镜像**：`nginx:alpine` 只有 7MB，适合生产环境

---

## 19. 常见问题与排查

### 404 Not Found

```bash
# 检查 root/alias 路径是否正确
# 检查文件权限
ls -la /var/www/html/

# 检查 Nginx 返回的实际内容
curl -v http://localhost/page
```

### 502 Bad Gateway

后端服务不可达：

```bash
# 检查后端是否在运行
curl http://backend:3000/health

# 检查 DNS 解析（Docker 中容器名是否可解析）
docker exec nginx ping backend

# 检查端口是否正确
ss -tlnp | grep 3000
```

### 504 Gateway Timeout

后端响应太慢：

```nginx
# 增加超时时间
proxy_read_timeout 300s;
proxy_connect_timeout 300s;
```

### 配置不生效

```bash
# 1. 测试配置语法
nginx -t

# 2. 重新加载配置
nginx -s reload

# 3. 检查是否改对了文件
nginx -T  # 打印完整生效的配置

# 4. 浏览器缓存
# Ctrl+Shift+R 强制刷新
```

### location 匹配不正确

```bash
# 查看实际匹配的 location
# 在 location 中添加调试头
add_header X-Matched-Location "location-name";
```

### 静态文件被代理而不是直接返回

确保静态文件的 location 优先级高于代理的 location：

```nginx
# 正确：静态资源用 ^~ 前缀匹配，优先于正则
location ^~ /assets/ {
    root /var/www/app;
    expires 1y;
}

# API 代理
location /api/ {
    proxy_pass http://backend:3000;
}
```

---

## 20. 常用配置模板

### 前端 SPA + 后端 API（最常用）

```nginx
server {
    listen 80;
    server_name app.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name app.example.com;

    ssl_certificate     /etc/nginx/ssl/app.example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/app.example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/app;
    index index.html;

    # SPA 路由回退
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 静态资源长缓存
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 纯反向代理

```nginx
server {
    listen 80;
    server_name api.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.example.com;

    ssl_certificate     /etc/nginx/ssl/api.example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/api.example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    location / {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 多域名多服务（Docker 场景）

```nginx
# 服务 A
server {
    listen 80;
    server_name a.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name a.example.com;
    ssl_certificate     /etc/nginx/ssl/a.example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/a.example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    location / {
        proxy_pass http://service-a:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 服务 B
server {
    listen 80;
    server_name b.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name b.example.com;
    ssl_certificate     /etc/nginx/ssl/b.example.com.pem;
    ssl_certificate_key /etc/nginx/ssl/b.example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    location / {
        proxy_pass http://service-b:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
