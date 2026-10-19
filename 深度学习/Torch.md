# 一、torch 函数

1. **rand()**
`rand()`：**随机生成 0 到 1 之间的数**。`torch.rand(3, 4)` 表示生成一个 shape 为 `(3, 4)` 的随机张量，其中每个元素服从 $[0,1)$ 上的均匀分布，例如：
```python
tensor([
    [0.23, 0.81, 0.14, 0.67],
    [0.92, 0.35, 0.48, 0.11],
    [0.56, 0.73, 0.29, 0.88]
])
```
2. **normal（mean, std）**
`normal（mean, std)`：按照均值为 `mean`、标准差为 `std` 的**正态分布**生成随机数。
```python
torch.normal(0.0, 0.5, (n_train,))
```
`0.0` 表示均值；`0.5` 表示标准差；`n_train` 表示生成一个长度为 `n_train` 的一维张量。
3. **arange（）**
`torch.arange(start, end, step)`：**按照指定步长生成一串连续数字**，其中包含 `start`，但**不包含 `end`**。
```python
x_test = torch.arange(0, 5, 0.1)
```
从 `0` 开始，到 `5` 之前，每隔 `0.1` 取一个值。
4. **sort（）**
`torch.sort()` 返回 `(排序后的值, 原索引)`。
```python
x = torch.tensor([3, 1, 2])
values, indices = torch.sort(x)

>>>values = tensor([1, 2, 3])
>>>indices = tensor([1, 2, 0])

values, _ = torch.sort(x)
```
其中 `indices = [1, 2, 0]` 表示排序后的元素原来在哪，`_` 表示该返回值不需要使用（惯例）。
5. **repeat_interleave()**
`torch.repeat_interleave()`：把每个元素重复若干次。
```python
import torch

x = torch.tensor([1, 2, 3])
y = torch.repeat_interleave(x, 2)

print(y)

>>>tensor([1, 1, 2, 2, 3, 3])
```
也就是每个元素重复 2 次。参数 `dim=0` 是沿第0维，也就是样本这一维重复。
6. **matmul（）**
`matmul`：**矩阵乘法**。
```python
y_hat = torch.matmul(A, B)
```
7. **torch.bmm()**
`torch.bmm()` 一次性对一批矩阵分别做矩阵乘法。

普通矩阵乘法是 `torch.matmul(A, B)`，而 bmm 专门处理这种三维张量 `A.shape = (batch, m, n)`、`B.shape = (batch, n, p)`，那么 `torch.bmm(A, B)` 输出 `(batch, m, p)`，也就是每个 batch 单独算 `A_iB_i`
8. **torch.randn()**
`torch.randn()` 是 **PyTorch 用来生成随机张量的函数**，它生成的随机数来自**标准正态分布**，也就是 $\mathcal{N}(0,1)$。括号里的参数表示**要生成的张量形状**。
```python
import torch
x = torch.randn(3)
print(x)

>>>tensor([ 0.52, -1.13, 0.08])
```
9. **torch.normal()**
`torch.normal(mean, std, size)` 是 **PyTorch 生成正态分布随机数** 的函数，和 `torch.randn()` 的区别是可以自己指定均值 `mean`、标准差 `std`。
```python
torch.normal(0.0, 1.0, (3,))

>>>tensor([ 0.32, -1.15, 0.67])
```
意思是生成 3 个服从均值 0、标准差 1 的正态分布随机数。
10. **.pow()**
`张量.pow(底数, 指数)` 是 **PyTorch 张量的方法**，作用是**做幂运算**。
- `torch.pow(底数, 指数)`
- `张量.pow(指数)`
```python
import torch

x = torch.tensor([2.0, 3.0])
print(x.pow(2))

>>> tensor([4., 9.])
```
11. **size()**
在 PyTorch 中，`size()` 用于查看张量的形状，与 `shape` 类似。
```python
import torch

query = torch.randn(2, 3, 4)

print(query.size())

>>> torch.Size([2, 3, 4])

print(query.shape)

>>> torch.Size([2, 3, 4])
```
说明 `query` 是一个三维张量，各维度大小分别为 2、3、4。
12. **torch.topk()**
`torch.topk(input, k, dim=None, largest=True, sorted=True)` 是 PyTorch 中非常常用的函数，用于从张量中选出数值最大的 k 个元素，并返回这些元素的值和索引。
参数说明：

| 参数        | 含义         | 默认值    |
| --------- | ---------- | ------ |
| `input`   | 输入张量       | 必填     |
| `k`       | 选择多少个元素    | 必填     |
| `dim`     | 沿哪个维度进行选择  | 最后一个维度 |
| `largest` | 是否选择最大的元素  | `True` |
| `sorted`  | 是否将结果按数值排序 | `True` |
返回两个张量：

