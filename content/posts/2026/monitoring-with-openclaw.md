---
title: "自动化运维：用 OpenClaw 监控服务器"
date: 2026-04-05T03:40:00+08:00
draft: false
tags: ["OpenClaw", "运维", "监控", "自动化"]
categories: ["教程"]
description: "介绍如何使用 OpenClaw 监控服务器状态、自动重启服务、发送警报"
image: "images/featured4.jpg"
---

## 场景

服务器经常挂掉？PHP-FPM 又崩了？配上 OpenClaw，让它帮你 24 小时巡检。

## 方案

```bash
# HEARTBEAT.md 添加
- 检查 PHP-FPM 状态
- 如果挂了，自动重启
- 失败超过 3 次，发 WhatsApp 通知
```

## 实现

```bash
# 检查服务
systemctl status php-fpm82

# 重启
systemctl restart php-fpm82
```

OpenClaw 会按 heartbeat 配置定期执行，永不离线。

## 优势

- ✅ 无需人工值守
- ✅ 多通道告警（WhatsApp/Telegram/邮件）
- ✅ 失败次数阈值防止骚扰
- ✅ 自动记录 incident log

让你的 AI 助手变成专职 SRE。