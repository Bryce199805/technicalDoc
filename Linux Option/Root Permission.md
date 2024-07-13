# su & sudo



## 权限继承问题

```shell
sudo <commend>  
# 输出 comment not found
# sudo会刷新用户环境变量替换为root变量

sudo -E <commend>
# 理论上可以继承用户环境变量  但是经测试无效 原因未知

sudo env PATH="$PATH" <commend>
# 强制继承用户的环境变量
```

```shell
su # 进入root用户 用root的环境变量替换用户环境变量

su -m or su -p  # 进入root用户并保留用户的环境变量
```

