# git config

```shell
# 查看全局配置信息
git config --global --list
# 查看当前仓库配置信息
git config --local --list

# 设置git代理
git config --global http.proxy http://127.0.0.1:10809
git config --global https.proxy https://127.0.0.1:10809
```



## git reset

```shell
git reset --hard HEAD^ 回退到上个版本。
git reset --hard HEAD~n 回退到前n次提交之前，若n=3，则可以回退到3次提交之前。
git reset --hard commit_sha 回滚到指定commit的sha码，推荐使用这种方式。

# 执行上述某条命令后，本地文件就会被修改，回滚到指定commit SHA。
# 如果再执行如下命令，则会强推到远程仓库，进而修改远程仓库的文件：
git push origin HEAD --force
```

