## option

```cmake
option(<variable> "<help_text>" [value])

# 不初始化或赋为非ON的值，全部视为OFF
option(USE_FILESYSTEM "Enable file system support" ON)

#如果再代码中要使用预定义宏来控制 CMakeList中需要添加
target_compile_definitions(MYEXE PRIVATE USE_FILESYSTEM)
```

```shell
# 使用cmake构建时
cmake -DUSE_FILESYSTEM=ON ..	# USE_FILESYSTEM = ON
cmake -DUSE_FILESYSTEM=OFF ..	# USE_FILESYSTEM = OFF
cmake -DUSE_FILESYSTEM=ASD ..	# USE_FILESYSTEM = OFF (非ON的值)
cmake ..	# USE_FILESYSTEM = OFF (未初始化)
```

```c++
#ifdef USE_FILESYSTEM
	void test(){
        ...
    }	// 这部分代码会在 -DUSE_FILESYSTEM=ON 时有效
#endif
```

