# CodeBuddy Code 用户偏好设置

## Git Commit 规则

### Commit 策略
- **单文件提交**: 每个修改的文件应该单独创建一个commit,而不是将多个文件的修改放在一个commit中
- **原因**: 提高每个commit的可读性和原子性,使git历史更清晰易懂

### Commit Message 格式
- 每个commit message应该简洁明了,描述该文件的具体修改内容
- 不要创建包含多个文件修改的长commit message

### 示例
```
# 好的做法 ✓
git commit -m "fix: 修复登录页面的表单验证逻辑" -- src/pages/login.vue
git commit -m "feat: 添加用户信息API接口" -- src/api/user.js

# 避免的做法 ✗
git commit -m "修复登录页面、添加用户API、更新配置文件..." --all
```

---

_此文件会自动加载到每个会话中,用于记录重要的编码偏好和规则。_