- `values`：选出的 k 个元素的数值。
- `indices`：这些元素在原张量中对应维度上的索引。

```python
import torch

x = torch.tensor([0.2, 0.8, 0.1, 0.9, 0.5])

values, indices = torch.topk(x, k=3)

print(values)

>>> tensor([0.9000, 0.8000, 0.5000])

print(indices)

>>> tensor([3, 1, 4])
```
# 二、torch.Tensor 张量方法
1. **repeat()**
`repeat()`：**重复整个张量 / 整块复制**，形式是 `张量.repeat(第0维重复次数, 第1维重复次数, 第2维重复次数, ...)`，也可以把这些数字写成一个元组 `张量.repeat((2, 3))` 和 `张量.repeat(2, 3)` 是一样的。
```python
x_train = [1, 2, 3]
n_train = 3

X_tile = x_train.repeat((n_train, 1))
````
则 $X_{\text{tile}}=\begin{bmatrix}1&2&3\\1&2&3\\1&2&3\end{bmatrix}$，形状 `[3, 3]`。也就是把 `x_train` **复制 3 行**。  
2. **mean()**
`.mean()`：求 Tensor 平均值。
```python
import torch

x = torch.tensor([1.0, 2.0, 3.0])

print(x.mean())

>>>tensor(2.)
```
3. **unsqueeze(dim)**
`tensor.unsqueeze(dim)`:在第 `dim` 个位置插入一个大小为 1 的维度。
```python
import torch

x = torch.tensor([1, 2, 3])
print(x.shape)

>>>torch.Size([3])

y = x.unsqueeze(0)
print(y.shape)

>>>torch.Size([1,3])
```
4. **.type(torch.bool)**
`.type(torch.bool)` 作用是：**把张量的数据类型转换成布尔类型 `bool`**。
```python
x = torch.tensor([0, 1, 2])
x.type(torch.bool)

>>>tensor([False, True, True])
```
规则：$\begin{cases} 0 → False \\ 非 0 → True \end{cases}$
5. **.reshape （）**
`.reshape（）` 是 **PyTorch 张量的方法**，作用是**改变张量的形状，但不改变里面元素的数量**。
```python
import torch

x = torch.tensor([1, 2, 3, 4, 5, 6])
print(x.shape)       

>>>torch.Size([6])

x_reshape = x.reshape(2, 3)
print(x_reshape.shape)

>>>torch.Size([2, 3])
```
`X.reshape(-1, shape[-1])` 前面的维度全部合并，最后一维保持不变。
6. **.squeeze()**
`.squeeze()` 是 **PyTorch 张量的方法**，作用是**删除张量里所有长度为 1 的维度**。
```python
x = torch.randn(1, 3, 1, 5)
print(x.shape)

>>>torch.Size([1, 3, 1, 5])

y = x.squeeze()
print(y.shape)

>>>torch.Size([3, 5])
```
`.squeeze()` 括号里的参数表示**指定要删除哪一个维度**，而且**指定的那个维度如果不是 1**，**就不会被删掉**。
7. **.transpose()**
`.transpose(a, b)` 是 **PyTorch 张量的方法**，作用是**交换第 a 维和第 b 维**。
```python
print(keys.shape)
>>> torch.Size([2, 10, 8])

>>> print(keys.transpose(1, 2).shape)
>>> torch.Size([2, 8, 10])
```

注：
- 二维矩阵转置：交换行和列。
- 高维张量转置：交换指定的两个维度。
1. **二维矩阵转置**
假设 $K=\begin{bmatrix}1&2&3\\4&5&6\end{bmatrix}$，它有 2 行、3 列，形状是 $(2,3)$。转置就是把行变成列，列变成行，$K^\top=\begin{bmatrix}1&4\\2&5\\3&6\end{bmatrix}$，形状变成 $(3,2)$。
```python
import torch

K = torch.tensor([
    [1, 2, 3],
    [4, 5, 6]
])

print(K.transpose(0, 1))

>>> 
```
2. **三维张量转置**
假设 $K[0]=\begin{bmatrix}1&2&3\\4&5&6\end{bmatrix}$、$K[1]=\begin{bmatrix}7&8&9\\10&11&12\end{bmatrix}$，这个张量的形状是 $(2,2,3)$，可以理解为**两个 $2\times3$ 的矩阵堆叠在一起**。
```python
K = torch.tensor([
    [[1, 2, 3],
     [4, 5, 6]],

    [[7, 8, 9],
     [10, 11, 12]]
])
```

如果执行：
```python
K_T = K.transpose(-1, -2)
```
就是交换最后两个维度。

原形状 $(2,2,3)$，转置后 $(2,3,2)$。$K_T[0]=\begin{bmatrix}1&4\\2&5\\3&6\end{bmatrix}$，3 行 × 2 列；$K_T[1]=\begin{bmatrix}7&10\\8&11\\9&12\end{bmatrix}$，3 行 × 2 列。两个矩阵没有交换位置，只是每个矩阵内部进行了转置。
8. **permute()**
`permute(新的维度顺序)` 是 **PyTorch 张量的方法**，作用是**按照指定的顺序，重新排列张量的各个维度**。`transpose()` 只能交换两个维度；`permute()` 可以一次重新排列所有维度。
```python
print(X.shape)

