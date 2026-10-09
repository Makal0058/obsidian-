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
3. **enumerate(header_row)**
`enumerate(header_row)` 会把 `header_row` 里的每个元素，和它对应的**索引**配成一对。
```python
header_row = [
    'AKDT',
    'Max TemperatureF',
    'Mean TemperatureF',
    'Min TemperatureF'
]

enumerate(header_row)

>>>(0, 'AKDT')
>>>(1, 'Max TemperatureF')
>>>(2, 'Mean TemperatureF')
>>>(3, 'Min TemperatureF')
```
这里每一行都是一个元组。
4. **datetime.strptime()**
`datetime.strptime()`：把“日期/时间格式的字符串”解析成真正的 `datetime` 日期时间对象。
```python
from datetime import datetime

first_date = datetime.strptime('2014-7-1', '%Y-%m-%d')
print(first_date)

>>>2014-07-01 00:00:00
```
这里原本 `'2014-7-1'` 只是一个普通字符串，而 `'%Y-%m-%d'` 是在告诉 Python 这个字符串的格式：`%Y`：四位年份、`%m`：月份、`%d`：日期。所以最后 `first_date` 不再是普通字符串，而是一个 `datetime` 对象。

| 实参   | 含义                 |
| ---- | ------------------ |
| `%Y` | 四位的年份，如 2015       |
| `%m` | 用数字表示的月份（01～12）    |
| `%d` | 用数字表示月份中的一天（01～31） |
| `%H` | 24 小时制的小时数（00～23）  |
| `%M` | 分钟数（00～59）         |
| `%S` | 秒数（00～61）          |
# 二、笔记
## 2.1 CSV 文件格式

CSV 全称是 Comma-Separated Values（逗号分隔值），意思是**一行通常表示一条记录，不同字段之间用逗号隔开**。例如，下面是一行 CSV 格式的天气数据：
```text
2014-1-5,61,44,26,18,7,-1,56,30,9,30.34,30.27,30.15,,,,10,4,,0.00,0,,195
```
