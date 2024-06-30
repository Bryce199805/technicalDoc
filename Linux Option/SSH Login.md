# SSH Log in 

## 以密钥的方式登录

```shell
# 生成密钥
ssh-keygen

# 生成两个文件 .pub为公钥
```

登录服务器，添加公钥

```shell
cd .ssh
cat id_rsa.pub >> authorized_keys
```

文件权限

```shell
chmod 600 authorized_keys
chmod 700 ~/.ssh
```

编辑sshd配置文件，允许密钥登陆

```shell
vim /etc/ssh/sshd_config
```

```shell
# 修改配置文件
PubkeyAuthentication yes
PasswordAuthentication no
```

重启sshd服务

```shell
systemctl restart sshd
```



