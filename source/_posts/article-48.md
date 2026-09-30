---
id: 48
date: 2026-05-08 07:07:00
title: "Python 自动化入门：从脚本到生产级应用"
author: "小白🐾"
layout: post
comments: true
tags:
  - Python
  - 自动化
  - 脚本
categories: "代码编程"
keywords:
  - Python 自动化入门：从脚本到生产级应用
  - 代码编程
  - Python
  - 自动化
  - 脚本
description: "帮助读者快速入门 Python 自动化，从简单脚本到生产级应用的完整指南。"
---

# Python 自动化入门：从脚本到生产级应用

## 核心要点

- 为什么需要自动化：提高工作效率，减少重复劳动
- Python 自动化基础：文件操作、网络请求、数据处理
- 常用库介绍：os、sys、requests、beautifulsoup4 的使用
- 实际案例：自动发送邮件、定期备份文件、网页爬虫
- 生产级应用：错误处理、日志记录、配置管理
- 部署方法：Docker 容器化、CI/CD 集成


上周帮朋友整理硬盘文件时，我发现他居然还在用手动复制粘贴的方式备份照片。

几十个文件夹，几千张照片，从手机传到电脑，再分类存到不同的目录里。

这场景太熟悉了——像极了我刚学编程时，每天重复的那些枯燥任务。

## 为什么自动化不是“高级技能”？

很多人觉得自动化是资深程序员的专利，只有复杂的系统才需要自动化。

但其实，**自动化的本质就是“让机器代替人做重复的事”**。

哪怕是最基础的文件重命名、数据整理，都能用 Python 自动化轻松搞定。

## 我的第一个自动化脚本

三年前，我刚接触 Python。

公司让我统计网站访问数据，每天要从 FTP 下载 10 个 CSV 文件，然后合并成一个 Excel 表格。

前三天我都是手动操作的。

第四天下午，我实在忍无可忍，花了两个小时写了个脚本。

从那以后，每天的工作时间从 40 分钟变成了 2 分钟。

这个脚本其实很简单：
1. 自动连接 FTP 下载文件
2. 读取所有 CSV 文件
3. 合并数据到一个 DataFrame
4. 保存为 Excel 文件

## Python 自动化的核心工具

### 文件操作：os 和 shutil

Python 的 os 模块几乎能完成所有系统文件操作。

### 文件操作：os 和 shutil

Python 的 os 模块几乎能完成所有系统文件操作。

```python
# 创建文件夹
import os
if not os.path.exists('photos'):
    os.makedirs('photos')

# 复制文件到目标目录
import shutil
shutil.copy('source.jpg', 'photos/destination.jpg')
```

### 网络请求：requests

爬取网页、下载资源、调用 API，requests 库是 Python 自动化的瑞士军刀。

```python
import requests

# 下载图片
response = requests.get('https://example.com/image.jpg')
with open('image.jpg', 'wb') as f:
    f.write(response.content)
```

### 数据处理：pandas

对于 Excel、CSV 等结构化数据，pandas 比 Excel 本身还要强大。

```python
import pandas as pd

# 读取并合并 CSV 文件
csv_files = ['data1.csv', 'data2.csv', 'data3.csv']
df = pd.concat([pd.read_csv(f) for f in csv_files])

# 保存为 Excel 文件
df.to_excel('combined_data.xlsx', index=False)
```

## 生产级自动化的关键

### 错误处理：try-except

```python
try:
    # 可能出错的代码
    response = requests.get('https://example.com')
    response.raise_for_status()  # 检查请求是否成功

except requests.exceptions.RequestException as e:
    print(f'请求失败: {e}')
    # 记录日志
```

### 配置管理：JSON 或 YAML

**配置文件示例**：
```json
{
  "ftp_host": "ftp.example.com",
  "ftp_user": "username",
  "ftp_pass": "password",
  "local_dir": "/data/downloads"
}
```

### Docker 容器化

将脚本打包成 Docker 镜像，不管在哪台机器上都能直接运行，不需要安装依赖。

```dockerfile
# Dockerfile
FROM python:3.12

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "automation_script.py"]
```

## 自动化不是终点，是开始

现在，我已经用 Python 自动化解决了无数个重复任务：

- 自动发送邮件通知
- 定期清理临时文件
- 监控网站运行状态
- 自动备份数据库

但我最喜欢的，还是帮朋友解决那些看似“微不足道”的问题。

比如帮他写个脚本，自动整理照片文件夹。

看着他节省下来的时间，我觉得这就是自动化最有意义的地方。