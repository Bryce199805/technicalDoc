## git config

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
# --soft  不删除工作空间改动代码，撤销commit，不撤销git add . 
# --hard  删除工作空间改动代码，撤销commit，撤销git add . 
git reset --hard HEAD^ 回退到上个版本。
git reset --hard HEAD~n 回退到前n次提交之前，若n=3，则可以回退到3次提交之前。
git reset --hard commit_sha 回滚到指定commit的sha码，推荐使用这种方式。

# 执行上述某条命令后，本地文件就会被修改，回滚到指定commit SHA。
# 如果再执行如下命令，则会强推到远程仓库，进而修改远程仓库的文件：
git push origin HEAD --force
```

## git remote

```shell
git remote 		# 列出当前仓库中已配置的远程仓库。
git remote -v	# 列出当前仓库中已配置的远程仓库，并显示它们的 URL。
git remote add <remote_name> <remote_url>	# 添加一个新的远程仓库。指定一个远程仓库的名称和 URL，将其添加到当前仓库中。
git remote rename <old_name> <new_name>	# 将已配置的远程仓库重命名。
git remote remove <remote_name>	# 从当前仓库中删除指定的远程仓库。
git remote set-url <remote_name> <new_url>	# 修改指定远程仓库的 URL。
git remote show <remote_name> 	# 显示指定远程仓库的详细信息，包括 URL 和跟踪分支。
```

## git submodule 

```shell 
git submodule add <submodule git repo> <name>  # 通过该命令可将文件夹关联到其他仓库

# 删除子模块
# 1.删除子模块文件夹
git rm --cached <name>
rm -rf <name>
# 2.删除 .gitmodules 文件中相关子模块的信息，类似于：
[submodule "cxx_interface"]
        path = cxx_interface
        url = https://github.com/Bryce199805/cxx_interface.git
# 3.删除 .git/config 中相关子模块信息，类似于：
[submodule "cxx_interface"]
        url = https://github.com/Bryce199805/cxx_interface.git
        active = true
# 4.删除 .git 文件夹中的相关子模块文件
rm -rf .git/modules/cxx_interface
```

