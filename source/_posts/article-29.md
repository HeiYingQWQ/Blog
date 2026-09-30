---
id: 29
date: "2026-04-21 18:00:00"
title: "WebAssembly 入门：浏览器里的高性能计算"
author: "小白🐾"
layout: post
comments: true
tags:
  - WebAssembly
  - 前端
categories: "代码编程"
description: "介绍 WebAssembly 技术，帮助前端开发者拓展性能优化思路。"
keywords:
  - "WebAssembly 入门：浏览器里的高性能计算"
  - "代码编程"
  - WebAssembly
  - 前端
---

# WebAssembly 入门：浏览器里的高性能计算

上周我在逛技术论坛时，看到一个帖子问："前端能不能做视频剪辑？"下面有人回："用 WebAssembly 啊。"然后就没下文了。

这让我想起自己第一次听说 WASM 的时候——也是这么一头雾水。好像突然之间，所有人都在聊这个 "浏览器里的高性能计算"，但没人告诉我它到底能干啥。

## 不是替代 JS，而是补刀

先说清楚一件事：WebAssembly 不是要干掉 JavaScript。

JavaScript 活了二十多年，生态系统庞大到离谱。WASM 的定位更像是 JS 的"外援"——当 JS 遇到性能瓶颈时，WASM 上场解决问题。

打个比方：JS 是瑞士军刀，能开瓶盖、能削苹果、能拧螺丝。但你要切个牛排，还是得用专门的餐刀。WASM 就是那把餐刀。

什么场景需要这把餐刀？

- 图像处理（滤镜、特效、压缩）
- 音视频编解码（剪辑、转码、实时处理）
- 游戏引擎（物理计算、3D 渲染）
- AI 推理（模型跑在浏览器里）

这些东西用 JS 写不是不行，只是慢得让人想砸电脑。

## 我曾经不信邪

去年有个项目需要做图片批量压缩。我想，不就调个 canvas 的 API 吗，能有多难。

结果用户上传了 50 张 4K 照片，页面直接卡死 30 秒。Chrome 的内存占用飙到 2GB，风扇声音像要起飞。

后来换成了 WASM 版本的 libwebp，同样 50 张图，压缩时间降到 3 秒。内存占用不到原来的三分之一。

这就是 WASM 的核心价值：把耗时的计算密集型任务，交给更接近硬件的方式执行。

## 三种主流开发方式

想用 WASM，你有三条路可以走：

**Emscripten**：C/C++ 代码直接编译成 WASM。适合已经有 C++ 库的项目，比如游戏引擎、图像处理库。缺点是工具链复杂，编译慢。

**Rust + wasm-pack**：Rust 是一门现代系统编程语言，内存安全、性能优秀。wasm-pack 工具链体验很好，生态也在快速成长。

**AssemblyScript**：TypeScript 语法，编译成 WASM。如果你熟悉 TS，上手最快。但目前生态还比较稚嫩，生产环境用得少。

我的建议：新项目用 Rust，老项目迁移用 Emscripten，AssemblyScript 先观望。

## 实战：第一个 WASM 模块

来看个最简单的例子——用 Rust 写一个加法函数，在浏览器里调用。

先安装 Rust 和 wasm-pack：

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安装 wasm-pack
curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
```

创建 Rust 项目：

```bash
wasm-pack new my-wasm-project
cd my-wasm-project
```

编辑 `src/lib.rs`：

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[wasm_bindgen]
pub fn heavy_calc(n: i32) -> i32 {
    // 模拟计算密集型任务
    (0..n).fold(0, |acc, x| acc + x)
}
```

编译成 WASM：

```bash
wasm-pack build --target web
```

在前端使用：

```javascript
import init, { add, heavy_calc } from './pkg/my_wasm_project.js';

async function run() {
    // 初始化 WASM
    await init();
    
    // 调用 WASM 函数
    console.log(add(1, 2)); // 3
    
    // 性能对比
    const start = performance.now();
    const result = heavy_calc(1000000);
    const end = performance.now();
    
    console.log(`结果: ${result}, 耗时: ${end - start}ms`);
}

run();
```

看起来和调用普通 JS 函数没什么区别？

这就是 WASM 的设计哲学：对用户透明。底层再复杂，暴露给开发者的接口要简单。

当然，真实的项目不会这么简单。内存管理、数据传递、错误处理，这些才是坑。但这就是另一个话题了。

## 什么时候用 WASM

我的观点是：前端工程师应该了解 WASM 的基本原理，但没必要急着深入。

什么时候必须学？当你真的遇到性能瓶颈，且确定是计算密集型问题时。

WebAssembly 不是银弹。它解决的问题很具体，带来的复杂度也不小。但如果你的项目恰好在那个"具体的点"上，它能救命。

至少下次再有人问"前端能不能做视频剪辑"，你可以自信地说：

"能。用 WebAssembly。"