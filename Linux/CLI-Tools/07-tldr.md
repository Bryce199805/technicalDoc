# tldr 命令文档

## 简介

tldr (Too Long; Didn't Read) 是简化版的 man 手册，提供简洁的命令示例。

## 安装

```bash
sudo apt install tldr
```

首次使用需要下载文档：
```bash
tldr --update
```

---

## 基本用法

```bash
# 查看 tar 命令用法
tldr tar

# 查看 git commit 用法
tldr git-commit

# 查看 docker run 用法
tldr docker-run
```

---

## tldr vs man

### man tar
```
TAR(1)                          GNU TAR MANUAL                         TAR(1)

NAME
       tar - an archiving utility

SYNOPSIS
       tar [OPTION...] [FILE]...

DESCRIPTION
       GNU  tar  is  an archiving program designed to store multiple files in
       a single file (an archive), and to manipulate such archives.   The  ar‐
       chive  can  be  either  a regular file or a device (such as a tape drive,
       ...
   (几十页内容)
```

### tldr tar
```
  tar

  archiving utility
  often combined with a compression method, such as gzip or bzip2

  [c]reate an archive from files:
      tar cf target.tar file1 file2 file3

  [c]reate a g[z]ipped archive from files:
      tar czf target.tar.gz file1 file2 file3

  [x]tract a g[z]ipped archive to the current directory:
      tar xzf source.tar.gz

  [x]tract an archive to a target directory:
      tar xf source.tar -C directory

  [t]est contents of an archive:
      tar tvf source.tar
```

---

## 常用命令示例

### 文件操作

```bash
tldr cp         # 复制文件
tldr mv         # 移动文件
tldr rm         # 删除文件
tldr mkdir      # 创建目录
tldr chmod      # 修改权限
tldr chown      # 修改所有者
```

### 压缩解压

```bash
tldr tar        # tar 归档
tldr zip        # zip 压缩
tldr unzip      # zip 解压
tldr gzip       # gzip 压缩
```

### Git

```bash
tldr git        # git 总览
tldr git-clone  # 克隆仓库
tldr git-commit # 提交
tldr git-push   # 推送
tldr git-pull   # 拉取
tldr git-branch # 分支
```

### Docker

```bash
tldr docker     # docker 总览
tldr docker-run # 运行容器
tldr docker-ps  # 列出容器
tldr docker-exec # 执行命令
```

### 网络

```bash
tldr curl       # HTTP 请求
tldr wget       # 下载文件
tldr ssh        # SSH 连接
tldr scp        # 远程复制
```

---

## 常用选项

| 选项 | 说明 |
|------|------|
| `-u, --update` | 更新文档库 |
| `-L, --language` | 指定语言（如 zh） |
| `-p, --platform` | 指定平台（linux/macos/windows） |
| `-s, --source` | 指定来源 |

---

## 中文支持

```bash
# 使用中文文档
tldr --language zh tar

# 设置默认中文
export TLDR_LANGUAGE=zh
```

---

## 平台指定

```bash
# 查看 Linux 平台的命令
tldr --platform linux apt

# 查看 macOS 平台的命令
tldr --platform macos brew

# 查看 Windows 平台的命令
tldr --platform windows dir
```

---

## 定期更新

建议定期更新文档：

```bash
tldr --update
```

或在 `~/.zshrc` 中添加定时更新提醒。
