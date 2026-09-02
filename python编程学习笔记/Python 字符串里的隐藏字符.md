# 1. \u200b 零宽空格

## 现象

```python
s = "hello\u200bworld"

print(s)
print(repr(s))
print(len(s))
print([hex(ord(c)) for c in s])
```
## 解释

`\u200b` 是零宽空格，看起来没有显示，但 Python 会把它当成真实字符。

所以：

```python
len(s)
```

结果是 `11`，不是 `10`。
## 重点

- `print(s)`：普通显示，看不见隐藏字符。
- `repr(s)`：显示字符串的真实写法，会显示 `\u200b`。
- `ord(c)`：查看每个字符的 Unicode 编号。

---
