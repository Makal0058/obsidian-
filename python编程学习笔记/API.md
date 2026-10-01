```table-of-contents
```
# 一、方法
1. **.get()**
`.get()` 是 `requests` 库提供的方法，用来向指定网址发送一个 GET 请求，也就是“去这个地址拿数据”。
```python
import requests

# 执行API调用并存储响应
url = 'https://api.github.com/search/repositories?q=language:python&sort=stars'
r = requests.get(url)
print("Status code:", r.status_code)

# 将API响应存储在一个变量中
response_dict = r.json()

# 处理结果
print(response_dict.keys())
```
- `.status_code` 是响应对象 `r` 的一个属性，用来告诉你这次网络请求结果怎么样。
- `q` 是 URL 查询参数名，通常是 **query（查询）** 的缩写。比如`https://api.github.com/search/repositories?q=language:python&sort=stars` 可以拆成 `q=language:python`。意思是查询条件是：编程语言为 Python。

所以这里：
- `?`：开始写查询参数
- `q=...`：查询内容
- `&`：分隔多个参数
- `sort=...`：另一个参数
# 二、笔记
## 2.1 状态码
**状态码（status code）是服务器对一次网络请求返回的“结果编号”**。
- 常见状态码：
```text
200：成功
404：网址对应的资源不存在
403：没有权限访问
401：需要认证
429：请求太频繁
500：服务器内部出错
```

大规律：
```text
2xx → 成功
3xx → 跳转
4xx → 请求方这边有问题
5xx → 服务器这边有问题
```
## 2.2 URL
全称是 **Uniform Resource Locator**，统一资源定位符。  
