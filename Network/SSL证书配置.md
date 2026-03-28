# SSL 证书申请与配置指南

本文档介绍为域名申请免费 SSL 证书并配置 HTTPS 的完整流程，以阿里云免费证书 + Cloudflare DNS 验证为例。

---

## 一、申请免费 SSL 证书

### 1. 登录阿里云控制台

访问 [阿里云 SSL 证书控制台](https://yundun.console.aliyun.com/?p=cas)

### 2. 申请免费证书

1. 点击 **SSL证书 → 免费证书 → 创建证书**
2. 填写域名（如：`example.com` 或 `sub.example.com`）
3. 选择 **DV 单域名证书（免费）**
4. 验证方式选择 **DNS 验证**

### 3. 获取 DNS 验证信息

提交后，阿里云会显示类似以下信息：

| 记录类型 | 主机记录 | 记录值 |
|---------|---------|--------|
| CNAME | `_dnsauth.memopad` | `xxx.aliyunauth.certificate-validations.com` |

---

## 二、在 Cloudflare 添加验证记录

### 1. 登录 Cloudflare

访问 [Cloudflare Dashboard](https://dash.cloudflare.com/)

### 2. 添加 DNS 记录

1. 选择你的 Zone
2. 点击 **DNS → Records → Add Record**
3. 添加验证记录：

```
Type:     CNAME
Name:     _dnsauth.<子域名>    # 如 _dnsauth.www 或 _dnsauth.api
Content:  <阿里云提供的验证值>
Proxy:    仅 DNS（灰色云朵，关闭代理）
```

### 3. 验证 DNS 生效

```bash
# 替换为你的实际域名
nslookup -type=CNAME _dnsauth.<子域名>.<主域名>
```

### 4. 回阿里云完成验证

返回阿里云证书页面，点击 **验证**，等待证书签发。

---

## 三、下载并部署证书

### 1. 下载证书

在阿里云证书页面：
1. 点击 **下载**
2. 选择 **Nginx** 格式
3. 解压得到两个文件：`xxx.pem` 和 `xxx.key`

### 2. 上传到服务器

```bash
# 在服务器创建目录
mkdir -p /opt/<项目名>/ssl

# 上传证书文件（在本地执行）
scp cert.pem root@服务器IP:/opt/<项目名>/ssl/
scp cert.key root@服务器IP:/opt/<项目名>/ssl/
```

### 3. 确认文件权限

```bash
ls -la /opt/<项目名>/ssl/
# 应该看到 cert.pem 和 cert.key
```

---

## 四、配置 Nginx HTTPS

### nginx.conf 示例

```nginx
# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS server
server {
    listen 443 ssl;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/cert.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # ... 其他配置
}
```

### docker-compose.yml 示例

```yaml
services:
  backend:
    build: ./backend
    container_name: memopad-backend
    restart: unless-stopped
    volumes:
      - backend-data:/app/data

  web:
    build: ./web
    container_name: memopad-web
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /opt/memopad/ssl:/etc/nginx/ssl:ro
    depends_on:
      - backend

volumes:
  backend-data:
```

---

## 五、部署与验证

### 1. 部署

```bash
cd /opt/<项目目录>
docker compose down
docker compose up -d --build
```

### 2. 验证 HTTPS

```bash
# 测试 HTTPS 连接
curl -I https://<你的域名>

# 或在浏览器访问
https://<你的域名>
```

---

## 六、常见问题

### 证书文件找不到

错误信息：
```
cannot load certificate "/etc/nginx/ssl/cert.pem": BIO_new_file() failed
```

解决：
1. 检查证书文件是否存在：`ls -la /opt/<项目名>/ssl/`
2. 检查 docker-compose.yml 挂载路径是否正确
3. 确保文件名是 `cert.pem` 和 `cert.key`

### DNS 验证失败

解决：
1. 确保 Cloudflare 的 Proxy 状态是 **灰色云朵**（DNS only）
2. 等待几分钟让 DNS 生效
3. 用 `nslookup` 验证解析是否正确

### 证书过期

免费证书有效期 1 年，到期前需要重新申请：
1. 重复上述流程申请新证书
2. 替换服务器上的证书文件
3. 重启容器：`docker compose restart web`

---

## 七、相关链接

- [阿里云 SSL 证书控制台](https://yundun.console.aliyun.com/?p=cas)
- [Cloudflare Dashboard](https://dash.cloudflare.com/)
- [Let's Encrypt 官方文档](https://letsencrypt.org/docs/)
