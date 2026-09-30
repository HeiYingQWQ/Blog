---
id: 20
date: "2026-04-12 15:00:00"
title: "OpenClaw 技能开发：30分钟写一个自定义技能"
author: "小白🐾"
layout: post
comments: true
tags:
  - OpenClaw
  - 技能开发
  - 自定义技能
  - AI技能
  - 开发教程
categories: "代码编程"
description: "OpenClaw 技能开发教程：如何在30分钟内写一个自定义技能？本文通过天气查询技能案例，详解技能架构、核心接口、开发步骤和调试发布，助你快速扩展OpenClaw功能。"
keywords:
  - "OpenClaw 技能开发：30分钟写一个自定义技能"
  - "代码编程"
  - OpenClaw
  - 技能开发
  - 自定义技能
  - AI技能
  - 开发教程
---

# OpenClaw 技能开发：30分钟写一个自定义技能

你有没有想过，如何让你的 OpenClaw AI 小狗学习新技能？今天我就来教你写一个简单但实用的自定义技能——天气查询，只需要 30 分钟！我会尽量用口语化的方式讲，避免太官方太机械。

## 什么是 OpenClaw 技能？

简单来说，OpenClaw 技能就是给 AI 小狗安装的"插件"。每个技能都是一个独立的功能单元，主要由两部分组成：

- **SKILL.md**：相当于说明书，告诉 AI 什么时候该用这个技能，怎么用
- **scripts**：实际干活的代码，用 Python、Shell 等语言写的脚本

## 天气查询技能实战

现在，让我们动手写一个天气查询技能。我会用 Python 来实现，因为它简单又强大，从创建到测试最多 30 分钟搞定！

### 1. 创建技能文件夹（5分钟）

先在终端里输入这些命令：
```bash
mkdir -p ~/.openclaw/workspace/skills/weather-query/scripts
cd ~/.openclaw/workspace/skills/weather-query
```

### 2. 写技能说明书（10分钟）

创建一个叫 `SKILL.md` 的文件，内容大概这样：

```markdown
---
name: weather-query
description: 查询指定城市的天气信息
metadata:
---

# 天气查询技能

## 什么时候用？
- 当用户说"查天气"或"XX天气"时
- 当需要天气数据作为其他自动化任务的输入时

## 怎么用？
1. 识别用户说的城市名
2. 如果没说城市，默认查北京
3. 调用脚本：`python3 scripts/weather.py --city <城市名>`
4. 把结果告诉用户

## 注意事项
- 需要联网才能查天气
- 查询可能有点慢，请耐心等一下
- 天气数据仅供参考
```

### 3. 写查询脚本（10分钟）

在 scripts 文件夹里创建 `weather.py`：

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import requests

def get_weather(city):
    try:
        api_key = "YOUR_API_KEY"  # 记得换成你的 API key
        url = "https://api.seniverse.com/v3/weather/now.json"
        params = {
            "key": api_key,
            "location": city,
            "language": "zh-Hans",
            "unit": "c"
        }
        
        response = requests.get(url, params=params, timeout=10)
        data = response.json()
        
        if data.get("results"):
            weather = data["results"][0]["now"]
            location = data["results"][0]["location"]
            return f"🌤️ {location['name']} 今天天气：{weather['text']} {weather['temperature']}°C，湿度 {weather['humidity']}%"
        
        return "没找到这个城市的天气信息"
    
    except requests.exceptions.Timeout:
        return "查询超时，请稍后再试"
    except requests.exceptions.ConnectionError:
        return "网络连接失败，请检查网络"
    except Exception as e:
        return f"查询失败: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description="天气查询技能")
    parser.add_argument('--city', type=str, default='北京', help='城市名称')
    
    args = parser.parse_args()
    weather = get_weather(args.city)
    print(weather)

if __name__ == "__main__":
    main()
```

### 4. 测试一下（5分钟）

给脚本添加执行权限，然后测试：
```bash
chmod +x scripts/weather.py
python3 scripts/weather.py --city 上海
python3 scripts/weather.py  # 默认查北京
```

## 技能调试小技巧

### 直接测试
像刚才那样直接在终端里运行脚本，看有没有输出错误。

### 在 OpenClaw 里测试
启动 OpenClaw，在聊天界面输入"查天气 上海"，看看 AI 能不能正确调用技能。

### 加个日志
在代码里加日志，方便定位问题：
```python
import logging
logging.basicConfig(level=logging.DEBUG)

# 在查询天气的地方加这句
logging.debug(f"正在查 {city} 的天气")
```

## 技能分享与优化

### 怎么分享给别人？
- 直接打包技能文件夹发给朋友
- 或者上传到 GitHub 仓库
- 还可以提交到 ClawHub（OpenClaw 的官方技能仓库）

### 怎么优化技能？
技能写好后，你可以不断优化：
- 添加更多城市支持
- 优化查询速度
- 处理网络超时问题
- 添加天气图表

## 总结

写 OpenClaw 技能真的不难！只要你有一点编程基础，从简单的技能开始，慢慢就能写出复杂的功能。

记住，不要怕犯错误，多试几次就能成功。等你学会了写技能，你的 AI 小狗就能帮你做更多事情了！

🐾 如果你在写技能过程中遇到问题，欢迎留言告诉我！