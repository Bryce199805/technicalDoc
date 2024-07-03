# Dockerfile

## Commend

| 关键字        | 作用                     | 备注                                                         |
| :------------ | :----------------------- | :----------------------------------------------------------- |
| `FROM`        | 指定父镜像               | 指定 `dockerfile` 基于哪个 `image` 构建                      |
| `MAINTAINER`  | 作者信息 (已弃用)        | 用来标明这个 `dockerfile` 谁写的                             |
| `LABEL`       | 标签                     | 用来标明 `dockerfile` 的标签，可以使用 `Label` 代替 `Maintainer`，最终都是在 `docker image` 基本信息中可以查看 |
| `RUN`         | 执行命令                 | 执行一段命令，默认是 `/bin/sh`，格式：`RUN command` 或者 `RUN ["command","param1","param2"]` |
| `CMD`         | 容器启动命令             | 提供启动容器时的默认命令，和 `ENTRYPOINT` 配合使用。格式：`CMD command param1 param2` 或者 `CMD['command','param1','param2']` |
| `ENTRYPOINT`  | 入口                     | 一般在制作一些执行就关闭的容器中会使用                       |
| `COPY`        | 复制文件                 | `build` 的时候复制文件到 `image` 中                          |
| `ADD`         | 添加文件                 | `build` 的时候添加文件到 `image` 中，不仅局限于当前 `build` 上下文，可以来源于远程服务 |
| `ENV`         | 环境变量                 | 指定 `build` 时的环境变量，可以在启动的容器时通过 `-e` 覆盖，格式：`ENV name=value` |
| `ARG`         | 构建参数                 | 只在构建的时候使用的参数，如果有 `ENV`，那么 `ENV` 的相同名字的值始终覆盖 `ARG` 的参数 |
| `VOLUME`      | 定义外部可以挂载的数据卷 | 指定 `build` 的 `image` 那些目录，可以启动的时候挂载到文件系统中，启动容器的时候使用 `-v` 绑定。格式：`VOLUME["目录"]` |
| `EXPOSE`      | 暴露端口                 | 定义容器运行的时候监听的端口，启动容器的时候使用 `-p` 来绑定。格式：`EXPOSE 8080` 或者 `EXPOSE 8080/udp` |
| `WORKDIR`     | 工作目录                 | 指定容器内部的工作目录，如果没有创建则自动创建，如果指定 `/`，使用的是绝对地址，如果不是 `/` 开头，那么是在上一条 `WORKDIR` 的路径的相对路径 |
| `USER`        | 指定执行用户             | 指定 `build` 或者启动的时候的用户，在 `RUN CMD ENTRYPOINT` 执行的时候的用户 |
| `HEALTHCHECK` | 健康检查                 | 指定监测当前容器的健康监测的命令，基本上没用，因为很多时候，应用本身有健康监测机制 |
| `ONBUILD`     | 触发器                   | 当存在 `ONBUILD` 关键字的镜像作为基础镜像的时候，当执行 `FROM` 完成之后，会执行 `ONBUILD` 的命令，但是不影响当前镜像，用处也不怎么大 |
| `STOPSIGNAL`  | 发送信号量到宿主机       | 该 `STOPSIGNAL` 指令设置将发送到容器的系统调用信号以退出     |
| `SHELL`       | 指定执行脚本的shell      | 指定 `RUN CMD ENTRYPOINT` 执行命令的时候使用的 `shell`       |



## Sample

> mycat2 定制镜像文件目录：
>
> - Dockerfile
> - mycat2-1.21-release-jar-with-dependencies.jar  mycat2依赖包
> - mycat2-install-template-1.21.zip  mycat2框架
> - prototypeDs.datasource.json  数据源文件，根据自身服务情况填写

```dockerfile
FROM java:openjdk-8u111

LABEL author="bryce" version="1.0"

# 设置工作目录
WORKDIR /root/mycat2

# 拷贝mycat2基础框架  jar依赖包  数据源配置文件（根据部署的数据库情况自行修改）
COPY ./mycat2-install-template-1.21.zip .
COPY ./mycat2-1.21-release-jar-with-dependencies.jar .
COPY ./prototypeDs.datasource.json .

# 执行安装构建命令

RUN unzip mycat2-install-template-1.21.zip \
        && mv mycat2-1.21-release-jar-with-dependencies.jar mycat/lib \
        && chmod +x mycat/bin/mycat \
        && chmod +x mycat/bin/wrapper-linux* \
        && mv prototypeDs.datasource.json mycat/conf/datasources/prototypeDs.datasource.json \
        && echo "/root/mycat2/mycat/bin/mycat start" >> ~/.bashrc \
        && echo "/root/mycat2/mycat/bin/mycat status" >> ~/.bashrc \
        && rm -rf mycat2-install-template-1.21.zip

EXPOSE 8066 1984

CMD ["/bin/bash"]
```

在mycat2目录下，利用dockerfile构建镜像

```shell
sudo docker build -t mycat2:v1 .
```

利用定制的镜像创建容器

``` shell
docker run -itd -p 8066:8066 -p 1984:1984 mycat2:v1
```



开机自启动是很麻烦的一个操作，共以下三种方案

- `docker run ... --privileged=true ...` 就可以使用 `systemd` 了，**亲测没用**
- `init` 脚本开机自启（未尝试）
- 写一个启动脚本，将脚本运行写入 `.bashrc` 中
  - 需要运行的服务在 `/etc/init.d/` 目录下，使用 `service` 命令启动，或者 `/etc/init.d/xxx start` 启动，这些文件有 `{start|stop|reload|force-reload|restart|try-restart|status}` 方法
