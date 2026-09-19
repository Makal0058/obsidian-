```table-of-contents
```
# 一、方法
1. lower（）
函数`lower()` 是把字符串里的英文字母全部转换成小写，函数 `lower()` 不会修改存储在变量 `car` 中的值。
```python
car = 'Audi'

print(car.lower() == 'audi')

>>>True

print(car)

>>>Audi
```
# 二、笔记
## 2.1 条件测试

每条 if 语句的核心都是一个值为 True 或 False 的表达式，这种表达式被称为**条件测试**。

Python 根据**条件测试的值为 True 还是 False** 来决定是否执行 if 语句中的代码。如果条件测试的值为 True，Python 就执行紧跟在 if 语句后面的代码；如果为 False，Python 就忽略这些代码。
## 2.2 检查是否不相等

要判断两个值是否不等，可结合使用惊叹号和等号 `!=`，其中的**惊叹号表示不**，在很多编程语言中都如此。
```python
requested_topping = 'mushrooms'

if requested_topping != 'anchovies':
    print("Hold the anchovies!")
    
>>>Hold the anchovies!
```
## 2.3 if-else 语句

经常需要在条件测试通过了时执行一个操作，并在没有通过时执行另一个操作；在这种情况下，可使用 Python 提供的 if-else 语句。

if-else 语句块类似于简单的 if 语句，但其中的 else 语句让你能够指定条件测试未通过时要执行的操作。
```python
age = 17

if age >= 18:
    print("You are old enough to vote!")
else:
    print("Sorry, you are too young to vote.")
   
>>>Sorry, you are too young to vote.
```
## 2.4 if-elif-else 结构

经常需要检查超过两个的情形，为此可使用 Python 提供的 if-elif-else 结构。

Python 只执行 if-elif-else 结构中的一个代码块，它依次检查每个条件测试，直到遇到通过了的条件测试。测试通过后，Python 将执行紧跟在它后面的代码，并跳过余下的测试。
```python
age = 12

if age < 4:
    print("Your admission cost is $0.")
elif age < 18:
    print("Your admission cost is $5.")
else:
    print("Your admission cost is $10.")

>>>Your admission cost is $5.
```
`elif` 代码行其实是另一个 if 测试，它仅在前面的测试未通过时才会运行，可根据需要使用任意数量的 `elif` 代码块。