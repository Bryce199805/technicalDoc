# Docker 安装与配置

## 系统要求

### Linux 系统要求

| 系统 | 最低版本 | 推荐版本 |
|------|---------|---------|
| Ubuntu | 20.04 LTS | 22.04 LTS |
| Debian | 10 (Buster) | 12 (Bookworm) |
| CentOS | 7 | Stream 9 |
| Fedora | 34 | Latest |
| RHEL | 7 | 9 |

### 硬件要求

| 配置项 | 最低要求 | 推荐配置 |
|--------|---------|---------|
| CPU | 2 核 | 4 核+ |
| 内存 | 2 GB | 4 GB+ |
| 磁盘空间 | 20 GB | 50 GB+ |

---

## Ubuntu/Debian 安装

### 方法一：使用官方脚本（推荐）

```bash
# 下载并执行官方安装脚本
curl -fsSL https://get.docker.com | sh

# 将当前用户加入 docker 组（免 sudo）
sudo usermod -aG docker $USER

# 重新登录或执行以下命令使组权限生效
newgrp docker
```

### 方法二：手动安装（Ubuntu）

```bash
# 1. 更新软件包索引
sudo apt-get update

# 2. 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. 添加 Docker 官方 GPG 密钥
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 4. 设置稳定版仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. 安装 Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 方法三：手动安装（Debian）

```bash
# 1. 更新软件包索引
sudo apt-get update

# 2. 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. 添加 Docker 官方 GPG 密钥
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 4. 设置稳定版仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. 安装 Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

## CentOS/RHEL 安装

### CentOS 7/8 安装

```bash
# 1. 安装必要工具
sudo yum install -y yum-utils

# 2. 添加 Docker 仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 3. 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 5. 验证安装
sudo docker run hello-world
```

### CentOS Stream 9 / RHEL 9

```bash
# 1. 安装必要工具
sudo dnf -y install dnf-plugins-core

# 2. 添加 Docker 仓库
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 3. 安装 Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```

---

## Fedora 安装

```bash
# 1. 安装必要工具
sudo dnf -y install dnf-plugins-core

# 2. 添加 Docker 仓库
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# 3. 安装 Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 5. 验证安装
sudo docker run hello-world
```

---

## macOS 安装

### 方法一：Docker Desktop（推荐）

1. 下载 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
2. 打开 `.dmg` 文件，将 Docker 拖入 Applications
3. 启动 Docker Desktop
4. 验证安装：

```bash
docker --version
docker-compose --version
```

### 方法二：使用 Homebrew

```bash
# 安装 Docker Desktop
brew install --cask docker

# 或者安装命令行工具
brew install docker docker-compose

# 启动 Docker Desktop（首次需要）
open /Applications/Docker.app
```

### 系统要求

| 要求 | 说明 |
|------|------|
| 芯片 | Intel 或 Apple Silicon (M1/M2/M3) |
| macOS | 11 Big Sur 或更高版本 |
| 内存 | 至少 4 GB |
| 虚拟化 | 需要启用 |

---

## Windows 安装

### 方法一：Docker Desktop（推荐）

#### 系统要求

| 要求 | 说明 |
|------|------|
| Windows | Windows 10/11 64位 (Pro/Enterprise/Education) |
| WSL 2 | 需要 WSL 2 支持 |
| Hyper-V | 需要启用 Hyper-V 和容器功能 |
| 内存 | 至少 4 GB |

#### 安装步骤

```powershell
# 1. 启用 WSL 2（管理员 PowerShell）
wsl --install

# 2. 启用必要功能（管理员 PowerShell）
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 3. 重启电脑

# 4. 下载并安装 WSL2 Linux 内核更新包
# https://aka.ms/wsl2kernel

# 5. 设置 WSL 2 为默认版本
wsl --set-default-version 2

# 6. 下载并安装 Docker Desktop
# https://www.docker.com/products/docker-desktop
```

### 方法二：使用 winget

```powershell
# 使用 Windows 包管理器安装
winget install Docker.DockerDesktop
```

### 方法三：使用 Chocolatey

```powershell
# 使用 Chocolatey 安装
choco install docker-desktop
```

---

## Linux 安装后配置

### 1. 配置用户权限（免 sudo）

```bash
# 将当前用户加入 docker 组
sudo usermod -aG docker $USER

# 使组权限立即生效（或重新登录）
newgrp docker

# 验证
docker run hello-world
```

### 2. 配置 Docker 服务

```bash
# 启动 Docker 服务
sudo systemctl start docker

# 设置开机自启
sudo systemctl enable docker

# 查看服务状态
sudo systemctl status docker

# 重启 Docker 服务
sudo systemctl restart docker

# 停止 Docker 服务
sudo systemctl stop docker
```

---

## Docker 配置优化

### daemon.json 配置文件

配置文件位置：`/etc/docker/daemon.json`

```json
{
    // 数据存储目录
    "data-root": "/data/docker",

    // 存储驱动
    "storage-driver": "overlay2",

    // 日志配置
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },

    // 镜像加速源（国内推荐）
    "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://dockerproxy.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://docker.nju.edu.cn"
    ],

    // 私有仓库（不验证证书）
    "insecure-registries": ["registry.example.com:5000"],

    // 默认 ulimit 配置
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 65535,
            "Soft": 65535
        }
    },

    // Cgroup 驱动（Kubernetes 要求）
    "exec-opts": ["native.cgroupdriver=systemd"],

    // 默认运行时
    "default-runtime": "runc",

    // 实时恢复
    "live-restore": true,

    // 最大并发下载数
    "max-concurrent-downloads": 10,

    // 最大并发上传数
    "max-concurrent-uploads": 5,

    // 默认地址池
    "default-address-pools": [
        {
            "base": "172.17.0.0/16",
            "size": 24
        }
    ]
}
```