>>>torch.Size([2, 4, 5, 20])

X = X.permute(0, 2, 1, 3)
print(X.shape)

>>>torch.Size([2, 5, 4, 20])
```
9. **切片语法 \[start : stop : step\]**
`[start : stop : step]` 含义分别是：start → 从哪里开始、stop  → 到哪里结束，但不包含这个位置、step  → 步长，每隔几个取一次。
单独一个 `:` 在 Python 切片里表示**这一维全部都要**；`::` 本身也是切片的一部分，表示 `start : stop : step`。`::2` 其实就是 start 省略、stop 省略、step = 2。`:stop` 表示**从开头开始，一直取到 `stop` 之前**。
```python
a = [0, 1, 2, 3, 4, 5]
print(a[:4])

>>>[0, 1, 2, 3]

b = [0, 1, 2, 3, 4, 5, 6]
print(b[0:6:2])

>>>[0, 2, 4]
```
表示从 0 开始，到 6 之前，每隔 2 个取一个。
10. **torch.cat()**
`torch.cat((张量1, 张量2, ...), dim=某个维度)` 是 **PyTorch 自带的张量拼接函数**，作用是**把多个张量沿指定维度拼接起来**。
```python
import torch

A = torch.tensor([[1, 2]])
B = torch.tensor([[3, 4]])
print(torch.cat((A, B), dim=0))

>>> tensor([[1, 2],
         [3, 4]])
```
这里 `dim=0` 表示沿第 0 维拼，也就是**上下拼接**。
```python
print(torch.cat((A, B), dim=1))

>>> tensor([[1, 2, 3, 4]])
```
这里 `dim=1` 表示沿第 1 维拼，也就是**左右拼接**。
11. **.dtype**
`.dtype` 是 PyTorch 张量（`torch.Tensor`）的一个属性（Attribute），用于获取张量中元素的数据类型。
```python
import torch

x = torch.tensor([1.0, 2.0, 3.0])
print(x.dtype)

>>> torch.float32
```
12. **.type()**
`.type()` 是 PyTorch 中 `torch.Tensor` 类的方法（Method），主要用于查看或转换张量的数据类型。**不传参数用于查看张量类型；传入参数用于转换数据类型**。
```python
import torch

x = torch.tensor([1.0, 2.0, 3.0])

print(type(x))
>>> <class 'torch.Tensor'>

print(x.type())
>>> torch.FloatTensor

x.type(torch.float16) #将张量 `x` 转换为 16 位浮点数类型。
```

注：
- `type(x)`：Python 内置函数，获取对象的类型。
- `x.type()`：PyTorch 张量的方法，可以查看张量类型，也可以转换类型。

13. **torch.empty()**
`torch.empty(*size, dtype=None, device=None)` 是 PyTorch 中的一个张量创建函数，用于创建指定形状的张量，但不初始化其中的元素数值。与 `torch.zeros()`、`torch.ones()` 最大的区别是：**`torch.empty()` 不会主动将张量填充为 0、1 或随机数**。

主要参数：

| 参数       | 含义               |
| -------- | ---------------- |
| `size`   | 张量的形状            |
| `dtype`  | 张量的数据类型          |
| `device` | 张量所在设备，如 CPU、GPU |

```python
import torch

x = torch.empty(2, 3)

print(x)

>>> tensor([[2.3694e-38, 0.0000e+00, 1.4013e-45],
>>>         [0.0000e+00, 4.2039e-45, 0.0000e+00]])

print(x.shape)

>>> torch.Size([2, 3])
```

注：**`torch.empty()` 创建的张量虽然有确定的形状，但其元素数值是不确定的**。它可能包含内存中残留的数据，不能假设这些数据等于 0，也不能把它们当成有意义的随机数。

14. **.item()**
`.item()` 是 PyTorch 中非常常用的一个方法，用于**将只包含一个元素的张量（Tensor）转换成普通的 Python 数值**。例如，将 `tensor(3.14)` 转换成 Python 的浮点数 `3.14`。
```python
import torch

x = torch.tensor(3.14)

print(x)

>>> tensor(3.1400)

print(x.item())

>>> 3.140000104904175

