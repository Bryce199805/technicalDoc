# Linux GPU 驱动与 DKMS 快查

> 面向 Ubuntu/Debian 和常见 Linux 服务器，重点覆盖 NVIDIA 驱动、DKMS、CUDA 兼容、Secure Boot、容器与故障排查，并补充 AMDGPU/ROCm。
>
> 最后核对：2026-08-09。驱动分支、支持的发行版和 GPU 型号会变化，安装前应再次查阅文末官方兼容矩阵。

快速导航：[现场检查](#2-五分钟现场检查) · [DKMS](#3-dkms) · [NVIDIA 安装](#4-nvidia-驱动安装) · [Secure Boot](#5-secure-boot-与模块签名) · [CUDA 兼容](#8-cuda-与驱动版本兼容) · [容器](#9-nvidia-容器) · [AMDGPU/ROCm](#10-amdgpu-与-rocm) · [故障对照](#11-常见故障对照) · [运维命令](#13-运维快查)

## 1. 先分清各层

GPU 软件栈不是一个包。排障时从下往上检查：

| 层级 | NVIDIA 示例 | AMD 示例 | 作用 |
|---|---|---|---|
| 硬件/PCIe | NVIDIA GPU | AMD GPU | 设备是否被主机枚举 |
| 内核模块 | `nvidia`、`nvidia_uvm`、`nvidia_drm` | `amdgpu` | 驱动硬件，创建设备节点 |
| 设备节点 | `/dev/nvidia*`、`/dev/dri/*` | `/dev/kfd`、`/dev/dri/*` | 用户态访问 GPU 的入口 |
| 用户态驱动库 | `libcuda.so`、NVML、OpenGL/Vulkan | ROCr、HIP、OpenGL/Vulkan | 应用与内核驱动通信 |
| 开发工具包 | CUDA Toolkit：`nvcc`、头文件、运行库 | ROCm/HIP SDK | 编译和运行计算程序 |
| 框架 | PyTorch、TensorFlow | PyTorch、TensorFlow | 使用 CUDA 或 HIP |
| 容器适配 | NVIDIA Container Toolkit | CDI/ROCm 设备映射 | 将宿主机设备和驱动库暴露给容器 |

关键结论：

- **GPU 驱动不等于 CUDA Toolkit**。机器可只有驱动而没有 `nvcc`。
- `nvidia-smi` 显示的 `CUDA Version` 是当前驱动最高支持的 CUDA API 版本，**不是已安装 Toolkit 的版本**。
- 容器通常复用宿主机的内核驱动；镜像携带 CUDA/ROCm 用户态库。不要在普通容器内安装内核驱动。
- DKMS 只管理需要针对内核构建的模块，不管理 CUDA 编译器或 PyTorch。

## 2. 五分钟现场检查

遇到问题先保存以下输出，不要立即重装：

```bash
# 系统、内核、启动参数
cat /etc/os-release
uname -a
cat /proc/cmdline

# 硬件是否被 PCIe 枚举，以及当前绑定的内核驱动
lspci -nnk | grep -A3 -Ei 'VGA|3D|Display'

# Secure Boot
command -v mokutil >/dev/null && mokutil --sb-state

# 已加载模块和 DKMS
lsmod | grep -E '^(nvidia|nouveau|amdgpu)'
command -v dkms >/dev/null && dkms status

# 内核日志
sudo journalctl -k -b | grep -Ei 'nvrm|nvidia|nouveau|amdgpu|drm|firmware|iommu|xid'

# NVIDIA
command -v nvidia-smi >/dev/null && nvidia-smi
test -r /proc/driver/nvidia/version && cat /proc/driver/nvidia/version

# AMD
test -e /dev/kfd && ls -l /dev/kfd
command -v rocminfo >/dev/null && rocminfo | sed -n '1,80p'
```

快速判断：

| 现象 | 优先检查 |
|---|---|
| `lspci` 看不到 GPU | BIOS、PCIe 插槽/供电、虚拟机直通、云实例是否挂载 GPU |
| `lspci` 有设备但没有 `Kernel driver in use` | 模块构建、签名、黑名单、内核兼容性 |
| 模块存在但加载失败 | `modprobe` 报错和 `journalctl -k -b` |
| `nvidia-smi` 找不到命令 | 用户态工具未安装或 `PATH` 问题 |
| `nvidia-smi` 无法连接驱动 | `nvidia` 模块未加载、版本不一致或设备未绑定 |
| 驱动正常但 PyTorch 不可用 | 框架构建版本、运行库、设备权限、容器配置 |

## 3. DKMS

DKMS（Dynamic Kernel Module Support）用于维护树外内核模块。发行版安装新内核后，DKMS 会尝试为新内核重新编译并安装模块。

```text
/usr/src/<module>-<version> 中的驱动源码
        ↓  DKMS add / build / install
/var/lib/dkms/<module>/<version>/<kernel>/ 中的构建状态
        ↓
/lib/modules/<kernel>/updates/dkms/ 中的模块
        ↓  depmod + initramfs
重启后由新内核加载
```

### 3.1 DKMS 与预编译模块

- **DKMS 模块**：本机针对目标内核构建，适合没有对应预编译包的情况。
- **预编译/签名模块**：发行版针对特定内核 ABI 提前构建，安装快且 Secure Boot 体验通常更平滑。

`dkms status` 没有 NVIDIA 条目不一定是故障，系统可能使用预编译模块：

```bash
modinfo -F filename nvidia 2>/dev/null
modinfo -F version nvidia 2>/dev/null
modinfo -F signer nvidia 2>/dev/null
```

### 3.2 常用命令

```bash
dkms status
dkms status -m nvidia
dkms status -m amdgpu

uname -r
ls /lib/modules
readlink -f /lib/modules/"$(uname -r)"/build
test -e /lib/modules/"$(uname -r)"/build && echo 'headers OK'

# 为已知模块补建缺失的内核版本
sudo dkms autoinstall

# 精确构建；MODULE/VERSION 来自 dkms status
sudo dkms build -m MODULE -v VERSION -k "$(uname -r)"
sudo dkms install -m MODULE -v VERSION -k "$(uname -r)"
sudo depmod -a
```

不要在包管理器仍管理模块时随意执行 `dkms remove --all`。优先修复依赖，让包管理器触发重建。

### 3.3 构建日志与高频原因

```bash
sudo find /var/lib/dkms -name make.log -type f -print
sudo less /var/lib/dkms/nvidia/*/build/make.log
sudo less /var/log/apt/term.log
sudo journalctl -k -b -p warning
```

高频原因：

1. 目标内核没有精确匹配的 headers/devel。
2. 新内核改变 API，而旧驱动不支持。
3. GCC/Clang、make 等构建工具缺失或不兼容。
4. `/boot`、`/var` 或根分区空间不足。
5. Secure Boot 拒绝未签名或未信任签名的模块。
6. 同时残留发行版包、厂商仓库包和 `.run` 安装结果。

Ubuntu/Debian 常用修复：

```bash
sudo apt update
sudo apt install build-essential dkms "linux-headers-$(uname -r)"
sudo dpkg --configure -a
sudo apt --fix-broken install
sudo dkms autoinstall
```

RHEL/Rocky/AlmaLinux 常用依赖：

```bash
sudo dnf install gcc make dkms \
  "kernel-headers-$(uname -r)" "kernel-devel-$(uname -r)"
```

仓库没有与 `uname -r` 匹配的开发包，通常表示当前内核已不在启用仓库中。更新并重启到受支持内核，或从引导菜单临时回退到已有可用模块的旧内核。

## 4. NVIDIA 驱动安装

### 4.1 安装策略

推荐顺序：

1. 云厂商镜像/驱动管理工具（云 GPU）。
2. Ubuntu 的 `ubuntu-drivers` 或发行版官方仓库。
3. NVIDIA 官方 APT/DNF 仓库。
4. `.run` 安装器仅用于临时、离线或发行版不受支持的环境。

不要混用第 2、3、4 种来源。`.run` 安装绕过包管理器，容易在升级内核、桌面栈或驱动后留下版本不一致的文件。

安装前：

```bash
lspci -nnk | grep -A3 -Ei 'VGA|3D|Display'
uname -r
command -v mokutil >/dev/null && mokutil --sb-state
df -h / /boot
```

### 4.2 开放与专有内核模块

NVIDIA 驱动的用户态组件相同，但内核模块有两种互斥实现：

| GPU 架构 | 选择 |
|---|---|
| Turing 及更新架构 | 使用开放内核模块；从 560 分支起为默认推荐 |
| Maxwell、Pascal、Volta | 必须使用专有内核模块 |
| Blackwell 及更新架构 | 必须使用开放内核模块 |

开放内核模块不表示整个用户态驱动都已开源。两种内核模块不能同时安装或加载。

```bash
modinfo nvidia | grep -E '^(license|version|filename):'
cat /proc/driver/nvidia/version
```

- `license: Dual MIT/GPL`：开放内核模块。
- `license: NVIDIA`：专有内核模块。

不确定 GPU 架构时，让发行版硬件检测工具推荐，或查询 NVIDIA 支持列表。

### 4.3 Ubuntu 推荐安装法

`ubuntu-drivers` 会按硬件选择驱动，并优先处理 Secure Boot 可用的签名方案。

```bash
sudo apt update
sudo apt install ubuntu-drivers-common

# 桌面/通用场景
sudo ubuntu-drivers list
sudo ubuntu-drivers install

# 计算服务器
sudo ubuntu-drivers list --gpgpu
sudo ubuntu-drivers install --gpgpu

sudo reboot
```

固定分支时，从 `list` 输出选择真实存在的值：

```bash
# 占位符不要原样复制
sudo ubuntu-drivers install nvidia:DRIVER_BRANCH
sudo ubuntu-drivers install --gpgpu nvidia:DRIVER_BRANCH-server
```

`-server` 分支适合长生命周期和计算负载；桌面分支更适合图形、游戏和笔记本。不要只因分支数字更大就切换。

### 4.4 NVIDIA 官方 APT 仓库

发行版仓库没有目标分支时可用 NVIDIA 官方仓库。仓库代号必须来自官方安装页，不能把任意 `/etc/os-release` 值直接拼进 URL。

```bash
sudo apt install "linux-headers-$(uname -r)"

# 按 NVIDIA 官方页面下载与发行版匹配的 cuda-keyring 包后
sudo dpkg -i cuda-keyring_*.deb
sudo apt update

# Turing 及更新架构
sudo apt install nvidia-open

# 旧架构或明确需要专有内核模块
sudo apt install cuda-drivers

sudo reboot
```

仅安装无桌面计算节点所需组件时，官方仓库提供 `libnvidia-compute` 配合 `nvidia-dkms-open` 或 `nvidia-dkms` 的方案。包名在 590 及之后有变化，应以当前指南为准，不要长期硬编码分支包名。

### 4.5 RHEL/Rocky/AlmaLinux

先启用与发行版大版本和架构完全对应的 NVIDIA 仓库，再按当前官方指南安装：

```bash
sudo dnf install "kernel-headers-$(uname -r)" \
  "kernel-devel-$(uname -r)" gcc make dkms
dnf search nvidia-open
dnf module list nvidia-driver 2>/dev/null
```

不同 RHEL 大版本分别使用 DNF 模块流、普通包或 versionlock；不要把 RHEL 8/9 的 `dnf module` 命令机械复制到 RHEL 10。

### 4.6 `.run` 安装器

仅在理解这些后果时使用：需要停止图形会话；自己维护 headers、模块重建和签名；卸载/升级须继续使用同一体系；CUDA Toolkit 安装器可能捆绑 Driver。

```bash
# 识别包管理器安装
dpkg -l | grep -E 'nvidia|cuda'        # Debian/Ubuntu
rpm -qa | grep -Ei 'nvidia|cuda'       # RPM 系

# .run 安装通常提供
command -v nvidia-uninstall
```

不要直接用 `.run` 覆盖已由 APT/DNF 管理的驱动。只装 Toolkit 时必须取消安装器中的 Driver 选项。

## 5. Secure Boot 与模块签名

Secure Boot 会阻止未签名或未被信任的第三方模块加载。典型表现是 DKMS 显示 `installed`，但 `modprobe nvidia` 返回 `Key was rejected by service`。

```bash
mokutil --sb-state
modinfo -F signer nvidia
modinfo -F sig_id nvidia
sudo journalctl -k -b | grep -Ei 'secure|lockdown|verification|key.*reject|nvidia'
```

Ubuntu 优先使用 `ubuntu-drivers`。安装时若要求设置 MOK 密码：

1. 完成安装并重启。
2. 在 MOK Manager 选择 `Enroll MOK`。
3. 选择 `Continue`、`Yes`，输入安装时设置的一次性密码。
4. 再次重启，检查 `modinfo -F signer nvidia` 和 `nvidia-smi`。

错过注册时，可按发行版文档重新导入 DKMS 生成的公钥：

```bash
sudo mokutil --import /var/lib/dkms/mok.pub
sudo reboot
```

私钥应严格保护。不要下载未知 MOK 私钥，也不要为了省事长期关闭 Secure Boot；生产环境应使用组织自己的模块签名和密钥轮换策略。

## 6. `nouveau` 冲突

`nouveau` 是社区驱动，不是 NVIDIA 开放 GPU 内核模块；后者模块名仍是 `nvidia`。

先确认是否真的加载并占用设备：

```bash
lsmod | grep nouveau
lspci -nnk | grep -A3 -Ei 'VGA|3D|Display'
```

多数发行版包会自动处理冲突。只有确认 `nouveau` 阻止 NVIDIA 模块绑定时才手动禁用：

```bash
printf '%s\n' 'blacklist nouveau' 'options nouveau modeset=0' \
  | sudo tee /etc/modprobe.d/disable-nouveau.conf
sudo update-initramfs -u       # Debian/Ubuntu
sudo reboot
```

RPM 系使用 `sudo dracut --force` 重建 initramfs。恢复时删除自己创建的配置，重建 initramfs 后重启。远程服务器操作前应确保有带外控制台或可回退内核。

## 7. 安装后验证

### 7.1 NVIDIA 内核与用户态

```bash
lspci -nnk | grep -A3 -Ei 'VGA|3D|Display'
lsmod | grep '^nvidia'
modinfo -F version nvidia
cat /proc/driver/nvidia/version
ls -l /dev/nvidia* /dev/dri/* 2>/dev/null

nvidia-smi
nvidia-smi -L
nvidia-smi --query-gpu=index,name,uuid,driver_version,pci.bus_id,memory.total \
  --format=csv
```

| 模块 | 作用 |
|---|---|
| `nvidia` | 核心硬件驱动 |
| `nvidia_modeset` | 显示模式设置 |
| `nvidia_drm` | DRM/KMS 与图形栈集成 |
| `nvidia_uvm` | CUDA Unified Virtual Memory；计算任务通常需要 |
| `nvidia_peermem` | GPUDirect RDMA/存储等对等内存场景 |

手动测试加载：

```bash
sudo modprobe nvidia
sudo modprobe nvidia_uvm
sudo modprobe nvidia_drm
sudo journalctl -k -b -n 100
```

### 7.2 CUDA Toolkit

```bash
command -v nvcc
nvcc --version
ls -l /usr/local/cuda 2>/dev/null
ldconfig -p | grep -E 'libcuda\.so|libnvidia-ml\.so'
```

`nvcc --version` 是 Toolkit 版本；`nvidia-smi` 顶部的 `CUDA Version` 是驱动能力上限。两者不同通常正常。

### 7.3 PyTorch

```bash
python - <<'PY'
import torch
print("torch:", torch.__version__)
print("built CUDA:", torch.version.cuda)
print("built HIP:", torch.version.hip)
print("available:", torch.cuda.is_available())
print("device count:", torch.cuda.device_count())
for i in range(torch.cuda.device_count()):
    print(i, torch.cuda.get_device_name(i), torch.cuda.get_device_capability(i))
PY
```

PyTorch wheel/conda 包通常自带 CUDA 用户态运行库，但仍依赖宿主机驱动。系统 `nvcc` 不必与 wheel 运行库完全相同；编译自定义 CUDA 扩展时才尤其要关注 Toolkit、编译器和 PyTorch 构建版本。

## 8. CUDA 与驱动版本兼容

CUDA 11 起支持同一大版本族内的 minor version compatibility。最低 Linux 驱动分支快查：

| CUDA Toolkit | 最低驱动分支 | 说明 |
|---|---:|---|
| CUDA 13.x | 580 | 更新驱动向后兼容 |
| CUDA 12.x | 525 | 525 ≤ 分支 < 580 属于 12.x 小版本兼容范围 |
| CUDA 11.x | 450 | 450 ≤ 分支 < 525 属于 11.x 小版本兼容范围 |

这是大版本级快查，不替代具体 Toolkit release notes：

- 新 Toolkit 特性可能要求更新驱动，否则出现 `cudaErrorCallRequiresNewerDriver`。
- 依赖 PTX JIT 的程序可能无法在较老驱动上运行。
- 新驱动通常能运行用旧 Toolkit 构建的程序。
- 容器中的 CUDA 运行库仍受宿主机驱动能力限制。
- 不要为匹配 Toolkit 而无必要地降级可向后兼容的新驱动。

```bash
nvidia-smi pmon -c 1
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
sudo fuser -v /dev/nvidia* 2>/dev/null
```

## 9. NVIDIA 容器

宿主机必须先保证 `nvidia-smi` 正常。然后安装 NVIDIA Container Toolkit，不是在镜像中安装内核驱动。

按 NVIDIA 官方安装页配置仓库并安装 `nvidia-container-toolkit` 后：

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 标签仅为示例，按实际驱动兼容性选择镜像
docker run --rm --gpus all nvidia/cuda:13.0.0-base-ubuntu24.04 nvidia-smi
```

containerd：

```bash
sudo nvidia-ctk runtime configure --runtime=containerd
sudo systemctl restart containerd
```

排障：

```bash
docker info | grep -i runtime
nvidia-container-cli info
docker run --rm --gpus '"device=0"' \
  nvidia/cuda:13.0.0-base-ubuntu24.04 nvidia-smi
```

| 现象 | 原因方向 |
|---|---|
| `could not select device driver ... [[gpu]]` | Toolkit 未安装或 Docker runtime 未配置 |
| 宿主机 `nvidia-smi` 失败 | 先修宿主驱动，容器不能绕过 |
| 容器提示 driver insufficient | 镜像 CUDA runtime 超过宿主驱动能力 |
| `daemon-reload` 后容器失去 GPU | 查看 Toolkit 的 systemd cgroup 已知问题并重建容器 |

## 10. AMDGPU 与 ROCm

### 10.1 两种驱动来源

多数 AMD GPU 的 `amdgpu` 已在 Linux 内核中。桌面图形通常只需发行版内核、`linux-firmware` 和 Mesa，**不需要另装 `amdgpu-dkms`**。

ROCm 仓库提供的 `amdgpu-dkms` 是受特定 ROCm/发行版/内核组合支持的驱动。仅在 ROCm 支持矩阵或所需功能明确要求时替换发行版模块；最新主线内核不一定被某个 ROCm DKMS 版本支持。

### 10.2 基础检查

```bash
lspci -nnk | grep -A3 -Ei 'VGA|3D|Display'
lsmod | grep '^amdgpu'
modinfo amdgpu | grep -E '^(filename|version|firmware):' | head
ls -l /dev/kfd /dev/dri/render* 2>/dev/null
sudo journalctl -k -b | grep -Ei 'amdgpu|kfd|drm|firmware'

glxinfo -B                    # 通常来自 mesa-utils
vulkaninfo --summary          # 通常来自 vulkan-tools
```

### 10.3 ROCm 安装原则

1. 核对 [ROCm compatibility matrix](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html)：GPU、发行版、内核、Python 和框架都要受支持。
2. 按当前发行版页面配置 AMD 官方仓库，不复用过期版本 URL。
3. 已有兼容的发行版 `amdgpu` 时，优先考虑 ROCm 的 `--no-dkms` 路径；矩阵要求厂商 KMD 时再装 `amdgpu-dkms`。
4. 将计算用户加入 `render`、`video` 组，重新登录生效。

```bash
sudo usermod -a -G render,video "$LOGNAME"

# 包名需在 AMD 当前发行版指南确认
sudo apt install "linux-headers-$(uname -r)" \
  "linux-modules-extra-$(uname -r)"
sudo apt install amdgpu-dkms
sudo apt install rocm
sudo reboot
```

验证：

```bash
groups
dkms status -m amdgpu
rocminfo
rocm-smi
hipcc --version
```

| 现象 | 优先检查 |
|---|---|
| `/dev/kfd` 不存在 | `amdgpu`/KFD、GPU 支持状态、内核日志 |
| `Permission denied` | 当前会话是否属于 `render`/`video`，设备节点 ACL |
| `rocminfo` 只有 CPU agent | GPU 型号与 ROCm 支持矩阵、KFD 日志 |
| 内核升级后 DKMS 失败 | ROCm KMD 是否支持新内核、headers 是否匹配 |
| PyTorch 安装后 GPU 不可用 | wheel 是否为 ROCm 构建、是否包含该 GPU 架构 |

## 11. 常见故障对照

### 11.1 `Failed to initialize NVML: Driver/library version mismatch`

用户态 NVIDIA 库与已加载的内核模块版本不同，常见于驱动包升级后尚未重启。

```bash
nvidia-smi
modinfo -F version nvidia
cat /proc/driver/nvidia/version
sudo journalctl -k -b | grep -i 'API mismatch'
```

确认无 GPU 任务后先重启。若仍不一致，检查是否混用了 APT/DNF、`.run`、容器挂载或残留库：

```bash
ldconfig -p | grep -E 'libnvidia-ml|libcuda'
readlink -f "$(ldconfig -p | awk '/libnvidia-ml.so.1/{print $NF; exit}')"
```

### 11.2 `NVIDIA-SMI has failed because it couldn't communicate...`

```bash
lspci -nnk | grep -A3 -Ei 'VGA|3D|Display'
lsmod | grep -E 'nvidia|nouveau'
sudo modprobe nvidia
sudo journalctl -k -b -n 200
dkms status
```

按 `modprobe` 错误分流：

- `Module nvidia not found`：当前内核没有模块，查 DKMS/预编译包和 headers。
- `Key was rejected by service`：处理 Secure Boot/MOK。
- `No such device`：查 PCI 绑定、硬件支持、直通或 `vfio-pci`。
- `Device or resource busy`：查 `nouveau`、`vfio-pci` 或旧 NVIDIA 模块占用。

### 11.3 `No devices were found`

```bash
nvidia-smi -L
lspci -nnk | grep -A3 -Ei 'VGA|3D|Display'
ls -l /dev/nvidia*
sudo journalctl -k -b | grep -Ei 'NVRM|Xid|RmInit|fallen off'
```

检查设备绑定、是否被 `vfio-pci` 占用、虚拟机/容器是否分配设备，以及硬件是否产生 Xid。

### 11.4 `CUDA driver version is insufficient for CUDA runtime version`

应用或容器内 CUDA runtime 高于宿主驱动能力：

```bash
nvidia-smi
nvcc --version 2>/dev/null
```

升级宿主驱动，或选择兼容的应用/容器 CUDA 版本。不要只在容器内安装新驱动包。

### 11.5 内核升级后驱动失效

```bash
uname -r
dkms status
test -e /lib/modules/"$(uname -r)"/build || echo 'missing headers'
sudo find /var/lib/dkms -name make.log -type f -print
sudo journalctl -k -b | grep -Ei 'nvidia|amdgpu|module|verification'
```

顺序：补齐精确 headers/devel → 阅读 `make.log` 第一处编译错误 → 更新到支持该内核的驱动 → `dkms autoinstall` → 重建 initramfs → 重启。不要只看最后一行 `Bad return status`。

### 11.6 GPU 消失、Xid 或 `fallen off the bus`

```bash
sudo journalctl -k -b | grep -E 'NVRM: Xid|fallen off|AER|PCIe Bus Error'
nvidia-smi -q
nvidia-smi -q -d TEMPERATURE,POWER,ECC,PCIE
sudo nvidia-bug-report.sh
```

可能涉及驱动缺陷、PCIe AER、供电、温度、硬件、虚拟化或超频。不要把所有 Xid 都归因于 CUDA。`nvidia-bug-report.sh` 可能收集主机名、路径和配置，外发前审查压缩包。

### 11.7 PyTorch `torch.cuda.is_available()` 为 `False`

按层检查：

1. `lspci` 是否看到 GPU。
2. `nvidia-smi` 或 `rocminfo` 是否正常。
3. Python 包是否为 CUDA/ROCm 构建，而非 CPU-only。
4. 驱动是否满足框架自带 runtime 的要求。
5. 容器是否传入 GPU。
6. 可见设备环境变量是否隐藏 GPU。

```bash
env | grep -E 'CUDA_VISIBLE_DEVICES|HIP_VISIBLE_DEVICES|ROCR_VISIBLE_DEVICES'
python -m torch.utils.collect_env
```

## 12. 升级、回退与卸载

升级前保存现场：

```bash
nvidia-smi -q > nvidia-smi-before.txt 2>&1
dkms status > dkms-before.txt 2>&1
uname -a > kernel-before.txt
dpkg-query -W '*nvidia*' '*cuda*' 2>/dev/null > gpu-packages-before.txt
```

建议：

- 生产节点固定经过验证的驱动分支、内核和 CUDA/ROCm 镜像组合。
- 重启前确认 DKMS/预编译模块已为新内核准备完成。
- 保留至少一个已验证可启动的旧内核。
- 多节点集群先升级 canary 节点，再滚动升级。
- 降级时保证内核模块、用户态库、Fabric Manager 属于同一版本。

Ubuntu 查看来源和手工安装项：

```bash
apt-cache policy 'nvidia-driver-*' 'nvidia-dkms-*' nvidia-open cuda-drivers
apt-mark showmanual | grep -Ei 'nvidia|cuda'
dpkg -l | grep -Ei 'nvidia|cuda'
```

卸载属于有状态操作，应先确认安装来源和远程恢复方式：

- APT/DNF 安装只用对应包管理器卸载。
- `.run` 安装使用匹配的 `nvidia-uninstall`。
- 不要手删 `/usr/lib`、`/lib/modules` 文件，以免破坏包数据库和回退能力。

## 13. 运维快查

```bash
# GPU 列表、拓扑、实时利用率
nvidia-smi -L
nvidia-smi topo -m
nvidia-smi dmon -s pucvmet -d 1

# 监控脚本易处理的 CSV
nvidia-smi --query-gpu=timestamp,index,uuid,name,temperature.gpu,utilization.gpu,\
memory.used,memory.total,power.draw --format=csv,noheader,nounits

# 进程和设备占用
nvidia-smi pmon
sudo fuser -v /dev/nvidia* 2>/dev/null

# 无显示计算节点常用的持久化服务
systemctl status nvidia-persistenced

# 模块参数
systool -vm nvidia 2>/dev/null
cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null
```

不要对正在运行任务的 GPU 随意 reset。显示模式、NVLink/NVSwitch、虚拟化环境或部分 GPU 不允许安全 reset。

## 14. 官方资料

- [NVIDIA Driver Installation Guide](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/)
- [NVIDIA Kernel Modules：开放/专有模块与发行版安装](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/kernel-modules.html)
- [Ubuntu Server：安装 NVIDIA 驱动](https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/)
- [CUDA Compatibility](https://docs.nvidia.com/deploy/cuda-compatibility/)
- [CUDA Toolkit Release Notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/)
- [NVIDIA Container Toolkit 安装](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [NVIDIA Linux x86_64 驱动与版本化 README 索引](https://download.nvidia.com/XFree86/Linux-x86_64/)
- [NVIDIA 驱动与 CUDA 支持生命周期](https://docs.nvidia.com/datacenter/tesla/drivers/supported-drivers-and-cuda-toolkit-versions.html)
- [ROCm Linux 安装](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/)
- [ROCm Compatibility Matrix](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html)
- [DKMS 项目文档](https://github.com/dell/dkms)
