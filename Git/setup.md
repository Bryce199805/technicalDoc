# 将本地项目关联到git仓库



```shell
# 初始化
git init
# 添加远程仓库地址
git remote add origin <remote address>
# 从远程仓库获取代码库
git fetch origin main
# 设置上游分支
git push --set-upstream origin master
# 添加本地文件夹到暂存区
git add .
# 添加注释并提交
git commit -m "添加提交注释"
# 推送到仓库
git push
```

