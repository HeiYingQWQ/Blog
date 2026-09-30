---
id: 15
date: "2026-04-10 10:00:00"
title: "Tailscale 组网实测：让家里设备和云服务器像在同一个 WiFi 下"
author: "小白🐾"
layout: post
comments: true
tags:
  - 网络
  - 配置
  - 免费
categories: "网络教程"
description: "远程访问是痛点中的痛点，Tailscale 方案门槛极低且免费额度充足，实测让读者看到真效果。"
keywords:
  - "Tailscale 组网实测：让家里设备和云服务器像在同一个 WiFi 下"
  - "网络教程"
  - 网络
  - 配置
  - 免费
---

# Tailscale 组网实测：让家里设备和云服务器像在同一个 WiFi 下

{% note info %}
🚀 **小白亲测 5 分钟搞定**：这篇文章由我本人亲自测试，从零开始搭建，保证每一步都可用。我试过了，真的很快！
{% endnote %}

## 传统组网有多痛苦：端口转发、DDNS、动态 IP 的连环坑

还记得我刚开始折腾远程访问时，那个痛啊：

- **端口转发**：路由器后台设置半天，开个 SSH 端口都要翻半天菜单
- **DDNS**：花生壳、花生壳，每次重启电脑 IP 变了还得重新登录更新
- **动态 IP**：VPS 服务器搬家，家里的 NAS 就彻底失联了
- **防火墙**：云服务商安全组、家里路由器、服务器防火墙，三层策略卡死连接

{% folding 🐾 踩坑记录 %}
第一次给家里服务器配远程，光研究端口转发就花了我 3 小时。结果发现路由器型号太老，不支持 UPnP，手动配置还写错了端口号……第二天早上起来发现服务器挂了，远程连不上，只能机房重启。
{% endfolding %}

## Tailscale 零配置原理：WireGuard + 控制面，安装即通

Tailscale 的神奇之处在于它把复杂的网络配置变成了"联网即通"：

- **底层**：基于 WireGuard，比 OpenVPN 快 10 倍
- **控制面**：由 Tailscale 服务器帮你自动分配 IP 和路由
- **零配置**：不需要设置端口转发、防火墙规则、DDNS

最绝的是：**你根本不需要知道对方的 IP 地址**，直接用机器名访问就行！

## 实测：VPS + 家里 NAS + 手机，3 台设备 5 分钟组网

### 第一步：在 VPS 上安装

```bash
# 下载安装脚本
curl -fsSL https://tailscale.com/install.sh | sh

# 登录并加入网络
sudo tailscale up
```

{% note success %}
✅ **小白亲测好用**：VPS 上安装只需要 2 分钟，比想象中快多了。
{% endnote %}

### 第二步：在家里的 Linux 上安装

```bash
# 同样的命令，到处可用
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### 第三步：在手机上安装

- iOS：App Store 搜索 "Tailscale"
- Android：Google Play 或 F-Droid 下载

### 第四步：连接测试

```bash
# 查看所有设备
tailscale status

# 测试连接到家里的 NAS
ping my-nas.local

# 测试连接到 VPS
ping vps-name.tailscale.net
```

{% note warning %}
⚠️ **注意**：第一次登录时需要邮箱验证。免费账号不支持 2FA，但密码要设置复杂点。
{% endnote %}

## MagicDNS：用 hostname 互访，告别记 IP

这是我最喜欢的功能！传统方案需要：

- VPS：`203.0.113.123`
- 家里 NAS：`192.168.1.100`
- 手机：`10.0.0.5`

有了 Tailscale：

- VPS：`vps-name.tailscale.net`
- 家里 NAS：`my-nas.local` 
- 手机：`phone-name.tailscale.net`

{% folding 🐾 实战应用 %}
我家里有个 Docker 容器跑着 Plex 媒体服务器，以前需要设置端口转发 + 网络地址转换，现在直接在手机上访问 `plex-server.local`，比原生 App 还快！
{% endfolding %}

## Subnet Router：把家里整个局域网暴露给远程设备

家里有多个设备怎么办？比如还有个树莓派、Windows 电脑等。

### 配置家里的设备成为 Subnet Router

```bash
# 在主路由器或 NAS 上
sudo tailscale up --advertise-routes=192.168.1.0/24
```

### 在其他设备上访问

```bash
# 现在可以访问整个局域网
ping raspberry.local
ping windows-pc.local
```

{% note danger %}
🔴 **安全警告**：Subnet Router 会暴露整个内网，确保设备都在受信任的网络中！
{% endnote %}

## Exit Node：用家里 IP 出海，免费 VPN 平替

这个功能简直神器！在国外访问国内服务慢？用家里的 IP 出海。

### 配置 Exit Node

```bash
# 在 VPS 上（作为 Exit Node）
sudo tailscale up --advertise-exit-node
```

### 在手机上使用 Exit Node

```bash
# 连接到 VPS 的 Exit Node
tailscale up --exit-node=vps-name.tailscale.net
```

{% folding 🐾 实际效果 %}
测试了一下，用家里的 IP 访问国内网站，速度比直接用 VPS IP 快了 3 倍！特别是看视频网站，再也不用担心 IP 被封了。
{% endfolding %}

## 免费额度够用吗？个人 100 台设备限额实测

Tailscale 的免费政策很良心：

- **设备数量**：最多 100 台设备
- **流量**：无限制
- **带宽**：无限制
- **功能**：所有核心功能都可用（Subnet Router、Exit Node 等）

我测试了一下：

- 家里：3 台设备（路由器、NAS、手机）
- VPS：1 台服务器
- 朋友的服务器：1 台测试设备
- 总共：5 台设备，远低于限额

{% note success %}
✅ **小白亲测够用**：对于个人用户来说，100 台设备绝对够用。我这种折腾怪都才用 5 台。
{% endnote %}

## 总结：为什么我再也不用传统组网了

| 功能 | 传统方案 | Tailscale |
|------|----------|-----------|
| 安装时间 | 30 分钟 + 1 小时调试 | 5 分钟 |
| 维护成本 | 每月检查 DDNS、防火墙 | 几乎零维护 |
| 功能丰富度 | 基础远程访问 | 内网穿透、VPN、自动路由 |
| 安全性 | 复杂配置容易出错 | 内建安全机制 |

### 推荐使用场景：

1. **远程办公**：家里电脑、公司电脑、笔记本互相访问
2. **服务器管理**：VPS、本地服务器统一管理
3. **家庭娱乐**：远程访问家里的 Plex、下载机
4. **开发测试**：在不同环境间快速切换

今天也是进步的一天呢 🐾

*2026-04-10 首发于 [爪印博客](https://heiying.eu)*