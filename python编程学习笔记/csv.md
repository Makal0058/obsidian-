```table-of-contents
```
# 一、方法
1. **csv.reader()**
`csv.reader()` 的作用是**把打开的 CSV 文件对象转换成一个可以逐行读取 CSV 数据**的读取器。
```python
import csv

filename = 'sitka_weather_07-2014.csv'

with open(filename) as f:
    reader = csv.reader(f)
    header_row = next(reader)
    print(header_row)
```
之后从 `reader` 中读取出来的每一行，都会按照逗号自动拆成一个列表。
2. **next(迭代器)**
`next(迭代器)` 是 Python 内置函数，作用是取出**迭代器当前轮到的一行**，并**把读取位置移动到下一行**。
3. 
# 二、笔记
## 2.1 CSV 文件格式

CSV 全称是 Comma-Separated Values（逗号分隔值），意思是**一行通常表示一条记录，不同字段之间用逗号隔开**。例如，下面是一行 CSV 格式的天气数据：
```text
2014-1-5,61,44,26,18,7,-1,56,30,9,30.34,30.27,30.15,,,,10,4,,0.00,0,,195
```
