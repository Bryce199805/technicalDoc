# Git 分支管理

分支是Git最强大的功能之一，让你可以并行开发多个功能而不互相干扰。

## 分支基础

### 创建和切换分支
```bash
# 查看所有分支（当前分支前有*标记）
git branch

# 创建新分支
git branch feature/new-feature

# 切换到分支
git checkout feature/new-feature
# 或使用新版本
git switch feature/new-feature

# 创建并切换到新分支（常用）
git checkout -b feature/new-feature
# 或使用新版本
git switch -c feature/new-feature
```

### 合并分支
```bash
# 切换到目标分支（如main）
git switch main

# 合并feature分支到当前分支
git merge feature/new-feature

# 如果遇到冲突，解决后提交
git add .
git commit -m "Resolve merge conflicts"
```

### 删除分支
```bash
# 删除已合并的分支
git branch -d feature/new-feature

# 强制删除未合并的分支
git branch -D feature/new-feature

# 删除远程分支
git push origin --delete feature/new-feature
git push origin :feature/new-feature  # 等效写法
```

## 分支策略

### Git Flow 模型
```
main (master)          # 生产环境分支
├── develop            # 开发环境分支
│   ├── feature/user-auth
│   ├── feature/payment
│   └── feature/ui-redesign
├── hotfix/critical-bug
└── release/v1.2.0
```

### GitHub Flow 模型（推荐）
- `main` 分支始终保持可部署状态
- 功能开发在特性分支进行：`feature/xxx`
- 通过Pull Request合并到`main`
- 自动化测试和部署

### 分支命名规范
```bash
feature/add-user-profile    # 新功能
fix/login-validation-error   # Bug修复
hotfix/critical-security-patch  # 紧急修复
release/v1.2.0              # 发布准备
refactor/api-endpoints      # 重构
chore/update-dependencies   # 维护任务
doc/update-readme           # 文档更新
```

## 高级分支操作

### 变基 (Rebase)
```bash
# 将feature分支变基到main最新状态
git switch feature/new-feature
git rebase main

# 交互式变基（修改提交历史）
git rebase -i HEAD~3  # 修改最近3个提交
```

**Rebase vs Merge**：
- Rebase：线性历史，更干净
- Merge：保留分支拓扑，更真实

###  cherry-pick
```bash
# 将特定提交应用到当前分支
git cherry-pick abc123def456

# 应用多个提交
git cherry-pick oldest_commit..newest_commit
```

### 分支比较
```bash
# 比较两个分支的差异
git diff main..feature/new-feature

# 查看哪些提交在一个分支但不在另一个分支
git log main..feature/new-feature
git log feature/new-feature..main
```

## 冲突解决

### 识别冲突
```bash
# 拉取时发生冲突
git pull origin main
# 输出：CONFLICT (content): Merge conflict in filename

# 合并时发生冲突
git merge feature-branch
# 输出：Automatic merge failed; fix conflicts and then commit the result
```

### 解决冲突步骤
1. **打开冲突文件**，寻找冲突标记：
   ```
   <<<<<<< HEAD
   当前分支的内容
   ========
   待合并分支的内容
   >>>>>>> feature-branch
   ```

2. **编辑文件**，保留正确内容，删除冲突标记

3. **标记冲突已解决**：
   ```bash
git add filename
   ```

4. **完成合并**：
   ```bash
git commit
   ```

### 中止合并
```bash
# 如果冲突太复杂，可以中止合并
git merge --abort

# 如果rebase有问题
git rebase --abort
```

## 长期分支维护

### 保持分支同步
```bash
# 定期从main更新feature分支
git switch feature/new-feature
git rebase main
# 或使用merge
git merge main
```

### 清理过期分支
```bash
# 查找已合并到main的分支
git branch --merged main | grep -v "\*main"

# 安全删除已合并分支
git branch -d branch_name
```

## 实用技巧

### 查看分支图
```bash
git log --oneline --graph --all
# 或使用别名（如果设置了）
git lg --all
```

### 临时保存工作
```bash
# 储藏当前修改，切换去处理紧急任务
git stash
git switch hotfix/urgent-fix
# ...处理完后...
git switch feature/new-feature
git stash pop
```

### 部分合并
```bash
# 只合并某个文件的特定提交
git checkout source_branch -- path/to/file
```

---

**上一步**: [Git日常操作](Git日常操作.md)  
**下一步**: [Git高级技巧](Git高级技巧.md)

## 总结

- 频繁创建分支进行功能开发
- 使用有意义的分支名称
- 定期同步主线分支的更新
- 及时删除已合并的分支
- 冲突不可避免时，耐心解决