### 应用配置

```bash
# 创建配置目录
sudo mkdir -p /etc/docker

# 创建或编辑配置文件
sudo vim /etc/docker/daemon.json

# 重启 Docker 使配置生效
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证配置
docker info | grep -A 10 "Storage Driver"
docker info | grep -A 5 "Registry Mirrors"
```

---

## 配置代理加速

### 方法一：配置 Docker Daemon 代理

```bash
# 创建 systemd 服务配置目录
sudo mkdir -p /etc/systemd/system/docker.service.d

# 创建代理配置文件
sudo vim /etc/systemd/system/docker.service.d/http-proxy.conf
```

```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:7890"
Environment="HTTPS_PROXY=http://proxy.example.com:7890"
Environment="NO_PROXY=localhost,127.0.0.1,*.internal.example.com"
```

```bash
# 重新加载配置并重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证代理配置
sudo systemctl show --property=Environment docker
```

### 方法二：配置镜像加速源

```bash
# 编辑 daemon.json
sudo vim /etc/docker/daemon.json
```

```json
{
    "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://dockerproxy.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://docker.nju.edu.cn",
        "https://mirror.ccs.tencentyun.com"
    ]
}
```

```bash
# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 方法三：Docker 客户端代理（用于 docker build）

在 Dockerfile 构建过程中需要代理时：

```bash
# 创建或编辑客户端配置
mkdir -p ~/.docker
vim ~/.docker/config.json
```

```json
{
    "proxies": {
        "default": {
            "httpProxy": "http://proxy.example.com:7890",
            "httpsProxy": "http://proxy.example.com:7890",
            "noProxy": "localhost,127.0.0.1"
        }
    }
}
```

---

## 数据目录迁移

默认情况下，Docker 数据存储在 `/var/lib/docker`。如果需要迁移到其他磁盘：

### 方法一：修改配置文件

```bash
# 1. 停止 Docker 服务
sudo systemctl stop docker

# 2. 创建新的数据目录
sudo mkdir -p /data/docker

# 3. 迁移数据（可选）
sudo rsync -avz /var/lib/docker/ /data/docker/

# 4. 修改配置文件
sudo vim /etc/docker/daemon.json
```

```json
{
    "data-root": "/data/docker"
}
```

```bash
# 5. 重启 Docker
sudo systemctl daemon-reload
sudo systemctl start docker

# 6. 验证
docker info | grep "Docker Root Dir"
```

### 方法二：使用软链接

```bash
# 1. 停止 Docker 服务
sudo systemctl stop docker

# 2. 迁移数据
sudo mv /var/lib/docker /data/docker

# 3. 创建软链接
sudo ln -s /data/docker /var/lib/docker

# 4. 启动 Docker
sudo systemctl start docker
```

---

## 卸载 Docker

### Ubuntu/Debian 卸载

```bash
# 1. 卸载 Docker 包
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# 2. 删除数据目录（可选，会删除所有容器、镜像、卷）
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 3. 删除配置文件（可选）
sudo rm -rf /etc/docker
sudo rm -rf /var/run/docker.sock

# 4. 清理残留依赖
sudo apt-get autoremove -y
```

### CentOS/RHEL/Fedora 卸载

```bash
# 1. 卸载 Docker 包
sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# 或使用 yum（CentOS 7）
sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# 2. 删除数据目录（可选）
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 3. 删除配置文件（可选）
sudo rm -rf /etc/docker
sudo rm /etc/yum.repos.d/docker-ce.repo
```

---

## 常见问题排查

### 1. 权限问题

```bash
# 错误：Got permission denied while trying to connect to the Docker daemon socket

# 解决方案 1：将用户加入 docker 组
sudo usermod -aG docker $USER
newgrp docker

# 解决方案 2：临时使用 sudo
sudo docker ps

# 解决方案 3：修改 socket 权限（不推荐）
sudo chmod 666 /var/run/docker.sock
```

### 2. 服务无法启动

```bash
# 检查服务状态
sudo systemctl status docker

# 查看详细日志
sudo journalctl -xeu docker.service

# 检查配置文件语法
dockerd --validate

# 检查网络问题
sudo iptables -L -n
```

### 3. 镜像拉取失败

```bash
# 检查网络连接
ping -c 4 hub.docker.com

# 检查 DNS 解析
nslookup hub.docker.com

# 检查代理配置
sudo systemctl show --property=Environment docker

# 使用镜像加速
# 编辑 /etc/docker/daemon.json 添加 registry-mirrors
```

### 4. 磁盘空间不足

```bash
# 查看 Docker 磁盘使用
docker system df

# 清理未使用的资源
docker system prune -a --volumes

# 查看具体占用
docker system df -v
```

### 5. Docker daemon 不响应

```bash
# 检查 Docker 进程
ps aux | grep docker

# 检查 Docker socket
ls -la /var/run/docker.sock

# 重启 Docker 服务
sudo systemctl restart docker

# 如果完全卡住，强制终止
sudo systemctl kill docker
sudo systemctl start docker
```

---

## 验证安装

```bash
# 查看版本
docker --version
docker compose version

# 查看详细信息
docker info

# 运行测试容器
docker run --rm hello-world

# 查看 Docker 组件版本
docker version
```

---

## 参考链接

- [Docker 官方安装文档](https://docs.docker.com/engine/install/)
- [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- [Post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/)
