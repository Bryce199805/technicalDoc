# Git 基础入门

## 什么是Git？

Git是一个分布式版本控制系统，用于跟踪文件变化，协调多人协作开发。

## 安装Git

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install git

# CentOS/RHEL
sudo yum install git

# macOS (使用Homebrew)
brew install git

# Windows: 下载Git for Windows
# https://git-scm.com/download/win
```

## 初次配置

```bash
# 设置用户信息（会记录在每次提交中）
git config --global user.name "你的姓名"
git config --global user.email "your.email@example.com"

# 设置代理（如需要）
git config --global http.proxy http://127.0.0.1:10809
git config --global https.proxy https://127.0.0.1:10809

# 查看配置
git config --global --list  # 全局配置
git config --local --list   # 当前仓库配置
```

## 基本概念

- **仓库(Repository)**: 存储项目文件和版本历史的地方
- **工作区(Working Directory)**: 你正在编辑的文件目录
- **暂存区(Staging Area)**: 准备提交的文件区域
- **提交(Commit)**: 保存文件快照的操作
- **分支(Branch)**: 独立的开发线
- **远程仓库(Remote)**: 托管在网络的仓库

## 创建第一个仓库

### 新建项目并初始化
```bash
mkdir my-project && cd my-project
git init
git add .
git commit -m "Initial commit"
```

### 克隆现有仓库
```bash
git clone <repository-url>
# 例如: git clone https://github.com/username/repository.git
```

### 关联远程仓库
```bash
git init
git remote add origin <remote-address>
git add .
git commit -m "Initial commit"
git push -u origin main
```

---

**下一步**: [Git日常操作](Git日常操作.md)