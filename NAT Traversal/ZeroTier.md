# ZeroTier异地组网

## Plan1. 配置Moon中转节点

### 1. 安装zerotier并加入网络

```shell
curl -s https://install.zerotier.com | sudo bash
zerotier-cli join <network ID>
```

### 2. 生成Moon配置文件

```shell
cd /var/lib/zerotier-one
sudo zerotier-idtool initmoon identity.public > moon.json
```

### 3. 修改Moon配置文件 添加VPS公网IP与端口号

```shell
vim moon.json

"stableEndpoints": [ "IP/Port" ]
```

### 4. 生成Moon配置文件

```shell
sudo zerotier-idtool genmoon moon.json 
# 生成一个类似000000xxxxxxxxxx.moon的文件
```

### 5. 应用配置文件

```shell
mkdir moons.d
mv 000000xxxxxxxxxx.moon moons.d/
```

### 6. 重启zerotier服务

```shell
systemctl restart zerotier-one
```

### 7. 检查配置

```shell
zerotier-cli listpeers
# 若成功，应当出现带有MOON标记的节点
```

## 客户端配置

```shell
zerotier-cli join <network_id>
zerotier-cli orbit <moon_id> <moon_id>
systemctl restart zerotier-one
```

---

## Plan2. 自建Planet根服务器

2024.06.30更新

找到一个更好的  [ref](https://github.com/xubiaolin/docker-zerotier-planet)

---

以下为旧内容 ---2024.06.30

---

[ref](https://github.com/Jonnyan404/zerotier-planet)

### Requirements

- 公网IP服务器
- docker  docker-compose
- TCP 4000/9333/3180  UDP 9993

### Options

```shell
git clone https://github.com/Jonnyan404/zerotier-planet
# git clone https://gitee.com/Jonnyan404/zerotier-planet

cd zerotier-planet
# 请修改docker-compose.yml内的IP地址为你自己的
docker-compose up -d

# 以下步骤为创建planet和moon
docker cp mkmoonworld-x86_64 ztncui:/tmp
docker cp patch.sh ztncui:/tmp
docker exec -it ztncui bash /tmp/patch.sh
docker restart ztncui
```

3180端口是用来从Web端下载planet文件，下载完成后关闭3180

```http
http://[ip address]:4000  # 控制台地址
```

默认用户名：admin

密码：mrdoc.fun

登录后创建一个网络，选择EasySetup分IP，复制网络ID



---

客户端配置仍然有效 ---2024.06.30

---

### 客户端配置

#### Windows

下载并安装ZeroTier客户端，将下载的planet文件拷贝到“C:/ProgramData/ZeroTier/One”下，然后再服务中重启ZeroTier One服务

```shell
# 加入网络 输出200 Join OK
zerotier-cli.bat join [Network ID]
# 查看根服务器
zerotier-cli.bat peers
```

加入后到网页控制台进行授权

#### Linux 

安装客户端，替换/var/lib/zerotier-one 下的planet文件

重启服务

``` shell
systemctl restart zerotier-one
```

加入网络

```shell
# 加入网络 输出200 Join OK
zerotier-cli join [Network ID]
# 查看根服务器
zerotier-cli peers
```

加入后到网页控制台进行授权
