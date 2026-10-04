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
5. **repeat()**
`repeat()`：**重复整个张量 / 整块复制**，形式是 `张量.repeat(第0维重复次数, 第1维重复次数, 第2维重复次数, ...)`，也可以把这些数字写成一个元组 `张量.repeat((2, 3))` 和 `张量.repeat(2, 3)` 是一样的。
```python
x_train = [1, 2, 3]
n_train = 3

X_tile = x_train.repeat((n_train, 1))
````
则 $X_{\text{tile}}=\begin{bmatrix}1&2&3\\1&2&3\\1&2&3\end{bmatrix}$，形状 `[3, 3]`。也就是把 `x_train` **复制 3 行**。  
5. **repeat_interleave()**
`torch.repeat_interleave()`：把每个元素重复若干次。
```python
import torch

x = torch.tensor([1, 2, 3])
y = torch.repeat_interleave(x, 2)

print(y)

>>>tensor([1, 1, 2, 2, 3, 3])
```
也就是每个元素重复 2 次。
6. **mean()**
`.mean()`：求 Tensor 平均值。
```python
import torch

x = torch.tensor([1.0, 2.0, 3.0])

print(x.mean())

>>>tensor(2.)
```
7. **matmul（）**
`matmul`：**矩阵乘法**。
```python
y_hat = torch.matmul(A, B)
```
8. **unsqueeze(dim)**
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
9. **torch.bmm()**
`torch.bmm()` 一次性对一批矩阵分别做矩阵乘法。

普通矩阵乘法是 `torch.matmul(A, B)`，而 bmm 专门处理这种三维张量 `A.shape = (batch, m, n)`、`B.shape = (batch, n, p)`，那么 `torch.bmm(A, B)` 输出 `(batch, m, p)`，也就是每个 batch 单独算 `A_iB_i`
10. **.type(torch.bool)**
`.type(torch.bool)` 作用是：**把张量的数据类型转换成布尔类型 `bool`**。
```python
x = torch.tensor([0, 1, 2])
x.type(torch.bool)

>>>tensor([False, True, True])
```
规则：$\begin{cases} 0 → False \\ 非 0 → True \end{cases}$
11. **nn.MSELoss()**
`nn.MSELoss()` 是 **PyTorch 的均方误差损失函数**，计算的是 $\text{MSE}=\frac{1}{n}\sum_{i=1}^{n}(y_i-\hat y_i)^2$，也就是**预测值和真实值的差，先平方，再取平均。**
```python
import torch
from torch import nn

loss = nn.MSELoss()

y_pred = torch.tensor([2.0, 4.0])
y_true = torch.tensor([1.0, 5.0])

print(loss(y_pred, y_true))

>>>tensor(1.)
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

>>>tensor([1., 4.])
```
- $(2-1)^2=1$
- $(4-6)^2=4$
所以直接保留 `[1, 4]`
规则：$\begin{cases} none → 不处理 \\ mean → 求平均 \\ sum  → 求和 \end{cases}$
12. **net.parameters()**
`net.parameters()` 作用是**取出模型里所有需要训练的参数**。
13. **.reshape （）**
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
14. **nn.Linear()**
`nn.Linear(输入维度, 输出维度)` 是 **PyTorch 里的全连接线性层**。它做的事情本质上是 $y=xW^T+b$。
```python
layer = nn.Linear(4, 8)
```
把一个 **4 维向量** 变成一个 **8 维向量**。例如输入 `[x1, x2, x3, x4]`，经过 `nn.Linear(4, 8)` 后，输出会有 8 个数。
15. **nn.Dropout()**
`nn.Dropout()` 是 **PyTorch 的 Dropout 层**。作用是训练时，随机把一部分神经元输出变成 0，防止模型过拟合。
比如 `nn.Dropout(0.5)` 表示训练时大约随机丢掉 **50%** 的元素。
16. あるじさま，`.squeeze()` 是 **PyTorch 张量的方法**。🌿

作用是：

> **删除张量里所有长度为 1 的维度。**

比如：

```python
x = torch.randn(1, 3, 1, 5)
print(x.shape)
# torch.Size([1, 3, 1, 5])
```

执行：

```python
y = x.squeeze()
print(y.shape)
# torch.Size([3, 5])
```

因为原来：

```python
[1, 3, 1, 5]
 ↑     ↑
这两个维度大小都是 1
```

所以 `.squeeze()` 会把它们删掉，变成：

```python
[3, 5]
```

一句话记：

> **`.squeeze()` = 删除所有大小为 1 的维度。**


あるじさま，`.squeeze()` 括号里的参数表示：

> **指定要删除哪一个维度。**

比如：

```
x.squeeze(0)
```

表示：

> 删除第 `0` 维，但前提是这一维的大小必须是 `1`。

例如：

```
x.shape# torch.Size([1, 3, 5])
```

执行：

```
x.squeeze(0)
```

变成：

```
torch.Size([3, 5])
```

再比如：

```
x.squeeze(-1)
```

这里：

```
-1
```

表示 **最后一个维度**。

所以如果：

```
x.shape# torch.Size([2, 3, 1])
```

那么：

```
x.squeeze(-1)
```

变成：

```
torch.Size([2, 3])
```

直接记：

```
squeeze()      → 删除所有大小为1的维度
squeeze(0)     → 只尝试删除第0维
squeeze(1)     → 只尝试删除第1维
squeeze(-1)    → 只尝试删除最后一维
```

而且**指定的那个维度如果不是 1，就不会被删掉**。
