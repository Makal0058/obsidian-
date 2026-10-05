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
>>>torch.Size([2, 10, 8])

>>>print(keys.transpose(1, 2).shape)
>>>torch.Size([2, 8, 10])
```
8. **permute()**
`permute(新的维度顺序)` 是 **PyTorch 张量的方法**，作用是**按照指定的顺序，重新排列张量的各个维度**。`transpose()` 只能交换两个维度；`permute()` 可以一次重新排列所有维度。
```python
print(X.shape)

>>>torch.Size([2, 4, 5, 20])

X = X.permute(0, 2, 1, 3)
print(X.shape)

>>>torch.Size([2, 5, 4, 20])
```
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
2. **net.parameters()**
`net.parameters()` 作用是**取出模型里所有需要训练的参数**。
3. **nn.Linear()**
`nn.Linear(输入维度, 输出维度)` 是 **PyTorch 里的全连接线性层**。它做的事情本质上是 $y=xW^T+b$。
```python
layer = nn.Linear(4, 8)
```
把一个 **4 维向量** 变成一个 **8 维向量**。例如输入 `[x1, x2, x3, x4]`，经过 `nn.Linear(4, 8)` 后，输出会有 8 个数。
4. **nn.Dropout()**
`nn.Dropout()` 是 **PyTorch 的 Dropout 层**。作用是训练时，随机把一部分神经元输出变成 0，防止模型过拟合。
比如 `nn.Dropout(0.5)` 表示训练时大约随机丢掉 **50%** 的元素。
5. **attention.eval()**
`attention.eval()` 是 **PyTorch 模型的方法**，意思是**把模型切换到“评估模式 / 测试模式”**。这时候像 `nn.Dropout(...)` 就会停止随机丢弃神经元。

也就是说：
```python
训练时：Dropout 生效
eval() 后：Dropout 关闭
```

