

# Group

### 添加用户组 --groupadd

```shell
Usage: groupadd [options] GROUP

用法：groupadd [选项] 组

选项:
  -f, --force          			如果组已经存在则成功退出
                        		并且如果 GID 已经存在则取消
  -g, --gid GID                  为新组使用 GID
  -h, --help                     显示此帮助信息并推出
  -K, --key KEY=VALUE            不使用 /etc/login.defs 中的默认值
  -o, --non-unique               允许创建有重复 GID 的组
  -p, --password PASSWORD        为新组使用此加密过的密码
  -r, --system                   创建一个系统账户
  -R, --root CHROOT_DIR          chroot 到的目录
```

```shell
# 创建样例
groupadd newgroup
```

### 修改用户组  --groupmod

```shell
Usage: groupmod [options] GROUP

Options:
  -g, --gid GID                 change the group ID to GID
  -h, --help                    display this help message and exit
  -n, --new-name NEW_GROUP      change the name to NEW_GROUP
  -o, --non-unique              allow to use a duplicate (non-unique) GID
  -p, --password PASSWORD       change the password to this (encrypted)
                                PASSWORD
  -R, --root CHROOT_DIR         directory to chroot into
  -P, --prefix PREFIX_DIR       prefix directory where are located the /etc/* files
```

```shell
# 更改组名称样例
groupmod -n newGROUP newgroup
```



### 删除用户组 --groupdel

```shell
Usage: groupdel [options] GROUP

Options:
  -h, --help                    display this help message and exit
  -R, --root CHROOT_DIR         directory to chroot into
  -P, --prefix PREFIX_DIR       prefix directory where are located the /etc/* files
  -f, --force                   delete group even if it is the primary group of a user
      --extrausers              Use the extra users database
```

```shell
# delete group sample
groupdel newgroup
```



### 管理组  --gpasswd 

```shell
Usage: gpasswd [option] GROUP

Options:
  -a, --add USER                add USER to GROUP
  -d, --delete USER             remove USER from GROUP
  -h, --help                    display this help message and exit
  -Q, --root CHROOT_DIR         directory to chroot into
  -r, --remove-password         remove the GROUP's password
  -R, --restrict                restrict access to GROUP to its members
  -M, --members USER,...        set the list of members of GROUP
      --extrausers              use the extra users database
  -A, --administrators ADMIN,...
                                set the list of administrators for GROUP
Except for the -A and -M options, the options cannot be combined.
```

```shell
## 添加 删除组内用户
gpasswd -a newuser newgroup
gpasswd -d newuser newgroup
```

# User

### 创建用户 --useradd

```shell
useradd [option] <username>

选项：
  -b, --base-dir BASE_DIR       设置基本路径作为用户的登录目录  
  -c, --comment COMMENT         对用户的注释  
  -d, --home-dir HOME_DIR       设置用户的登录目录  
  -D, --defaults                改变设置  
  -e, --expiredate EXPIRE_DATE  新账户的过期日期。设置用户的有效期  
  -f, --inactive INACTIVE       用户过期后，让密码无效  
  -g, --gid GROUP               使用户 “只属于某个组 ” （只能属于一个组）
  -G, --groups GROUPS           新账户的附加组列表。使用户加入某个组（可以属于多个组） 多个组逗号隔开  
  -h, --help                    帮助
  -k, --skel SKEL_DIR           使用此目录作为骨架目录
  -K, --key KEY=VALUE           不使用 /etc/login.defs 中的默认值
  -l, --no-log-init             不把用户加入到lastlog文件中  
  -m, --create-home             自动创建登录目录  
  -M, --no-create-home          不自动创建登录目录  
  -N, --no-user-group           不创建同名的组
  -o, --non-unique              允许使用重复的 UID 创建用户
  -p, --password PASSWORD       为新用户使用加密密码  
  -r, --system                  创建一个系统账户
  -R, --root CHROOT_DIR         chroot 到的目录
  -s, --shell SHELL             登录时候的shell  
  -u, --uid UID                 为新用户指定一个UID  
  -U, --user-group              创建与用户同名的组
  -Z, --selinux-user SEUSER     为 SELinux 用户映射使用指定 SEUSER
```

```shell
# 创建用户样例
useradd -d /home/newuser -g newgroup -G docker,sudo -m -s /bin/bash newuser
# 创建后修改用户密码
passwd newuser
# 要想使用户能够使用sudo命令，需要将用户添加到sudo组中
```



### 修改用户属性  --usermod

```shell
usermod -h     
Usage: usermod [options] LOGIN
 
Options:
  -b, --badnames                allow bad names
  -c, --comment COMMENT         new value of the GECOS field
  -d, --home HOME_DIR           new home directory for the user account
  -e, --expiredate EXPIRE_DATE  set account expiration date to EXPIRE_DATE
  -f, --inactive INACTIVE       set password inactive after expiration
                                to INACTIVE
  -g, --gid GROUP               force use GROUP as new primary group
  -G, --groups GROUPS           new list of supplementary GROUPS
  -a, --append                  append the user to the supplemental GROUPS
                                mentioned by the -G option without removing
                                the user from other groups
  -r, --remove                  remove the user from only the supplemental GROUPS
                                mentioned by the -G option without removing
                                the user from other groups
  -h, --help                    display this help message and exit
  -l, --login NEW_LOGIN         new value of the login name
  -L, --lock                    lock the user account
  -m, --move-home               move contents of the home directory to the
                                new location (use only with -d)
  -o, --non-unique              allow using duplicate (non-unique) UID
  -p, --password PASSWORD       use encrypted password for the new password
  -R, --root CHROOT_DIR         directory to chroot into
  -P, --prefix PREFIX_DIR       prefix directory where are located the /etc/* files
  -s, --shell SHELL             new login shell for the user account
  -u, --uid UID                 new UID for the user account
  -U, --unlock                  unlock the user account
  -v, --add-subuids FIRST-LAST  add range of subordinate uids
  -V, --del-subuids FIRST-LAST  remove range of subordinate uids
  -w, --add-subgids FIRST-LAST  add range of subordinate gids
  -W, --del-subgids FIRST-LAST  remove range of subordinate gids
  -Z, --selinux-user SEUSER     new SELinux user mapping for the user account
```

```shell
# 修改用户所属组列表
usermod -G newgroup,sudo,docker newuser
# 在当前所属组中追加docker组
usermod -a -G docker newuser
```



### 删除用户  --userdel

```shell
Usage: userdel [options] LOGIN

Options:
  -f, --force                   force removal of files,
                                even if not owned by user
  -h, --help                    display this help message and exit
  -r, --remove                  remove home directory and mail spool
  -R, --root CHROOT_DIR         directory to chroot into
  -P, --prefix PREFIX_DIR       prefix directory where are located the /etc/* files
      --extrausers              Use the extra users database
  -Z, --selinux-user            remove any SELinux user mapping for the user
```

```shell
# 删除用户并删除用户目录
userdel -r newuser
```



### 查看用户所属组 --groups

```shell
groups <user>
groups newusers
```



[refs](https://blog.csdn.net/freeking101/article/details/78201539)