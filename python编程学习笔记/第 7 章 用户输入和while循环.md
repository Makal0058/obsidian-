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
prompt = "\nTell me something, and I will repeat it back to you:"
prompt += "\nEnter 'quit' to end the program. "

message = ""
while message != 'quit':
    message = input(prompt)

    if message != 'quit':
        print(message)

Tell me something, and I will repeat it back to you:
Enter 'quit' to end the program. Hello everyone!

>>>Hello everyone!

Tell me something, and I will repeat it back to you:
Enter 'quit' to end the program. quit
```
注：`!=` 判断是否**不等于**。
## 2.4 break
要**立即退出 while 循环**，不再运行循环中余下的代码，也不管条件测试的结果如何，可使用 break 语句。
## 2.5 continue
要返回到循环开头，并**根据条件测试结果决定是否继续执行循环**，可使用 `continue` 语句。
```python
current_number = 0

while current_number < 10:
    current_number += 1

    if current_number % 2 == 0:
        continue

    print(current_number)

>>>1
>>>3
>>>5
>>>7
>>>9
```

注：
- `continue`：跳过**本轮循环剩下的代码**，直接进入下一轮。  
- `break`：直接结束**整个循环**。

如果程序陷入无限循环，可按 **Ctrl + C**，也可关闭显示程序输出的终端窗口


