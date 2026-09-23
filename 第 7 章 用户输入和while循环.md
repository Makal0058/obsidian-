```table-of-contents
```
# 一、方法
1. **input()**
函数 `input()` 让程序暂停运行，等待用户输入一些文本。获取用户输入后，Python 将其存储在一个变量中，以方便你使用。

函数 `input()` **接受一个参数**，即要向用户显示的提示或说明，让用户知道该如何做。
```python
message = input("Tell me something, and I will repeat it back to you: ")
print(message)

>>>Tell me something, and I will repeat it back to you:
```

例如用户输入：
```python
Hello everyone!
```

最终显示：
```python
message = input("Tell me something, and I will repeat it back to you: ")
print(message)

>>>Tell me something, and I will repeat it back to you:

Tell me something, and I will repeat it back to you: Hello everyone!

>>>Hello everyone!
```
2. **int()**
函数 `int()` 让 Python 将输入视为数值，将数字的字符串表示转换为数值表示。
```python
age = input("How old are you? ")

>>>How old are you? 

How old are you? 21

age = int(age)
print(age >= 18)

>>>True
```

注：`input()` 得到的内容默认是字符串。

3. 
# 二、笔记
## 2.1 求模运算符 `%`

作用是两个数相除，返回**余数**。
```python
4 % 3

>>>1
```
## 2.2 `+=` 拼接字符串
`字符串 A += 字符串 B` 的意思就是把字符串 B 接到原来的 字符串 A 后面。
```python
prompt += "\nEnter 'quit' to end the program. "
prompt = prompt + "\nEnter 'quit' to end the program. "
```
效果一样
## 2.3 哨兵值

哨兵值是**专门用来告诉程序“该停了”的特殊值。**
```python
while message != 'quit':
```

意思是：

> 只要 `message` 还不等于 `'quit'`，就一直循环。

每一轮：

```python
message = input(prompt)
```

让用户输入内容，然后：

```python
print(message)
```

把用户输入的内容再打印出来。

比如你输入：

```text
hello
```

程序会打印：

```text
hello
```

然后继续问。

直到你输入：

```text
quit
```

循环条件：

```python
message != 'quit'
```

就变成：

```python
False
```

下一轮就不再继续了。

不过这段代码有一个小问题：**输入 `quit` 时，它还是会先打印一次 `quit`，然后才结束。**

您现在笔记里可以记：

> `+=`：在原变量基础上继续追加内容。  
> `while 条件:`：只要条件为 `True`，就不断重复执行代码。