print(type(x))

>>> <class 'torch.Tensor'>

print(type(x.item()))

>>> <class 'float'>
```
`torch.tensor(3.14)` 默认使用 `float32` 保存数值，所以转换成 Python 浮点数后，可能出现微小的精度差异。
15. **.view()**
`.view(*shape)` 是 PyTorch 中非常常用的张量方法，用于改变张量的形状（Shape），但不改变元素的数值和总数量。其中参数 `shape` 是目标形状。与 `.reshape()` 非常相似，主要区别在于 **`.view()` 要求张量的内存布局与目标形状兼容，而 `.reshape()` 在必要时可以复制数据**。
```python
import torch

x = torch.arange(12)
print(x)

>>> tensor([ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11])

print(x.shape)

>>> torch.Size([12])

y = x.view(3, 4)
print(y)

>>> tensor([[ 0,  1,  2,  3],
>>>         [ 4,  5,  6,  7],
>>>         [ 8,  9, 10, 11]])

print(y.shape)

>>> torch.Size([3, 4])
```

原来的张量有 12 个元素，变形后的张量仍然有 12 个元素。因此，必须满足 $\text{改变形状前的元素总数}=\text{改变形状后的元素总数}$。
16. **.expand()**
`expand(*sizes)` 是 PyTorch 中用于扩展张量形状的方法，**它可以把大小为 `1` 的维度扩展成指定大小，而且通常不需要复制数据，因此比 `repeat()` 更节省内存**。
```python
import torch

x = torch.tensor([[1, 2, 3]])
print(x.shape)

>>> torch.Size([1, 3])

y = x.expand(3, 3)
print(y)

>>> tensor([[1, 2, 3],
>>>         [1, 2, 3],
>>>         [1, 2, 3]])

print(y.shape)

>>> torch.Size([3, 3])
```
原来的张量 $X=\begin{bmatrix}1&2&3\end{bmatrix}$，使用 `expand(3, 3)` 后 $Y=\begin{bmatrix}1&2&3\\1&2&3\\1&2&3\end{bmatrix}$。可以理解为把原来的一行扩展成三行。
17. **.masked_fill()**
`.masked_fill(mask, value)` 是 PyTorch 中非常常用的张量方法，用于根据布尔掩码（Mask），将张量中指定位置的元素替换为某个数值。返回一个新的张量，原始张量不会被修改。

| 参数 | 含义 |
| --- | --- |
| `tensor` | 原始张量 |
| `mask` | 布尔掩码，`True` 表示需要替换 |
| `value` | 用来替换的数值 |
注：**核心规则：`mask=True` 的位置被替换，`mask=False` 的位置保持不变**。
```python
import torch

x = torch.tensor([1, 2, 3, 4, 5])
mask = torch.tensor([False, True, False, True, False])
y = x.masked_fill(mask, 0)

print(x)

>>> tensor([1, 2, 3, 4, 5])

print(mask)

>>> tensor([False, True, False, True, False])

print(y)

>>> tensor([1, 0, 3, 0, 5])
```

18. **.contiguous()**
`tensor.contiguous()` 是 PyTorch 中非常常用的张量方法，用于确保张量的数据在内存中按照连续的布局存储。它不需要传入参数，返回一个内存布局连续的张量。

注：
- 如果原张量已经连续，通常直接返回原张量。
- 如果原张量不连续，就复制数据并重新排列，使其在内存中连续。
- 不改变张量的形状，也不改变对应位置的元素值。

**什么叫内存连续？**
```python
import torch

x = torch.tensor([
    [1, 2, 3],
    [4, 5, 6]
])

print(x.is_contiguous())

>>> True

print(x.stride())

>>> (3, 1)
```
这里的 `is_contiguous()` 用来检查张量的内存是否连续。**`stride()` 表示在内存中沿某个维度移动一个位置，需要跨过多少个元素**。原张量：

| 第 1 列 | 第 2 列 | 第 3 列 |
| --- | --- | --- |
| 1 | 2 | 3 |
| 4 | 5 | 6 |
张量形状：`(2, 3)`。内存中的排列顺序 `1 → 2 → 3 → 4 → 5 → 6`。张量按行排列时，元素在内存中也是按照 1、2、3、4、5、6 的顺序存放的。
# 三、torch.nn（含 nn.Module 模型方法）

1. **nn.MSELoss()**
`nn.MSELoss()` 是 **PyTorch 的均方误差损失函数**，计算的是 $\text{MSE}=\frac{1}{n}\sum_{i=1}^{n}(y_i-\hat y_i)^2$，也就是**预测值和真实值的差，先平方，再取平均。**
```python
import torch
from torch import nn

loss = nn.MSELoss()

