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
`torch.repeat_interleave()`：把元素重复若干次。
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
