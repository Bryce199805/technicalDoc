# Docker Proxy

[refs](https://neucrack.com/p/286)

## docker pull

```shell
sudo vim /etc/systemd/system/docker.service.d/http-proxy.conf
```

```shell
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:8123"
Environment="HTTPS_PROXY=http://127.0.0.1:8123"
```

```shell
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo systemctl show --property=Environment docker
```

docker换源

```shell
# /etc/docker/daemon.json 
{
        "exec-opts":["native.cgroupdrivers=systemd"],
        "registry-mirrors":["https://kn0t2bca.mirror.aliyuncs.com"]
}
```

```shell
systemctl restart docker
```