y_pred = torch.tensor([2.0, 4.0])
y_true = torch.tensor([1.0, 5.0])

print(loss(y_pred, y_true))

>>> tensor(1.)
```

计算：
- $(2-1)^2=1$
- $(4-5)^2=1$

平均：$\frac{1+1}{2}=1$

注：`reduction='none'` 的意思是**每个样本的损失都保留下来，不求平均，也不求和**。
```python
loss = nn.MSELoss(reduction='none')

y_pred = torch.tensor([2.0, 4.0])
y_true = torch.tensor([1.0, 6.0])

loss(y_pred, y_true)

>>> tensor([1., 4.])
```
- $(2-1)^2=1$
- $(4-6)^2=4$
所以直接保留 `[1, 4]`
规则：$\begin{cases} none → 不处理 \\ mean → 求平均 \\ sum  → 求和 \end{cases}$

2. **.parameters()**
`.parameters()` 是 PyTorch 中非常常用的方法，用于获取神经网络模型中所有已注册的可训练参数。它是 `torch.nn.Module` 类提供的方法，因此继承自 `nn.Module` 的神经网络都可以使用。
```python
import torch
from torch import nn

model = nn.Linear(3, 2)

for param in model.parameters():
    print(param)
```
可能输出：
```python
>>> Parameter containing:
>>> tensor([[ 0.1234, -0.2345,  0.3456],
>>>         [ 0.4567,  0.5678, -0.6789]], requires_grad=True)
>>> Parameter containing:
>>> tensor([0.1234, -0.2345], requires_grad=True)
```

2. **nn.Linear()**
`nn.Linear(输入维度, 输出维度)` 是 **PyTorch 里的全连接线性层**。它做的事情本质上是 $y=xW^T+b$。
```python
layer = nn.Linear(4, 8)
```
把一个 **4 维向量** 变成一个 **8 维向量**。例如输入 `[x1, x2, x3, x4]`，经过 `nn.Linear(4, 8)` 后，输出会有 8 个数。

4. **nn.Dropout()**
PyTorch 的 `torch.nn` 确实提供了两种 `Dropout` 接口 `nn.Dropout()与nn.functional.dropout()`。
- `nn.Dropout(p，inplace)` 是 **PyTorch 的 Dropout 层**，作用是训练时随机把一部分神经元输出变成 0，防止模型过拟合。
 > PyTorch 的 Dropout 在训练时会对保留下来的数值进行缩放，缩放公式 $x_{\text{保留后}}=\frac{x}{1-p}$。例如随机选择将第 1、3 个元素置零 $[1,2,3,4]\to[0,2,0,4]$，但 PyTorch 的 Dropout 还会把保留的元素除以 $1-p$，$\frac{1}{1-0.5}=2$，所以实际输出为 $[1,2,3,4]\to[0,4,0,8]$。乘以 2 是为了让 Dropout 输出的期望值与原输入相同，避免平均数值因随机置零而缩小。
>
 > 比如 p（随机失活概率）=0.5，则 `nn.Dropout(0.5)` 训练时大约随机丢掉 **50%** 的元素。
 > 比如 `inplace（是否原地操作）=False`，则**不直接修改输入张量，返回处理后的结果**。不传 `inplace` 时，默认是 `False`。
```python
import torch
from torch import nn

x = torch.ones(4)
dropout = nn.Dropout(p=0.5, inplace=False)
y = dropout(x)
print("x =", x)

>>> x = tensor([1., 1., 1., 1.])

print("y =", y)

>>> y = tensor([0., 2., 0., 2.])
```
`inplace=True`：直接修改原张量
```python
import torch
from torch import nn

x = torch.ones(4)
dropout = nn.Dropout(p=0.5, inplace=True)
y = dropout(x)
print("x =", x)

>>> x = tensor([0., 2., 0., 2.])

print("y =", y)

>>> y = tensor([0., 2., 0., 2.])
```
- `nn.functional.dropout()`相比 `nn.Dropout()`，主要多了一个显式的 `training` 参数，以及一个必填的 `input` 参数。
> `training` 可以直接控制是否启用随机失活。
```python
import torch
import torch.nn.functional as F

x = torch.ones(4)

y = F.dropout(x, p=0.5, training=True) # 启用 Dropout
z = F.dropout(x, p=0.5, training=False) # 关闭 Dropout
```
> `input` 是 `nn.functional.dropout()` 的输入张量参数，表示要对哪个张量执行 Dropout。
```python
import torch
import torch.nn.functional as F

x = torch.tensor([1.0, 2.0, 3.0, 4.0])
y = F.dropout(
    input=x,
    p=0.5,
    training=True
)
print(y)

