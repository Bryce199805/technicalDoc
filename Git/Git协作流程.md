# Git 协作流程

## 远程仓库操作

### 远程仓库管理（整合原有文档）
```bash
# 查看远程仓库
git remote                     # 列出当前仓库中已配置的远程仓库
git remote -v                  # 列出当前仓库中已配置的远程仓库，并显示它们的 URL

# 添加远程仓库
git remote add <remote_name> <remote_url>    # 添加一个新的远程仓库

# 修改远程仓库
git remote rename <old_name> <new_name>        # 将已配置的远程仓库重命名
git remote set-url <remote_name> <new_url>     # 修改指定远程仓库的 URL

git remote show <remote_name>                    # 显示指定远程仓库的详细信息

git remote remove <remote_name>                  # 从当前仓库中删除指定的远程仓库

# 示例
git remote add origin <remote address>
git remote add upstream https://github.com/original/repo.git
```

### 推送和拉取
```bash
# 首次推送并建立上游分支
git push -u origin main

# 常规推送
git push

# 推送所有分支
git push --all origin

# 删除远程分支
git push origin --delete feature/old-feature

# 拉取远程变更
git pull origin main

# 拉取并合并
git fetch origin
git merge origin/main
```

## 常见协作模式

### Fork & Pull Request 模式
1. Fork 原项目到自己的账户
2. Clone 自己的fork：`git clone https://github.com/yourname/repo.git`
3. 添加上游仓库：`git remote add upstream https://github.com/original/repo.git`
4. 创建功能分支：`git checkout -b feature/my-contribution`
5. 开发并提交变更
6. Push到自己的fork：`git push origin feature/my-contribution`
7. 在GitHub上发起Pull Request

### Shared Repository 模式
1. Clone共享仓库：`git clone https://github.com/team/repo.git`
2. 创建功能分支：`git checkout -b feature/new-feature`
3. 定期同步：`git pull origin main`
4. Push分支：`git push origin feature/new-feature`
5. 发起Pull Request或直接合并

## 同步上游变更

### 保持Fork同步
```bash
# 获取上游仓库最新变更
git fetch upstream

# 切换到本地main分支
git checkout main

# 合并上游变更
git merge upstream/main

# 推送到自己的fork
git push origin main
```

### 同步功能分支
```bash
# 切换到功能分支
git checkout feature/my-feature

# 变基到最新的main
git rebase main

# 如果有冲突，解决后继续
git add .
git rebase --continue

# 强制推送到远程分支（因为rebase改写了历史）
git push origin feature/my-feature --force-with-lease
```

## Pull Request 最佳实践

### 创建PR前的检查
```bash
# 确保分支是最新的
git pull origin main

# 运行测试确保所有检查通过
npm test

# 检查代码风格
npm run lint

# 确认提交信息规范
git log --oneline
```

### PR描述模板
```markdown
## 变更内容
- [ ] 新增用户登录功能
- [ ] 修复密码验证bug
- [ ] 更新API文档

## 测试情况
- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 手动测试完成

## 相关Issue
Closes #123
Related #456

## 截图（如适用）
[添加截图]
```

## 代码审查流程

### 作为审查者
- 检查代码逻辑是否正确
- 确认是否符合项目规范
- 测试关键功能点
- 提出建设性意见
- 批准或请求修改

### 作为开发者
- 及时响应审查意见
- 解释设计决策的原因
- 分批处理多个小修改
- 感谢反馈并持续改进

## 冲突解决策略

### 预防冲突
- 频繁同步主线分支变更
- 保持功能分支周期短
- 小步提交，经常推送

### 解决冲突步骤
1. 拉取最新变更：`git pull origin main`
2. 解决冲突文件中的冲突标记
3. 测试确保功能正常
4. 提交解决结果：`git add . && git commit -m "Resolve merge conflicts"`
5. 推送更新：`git push`

## 发布管理

### 版本标签
```bash
# 创建版本标签
git tag -a v1.2.0 -m "Release version 1.2.0"

# 推送标签到远程
git push origin v1.2.0

# 推送所有标签
git push origin --tags
```

### 发布分支
```bash
# 从main创建发布分支
git checkout -b release/v1.2.0 main

# 进行发布准备（最后测试、文档更新）
# ...

# 打标签并合并到main和develop
git tag v1.2.0
git checkout main
git merge release/v1.2.0
git checkout develop
git merge release/v1.2.0
```

## 大型项目协作

### 长期分支策略
- `main`: 生产就绪代码
- `develop`: 下一个版本的集成分支
- `feature/*`: 功能开发分支
- `release/*`: 发布准备分支
- `hotfix/*`: 紧急修复分支

### 渐进式稳定
1. 功能开发在`feature/*`分支
2. 完成后合并到`develop`分支
3. 定期从`develop`创建`release/*`分支
4. 测试通过后合并到`main`和`develop`
5. 紧急修复直接从`main`创建`hotfix/*`分支

---

**上一步**: [Git高级技巧](Git高级技巧.md)  
**下一步**: [Git常见问题](Git常见问题.md)

## 协作检查清单

- [ ] 提交前运行测试
- [ ] 遵循项目的提交规范
- [ ] 保持分支与主线的同步
- [ ] 写清晰的PR描述
- [ ] 积极回应代码审查
- [ ] 及时处理CI/CD失败