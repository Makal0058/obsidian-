
1. **@dataclass**
`@dataclass` 是 Python 提供的一个装饰器，中文通常称为「数据类装饰器」，主要作用是：自动为类生成 `__init__()` 等方法，让我们不用手动编写重复的初始化代码。

- **不使用 @dataclass**
```python
class MoTConfig:
    def __init__(self, num_stacks=4, top_k=3): #层组数量，默认值为 4、激活专家数量，默认值为 3
        self.num_stacks = num_stacks
        self.top_k = top_k

config = MoTConfig()
print(config.num_stacks)

>>> 4

print(config.top_k)

>>> 3
```
这里必须自己编写 `__init__()`，将传入的参数保存到对象中。

- **使用 @dataclass**
```python
from dataclasses import dataclass

@dataclass
class MoTConfig:
    num_stacks: int = 4
    top_k: int = 3

config = MoTConfig()
print(config.num_stacks)

>>> 4

print(config.top_k)

>>> 3

print(config)

>>> MoTConfig(num_stacks=4, top_k=3)
```
可以看到，没有编写 `__init__()`，但依然可以正常创建对象。这是因为 `@dataclass` 自动生成了类似下面的方法：
```python
def __init__(self, num_stacks=4, top_k=3):
    self.num_stacks = num_stacks
    self.top_k = top_k
```
另外，它还会自动生成 `__repr__()`，让 `print(config)` 能直接显示对象里的参数。

注：@dataclass 和普通 class 的区别

| 功能              | 普通 `class` | `@dataclass` |
| --------------- | ---------- | ------------ |
| 创建对象            | 支持         | 支持           |
| 自动生成 `__init__` | 否          | 是            |
| 自动生成 `__repr__` | 否          | 是            |
| 自动生成 `__eq__`   | 否          | 是            |
| 自定义方法           | 支持         | 支持           |
| 适合用途            | 各种类        | 主要用于保存结构化数据  |
`@dataclass` 还可以根据配置自动生成其他方法，但默认不会自动生成所有比较方法。

2. __repr__()
`__repr__()` 是 Python 类中的一个特殊方法，用于决定一个对象应该如何表示为字符串，当使用 `print(对象)` 时，`__repr__()` 可以决定显示什么内容。

- **不使用 `__repr__()`**
```python
class Student:
    def __init__(self, name, age):
        self.name = name
        self.age = age

student = Student("小明", 20)
print(student)

>>> <__main__.Student object at 0x104a3b890>
```
因为没有定义对象的字符串表示方式，所以 Python 默认显示对象的类型和内存地址等信息。

- **使用 `__repr__()`**
```python
class Student:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __repr__(self):
        return f"Student(name={self.name}, age={self.age})"

student = Student("小明", 20)
print(student)

>>> Student(name=小明, age=20)
```
`def __repr__(self):` 定义一个特殊方法。当 Python 需要获取对象的正式字符串表示时，会调用它，返回一个包含学生信息的字符串。

注：`__repr__()` 和 `__str__()` 有什么区别？

Python 提供了两个用于显示对象的方法：

| 方法 | 主要用途 | 调用方式 |
| --- | --- | --- |
| `__repr__()` | 对象的正式表示，通常用于调试 | `repr(student)` |
| `__str__()` | 面向用户的可读表示 | `str(student)` |
`print(student)` 会优先使用 `__str__()`；如果没有定义 `__str__()`，就会使用 `__repr__()`。因此，前面的例子能够正常输出学生信息。

3. **hasattr()**
`hasattr(要检查的对象, 属性名称（必须是字符串）)` 是 Python 的一个内置函数，用于判断某个对象是否具有指定的属性。

- 返回 `True`：对象具有该属性。
- 返回 `False`：对象没有该属性。
```python
class Student:
    def __init__(self):
        self.name = "小明"
        self.age = 20

student = Student()

print(hasattr(student, "name"))

>>> True

print(hasattr(student, "age"))

>>> True

print(hasattr(student, "height"))

>>> False
```
`student` 对象具有 `name` 和 `age` 属性，但是没有 `height` 属性，所以第三个结果为 `False`。

**也可以判断对象是否具有方法**
```python
class Student:
    def study(self):
        print("正在学习")

student = Student()

print(hasattr(student, "study"))

>>> True

print(hasattr(student, "sleep"))

>>> False
```
因为方法也是对象的属性，所以 **`hasattr()` 不仅能检查变量，还能检查方法。**

4. **math.ceil()**
`math.ceil(x)` 是 Python `math`（数学）模块中的一个函数，用于向上取整，返回一个整数 `int。
```python
import math

print(math.ceil(3.1))

>>> 4
```

5. **isinstance()**
`isinstance(需要检查的对象, 指定的类型或类)` 是 Python 的一个内置函数，用于判断某个对象是否属于指定的类型（类）。
```python
a = 10
b = 3.14
print(isinstance(a, int))

>>> True

print(isinstance(b, float))

>>> True
```

5. **enumerate()**
`enumerate(iterable, start=0)` 是 Python 中非常常用的内置函数，用于在遍历列表等可迭代对象时，同时获取元素的索引和元素本身。

| 参数         | 含义                | 默认值 |
| ---------- | ----------------- | --- |
| `iterable` | 可迭代对象，例如列表、元组、字符串 | 必填  |
| `start`    | 索引（计数）的起始值        | `0` |
**`enumerate()` 返回一个枚举迭代器，每次迭代产生一个包含索引和元素的元组。**
```python
experts = ["专家A", "专家B", "专家C"]

for expert in experts:
    print(expert)

>>> 专家A
>>> 专家B
>>> 专家C

experts = ["专家A", "专家B", "专家C"]

for i, expert in enumerate(experts):
    print(i, expert)

>>> 0 专家A
>>> 1 专家B
>>> 2 专家C
```
