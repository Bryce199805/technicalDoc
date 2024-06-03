# Tex Live in WSL

## Installation

[iso download](https://tug.org/texlive/acquire-iso.html)

```shell
# 挂载镜像
sudo mkdir /mnt/texlive
sudo mount [path to texlive.iso] /mnt/textlive
```

```shell
# 执行安装脚本并进行定制化
cd /mnt/textlive
sudo ./install-tl
```

[参考链接](https://www.cnblogs.com/eslzzyl/p/17358405.html)

```shell
# 解挂载 删除
sudo umount /mnt/texlive	
sudo rm -r /mnt/texlive
```

```shell
# 添加环境变量 .bashrc
# Tex Live
export MANPATH=/home/bryce/app/texLive/texmf-dist/doc/man:$MANPATH
export INFOPATH=/home/bryce/app/texLive/texmf-dist/doc/info:$INFOPATH
export PATH=/home/bryce/app/texLive/bin/x86_64-linux:$PATH
```

```shell
# test
tex -v
```

```shell
# 建立字体软链接
ln -s /home/bryce/app/texLive/texmf-var/fonts/conf/texlive-fontconfig.conf  /etc/fonts/conf.d/09-texlive.conf
sudo fc-cache -fsv
```



## Uninstallation

```shell
rm -rf ~/app/texLive
```

