```table-of-contents
```
# 一、方法
```python
import matplotlib.pyplot as plt
```
1. **plt.title()**
`plt.title()` 设置图表标题，参数 `fontsize` 用于设置**标题文字的字号**
```python
squares = [1, 4, 9, 16, 25]

plt.title("Square Numbers", fontsize=24)
```

函数 `xlabel()` 和 `ylabel()` 为每条轴设置标题。
```python
plt.xlabel("Value", fontsize=14)
plt.ylabel("Square of Value", fontsize=14)
```
2. **plt.plot(x, y)**
`plt.plot(x, y)` 绘制折线图，第一个参数是 x 轴数据，第二个参数是 y 轴数据，用线条连接各个数据点；参数 `linewidth` 决定了 `plot()` 绘制的线条的粗细。

只传一组数据时，这组数据默认作为 y 值，x 自动取 `0, 1, 2, ...`
```python
squares = [1, 4, 9, 16, 25]

plt.plot(squares, linewidth=5)
plt.show()
```
`plt.show()` 显示已经绘制好的图表。
3. **plt.tick_params()**
函数 `tick_params()` 设置刻度的样式，其中指定的实参将影响 x 轴和 y 轴上的刻度（`axis='both'`），并将刻度标记的字号设置为 14（`labelsize=14`）。
```python、
plt.tick_params(axis='both', labelsize=14)
```
4. **scatter()**
要绘制单个点，可使用函数 `scatter()`，并向它传递一对 x 和 y 坐标，它将在指定位置绘制一个点。
- 实参 `s` 设置了绘制图形时使用的点的尺寸。
- 实参 `c` 设置了要修改数据点的颜色名称；`edgecolor` 控制**边框颜色**
```python
import matplotlib.pyplot as plt

plt.scatter(x_values, y_values, c='red', edgecolor='none', s=40)
plt.show()
```
5. **plt.axis()**
函数 `axis()` 指定了每个坐标轴的取值范围，要求提供四个值，顺序是`[x 最小值, x 最大值, y 最小值, y 最大值]`。
```python
plt.axis([0, 1100, 0, 1100000])
```
6. **plt.savefig(文件名)**
`plt.savefig(文件名)` **把当前已经绘制好的图表保存成文件**。下面是把图保存为 `squares_plot.png`。
```python
plt.savefig('squares_plot.png', bbox_inches='tight')
```
`bbox_inches='tight'` 作用是**让保存图片时的边界尽量贴合图表内容，减少周围多余的空白**。
7. **plt.figure()**
`plt.figure()`：创建并设置绘图画布。

`figsize=()` 用于设置画布大小，单位是英寸；`dpi` 是每英寸有多少个像素点，影响图像的**分辨率/清晰度**。
```python
# 设置绘图窗口的尺寸
plt.figure(dpi=128, figsize=(10, 6))
```
8. **randint()**
`randint()` 是 `random` 模块中的函数，用于**随机生成一个整数**。
```python
from random import randint

print(randint(1, 6))
```
每次运行，都可能得到
```python
>>>1
>>>2
>>>3
>>>4
>>>5
>>>6
```
中的任意一个。

注：`randint(a, b)` 会同时包含两端，也就是可能取到 `a`，也可能取到 `b`。

9. **range()**
`range(n)` 生成从 `0` 到 `n-1` 的整数序列，共 `n` 个数。
```python
range(5)

>>>0, 1, 2, 3, 4
```
# 二、笔记
## 2.1 自动计算数据

手工计算列表要包含的值可能效率低下，需要绘制的点很多时尤其如此。可以不必手工计算包含点坐标的列表，而让 Python 循环来替我们完成这种计算。下面是绘制 1000 个点的代码：
```python
import matplotlib.pyplot as plt

x_values = list(range(1, 1001))
y_values = [x**2 for x in x_values]

plt.scatter(x_values, y_values, s=40)

# 设置图表标题并给坐标轴加上标签
--snip--

# 设置每个坐标轴的取值范围
plt.axis([0, 1100, 0, 1100000])

plt.show()
```
## 2.2 颜色映射

颜色映射是从起始颜色渐变到结束颜色的一系列颜色，用于突出数据的规律。模块 `pyplot` 内置了一组颜色映射。下面演示了如何根据每个点的 y 值来设置其颜色。
```python
import matplotlib.pyplot as plt

x_values = list(range(1001))
y_values = [x**2 for x in x_values]

plt.scatter(
    x_values,
    y_values,
    c=y_values,
    cmap=plt.cm.Blues,
    edgecolor='none',
    s=40
)

# 设置图表标题并给坐标轴加上标签
--snip--
```
参数 `c` 设置成了一个 y 值列表，并使用参数 `cmap` 告诉 `pyplot` 使用哪个颜色映射。这些代码将 y 值较小的点显示为浅蓝色，并将 y 值较大的点显示为深蓝色。

其中 `c=y_values` 表示**根据每个点的 y 值决定颜色深浅**；`cmap=plt.cm.Blues` 使用 `Blues` 这一套蓝色渐变颜色映射。

注：`cmap` 是 **colormap**（**颜色映射**）的缩写，用来指定“数值对应什么颜色”。
