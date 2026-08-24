# GPU

本目录记录 Linux GPU 驱动、CUDA/ROCm 环境和 GPU 加速计算。

## 当前内容

| 主题 | 入口 | 内容 |
|------|------|------|
| Drivers | [GPU 驱动](Drivers/README.md) | NVIDIA/AMDGPU、DKMS、Secure Boot、兼容性和排障 |
| CUDA | [CUDA](CUDA/README.md) | 无 sudo 环境安装 CUDA Toolkit |

## 推荐学习路径

1. 理解硬件、内核驱动、用户态运行库和计算框架的分层。
2. 完成驱动、DKMS、Secure Boot 和设备验证。
3. 安装 CUDA/ROCm 工具链并建立版本兼容意识。
4. 学习性能分析、容器化和 PyTorch 等上层框架。

## 未来扩展

- GPU 架构、显存层次、PCIe、NUMA 与拓扑。
- CUDA 编程模型、Kernel、内存管理和并发执行。
- ROCm 环境与 NVIDIA/AMD 工具链对照。
- Nsight、rocprof、利用率和性能瓶颈分析。
- NVIDIA Container Toolkit 与 GPU 容器调度。
- PyTorch、混合精度、分布式训练和可复现环境。
