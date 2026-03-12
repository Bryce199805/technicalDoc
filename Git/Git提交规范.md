# Git 提交规范 (Commit Message Convention)

良好的提交信息对于项目维护至关重要。本文将介绍业界广泛采用的提交规范。

## 为什么需要规范？

- **可读性**: 清晰描述变更内容
- **自动化**: 支持自动生成CHANGELOG
- **协作**: 便于团队成员理解变更
- **调试**: 快速定位问题引入点

## Conventional Commits 规范

最常用的规范是 [Conventional Commits](https://conventionalcommits.org/)，格式如下：

```
<类型>[可选的作用域]: <描述>

[可选的正文]

[可选的脚注]
```

### 1. 提交类型 (Type)

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: add user login API` |
| `fix` | Bug修复 | `fix: resolve memory leak in parser` |
| `docs` | 文档更新 | `docs: update README installation guide` |
| `style` | 代码格式调整 | `style: format code with prettier` |
| `refactor` | 重构代码 | `refactor: simplify user validation logic` |
| `test` | 测试相关 | `test: add unit tests for auth module` |
| `chore` | 构建过程或辅助工具的变动 | `chore: update webpack config` |
| `perf` | 性能优化 | `perf: optimize image loading` |
| `ci` | CI配置文件和脚本变动 | `ci: add github actions workflow` |
| `build` | 构建系统或外部依赖变动 | `build: upgrade react to v18` |

### 2. 作用域 (Scope) - 可选

指定变更的模块或组件：
```
feat(auth): add password strength validation
fix(api): resolve timeout issue in user service
```

常见作用域示例：
- `auth`: 认证模块
- `api`: API接口
- `ui`: 用户界面
- `db`: 数据库
- `config`: 配置文件

### 3. 描述 (Description)

- 使用**祈使句**，动词开头
- 首字母小写
- 不加句号结尾
- 简明扼要，不超过50字符

❌ 错误示例：
- `Fixed the bug in login` (过去式)
- `Added new feature for user registration.` (过去式+句号)

✅ 正确示例：
- `Fix login validation error`
- `Add user registration feature`

### 4. 正文 (Body) - 可选

详细说明变更原因和影响：
```
feat: add email verification for new users

- Add email verification endpoint
- Send verification token to user email
- Require email verification before account activation

Closes #123
```

### 5. 脚注 (Footer) - 可选

用于关联Issue或Breaking Changes：
```
BREAKING CHANGE: remove deprecated login method
```

```
Fix: resolve database connection timeout

Closes #456, #789
```

## 实际示例

### 简单提交
```bash
git commit -m "feat: add search functionality to user list"
git commit -m "fix: correct typo in error message"
git commit -m "docs: update API documentation"
```

### 复杂提交
```bash
git commit -m "feat(auth): implement OAuth2 login flow

- Add Google OAuth2 provider integration
- Create login callback handler
- Store access tokens securely
- Update user model to support OAuth providers

Closes #234
Refs #567
"
```

### 破坏性变更
```bash
git commit -m "feat!: migrate from REST to GraphQL API

BREAKING CHANGE: All API endpoints have changed from /api/v1/* to /graphql
Clients must update to use GraphQL queries
"
```

## 快捷模板

### 方法1：Git Commit Template

创建 `~/.gitmessage` 文件：
```
# <类型>[可选的作用域]: <描述>
#
# 正文
#
# 脚注
#
# 类型: feat, fix, docs, style, refactor, test, chore, perf, ci, build
# 作用域: auth, api, ui, db, config (可选)
```

启用模板：
```bash
git config --global commit.template ~/.gitmessage
```

### 方法2：Commitizen工具

使用 [Commitizen](https://github.com/commitizen/cz-cli) 引导式提交：
```bash
npm install -g commitizen cz-conventional-changelog
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc

# 使用cz代替git commit
cz
```

## 验证提交信息

使用 [commitlint](https://github.com/conventional-changelog/commitlint) 自动检查：

```bash
# 安装
npm install --save-dev @commitlint/{config-conventional,cli}
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js

# 配合husky使用
npx husky install
npx husky add .husky/commit-msg 'npx --no-install commitlint --edit $1'
```

## 生成CHANGELOG

使用 [standard-version](https://github.com/conventional-changelog/standard-version)：
```bash
npm install --save-dev standard-version
npx standard-version
```

## 团队约定

建议团队制定并遵循统一的提交规范：

1. **强制使用**: 所有提交必须遵循规范
2. **工具支持**: 配置pre-commit hooks验证
3. **定期回顾**: 根据实际情况调整规范
4. **文档共享**: 确保新成员了解规范

## 总结

好的提交信息应该：
- ✅ 清晰描述"什么"被改变
- ✅ 简要说明"为什么"改变
- ✅ 遵循一致的格式
- ✅ 使用正确的类型

记住：**提交信息是给人类看的，不是给机器看的！**

---

**相关链接**:
- [Conventional Commits 官网](https://conventionalcommits.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- [Git Commit Best Practices](https://cbea.ms/git-commit/)