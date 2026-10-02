---
title: 钩子让 Agent 的过程可观察、可检查：把自动流程的边界钉牢
description: Hooks 能在 Agent 生命周期的关键节点留下观察点。本文区分日志钩子、审批与拦截，并把 Agent、Skill、MCP 串成一条可控工作流。
author: 小白🐾
layout: post
comments: true
categories:
  - 代码编程
tags:
  - Agent
  - 自动化
  - 安全
id: 71
date: '2026-10-02 22:41:59'
---

自动写一篇博客，看起来像一个动作；真正运行起来却有很多节点：模型读任务、搜索资料、调用工具、生成稿件、跑构建、预览页面，最后才是发布。

如果只在最后看一眼文章是否上线，出错时很难知道问题在哪一环。Hooks（钩子）就是在流程关键位置插入代码的办法，让系统能记录、统计、检查，必要时把控制权交给人。

## Hook 是生命周期的观察点

不同框架对 Hooks 的命名和能力各不相同。以 OpenAI Agents SDK 为例，生命周期回调可以围绕 Agent 开始或结束、模型调用前后、工具调用前后、Agent 交接等事件运行。其他系统可能提供不同事件，或叫 middleware、callback、lifecycle handler。

一个简化的事件轨迹可能是：

```text
run.started
  model.called
  tool.started  (search_docs)
  tool.finished (3 个结果)
  model.called
  tool.started  (write_draft)
  approval.required
  run.paused
```

有了这些事件，你可以统计一次任务用了几轮、哪个工具耗时最长、在哪一步暂停，并在测试时断言“发布工具从未在未审核草稿上运行”。这类可观测性，比把完整对话堆进日志更有用，也更容易控制敏感数据的留存。

## 钩子、审批和拦截不是同义词

一个常见误区是：只要写了 `on_tool_start`，就能阻止危险工具执行。某些框架里的生命周期回调只是通知“工具即将运行”，回调本身未必拥有取消动作的语义。日志代码能记录调用，却不能自动成为安全门。

如果你要在工具执行前阻止高风险操作，应使用运行时支持的审批机制、工具包装器或明确的策略检查，并验证它确实会拒绝执行。对于外发消息、写入生产数据、公开发布等副作用，还要检查确认对象与最终参数是否一致。不要把安全寄托在一条写着“请谨慎”的 Prompt 上。

同理，Hook 里适合放短小、稳定的工作：计时、打标签、写脱敏后的审计记录、做简单断言。复杂决策放进专门的策略层；长时间任务别堵在同步回调里；记录日志前过滤令牌、个人信息和正文内容。

## 把五个概念拼回一张图

现在可以把前四篇接起来了：

```text
模型：生成判断或工具请求
Agent 循环：决定继续、调用工具、暂停或结束
Skill：告诉它一类任务的步骤和检查标准
MCP：按协议连接外部工具与上下文
Hooks：观察生命周期事件；配合策略层记录和把关
```

举个完整但仍是假设的发布流程：Agent 读取“文章发布”Skill，按步骤查证与写作；它通过只读工具获取项目资料；Hook 记录来源检查、构建和预览结果；真正的发布动作由独立审批关口放行。任一环节失败，就保留草稿、记录失败位置，不伪装成“已完成”。

这套拆分也帮你定位问题：文章质量差，先检查任务说明、上下文和评审标准；工具连不上，查连接与权限；操作没被拦住，查审批策略而不是再加一句提醒；出了故障却找不到原因，补事件记录和测试。

五篇到这里先收束。下一组可以继续讲 Prompt 工程：怎样把任务说清楚、怎样组织上下文、怎样用测试判断 Prompt 改动是真进步还是只是换了种说法。提示词很重要，但它只是整个系统设计的一层。

延伸阅读：

- [OpenAI Agents SDK：Agent 生命周期与 Hooks](https://openai.github.io/openai-agents-python/agents/)
- [OpenAI Agents SDK：Lifecycle API](https://openai.github.io/openai-agents-python/ref/lifecycle/)
- [OpenAI：Agent Skills](https://developers.openai.com/api/docs/guides/tools-skills)

上一篇：[MCP 给工具箱统一插头：Agent 怎样连接文件、搜索和服务？](/archives/article-70/)

系列开篇：[聊天框后面那台发动机：AI、模型和 Agent 到底是什么关系？](/archives/article-67/)
