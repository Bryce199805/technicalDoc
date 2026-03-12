# Git 基础入门

## 什么是Git？

Git是一个分布式版本控制系统，用于跟踪文件变化，协调多人协作开发。

## 安装Git

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install git

# CentOS/RHEL
sudo yum install git

# macOS (使用Homebrew)
brew install git

# Windows
# 下载Git for Windows: https://git-scm.com/download/win
```

## 初次配置

```bash
# 设置用户名（重要：会记录在每次提交中）
git config --global user.name "你的姓名"

# 设置邮箱（重要：会记录在每次提交中）
git config --global user.email "your.email@example.com"

# 设置默认编辑器（可选）
git config --global core.editor vim

# 设置git代理（原有文档整合）
git config --global http.proxy http://127.0.0.1:10809
git config --global https.proxy https://127.0.0.1:10809

# 查看配置
git config --global --list    # 查看全局配置信息
git config --local --list     # 查看当前仓库配置信息

# 查看远程仓库配置
git remote                    # 列出当前仓库中已配置的远程仓库
git remote -v                 # 列出当前仓库中已配置的远程仓库，并显示它们的 URL
```

## 基本概念

- **仓库(Repository)**: 存储项目文件和版本历史的地方
- **工作区(Working Directory)**: 你正在编辑的文件目录
- **暂存区(Staging Area)**: 准备提交的文件区域
- **提交(Commit)**: 保存文件快照的操作
- **分支(Branch)**: 独立的开发线
- **远程仓库(Remote)**: 托管在网络的仓库

## 创建第一个仓库

### 方式1：初始化新仓库
```bash
# 创建项目目录
mkdir my-project
cd my-project

# 初始化Git仓库
git init

# 创建初始文件
echo "# My Project" > README.md

# 添加到暂存区
git add README.md

# 首次提交
git commit -m "Initial commit"
```

### 方式2：项目关联远程仓库（原有文档整合）
```bash
# 初始化
git init
# 添加远程仓库地址
git remote add origin <remote address>
# 从远程仓库获取代码库
git fetch origin main
# 设置上游分支
git push --set-upstream origin master
# 添加本地文件夹到暂存区
git add .
# 添加注释并提交
git commit -m "添加提交注释"
# 推送到仓库
git push
```

### 方式3：克隆现有仓库
```bash
git clone <repository-url>
git clone https://github.com/username/repository.git
```

### 方式2：克隆现有仓库
```bash
git clone <repository-url>
git clone https://github.com/username/repository.git
```

---

**下一步**: [Git日常操作](Git日常操作.md)