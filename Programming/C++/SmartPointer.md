# SmartPointer  智能指针



## std::unique_ptr

仅能有一个 `unique_ptr` 指向某一块内存，具有独占权。

```c++
#include <memory>

std::unique_ptr<int> ptr = std::make_unique<int>(42);  // 动态分配内存
std::cout << *ptr << std::endl;  // 输出 42
// 自动释放内存，出作用域时会调用 delete
```

## std::shared_ptr

可以有多个 `shared_ptr` 指向同一块内存，使用引用计数管理内存，当最后一个 `shared_ptr` 被销毁时，内存才会被释放。

```c++
#include <memory>

std::shared_ptr<int> ptr1 = std::make_shared<int>(42);
std::shared_ptr<int> ptr2 = ptr1;  // 共享同一块内存
std::cout << *ptr1 << ", " << *ptr2 << std::endl;  // 输出 42, 42
// 当 ptr1 和 ptr2 超出作用域时，内存会自动释放
```

