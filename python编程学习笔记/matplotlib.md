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
2. **plt.plot()**
`plt.plot()` 绘制折线图，用线条连接各个数据点，参数 `linewidth` 决定了 `plot()` 绘制的线条的粗细。
```python
squares = [1, 4, 9, 16, 25]

plt.plot(squares, linewidth=5)
```
3. **plt.tick_params()**
函数 `tick_params()` 设置刻度的样式，其中指定的实参将影响 x 轴和 y 轴上的刻度（`axis='both'`），并将刻度标记的字号设置为 14（`labelsize=14`）。
```python、
plt.tick_params(axis='both', labelsize=14)
```
4. **plt.show()**
`plt.show()` 显示已经绘制好的图表。



# 二、笔记
