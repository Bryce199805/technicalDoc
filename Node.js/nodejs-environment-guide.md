# Node.js 开发环境配置指南

本文档整理了 nvm、npm、包管理器的使用方法,以及 zsh/bash shell 配置的最佳实践。

---

## 目录

1. [nvm - Node.js 版本管理](#nvm---nodejs-版本管理)
2. [npm - Node 包管理器](#npm---node-包管理器)
3. [其他包管理器](#其他包管理器)
4. [常见问题与冲突解决](#常见问题与冲突解决)
5. [Shell 环境配置](#shell-环境配置)
6. [最佳实践](#最佳实践)

---

## nvm - Node.js 版本管理

### 什么是 nvm?

nvm (Node Version Manager) 允许在同一台机器上安装和管理多个 Node.js 版本,并可以随时切换。

### 安装 nvm

```bash
# 使用 curl 安装
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# 或使用 wget
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# 安装后重新加载 shell 配置
source ~/.zshrc  # 或 source ~/.bashrc
```

### nvm 常用命令

```bash
# 查看帮助
nvm --help

# 安装最新 LTS 版本
nvm install --lts

# 安装指定版本
nvm install 18
nvm install 20.10.0
nvm install 24

# 列出可安装的版本
nvm ls-remote
nvm ls-remote --lts

# 列出已安装的版本
nvm ls

# 切换 Node 版本
nvm use 18
nvm use 20
nvm use default

# 设置默认版本
nvm alias default 18
nvm alias default 20

# 查看当前使用的版本
nvm current

# 卸载指定版本
nvm uninstall 18.17.0

# 查看某个版本的安装路径
nvm which 18
nvm which current
```

### .nvmrc 文件

在项目根目录创建 `.nvmrc` 文件,指定项目需要的 Node 版本:

```
# .nvmrc 文件内容示例
18.17.0
```

使用方法:
```bash
# 进入项目目录
cd my-project

# 自动切换到 .nvmrc 指定的版本
nvm use
# 或
nvm install && nvm use
```

### nvm 的目录结构

```
~/.nvm/
├── nvm.sh                    # nvm 脚本
└── versions/
    └── node/
        ├── v18.20.0/         # Node 18
        │   ├── bin/
        │   │   ├── node
        │   │   ├── npm
        │   │   └── npx
        │   ├── include/
        │   ├── lib/
        │   │   └── node_modules/  # 全局包
        │   └── share/
        ├── v20.10.0/         # Node 20
        └── v24.14.1/         # Node 24
```

### nvm 环境变量配置

在 `~/.zshrc` 或 `~/.bashrc` 中添加:

```bash
# nvm 配置
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

---

## npm - Node 包管理器

### 什么是 npm?

npm (Node Package Manager) 是 Node.js 的默认包管理器,用于安装、管理和发布 JavaScript 包。

### npm 配置

#### 配置文件层级

npm 会按以下顺序查找配置文件(优先级从高到低):

1. **项目级别**: `/path/to/project/.npmrc`
2. **用户级别**: `~/.npmrc`
3. **全局级别**: `$PREFIX/etc/npmrc`
4. **npm 内置**: `/path/to/npm/npmrc`

#### ~/.npmrc 配置示例

```ini
# 镜像源设置(国内用户推荐)
registry=https://registry.npmmirror.com

# 或者使用官方源
# registry=https://registry.npmjs.org

# 认证信息(私有包)
//registry.npmjs.org/:_authToken=xxxx-xxxx-xxxx-xxxx

# 代理设置
# proxy=http://proxy.company.com:8080
# https-proxy=http://proxy.company.com:8080

# 其他设置
save-exact=true              # 安装时使用精确版本号
engine-strict=true           # 严格检查 Node 版本
```

**重要**: 如果你使用 nvm,**不要**在 `~/.npmrc` 中设置 `prefix`,这会与 nvm 冲突。

#### 查看 npm 配置

```bash
# 查看所有配置
npm config list

# 查看详细配置
npm config ls -l

# 查看某个配置项
npm config get registry
npm config get prefix

# 设置配置
npm config set registry https://registry.npmmirror.com

# 删除配置
npm config delete proxy
```

### package.json 文件

#### 基本结构

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "项目描述",
  "main": "index.js",
  "scripts": {
    "dev": "node server.js",
    "build": "webpack --mode production",
    "test": "jest",
    "lint": "eslint src/"
  },
  "keywords": ["node", "express"],
  "author": "Your Name <email@example.com>",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "eslint": "^8.56.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

#### 版本号规范

```
^1.2.3  := >=1.2.3 <2.0.0     允许次版本更新(推荐)
~1.2.3  := >=1.2.3 <1.3.0     允许补丁版本更新
1.2.3   := 1.2.3              精确版本
>=1.2.3 >=1.2.3               最低版本
1.2.x   := >=1.2.0 <1.3.0     指定主次版本
*       := >=0.0.0            任意版本(不推荐)
```

### npm 常用命令

#### 项目初始化

```bash
# 交互式创建 package.json
npm init

# 快速创建(使用默认值)
npm init -y

# 使用特定初始化工具
npm init react-app my-app
npm init vite@latest
```

#### 安装依赖

```bash
# 安装 package.json 中的所有依赖
npm install
npm i

# 安装生产依赖(写入 dependencies)
npm install express
npm i express
npm i express@4.18.2        # 安装指定版本

# 安装开发依赖(写入 devDependencies)
npm install -D jest
npm i --save-dev jest

# 安装可选依赖(写入 optionalDependencies)
npm install -O package-name
npm i --save-optional package-name

# 全局安装
npm install -g typescript
npm i -g typescript

# 安装特定来源
npm install github:user/repo
npm install git+https://github.com/user/repo.git
npm install ./local-package.tgz
```

#### 更新和删除

```bash
# 检查过期包
npm outdated

# 更新依赖(遵循 package.json 版本范围)
npm update
npm update express

# 更新到最新版本(忽略版本范围)
npm install express@latest

# 更新 npm 自身
npm install -g npm@latest

# 删除依赖
npm uninstall express
npm uninstall -D jest
npm uninstall -g typescript

# 清理缓存
npm cache clean --force
```

#### 运行脚本

```bash
# 运行 package.json 中的脚本
npm run dev
npm run build
npm run test

# 运行 start 和 test 可以省略 run
npm start
npm test

# 传递参数
npm run dev -- --port 3000

# 查看所有可用脚本
npm run
```

#### 查看信息

```bash
# 查看包信息
npm view express
npm view express versions    # 查看所有版本
npm view express dependencies

# 查看已安装的包
npm list
npm list --depth=0           # 仅顶层
npm list -g --depth=0        # 全局包

# 查看包的安装路径
npm root                     # 本地包路径
npm root -g                  # 全局包路径

# 查看配置
npm config list
```

#### 发布包

```bash
# 登录 npm
npm login

# 发布包
npm publish

# 发布到特定 tag
npm publish --tag beta

# 废弃包
npm deprecate my-package@1.0.0 "此版本有安全问题"

# 取消发布(谨慎使用)
npm unpublish my-package@1.0.0
```

### package-lock.json

`package-lock.json` 用于锁定依赖版本,确保团队成员和 CI/CD 环境使用完全相同的依赖版本。

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "my-project",
      "version": "1.0.0",
      "dependencies": {
        "express": "^4.18.2"
      }
    },
    "node_modules/express": {
      "version": "4.18.2",
      "resolved": "https://registry.npmjs.org/express/-/express-4.18.2.tgz",
      "integrity": "sha512-..."
    }
  }
}
```

**重要提示**:
- **必须提交到 Git 仓库**
- 不要手动编辑
- 确保 npm 版本 >= 7 (lockfileVersion: 2+)

---

## 其他包管理器

### pnpm

#### 特点
- 使用硬链接和符号链接,节省磁盘空间
- 安装速度快
- 严格的依赖管理,避免幽灵依赖

#### 安装

```bash
npm install -g pnpm
```

#### 常用命令

```bash
# 安装依赖
pnpm install

# 添加依赖
pnpm add express
pnpm add -D jest
pnpm add -g typescript

# 运行脚本
pnpm dev
pnpm run build

# 更新
pnpm update

# 删除
pnpm remove express
```

#### pnpm-lock.yaml

pnpm 使用 `pnpm-lock.yaml` 锁定依赖版本。

### yarn

#### 特点
- 并行安装,速度快
- 离线缓存
- 确定性安装

#### 安装

```bash
npm install -g yarn
```

#### 常用命令

```bash
# 安装依赖
yarn
yarn install

# 添加依赖
yarn add express
yarn add -D jest

# 全局安装
yarn global add typescript

# 运行脚本
yarn dev
yarn build

# 更新
yarn upgrade

# 删除
yarn remove express
```

#### yarn.lock

yarn 使用 `yarn.lock` 锁定依赖版本。

### 包管理器对比

| 特性 | npm | pnpm | yarn |
|------|-----|------|------|
| 安装速度 | 中等 | 快 | 快 |
| 磁盘空间 | 多 | 少 | 中等 |
| 幽灵依赖 | 有 | 无 | 有 |
| 锁文件 | package-lock.json | pnpm-lock.yaml | yarn.lock |
| workspaces | 支持 | 支持 | 支持 |

**幽灵依赖**: 指项目中可以引用未在 `package.json` 中声明的依赖。

---

## 常见问题与冲突解决

### 问题1: nvm 与 npm prefix 冲突

**错误信息**:
```
Your user's .npmrc file (${HOME}/.npmrc)
has a `globalconfig` and/or a `prefix` setting,
which are incompatible with nvm.
```

**原因**:
nvm 需要完全控制 Node.js 的安装路径,但 `~/.npmrc` 中的 `prefix` 设置会覆盖 nvm 的路径管理。

**解决方案**:

```bash
# 方案1: 删除 prefix 配置(推荐)
sed -i '/^prefix=/d' ~/.npmrc
nvm use --delete-prefix vX.X.X

# 方案2: 清空 .npmrc(如果没有其他配置)
> ~/.npmrc

# 方案3: 手动编辑删除
nano ~/.npmrc
# 删除包含 prefix= 的行
```

**原因解析**:

nvm 的全局包路径结构:
```
~/.nvm/versions/node/v24.14.1/lib/node_modules/
~/.nvm/versions/node/v18.20.0/lib/node_modules/
```

每个 Node 版本有独立的全局包目录,如果设置 `prefix=~/.npm-global`,所有版本的全局包都会安装到同一位置,破坏了版本隔离。

### 问题2: 全局安装后命令找不到

**错误信息**:
```bash
npm install -g @tencent-ai/codebuddy-code
# 安装成功,但运行时
codebuddy
# zsh: command not found: codebuddy
```

**原因**:
1. PATH 环境变量未包含 npm 全局 bin 目录
2. zsh 未刷新命令缓存

**解决方案**:

```bash
# 方法1: 检查 npm 全局路径
npm config get prefix
# 输出: /home/bryce/.npm-global (非 nvm 用户)
# 或: ~/.nvm/versions/node/v24.14.1 (nvm 用户)

# 方法2: 添加到 PATH
# 非nvm 用户,添加到 ~/.zshrc 或 ~/.bashrc
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# nvm 用户,检查 nvm 配置是否正确加载
source ~/.zshrc

# 方法3: 刷新 zsh 命令缓存
rehash

# 方法4: 验证命令存在
which codebuddy
ls -la $(npm config get prefix)/bin/
```

### 问题3: zsh 和 bash 环境不同步

**原因**:
zsh 和 bash 使用不同的配置文件:

| Shell | 配置文件 | 用途 |
|-------|---------|------|
| bash | `~/.bashrc` | 交互式非登录 shell |
| bash | `~/.bash_profile` | 登录 shell |
| bash | `~/.profile` | 登录 shell(通用) |
| zsh | `~/.zshrc` | 交互式 shell |
| zsh | `~/.zshenv` | 所有 shell(环境变量) |
| zsh | `~/.zprofile` | 登录 shell |

**解决方案**:

```bash
# 方案1: 统一管理环境变量(推荐)
# 创建 ~/.profile,两个 shell 都加载
cat > ~/.profile << 'EOF'
# npm 全局路径
export PATH="$HOME/.npm-global/bin:$PATH"

# 其他环境变量
export EDITOR=nvim
EOF

# 在 ~/.bashrc 中引入
echo '[[ -f ~/.profile ]] && source ~/.profile' >> ~/.bashrc

# 在 ~/.zshrc 中引入
echo '[[ -f ~/.profile ]] && source ~/.profile' >> ~/.zshrc

# 方案2: 检查当前 shell 的配置
grep -n "npm" ~/.zshrc ~/.bashrc ~/.profile 2>/dev/null
```

### 问题4: npm install 速度慢

**解决方案**:

```bash
# 方法1: 使用淘宝镜像
npm config set registry https://registry.npmmirror.com

# 方法2: 临时使用
npm install --registry=https://registry.npmmirror.com

# 方法3: 使用 nrm 管理镜像源
npm install -g nrm
nrm ls
nrm use taobao
nrm test          # 测试速度
nrm use npm       # 切换回官方源

# 方法4: 使用 pnpm(更快)
npm install -g pnpm
pnpm install
```

### 问题5: 权限错误

**错误信息**:
```
npm ERR! Error: EACCES: permission denied
```

**原因**:
npm 尝试写入系统目录(如 `/usr/lib/node_modules`)

**解决方案**:

```bash
# 方案1: 使用 nvm(推荐)
# nvm 安装的 Node 在用户目录,无需 sudo

# 方案2: 修改 npm 全局路径
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 方案3: 使用 sudo(不推荐)
sudo npm install -g package-name
```

---

## Shell 环境配置

### zsh 配置

#### ~/.zshrc 完整示例

```bash
# ========== nvm 配置 ==========
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ========== npm 全局路径(非 nvm 用户) ==========
# 如果使用 nvm,注释掉下面这行
# export PATH="$HOME/.npm-global/bin:$PATH"

# ========== pnpm 全局路径 ==========
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ]; then
  export PATH="$PNPM_HOME:$PATH"
fi

# ========== yarn 全局路径 ==========
if [ -d "$HOME/.yarn/bin" ]; then
  export PATH="$HOME/.yarn/bin:$PATH"
fi

# ========== 常用别名 ==========
alias ni="npm install"
alias nid="npm install --save-dev"
alias nig="npm install -g"
alias nr="npm run"
alias ns="npm start"
alias nt="npm test"
alias nu="npm update"
alias nun="npm uninstall"

# pnpm 别名
alias pi="pnpm install"
alias pa="pnpm add"
alias pad="pnpm add -D"
alias pag="pnpm add -g"
alias pr="pnpm run"

# yarn 别名
alias yi="yarn"
alias ya="yarn add"
alias yad="yarn add -D"
alias yag="yarn global add"
alias yr="yarn"
```

#### zsh 配置文件加载顺序

```
登录 shell:
/etc/zsh/zshenv → ~/.zshenv → /etc/zsh/zprofile → ~/.zshprofile → /etc/zsh/zshrc → ~/.zshrc → /etc/zsh/zlogin → ~/.zshlogin

交互式 shell:
/etc/zsh/zshenv → ~/.zshenv → /etc/zsh/zshrc → ~/.zshrc
```

**建议**:
- 环境变量(PATH 等)放在 `~/.zshenv` 或 `~/.zshrc`
- 别名和函数放在 `~/.zshrc`
- 启动程序放在 `~/.zprofile`

### bash 配置

#### ~/.bashrc 完整示例

```bash
# ========== nvm 配置 ==========
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ========== npm 全局路径(非 nvm 用户) ==========
# 如果使用 nvm,注释掉下面这行
# export PATH="$HOME/.npm-global/bin:$PATH"

# ========== 常用别名 ==========
alias ni="npm install"
alias nid="npm install --save-dev"
alias nig="npm install -g"
alias nr="npm run"
alias ns="npm start"
alias nt="npm test"
```

#### bash 配置文件加载顺序

```
登录 shell:
/etc/profile → ~/.bash_profile → ~/.bash_login → ~/.profile

交互式非登录 shell:
/etc/bash.bashrc → ~/.bashrc
```

**建议**:
- 环境变量放在 `~/.bashrc` (并在 `~/.bash_profile` 中 source)
- 别名和函数放在 `~/.bashrc`

#### 统一配置示例

```bash
# ~/.bash_profile
if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# ~/.bashrc
# 所有配置写在这里
export PATH="$HOME/.npm-global/bin:$PATH"
```

### 通用环境变量配置

创建 `~/.profile` (两个 shell 都会读取):

```bash
# ~/.profile
# 通用环境变量配置

# PATH 配置
export PATH="$HOME/.local/bin:$PATH"

# nvm (如果使用)
export NVM_DIR="$HOME/.nvm"

# Node 版本(可选,用于提示)
export NODE_VERSION=$(node -v 2>/dev/null)

# npm 镜像源(可选)
# export NPM_CONFIG_REGISTRY=https://registry.npmmirror.com

# 编辑器
export EDITOR=nvim
export VISUAL=nvim

# 语言
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

然后在 `~/.zshrc` 和 `~/.bashrc` 中加载:

```bash
# 加载通用配置
[[ -f ~/.profile ]] && source ~/.profile
```

---

## 最佳实践

### 1. 项目结构

```
my-project/
├── .nvmrc              # 指定 Node 版本
├── .npmrc              # 项目级 npm 配置(可选)
├── package.json        # 项目配置
├── package-lock.json   # 依赖锁定(必须提交)
├── node_modules/       # 依赖目录
└── src/                # 源代码
```

### 2. 团队协作规范

#### package.json

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  },
  "scripts": {
    "dev": "node server.js",
    "build": "webpack --mode production",
    "test": "jest",
    "lint": "eslint src/"
  }
}
```

#### .nvmrc

```
18.17.0
```

#### .npmrc (可选)

```ini
registry=https://registry.npmmirror.com
save-exact=true
```

### 3. 版本管理策略

#### 使用 nvm

```bash
# 项目初始化
cd my-project
echo "18.17.0" > .nvmrc
nvm install
nvm use

# 添加到 .gitignore
echo ".nvmrc" >> .gitignore
```

#### 不使用 nvm

确保团队成员使用相同的 Node 版本:

```bash
# 检查版本
node -v
# v18.17.0

# 使用 package.json engines 强制版本
# npm 会警告版本不匹配
```

### 4. 全局包管理

#### 推荐全局安装的工具

```bash
# 包管理器
npm install -g pnpm
npm install -g yarn

# 工具
npm install -g typescript
npm install -g ts-node
npm install -g nodemon
npm install -g @tencent-ai/codebuddy-code

# 代码质量
npm install -g eslint
npm install -g prettier

# 实用工具
npm install -g nrm         # 镜像源管理
npm install -g tldr        # 简化 man
npm install -g serve       # 静态服务器
```

#### 查看全局包

```bash
npm list -g --depth=0
pnpm list -g --depth=0
yarn global list
```

### 5. 安全最佳实践

#### 审计依赖

```bash
# 检查安全漏洞
npm audit

# 自动修复
npm audit fix

# 强制修复(可能有破坏性更改)
npm audit fix --force

# 查看详细报告
npm audit --json
```

#### 使用锁文件

```bash
# 确保使用锁文件安装
npm ci                 # 使用 package-lock.json,更快更安全
pnpm install --frozen-lockfile
yarn install --frozen-lockfile
```

#### .npmrc 安全

```bash
# 不要提交敏感信息
# .gitignore
.npmrc

# 使用环境变量
# .npmrc
//registry.npmjs.org/:_authToken=${NPM_TOKEN}

# .env
NPM_TOKEN=xxxx-xxxx-xxxx-xxxx
```

### 6. 性能优化

#### 加速安装

```bash
# 使用国内镜像
npm config set registry https://registry.npmmirror.com

# 或使用 nrm
nrm use taobao

# 使用 pnpm(更快)
pnpm install

# 清理缓存
npm cache clean --force
```

#### 减少 node_modules 大小

```bash
# 使用 pnpm
pnpm install

# 分析依赖
npx depcheck

# 查看依赖树
npm list --depth=1
npx npm-why lodash
```

### 7. CI/CD 配置

#### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
      - uses: actions/checkout@v4

      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm test
```

#### Docker

```dockerfile
FROM node:18-alpine

WORKDIR /app

# 使用 npm ci 加速构建
COPY package*.json ./
RUN npm ci --only=production

COPY . .

CMD ["npm", "start"]
```

---

## 快速参考卡片

### nvm 常用命令

```bash
nvm install 18           # 安装 Node 18
nvm use 18               # 切换到 Node 18
nvm alias default 18     # 设置默认版本
nvm ls                   # 列出已安装版本
nvm current              # 当前版本
```

### npm 常用命令

```bash
npm install               # 安装所有依赖
npm install express       # 安装 express
npm install -D jest       # 安装开发依赖
npm install -g typescript # 全局安装
npm run dev              # 运行脚本
npm update               # 更新依赖
npm audit                # 安全审计
```

### 包管理器对比

```bash
# npm
npm install express
npm install -D jest
npm run dev

# pnpm
pnpm add express
pnpm add -D jest
pnpm dev

# yarn
yarn add express
yarn add -D jest
yarn dev
```

### 故障排查

```bash
# 检查 Node 和 npm 版本
node -v && npm -v

# 检查 npm 全局路径
npm config get prefix

# 检查 PATH
echo $PATH | tr ':' '\n' | grep npm

# 刷新 zsh 命令缓存
rehash

# 重新加载配置
source ~/.zshrc
```

---

## 相关资源

- [nvm GitHub](https://github.com/nvm-sh/nvm)
- [npm 文档](https://docs.npmjs.com/)
- [pnpm 文档](https://pnpm.io/)
- [Yarn 文档](https://yarnpkg.com/)
- [Node.js 官网](https://nodejs.org/)
- [淘宝 npm 镜像](https://npmmirror.com/)

---

**最后更新**: 2026-04-07
