# Dockers Commend

## Images

```shell
# 列出本地镜像
docker images
# 在docker hub上搜索镜像
docker search <image_name>
# 拉取镜像到本地
docker pull <image_name>
# 删除本地镜像
docker rmi <image_name or image_id>
# 通过Dockerfile构建镜像
docker build -t <image_name> <path_to_dockerfile>
```

#### 通过配合awk命令批量删除镜像或容器

```shell
docker rmi `docker images | awk '/<arg1>'/{print $<arg2>}`
```
参数1是需要匹配的字符串模式；参数2为关键索引的列，在这里应为表示Image ID的列

## Container

```shell
# 创建容器
docker run [options] <image_name>
```

- `-d`:表示在后台运行容器。在这种模式下，容器将在后台启动并运行，而不会将输出显示到终端。这对于需要长时间运行的容器或不需要与容器进行交互的情况非常有用。
- `-i`: 表示以交互模式运行容器。在这种模式下，容器的标准输入（STDIN）将连接到终端，可以直接与容器内运行的程序进行交互。这对于调试容器或需要从容器内输入数据的情况非常有用。
- `-t`: 表示分配一个伪终端给容器。这意味着容器将拥有自己的终端，可以使用 `docker attach` 命令附加到该终端并与之交互。
- `-it` 创建的容器一般称为**交互式容器**。
- `-id` 创建的容器一般称为**守护式容器**。
- `--name kodbox` 或者 `--name=kodbox`: 用于指定容器的名称为 "kodbox"。
- `-p 10080:80`: 这个选项指定将容器的 80 端口映射到主机的 10080 端口。这样，通过访问 `http://localhost:10080`，你就可以访问到容器内部的 Web 服务。
- `-v /data/docker/kodbox:/var/www/html`: 这个选项用于将主机上的 `/data/docker/kodbox` 目录挂载到容器内的 `/var/www/html` 目录。
- `--restart` 参数用于指定容器的重启策略。这对于需要在容器退出后自动重启容器的情况非常有用。**以下是一些有效的 `--restart` 值：**
  - `no`：容器在退出后不会重启。这是默认值。
  - `on-failure`：容器在非正常退出时（退出状态非 0）才会重启。
  - `always`：容器在退出时总是重启。
  - `unless-stopped`：容器在退出时总是重启，但不会考虑在 Docker 守护进程启动时就已经停止的容器。

```shell
# 列出正在运行的容器
docker ps 
# 列出所有的容器，包括停止的
docker ps -a
# 仅列出所有容器的ID
docker ps -aq
# 在运行的容器中执行命令。它允许以交互模式或非交互模式运行命令，并可以设置环境变量和工作目录
docker exec
# 停止运行中的容器
docker stop <container_id or container_name>
# 启动已经停止的容器
docker start <container_id or container_name>
# 重启容器
docker restart <container_id or container_name>
# 删除已经停止的容器
docker rm <container_id or container_name>
# 删除所有容器
docker rm `docker ps -aq`
# 查看容器详细信息
docker inspect <container_id or container_name>
# 查看容器日志
docker logs <container_id or container_name>
# 查看容器资源占用情况
docker stats
# 查看指定容器资源占用
docker stats <container_id or container_name>
```

## Network

```shell
# 列出docker网络
docker network ls
# 显示容器端口映射
docker port <container_id or container_name>
```

## Export

```shell
# 容器保存为镜像 数据卷不会被保存
docker commit <container_id> <image_name:tag>
# 将镜像保存为压缩文件
docker save -o <image_name>.tar <image_name:tag>
# 从压缩文件导入镜像
docker load -i <image_name>.tar
# 将容器保存为压缩文件
docker export <container_id> -o <container_name>.tar
# 从压缩文件导入容器
docker import <container_name>.tar <image_name:tag>
```

