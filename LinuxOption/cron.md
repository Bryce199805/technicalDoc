# Cron Python task

利用cron创建定时任务执行python脚本

## python run script

- cron不会加载 `PATH`, `conda`需要给出具体路径
- cron脚本中使用绝对路径避免错误

```shell
source /opt/conda/bin/activate env_name

export NCCL_DEBUG=INFO
export NCCL_BLOCKING_WAIT=1
export NCCL_ASYNC_ERROR_HANDLING=1

CUDA_VISIBLE_DEVICES=0,1,2,3 torchrun --nproc_per_node=4 --master_port=29501 /code/src/train.py \
    --experiment_name ViT-B_ResNet50_4x4090d \
    --epochs 600 \
    --batch-size 160 \
    ...
```

## set task

下面这个定时任务的含义是每年的9月27日15:40会执行 `setsid nohup /root/cron.sh > /root/cron.log 2>&1`

```shell
crontab -e # 打开事件列表
# min hour day mouth week command
# * means any values
40 15 27 9 * setsid nohup /root/cron.sh > /root/cron.log 2>&1 
```

通过`crontab -l`查看设置好的任务