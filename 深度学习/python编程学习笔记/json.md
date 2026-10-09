```table-of-contents
```
# 一、方法
1. **json.dump()**
`json.dump(数据, 文件对象)`：把 Python 数据写入 JSON 文件。`json.dump()` 接受两个实参：**要存储的数据**以及**可用于存储数据的文件对象**。下面演示了如何使用 `json.dump()` 来存储数字列表。
```python
import json

numbers = [2, 3, 5, 7, 11, 13]

filename = 'numbers.json'
with open(filename, 'w') as f_obj:
    json.dump(numbers, f_obj)
```

注：`'numbers.json'` 里的 `.json` 是文件后缀名，表示这个文件通常按照 `JSON` 格式存储数据。
2. **json.load()**
`json.load(文件对象)` 从已经打开的 JSON 文件中读取数据，并把它转换成 Python 对象。
```python
import json

filename = 'numbers.json'

with open(filename) as f_obj:
    numbers = json.load(f_obj)

print(numbers)

>>>[2, 3, 5, 7, 11, 13]
```

# 二、笔记

## 2.1 存储数据

模块 `json` 让你能够将简单的 Python 数据结构存储到文件中，并在程序再次运行时加载该文件中的数据。你还可以使用 `json` 在 Python 程序之间分享数据。更重要的是，JSON 数据格式并非 Python 专用的，这让你能够将以 JSON 格式存储的数据与使用其他编程语言的人分享。这是一种轻便格式，很有用，也易于学习。