>>> tensor([0., 4., 0., 8.])
```
这里 `input=x` 表示对张量 `x` 执行 Dropout。Python 支持两种传参方式：

| 写法                   | 名称      |
| -------------------- | ------- |
| `F.dropout(x)`       | 位置参数传递  |
| `F.dropout(input=x)` | 关键字参数传递 |
这里的 `attn_weights` 是经过 Softmax 得到的注意力权重张量，Dropout 会随机将其中部分权重置零，并对保留的权重进行缩放。

5. **attention.eval()**
`attention.eval()` 是 **PyTorch 模型的方法**，意思是**把模型切换到“评估模式 / 测试模式”**。这时候像 `nn.Dropout(...)` 就会停止随机丢弃神经元。
也就是说：
```python
训练时：Dropout 生效
eval() 后：Dropout 关闭
```
`attention.eval()` 与 `training=False` 两者都能关闭 Dropout，但控制的范围不同。
- `training=False`：只控制当前这一次 `F.dropout()` 调用。
- `attention.eval()`：将整个 `attention` 模块及其子模块切换到评估模式。

6. **nn.LayerNorm(...)**
`nn.LayerNorm(...)` 是**层归一化**：对一个样本内部的特征做归一化，让数值分布更稳定。参数表示**把多少个特征看成一组，放在一起做归一化**。
比如一个词元向量：
```python
[2, 4, 6, 8]
```
`LayerNorm` 就在这几个特征内部做归一化。
7. **nn.BatchNorm1d()**
`nn.BatchNorm1d(...)` 是**一维批量归一化**：对一个 batch 里，同一个特征在不同样本之间做归一化。参数表示**数据一共有多少种特征**。
```python
样本1：[1, 10]
样本2：[2, 20]
样本3：[3, 30]
```
它会分别对 `第1个特征：[1, 2, 3]`、`第2个特征：[10, 20, 30]` 做归一化。

8. **nn.Embedding()**
`nn.Embedding()` 是 **PyTorch 自带的词嵌入层**，作用是**把词元 ID（整数）转换成可以训练的向量**。 
```python
import torch
from torch import nn

embedding = nn.Embedding(3, 4) # 创建词嵌入层，词表大小为3，每个词元转换成4维向量
X = torch.tensor([0, 2]) # 输入两个词元ID
Y = embedding(X) # 将词元ID转换成向量

print(X.shape)

>>>torch.Size([2])

print(Y.shape)

>>> torch.Size([2, 4])
```
- 为什么需要 Embedding？
>假设有一句话 `我 喜欢 猫`，模型先把它们转换成词元 ID：`我 → 0`、`喜欢 → 1`、`猫 → 2`，但这些数字只是编号。例如，“猫”的编号是 `2`，“喜欢”的编号是 `1`，并不意味着“猫”比“喜欢”大两倍。因此，我们需要把每个词元转换成向量。
- `nn.Embedding()` 怎么工作？
```python
nn.Embedding(num_embeddings, embedding_dim)
```
>两个参数分别是：num_embeddings：词表大小，即有多少个不同的词元 ID、embedding_dim：每个词元转换成多少维的向量。
```python
embedding = nn.Embedding(3, 4)
```
>表示：**词表有 3 个词元，每个词元用 4 维向量表示**。PyTorch 会创建一个可以训练的嵌入矩阵，假设这个矩阵是：
>$E=\begin{bmatrix}0.1&0.2&0.3&0.4\\0.5&0.6&0.7&0.8\\0.9&1.0&1.1&1.2\end{bmatrix}$
>其中：
```text
第0行 → 词元0的向量
第1行 → 词元1的向量
第2行 → 词元2的向量
```
>当输入 `torch.tensor([0, 2])`，Embedding 就会取出第 0 行和第 2 行：
>$\begin{bmatrix}0.1&0.2&0.3&0.4\\0.9&1.0&1.1&1.2\end{bmatrix}$

**注：Embedding 本质上是查表，不是把整数直接代入公式计算。**

- Embedding 的向量是怎么来的？
>**Embedding 的向量不是人工提前规定的，而是模型通过训练学习出来的**。初始时，PyTorch 默认使用随机初始化的向量。例如：`猫 → [0.2, -0.8, 0.1, 0.5]`，经过训练，模型通过反向传播逐渐调整这些数值，让它们更适合当前任务。

9. **nn.ReLU()**
`nn.ReLU()` 是 **PyTorch 自带的激活层**，作用是**把小于 0 的数变成 0，大于等于 0 的数保持不变**。公式 $\operatorname{ReLU}(x)=\max(0,x)$。它主要作用是给神经网络**加入非线性**，否则连续多个 `Linear` 本质上仍然只是一个线性变换。
```python
import torch
from torch import nn

relu = nn.ReLU()
X = torch.tensor([-2.0, -1.0, 0.0, 2.0, 3.0])
print(relu(X))

