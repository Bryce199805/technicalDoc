# Linux 与 Windows 文件共享 (Samba) 配置笔记

## 1. 安装 Samba
首先，在 Linux (Ubuntu/Debian) 系统上安装 Samba 服务：
```bash
sudo apt update
sudo apt install samba
```

## 2. 创建共享目录
创建一个用于共享的目录，并设置适当的权限：
```bash
mkdir -p /home/username/share
chmod 775 /home/username/share
```
*(注：请将 `username` 替换为你实际的 Linux 用户名)*

## 3. 配置 Samba
编辑 Samba 的主配置文件 `/etc/samba/smb.conf`：
```bash
sudo vim /etc/samba/smb.conf
```

### 3.1 修改全局配置 (可选)
如果需要，可以修改工作组名称以匹配你的 Windows 网络：
```ini
[global]
   workgroup = your_workgroup
```

### 3.2 添加共享目录配置
在配置文件的末尾添加以下内容，定义共享目录及其权限：
```ini
[share]
path = /home/username/share
browseable = yes
writable = yes
guest ok = no
valid users = username
create mask = 0664
directory mask  = 0775
```
**配置说明：**
- `[share]`：在 Windows 中显示的共享名称。
- `path`：Linux 上实际的共享目录绝对路径。
- `browseable = yes`：允许该共享在网络上可见（可浏览）。
- `writable = yes`：允许写入权限，可以新建和修改文件。
- `guest ok = no`：禁止匿名（访客）访问，需要密码验证以保证安全。
- `valid users = username`：指定只有该用户可以访问此共享。
- `create mask = 0664`：客户端新建文件的默认权限。
- `directory mask = 0775`：客户端新建目录的默认权限。

## 4. 添加 Samba 用户并设置密码
Samba 使用独立的密码数据库，必须将现有的 Linux 用户添加为 Samba 用户，并为其设置专门的 SMB 访问密码：
```bash
sudo smbpasswd -a username
```
执行后根据提示输入并确认密码。

## 5. 测试配置与重启服务
配置完成后，可以使用 `testparm` 命令检查配置文件是否有语法错误：
```bash
testparm
```
如果输出 `Loaded services file OK.`，说明配置无误。

然后，使配置生效。你可以选择重启服务：
```bash
sudo systemctl restart smbd nmbd
```
或者，如果不想中断现有的连接，可以平滑重载配置文件：
```bash
sudo smbcontrol all reload-config
```

## 6. 在 Windows 中访问
1. 打开 Windows 文件资源管理器 (快捷键 `Win + E`)。
2. 在地址栏输入 Linux 主机的 IP 地址，格式如下：
   ```text
   \\<Linux_IP_Address>
   ```
   例如：`\\192.168.1.100` 或直接定位到共享目录 `\\192.168.1.100\share`
3. 弹出“Windows 安全中心”网络凭据对话框时，输入刚才设置的用户名 (`username`) 和 Samba 密码即可访问共享文件夹。