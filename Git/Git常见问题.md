# Git 常见问题与解决方案

## 基础问题

### Q1: 如何撤销上一次提交？
```bash
# 保留变更在工作区
git reset --soft HEAD^ 

# 保留变更在暂存区
git reset HEAD^

# 完全丢弃变更（谨慎使用）
git reset --hard HEAD^
```

### Q2: 如何修改最后一次提交？
```bash
# 修改提交信息
git commit --amend -m "新的提交信息"

# 添加遗漏的文件
git add forgotten_file
git commit --amend --no-edit
```

### Q3: 如何恢复误删的文件？
```bash
# 从最近的提交恢复文件
git checkout HEAD -- filename
# 或使用新版本
git restore filename

# 从特定提交恢复
git checkout commit_hash -- filename
```

## 分支相关问题

### Q4: 如何解决合并冲突？
1. 冲突文件中会出现标记：
   ```
   <<<<<<< HEAD
   当前分支的代码
   ========
   要合并分支的代码
   >>>>>>> feature-branch
   ```
2. 编辑文件，保留正确代码，删除冲突标记
3. `git add filename` 标记为已解决
4. `git commit` 完成合并

### Q5: 如何删除远程分支？
```bash
git push origin --delete branch_name
git push origin :branch_name  # 等效写法
```

### Q6: 分支历史混乱，如何整理？
```bash
# 交互式变基整理最近3个提交
git rebase -i HEAD~3

# 选项：pick(保留)、squash(合并)、edit(修改)、drop(删除)
```

## 远程仓库问题

### Q7: 权限被拒绝(Permission denied)
```bash
# 检查远程仓库URL是否正确
git remote -v

# 如果使用HTTPS，可能需要输入凭据
# 建议使用SSH密钥认证

git remote set-url origin git@github.com:user/repo.git
```

### Q8: 如何同步Fork的仓库？
```bash
git remote add upstream https://github.com/original/repo.git
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

### Q9: Push失败，提示需要先pull
```bash
git pull origin branch_name
# 解决可能的冲突后
git push origin branch_name

# 或者使用强制推送（谨慎使用）
git push --force-with-lease origin branch_name
```

## 撤销和重置问题

### Q10: 如何找回已经reset的提交？
```bash
# 查看操作历史
git reflog

# 恢复到之前的引用
git reset --hard HEAD@{n}  # n是reflog中的索引号
```

### Q11: 如何撤销已经push的提交？
```bash
# 方法1：创建反向提交
git revert commit_hash

git push origin branch_name

# 方法2：强制推送覆盖远程（影响其他协作者）
git reset --hard commit_hash
git push --force-with-lease origin branch_name
```

## 性能和存储问题

### Q12: 仓库太大，如何瘦身？
```bash
# 清理大文件历史
git filter-branch --tree-filter 'rm -f large_file.zip' HEAD

# 清理悬空对象
git gc --prune=now

# 使用BFG Repo-Cleaner工具（第三方）
```

### Q13: 子模块更新失败
```bash
# 重新初始化子模块
git submodule deinit -f .
git submodule update --init --recursive

# 清理并更新所有子模块
git submodule foreach git clean -fd
git submodule foreach git checkout .
git submodule update --remote
```

## 配置问题

### Q14: 如何设置默认编辑器？
```bash
git config --global core.editor "code --wait"     # VS Code
git config --global core.editor "vim"              # Vim
git config --global core.editor "nano"             # Nano
```

### Q15: 如何配置换行符处理？
```bash
# Windows
git config --global core.autocrlf true

# macOS/Linux
git config --global core.autocrlf input
```

## 错误信息解析

### 常见错误信息

**"fatal: not a git repository"**
```bash
# 当前目录不是Git仓库
cd /path/to/repo
git init  # 如果是新项目
```

**"error: failed to push some refs"**
```bash
# 远程有本地没有的提交
git pull --rebase origin branch_name
git push origin branch_name
```

**"CONFLICT (content): Merge conflict"**
```bash
# 合并时发生冲突，按Q6步骤解决
```

**"detached HEAD state"**
```bash
# 当前不在任何分支上
# 如果想保留当前修改
git checkout -b new-branch-name
# 如果不需要修改
git checkout main
```

## 调试技巧

### 查看Git内部状态
```bash
# 查看对象数据库
git cat-file -p commit_hash

# 查看引用日志
git reflog

# 查看Git配置层级
git config --list --show-origin

# 调试钩子脚本
git hooks --verbose
```

### 逐步执行
```bash
# 使用--dry-run预览操作
git clean -n  # 预览将要删除的文件
git reset --hard --dry-run  # 预览重置操作

# 使用详细输出
git push -v
git pull --verbose
```

## 预防措施

### 最佳实践
- 提交前运行测试
- 推送前拉取最新变更
- 使用有意义的提交信息
- 定期清理不需要的分支
- 重要操作前备份分支

### 使用工具辅助
- **Git GUI客户端**: SourceTree, GitKraken
- **IDE集成**: VS Code Git插件, IntelliJ Git工具
- **命令行增强**: oh-my-zsh git插件
- **预提交钩子**: 自动代码检查

---

**相关文档**:
- [Git日常操作](Git日常操作.md) - 基础命令参考
- [Git分支管理](Git分支管理.md) - 分支策略详解
- [Git高级技巧](Git高级技巧.md) - 高级功能使用

记住：**大多数Git问题都有解决方案，不要害怕实验，多用`git reflog`找回丢失的工作！**