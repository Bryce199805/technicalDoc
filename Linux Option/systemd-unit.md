# Systemd Unit

[创建和修改 systemd 单元文件](https://docs.redhat.com/zh-cn/documentation/red_hat_enterprise_linux/7/html/system_administrators_guide/sect-managing_services_with_systemd-unit_files)

```shell
vim /etc/systemd/system/ssh-tunnel.service
```

- unit: 包含不依赖于这个单元类型的通用选项。这些选项提供单元描述，指定单元的行为，并将依赖项设置为其他单元。
- unit-type: 如果单元具有特定于类型的指令，则这些指令分组在以单元类型命名的部分中。例如，服务单元文件包含 [Service] 部分
- install: 包含 `systemctl enable` 和 `disable` 命令使用的单元安装信息

一个启动service启动例子：

```shell
[Unit]
Description=SSH Tunnel # 描述
After=network.target # 网络启动后执行

[Service]
User=bryce # 执行service的用户
ExecStart=/usr/bin/ssh -C -N -L 0.0.0.0:xxxx:xxx.xxx.xxx.xxx:xxxx user@localhost # 需要执行的命令
Restart=always # 重启策略
RestartSec=10 # 10s后重启

[Install]
WantedBy=multi-user.target # 开机进入多用户模式时自动启动本服务
```

