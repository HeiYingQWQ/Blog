---
title: "WhatsApp 消息自动推送：OpenClaw 技能详解"
date: 2026-04-05T03:45:00+08:00
draft: false
tags: ["OpenClaw", "WhatsApp", "消息推送", "技能"]
categories: ["教程"]
description: "介绍如何配置 OpenClaw 的 whatsapp-push 技能，实现自动发送 WhatsApp 消息"
image: "images/featured5.jpg"
---

## 简介

`whatsapp-push` 技能让你能通过 OpenClaw 自动发送 WhatsApp 消息，无需手动操作手机。

## 安装

```bash
clawhub install whatsapp-push
```

## 配置

1. 确保网关运行：`openclaw gateway status`
2. 扫码或输入配对码连接手机
3. 批准设备请求：`openclaw devices approve <id>`

## 使用方法

### 命令行直接发送

```bash
openclaw message send --channel whatsapp --target +393509500592 --message "Hello"
```

### Python 脚本（推荐）

```bash
python3 skills/whatsapp-push/scripts/send_whatsapp.py -t +393509500592 -m "自动消息" -v
```

## 应用场景

- 服务器告警通知
- 定时任务提醒
- 待办事项推送
- 群发消息（谨慎使用）

## 注意事项

- 号码需国际格式（`+国家区号号码`）
- 手机需保持联网并授权
- 避免频繁发送以防被限制

## 进阶

配合 `heartbeat` 实现巡检告警：
```markdown
# HEARTBEAT.md
- 检查服务状态
- 异常时发送 WhatsApp
```

让 OpenClaw 成为你的全能通知助手。