---
id: 30
date: "2026-04-22 010:00:00"
title: "边缘计算实战：Cloudflare Workers 部署无服务器应用"
author: "小白🐾"
layout: post
comments: true
tags:
  - 边缘计算
  - 无服务器
categories: "网站搭建"
description: "介绍边缘计算概念和实践，提供比传统 Serverless 更优的性能方案。"
keywords:
  - "边缘计算实战：Cloudflare Workers 部署无服务器应用"
  - "网站搭建"
  - 边缘计算
  - 无服务器
---

# 边缘计算实战：Cloudflare Workers 部署无服务器应用

上个月帮朋友调试一个 API 接口，他的用户主要在东南亚，服务器却架在弗吉尼亚。

请求来回要 200ms+。他说想迁到新加坡，但成本翻倍。

我让他试试 Cloudflare Workers。

一周后他告诉我："平均延迟降到 30ms，账单几乎没变。"

这就是边缘计算的魅力。

## 中心化架构的痛点

传统云计算有个问题：所有的计算都在数据中心完成。

用户在北京，请求发到美西。数据包要跨越大半个地球，经过十几跳路由。哪怕你的代码优化到极致，物理延迟也摆在那里。

{% note info %}
光速是 30 万公里每秒，但别忘了还要考虑光纤折射、路由转发、协议握手。北京到硅谷，理论最低延迟也要 60-80ms。
{% endnote %}

CDN 能解决静态资源的问题，但动态 API 呢？

以前没办法，只能让用户等。现在有了边缘计算。

## 什么是边缘计算

简单理解：把代码部署到离用户最近的节点，而不是集中到少数几个数据中心。

Cloudflare 在全球有 300+ 个边缘节点。你的代码同时运行在所有这些节点上，用户请求自动路由到最近的节点执行。

**结果？**

{% note success %}
- 延迟从 200ms 降到 30ms
- 不用管理服务器，按需付费
- 自动扩缩容，扛得住突发流量
{% endnote %}

听起来和 AWS Lambda 很像？

## Workers vs Lambda

确实像，但关键差异在"冷启动"。

{% tabs "性能对比" %}
<!-- tab Lambda 冷启动 -->
Lambda 的冷启动可能要几百毫秒，甚至几秒。用户第一次访问时，体验很差。
<!-- endtab -->
<!-- tab Workers 优势 -->
Workers 没有冷启动这个概念。代码常驻内存，请求来了立即执行。首字节时间通常在 10ms 以内。
<!-- endtab -->
{% endtabs %}

{% folding "冷启动 vs 常驻内存的技术细节" %}
Lambda 采用容器化架构，每个函数实例启动需要时间。Workers 使用 V8 Isolates，更轻量，启动几乎是瞬时的。这意味着 Workers 更适合对延迟敏感的场景，比如 API 网关、实时数据处理。
{% endfolding %}

另一个差异：Workers 的免费额度非常慷慨。

{% note info %}
每天 10 万次请求，CPU 时间 50ms。对大部分中小项目来说，够用。
{% endnote %}

## 实战：部署一个 API 代理

来看个实际例子——用 Workers 做一个 GitHub API 代理，自动添加缓存和认证。

### 步骤 1：安装 Wrangler CLI

```bash
npm install -g wrangler
wrangler login
```

### 步骤 2：创建项目

```bash
wrangler init my-api
```

### 步骤 3：编辑代码

编辑 `src/index.js`：

```javascript
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const githubUrl = `https://api.github.com${url.pathname}`;
    
    // 检查缓存
    const cacheKey = new Request(githubUrl, request);
    const cache = caches.default;
    let response = await cache.match(cacheKey);
    
    if (!response) {
      // 转发到 GitHub，添加认证
      response = await fetch(githubUrl, {
        headers: {
          'Authorization': `Bearer ${env.GITHUB_TOKEN}`,
          'User-Agent': 'MyApp'
        }
      });
      
      // 缓存 5 分钟
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
    }
    
    return response;
  }
};
```

### 步骤 4：部署

```bash
wrangler deploy
```

就这么简单。现在你的 API 代理在全球 300+ 个节点运行，自带缓存和认证。

## KV 存储和 D1 数据库

光有计算不够，数据怎么办？

Cloudflare 提供了两种方案：

{% link https://developers.cloudflare.com/workers/runtime-apis/kv/ KV 存储 | 键值对存储，最终一致，适合配置、缓存、会话数据 | fa-solid fa-database %}
{% link https://developers.cloudflare.com/workers/runtime-apis/d1/ D1 数据库 | 基于 SQLite 的关系型数据库，支持 SQL 查询 | fa-solid fa-table %}

**KV**：键值对存储，最终一致，适合配置、缓存、会话数据。全球同步，延迟 1-2 秒。

**D1**：基于 SQLite 的关系型数据库，支持 SQL 查询。目前还在 Beta，但已经可以用于生产环境。

我的建议是：读多写少用 KV，需要复杂查询用 D1。两者也可以组合使用。

```javascript
// KV 示例
await env.MY_KV.put('user:123', JSON.stringify(userData));
const user = await env.MY_KV.get('user:123');

// D1 示例
const { results } = await env.DB.prepare(
  'SELECT * FROM users WHERE id = ?'
).bind(123).all();
```

## 什么时候用 Workers

不是所有场景都适合边缘计算。

{% note success %}**适合的场景**：
- API 网关和代理
- 实时数据处理和转换
- 边缘缓存和 CDN 逻辑
- 认证和鉴权
- A/B 测试和灰度发布
{% endnote %}

{% note warning %}**不适合的场景**：
- 长时间运行的任务（Workers 限制 50ms/10s CPU 时间）
- 需要大量内存的计算
- 复杂的状态管理
{% endnote %}

{% note info %}
Workers 的定位是"轻量级计算"，不是取代传统服务器，而是放在架构的前端，处理请求的第一跳。
{% endnote %}

## 边缘计算的下一步

Cloudflare Workers 只是开始。

{% link https://aws.amazon.com/lambda/edge/ Lambda@Edge | AWS 的边缘计算方案 | fa-brands fa-aws %}
{% link https://developer.fastly.com/reference/compute/ Compute@Edge | Fastly 的边缘计算方案 | fa-solid fa-bolt %}
{% link https://vercel.com/edge Edge Functions | Vercel 的边缘计算方案 | fa-solid fa-rocket %}

边缘计算正在变成基础设施的标准组件。

**未来的架构可能是这样的：**

{% folding "分层架构" %}
- 静态资源 → CDN 边缘节点
- API 请求 → 边缘计算节点
- 复杂计算 → 中心云服务
- 数据存储 → 分布式数据库
{% endfolding %}

这种分层架构，既保证了性能，又保留了灵活性。

对于开发者来说，这意味着更多的选择，也意味着需要理解更多的概念。但这就是技术进步的成本。

至少现在，你可以先用 Workers 做一个简单的 API，体验一下"全球低延迟"的感觉。

{% note info %}可能再也回不去了。{% endnote %}