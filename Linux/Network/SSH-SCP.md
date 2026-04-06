# SSH & SCP



## 指定密钥登录

```shell
ssh -i <path_to_key> username@hostname

## 同理应用于scp
scp -i <path_to_key> <source_file_path> username@hostname:<target_file_path>
```

### 指定端口登录

```shell
ssh -p <port> username@hostname

## 应用于scp
scp -P <port> <source_file_path> username@hostname:<target_file_path>
```

