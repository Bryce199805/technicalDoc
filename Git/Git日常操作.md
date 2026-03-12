# Git 日常操作

## 基本工作流程

```bash
# 1. 检查当前状态
git status

# 2. 查看文件变更
git diff                    # 查看未暂存的变更
git diff --cached          # 查看已暂存的变更

# 3. 添加文件到暂存区
git add filename            # 添加特定文件
git add .                   # 添加所有变更文件
git add *.js                # 添加所有js文件

# 4. 提交变更
git commit -m "描述性提交信息"

# 5. 查看提交历史
git log                     # 详细历史
git log --oneline           # 简洁历史
git log --graph             # 图形化分支历史
```

## 文件操作

### 撤销修改
```bash
# 撤销工作区文件的修改（未暂存）
git checkout -- filename
# 或使用新版本
git restore filename

# 取消暂存的文件（已add但未commit）
git reset HEAD filename
# 或使用新版本
git restore --staged filename

# 完全撤销文件变更（包括暂存区）
git reset --hard HEAD
```

### 删除文件
```bash
# 从Git中删除文件（同时删除本地文件）
git rm filename

# 从Git中删除但保留本地文件
git rm --cached filename

# 移动/重命名文件
git mv oldname newname
```

## 查看历史

```bash
# 基本日志
git log

# 常用选项
git log --oneline                    # 单行显示
git log --graph --oneline           # 图形化单行显示
git log -p                           # 显示具体变更
git log -3                           # 最近3条记录
git log --author="用户名"            # 按作者筛选
git log --since="2 weeks ago"        # 时间筛选
git log --grep="keyword"            # 提交信息搜索

# 查看某个文件的修改历史
git log --follow filename

# 查看某行代码的变更历史
git blame filename
```

## 标签管理

```bash
# 创建标签
git tag v1.0.0                      # 轻量标签
git tag -a v1.0.0 -m "版本1.0发布"    # 附注标签

# 查看标签
git tag

# 推送标签到远程
git push origin v1.0.0              # 推送单个标签
git push origin --tags              # 推送所有标签

# 删除标签
git tag -d v1.0.0                   # 删除本地标签
git push origin :refs/tags/v1.0.0   # 删除远程标签
```

## 储藏 (Stash)

```bash
# 储藏当前工作现场
git stash

# 储藏时添加备注
git stash save "修复紧急bug前的状态"

# 查看储藏列表
git stash list

# 应用最近的储藏
git stash pop

# 应用指定储藏
git stash apply stash@{1}

# 删除储藏
git stash drop stash@{0}

# 清空储藏
git stash clear
```

## 实用技巧

### 批量操作
```bash
# 交互式添加文件变更
git add -p

# 撤销最后一次提交（保留变更）
git reset --soft HEAD^ 

# 修改最后一次提交
git commit --amend

# 压缩最后n个提交
git rebase -i HEAD~3
```

### 别名设置
```bash
# 设置常用别名
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg "log --oneline --graph --decorate"

# 使用别名
git st
git co master
git lg
```

---

**上一步**: [Git基础入门](Git基础入门.md)  
**下一步**: [Git分支管理](Git分支管理.md)