# Docker

## Install & Uninstall
### Fedora
[docker.docs](https://docs.docker.com/engine/install/fedora/)

```shell
# add repo 
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# install the latest version
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# start docker
sudo systemctl start docker

# uninstall 
sudo dnf remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## Option

```shell
# docker 免sudo
sudo gpasswd -a $USER docker
newgrp docker
```

## Proxy

[refs](https://neucrack.com/p/286)

### docker pull

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

