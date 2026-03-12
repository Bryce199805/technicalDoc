# Git 高级技巧

## 重置与回退

### git reset 三种模式
```bash
# --soft: 仅重置HEAD，保留暂存区和工作区
git reset --soft HEAD^          # 撤销上次提交，保留变更在暂存区
git reset --soft commit_hash    # 回滚到指定commit

# --mixed (默认): 重置HEAD和暂存区，保留工作区
git reset HEAD^                 # 撤销上次提交和add操作
git reset commit_hash          # 回退到指定提交

# --hard: 重置HEAD、暂存区和工作区（危险！）
git reset --hard HEAD^          # 完全回退到上次提交前状态
git reset --hard commit_hash    # 完全回滚到指定commit

# 强推到远程（谨慎使用）
git push origin HEAD --force
```

### 找回误删的提交
```bash
# 查看所有操作记录（包括重置前的提交）
git reflog

# 恢复到reflog中的某个状态
git reset --hard HEAD@{n}       # n是reflog中的索引
```

## 交互式操作

### 交互式暂存
```bash
# 逐块选择要暂存的变更
git add -p
# 或
git add --patch

# 选项说明：
y - 暂存此块
n - 跳过此块
s - 将此块分割成更小块
e - 手动编辑此块
d - 跳过剩余所有块
q - 退出
```

### 交互式变基
```bash
# 修改最近n个提交
git rebase -i HEAD~3

# 常用操作指令：
pick    - 保留提交
reword  - 修改提交信息
edit    - 修改提交内容
squash  - 合并到前一个提交
fixup   - 合并到前一个提交（丢弃提交信息）
exec    - 执行shell命令
drop    - 删除提交
```

## 子模块 (Submodules)

### 基本操作
```bash
# 添加子模块
git submodule add <repository-url> <path>

# 克隆含子模块的仓库
git clone --recursive <repository-url>

# 初始化和更新子模块
git submodule init
git submodule update
git submodule update --init --recursive

# 更新子模块到最新提交
git submodule update --remote

# 删除子模块
git submodule deinit -f path/to/submodule
git rm -f path/to/submodule
rm -rf .git/modules/path/to/submodule
```

## 子树合并 (Subtree)

### 添加子树
```bash
git subtree add --prefix=libs/external https://github.com/user/repo.git main --squash
```

### 更新子树
```bash
git subtree pull --prefix=libs/external https://github.com/user/repo.git main --squash
```

### 推送子树更改
```bash
git subtree push --prefix=libs/external https://github.com/user/repo.git main
```

## 钩子 (Hooks)

### 常用钩子
- `pre-commit`: 提交前执行（代码检查、格式化）
- `post-commit`: 提交后执行
- `pre-push`: 推送前执行（运行测试）
- `post-checkout`: 切换分支后执行

### 示例：pre-commit钩子
```bash
# 在 .git/hooks/pre-commit 文件中添加
#!/bin/sh
npm run lint
if [ $? -ne 0 ]; then
    echo "Lint failed, commit aborted"
    exit 1
fi
```

## 二分查找 (Bisect)

### 定位引入Bug的提交
```bash
# 开始二分查找
git bisect start

# 标记当前版本为坏的
git bisect bad

# 标记已知好的版本
git bisect good commit_hash

# Git会自动检出中间的提交，测试后标记为好或坏
git bisect good  # 或 git bisect bad

# 找到问题提交后
git bisect reset  # 回到原分支
```

## 工作树 (Worktree)

### 多工作目录管理
```bash
# 创建新的工作树
git worktree add ../hotfix-branch hotfix/urgent-fix

# 查看所有工作树
git worktree list

# 删除工作树
git worktree remove ../hotfix-branch
```

## 高级日志查询

### 图形化展示
```bash
# 美观的分支图
git log --graph --oneline --decorate --all

# 按时间线展示
git log --date-order --graph --format="%h %ad %s" --date=short
```

### 统计分析
```bash
# 统计每个作者的提交数
git shortlog -sn

# 统计代码行数变化
git log --author="username" --pretty=tformat: --numstat | awk '{ add += $1; subs += $2; loc += $1 - $2 } END { printf "added lines: %s, removed lines: %s, total lines: %s\n", add, subs, loc }'
```

## 恢复操作

### 撤销提交但保留变更
```bash
git reset --soft HEAD^          # 撤销提交，保留在暂存区
git reset HEAD^                 # 撤销提交和add，保留在工作区
git reset --hard HEAD^          # 完全撤销（谨慎使用）
```

### 修改最后一次提交
```bash
# 修改提交信息
git commit --amend -m "新的提交信息"

# 添加遗漏的文件到上次提交
git add forgotten-file.txt
git commit --amend --no-edit
```

### 恢复已删除的分支
```bash
# 找到删除分支的最后一次提交
git reflog | grep "branch-name"

# 基于该提交重建分支
git checkout -b branch-name commit_hash
```

---

**上一步**: [Git分支管理](Git分支管理.md)  
**下一步**: [Git协作流程](Git协作流程.md)

## 注意事项

- `--hard` 重置会永久删除未提交的变更
- 使用 `reflog` 可以找回大部分"丢失"的提交
- 子模块需要团队成员都了解其工作方式
- 交互式操作前建议先备份重要分支