>>> tensor([0., 0., 0., 2., 3.])
```

10. **add_module()**
`add_module(名字, 子模块)` 是 **PyTorch 自带的 `nn.Module` 方法**，作用是**给一个神经网络模块手动添加一个子模块，并给它起名字**。
```python
from torch import nn  

net = nn.Sequential()  
net.add_module(  
    "layer1",  
    nn.Linear(4, 8)  
)  
net.add_module(  
    "relu",  
    nn.ReLU()  
)  
print(net)

>>> Sequential(
  (layer1): Linear(in_features=4, out_features=8, bias=True)
  (relu): ReLU()
)
```

11. **nn.functional.softmax()**
`nn.functional.softmax(input, dim)` 是 PyTorch 中的 Softmax 函数，`input` 是输入张量、`dim` 是指定沿哪个维度进行 Softmax。作用是将一组原始分数转换为非负权重，使指定维度上的权重之和等于 1，$\operatorname{softmax}(x_i)=\frac{e^{x_i}}{\sum_{j=1}^{n}e^{x_j}}$。
其中：
- $x_i$：第 $i$ 个原始分数。
- $e$：自然常数，约等于 2.718。
- $n$：参与 Softmax 计算的元素个数。
```python
import torch
from torch import nn

x = torch.tensor([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0]
])

y = nn.functional.softmax(x, dim=-1)

print(y)

>>> tensor([[0.0900, 0.2447, 0.6652],
        [0.0900, 0.2447, 0.6652]])
```

12. **nn.init.normal_()**
`nn.init.normal_()` 是 PyTorch 中的一个参数初始化函数，用于按照正态分布（Normal Distribution）生成随机数，并填充到指定张量中。
```python
import torch
from torch import nn

x = torch.empty(2, 3)
nn.init.normal_(x, mean=0.0, std=0.01)

print(x)

>>> tensor([[ 0.0042, -0.0081,  0.0123],
>>>         [-0.0035,  0.0067, -0.0019]])

print(x.shape)

>>> torch.Size([2, 3])
```
- `tensor`：需要初始化的张量。
- `mean`：正态分布的均值，默认是 `0.0`。
- `std`：正态分布的标准差，默认是 `1.0`。

注：函数名称最后的 `_` 表示**原地操作**（In-place Operation），即**直接修改传入的张量**，而不是创建一个新的张量。

13. **nn.init.zeros_()**
`nn.init.zeros_()` 是 PyTorch 中的一个参数初始化函数，用于将指定张量中的所有元素设置为 0。
```python
import torch
from torch import nn

x = torch.randn(2, 3)
print(x)

>>> tensor([[ 0.2341, -1.2354,  0.4521],
>>>         [ 1.3245,  0.2345, -0.6721]])

nn.init.zeros_(x)
print(x)

>>> tensor([[0., 0., 0.],
>>>         [0., 0., 0.]])
```
- `nn.init`：PyTorch 提供的参数初始化模块。
- `zeros_()`：将张量中的所有元素设置为 0。
- `tensor`：需要初始化的张量。

14. **nn.Sequential()**
`nn.Sequential(网络层1, 网络层2, 网络层3, ...)` 是 **PyTorch 自带的神经网络容器类**，作用是**把多个神经网络层按顺序组合起来，输入数据后依次执行这些层**。
```python
import torch
from torch import nn

net = nn.Sequential( # 创建神经网络
    nn.Linear(4, 8),
    nn.ReLU(),
    nn.Linear(8, 2)
)
X = torch.ones((3, 4)) # 输入数据
Y = net(X) # 前向传播

print(Y.shape)

>>> torch.Size([3, 2])
```
这里的数据变化是 $4维\rightarrow8维\rightarrow\operatorname{ReLU}\rightarrow2维$

15. **nn.ModuleList()**
`nn.ModuleList(modules=None)` 是 PyTorch 中非常常用的一个神经网络模块容器，用于将多个神经网络层存放在一起，并让 PyTorch 自动管理这些层的参数。

参数说明：

| 参数        | 含义                      |
| --------- | ----------------------- |
| `modules` | 需要存放的神经网络模块，可以是列表等可迭代对象 |
| `None`    | 默认创建一个空的模块容器            |
```python
import torch
from torch import nn

layers = nn.ModuleList([
    nn.Linear(10, 20),
    nn.Linear(20, 30),
    nn.Linear(30, 5)
])

print(layers)

>>> ModuleList(
>>>   (0): Linear(in_features=10, out_features=20, bias=True)
>>>   (1): Linear(in_features=20, out_features=30, bias=True)
>>>   (2): Linear(in_features=30, out_features=5, bias=True)
>>> )

print(len(layers))

>>> 3

print(layers[0])

>>> Linear(in_features=10, out_features=20, bias=True)
```

注：与 nn.Sequential() 区别

| 特性            | `nn.ModuleList()` | `nn.Sequential()` |
| ------------- | ----------------- | ----------------- |
| 保存多个网络层       | 可以                | 可以                |
| 自动注册参数        | 可以                | 可以                |
| 支持索引访问        | 可以                | 可以                |
| **自动依次执行网络层** | 不可以               | 可以                |
| 需要自己编写执行逻辑    | 是                 | 通常不需要             |
| 适合复杂模型        | 更灵活               | 适合顺序结构            |

16. **nn.CrossEntropyLoss()**
`nn.CrossEntropyLoss()` 是 PyTorch 中非常常用的交叉熵损失函数（Cross-Entropy Loss），主要用于分类任务，衡量神经网络预测结果与真实类别之间的差距。
```python
import torch
from torch import nn

loss_fn = nn.CrossEntropyLoss()
loss = loss_fn(input, target)
```
整个过程分为两步：

1. `nn.CrossEntropyLoss()`：创建一个损失函数对象。
2. `loss_fn(input, target)`：调用损失函数，计算预测结果与真实标签之间的损失。两个主要参数：

| 参数       | 含义                       | 常见形状                        |
| -------- | ------------------------ | --------------------------- |
| `input`  | 模型输出的原始得分（Logits，未归一化得分） | `(batch_size, num_classes)` |
| `target` | 每个样本的真实类别索引              | `(batch_size,)`             |
注：**通常直接传入模型输出的 Logits，不需要提前使用 Softmax。**

假设有两个样本，每个样本需要从三个类别中选择一个。
```python
import torch
from torch import nn

logits = torch.tensor([ # 第一步：模型输出的原始得分
    [2.0, 1.0, 0.1],
    [0.5, 2.5, 0.3]
])
target = torch.tensor([0, 1]) # 第二步：真实类别索引
loss_fn = nn.CrossEntropyLoss() # 第三步：创建交叉熵损失函数
loss = loss_fn(logits, target) # 第四步：计算损失

print(logits.shape)

>>> torch.Size([2, 3])

print(target.shape)

>>> torch.Size([2])

print(loss)

>>> tensor(0.3185)

print(loss.item())

>>> 0.3185397684574127
```
逐行理解：

- `logits`：模型给两个样本各输出三个类别的得分。
- `target = [0, 1]`：第一个样本的正确类别是 0，第二个样本的正确类别是 1。
- `nn.CrossEntropyLoss()`：创建损失函数。
- `loss_fn(logits, target)`：计算两个样本的平均交叉熵损失。
- `loss.item()`：把损失张量转换成普通 Python 数值。

注：**交叉熵损失怎么算**

以第一个样本为例 `logits = torch.tensor([2.0, 1.0, 0.1])` 模型给三个类别的原始得分分别为 2.0、1.0 和 0.1。

**第一步，利用 Softmax 将得分转换成概率**：$p_i=\frac{e^{z_i}}{\sum_j e^{z_j}}$，得到大约 $p=[0.659,\ 0.242,\ 0.099]$。
第一个样本的预测概率：

| 类别 | 预测概率 |
| --- | --- |
| 类别 0（正确） | 65.9% |
| 类别 1 | 24.2% |
| 类别 2 | 9.9% |
**第二步，计算正确类别的负对数概率**：$L=-\log(p_{\text{正确类别}})$，第一个样本的真实类别是 0，因此 $L_1=-\log(0.659)\approx0.417$；同理，第二个样本的真实类别为 1，得到 $L_2\approx0.220$。

**最后，对两个样本取平均**：$L=\frac{L_1+L_2}{2}\approx0.3185$。这就是默认 `nn.CrossEntropyLoss()` 计算出来的损失。**正确类别的预测概率越大，交叉熵损失越小。**
# 四、其他
1. **对象[下标]**
`对象[下标]` 是 **Python 的索引语法**，表示从一个对象里，取指定位置的元素。`函数(...)[0]` = **先执行函数，再对函数返回结果做 `[0]` 索引。**
```python
a = [10, 20, 30]
print(a[0])

>>> 10
```
2. **隐藏维度**（Hidden Size）就是模型用多少个数字来表示一个 Token。假设输入一句话，经过分词器后得到 128 个 Token。GPT-2 会把每个 Token 转换成一个包含 768 个数字的向量。例如，第一个 Token $x_1=[0.12,\ 0.35,\ -0.21,\ \ldots,\ 0.67]$。所以：
- 128：有多少个 Token。
- 768：每个 Token 用多少个数字表示。
整个隐藏状态矩阵就是 $X:(128,768)$。
