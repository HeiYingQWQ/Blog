---
title: 从零实现一个带重试和超时的异步任务队列
author: 小白🐾
layout: post
comments: true
categories:
  - 代码编程
tags:
  - Node.js
  - 异步
  - 并发
description: 不依赖第三方队列库，用 Node.js 从零实现一个带并发限制、超时、指数退避、优雅关闭和测试的异步任务队列。
id: 66
date: '2026-09-09 11:22:50'
---

很多脚本一开始都长这样：拿到一组任务，`Promise.all()` 一把梭。

任务少的时候，它简单、直接，还显得很现代。任务一多，问题就一起出现了：瞬间发起几百个请求，失败后没有重试，某个 Promise 永远不结束，程序也不知道什么时候可以安全退出。

这次不调用现成的队列库，我们用 Node.js 的原生能力写一个小型异步任务队列。它只解决一件事：在内存里可靠地运行有限数量的任务，并为每个任务提供并发限制、超时、重试和优雅关闭。

先把边界说清楚：这不是生产级消息系统。它没有持久化，进程崩溃后队列里的任务会消失，也没有跨进程消费者。它的价值在于把异步调度最容易被忽略的部分摊开，让每一个决定都能看到。

## 先定义我们要的行为

一个任务进入队列后，应该经历这样的状态：等待执行、运行中、成功，或者失败后等待下一次尝试。队列本身还要遵守几条规则：

- 同时运行的任务数不能超过 `concurrency`；
- 一次执行超过 `timeoutMs`，就通过 `AbortSignal` 通知任务停止；
- 失败后最多重试 `retries` 次，每次等待时间逐步增加；
- 调用 `close()` 后不再接收新任务，但已经进入队列的任务可以排空；
- 每次 `add()` 返回一个 Promise，让调用方拿到任务最终结果。

这里有一个容易被忽略的词：**通知**。

JavaScript 的 Promise 没有“强制杀死”接口。`Promise.race()` 能让队列先得到超时结果，却不能抹掉已经开始执行的函数。要让超时真正有用，任务函数必须接收 `AbortSignal`，并在等待网络、文件或其他可取消操作时配合它。

## 第一版：只限制并发

队列的核心其实不复杂：数组保存等待中的任务，`running` 记录正在执行的数量，`pump()` 在有空位时不断取任务。

```js
function pump() {
  while (running < concurrency && pending.length > 0) {
    const item = pending.shift();
    running += 1;

    run(item).finally(() => {
      running -= 1;
      pump();
    });
  }
}
```

关键点是 `finally()`。无论任务成功还是失败，都必须把占用的并发槽释放掉。如果只在成功分支里减一，队列遇到第一个异常就会慢慢“锁死”。

## 完整实现：queue.mjs

下面这个实现只依赖 Node.js 内置模块。`timers/promises` 用来等待退避时间，`AbortController` 负责把超时信号传给任务。

```js
import { randomUUID } from 'node:crypto';
import { setTimeout as delay } from 'node:timers/promises';

export class TimeoutError extends Error {
  constructor(timeoutMs) {
    super(`task timed out after ${timeoutMs}ms`);
    this.name = 'TimeoutError';
    this.code = 'ETIMEDOUT';
    this.timeoutMs = timeoutMs;
  }
}

export class QueueClosedError extends Error {
  constructor() {
    super('queue is closed');
    this.name = 'QueueClosedError';
    this.code = 'EQUEUECLOSED';
  }
}

export class AsyncTaskQueue {
  #pending = [];
  #running = 0;
  #accepting = true;
  #idleWaiters = [];

  constructor({
    concurrency = 2,
    timeoutMs = 5_000,
    retries = 2,
    backoffMs = 200,
  } = {}) {
    if (!Number.isInteger(concurrency) || concurrency < 1) {
      throw new RangeError('concurrency must be a positive integer');
    }
    if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) {
      throw new RangeError('timeoutMs must be greater than zero');
    }
    if (!Number.isInteger(retries) || retries < 0) {
      throw new RangeError('retries must be a non-negative integer');
    }
    if (!Number.isFinite(backoffMs) || backoffMs < 0) {
      throw new RangeError('backoffMs must be non-negative');
    }

    this.concurrency = concurrency;
    this.timeoutMs = timeoutMs;
    this.retries = retries;
    this.backoffMs = backoffMs;
  }

  add(task, { id = randomUUID() } = {}) {
    if (typeof task !== 'function') {
      return Promise.reject(new TypeError('task must be a function'));
    }
    if (!this.#accepting) {
      return Promise.reject(new QueueClosedError());
    }

    const promise = new Promise((resolve, reject) => {
      this.#pending.push({ id, task, resolve, reject });
    });

    this.#pump();
    return promise;
  }

  close({ drain = true } = {}) {
    this.#accepting = false;

    if (!drain) {
      const error = new QueueClosedError();
      for (const item of this.#pending.splice(0)) {
        item.reject(error);
      }
    }

    this.#notifyIdle();
  }

  onIdle() {
    if (this.#running === 0 && this.#pending.length === 0) {
      return Promise.resolve();
    }
    return new Promise((resolve) => this.#idleWaiters.push(resolve));
  }

  #pump() {
    while (this.#running < this.concurrency && this.#pending.length > 0) {
      const item = this.#pending.shift();
      this.#running += 1;

      this.#run(item).finally(() => {
        this.#running -= 1;
        this.#pump();
        this.#notifyIdle();
      });
    }
  }

  async #run(item) {
    const maxAttempts = this.retries + 1;

    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      const controller = new AbortController();

      try {
        const result = await this.#withTimeout(
          () => item.task({
            id: item.id,
            attempt,
            signal: controller.signal,
          }),
          controller,
        );
        item.resolve(result);
        return;
      } catch (error) {
        if (attempt === maxAttempts) {
          item.reject(error);
          return;
        }

        const waitMs = this.backoffMs * 2 ** (attempt - 1);
        await delay(waitMs);
      }
    }
  }

  #withTimeout(task, controller) {
    let timer;
    const timeout = new Promise((_, reject) => {
      timer = setTimeout(() => {
        const error = new TimeoutError(this.timeoutMs);
        controller.abort(error);
        reject(error);
      }, this.timeoutMs);
    });

    const work = Promise.resolve().then(task);
    return Promise.race([work, timeout]).finally(() => clearTimeout(timer));
  }

  #notifyIdle() {
    if (this.#running !== 0 || this.#pending.length !== 0) return;
    for (const resolve of this.#idleWaiters.splice(0)) resolve();
  }
}
```

这段实现里有几个值得停下来看的地方。

`retries` 表示失败后额外尝试几次，所以 `retries: 2` 最多执行三次。退避时间使用 `backoffMs * 2 ** (attempt - 1)`，第一次失败等 200 毫秒，第二次失败等 400 毫秒。真实服务通常还会加一点随机抖动，避免一批任务在同一时刻再次撞向服务；这里先保持实现容易读懂。

`close({ drain: true })` 只关闭入口，不会砍掉已经排队的工作。如果传入 `drain: false`，等待中的任务会收到 `QueueClosedError`，已经运行的任务仍然需要自己响应信号或自然结束。队列没有替你做进程级别的强杀。

`onIdle()` 是一个很小但很重要的接口。直接调用 `close()` 后立刻让 Node 进程退出，可能会把还没完成的任务截断。等待 `onIdle()`，调用方才知道队列真的排空了。

## 写一个会失败两次的任务

```js
import { setTimeout as delay } from 'node:timers/promises';
import { AsyncTaskQueue } from './queue.mjs';

const queue = new AsyncTaskQueue({
  concurrency: 2,
  timeoutMs: 1_000,
  retries: 3,
  backoffMs: 100,
});

let calls = 0;
const result = await queue.add(async ({ attempt, signal }) => {
  calls += 1;
  await delay(50, undefined, { signal });

  if (attempt < 3) {
    throw new Error(`temporary failure on attempt ${attempt}`);
  }
  return 'done';
}, { id: 'demo-task' });

console.log(result, calls); // done 3

queue.close();
await queue.onIdle();
```

这次任务前两次抛错，第三次成功。队列只把错误当作“还可以再试”的信号，并不知道这个错误是否值得重试。网络临时断开、限流、上游 503 可能适合重试；参数校验失败、权限不足和重复扣款通常不适合。

因此，生产代码不应该对所有异常无脑重试。可以在 `catch` 里增加一个 `shouldRetry(error)`，只对明确的临时错误重试，并给任务设置幂等键。重试本身不是可靠性，它只是把一次失败换成了几次机会。

## 超时并不等于停止执行

这是本文最容易被误用的一点。

```js
await queue.add(async ({ signal }) => {
  await delay(10_000, undefined, { signal });
  return 'too late';
});
```

超过 `timeoutMs` 后，队列会把任务标记为超时，并调用 `controller.abort()`。因为 `timers/promises.setTimeout()` 接收了这个信号，等待会被取消，任务也就能尽快结束。

如果任务内部是这样的：

```js
await new Promise((resolve) => setTimeout(resolve, 10_000));
```

它不会理会 `signal`。队列可以先返回超时，但那段定时器仍然会继续跑。对网络请求，要把 signal 传给 `fetch`；对文件或数据库库，要确认它们是否支持取消；对无法取消的 CPU 密集任务，则应该考虑 `Worker` 或子进程，把任务放到可以真正终止的边界里。

## 用内置测试验证四件事

没有测试的并发代码，很容易只在“任务刚好成功”的时候显得正确。Node.js 自带 `node:test`，可以直接检查队列最重要的行为：

```js
import assert from 'node:assert/strict';
import test from 'node:test';
import { setTimeout as delay } from 'node:timers/promises';
import {
  AsyncTaskQueue,
  QueueClosedError,
  TimeoutError,
} from './queue.mjs';

test('retries a temporary failure and eventually resolves', async () => {
  const queue = new AsyncTaskQueue({ retries: 2, backoffMs: 1 });
  let attempts = 0;

  const result = await queue.add(async () => {
    attempts += 1;
    if (attempts < 3) throw new Error('temporary');
    return 'ok';
  });

  assert.equal(result, 'ok');
  assert.equal(attempts, 3);
});

test('times out a task and aborts cooperative work', async () => {
  const queue = new AsyncTaskQueue({ timeoutMs: 10, retries: 0 });

  await assert.rejects(
    queue.add(({ signal }) => delay(100, undefined, { signal })),
    (error) => error instanceof TimeoutError,
  );
});

test('never exceeds the concurrency limit', async () => {
  const queue = new AsyncTaskQueue({ concurrency: 2 });
  let active = 0;
  let peak = 0;

  await Promise.all(Array.from({ length: 6 }, (_, index) => queue.add(async () => {
    active += 1;
    peak = Math.max(peak, active);
    await delay(5);
    active -= 1;
    return index;
  })));

  assert.equal(peak, 2);
});

test('rejects new work after close', async () => {
  const queue = new AsyncTaskQueue();
  queue.close();
  await assert.rejects(queue.add(() => 'never'), QueueClosedError);
});
```

运行：

```bash
node --test queue.test.mjs
```

这四个测试分别守住重试、超时、并发上限和生命周期边界。还可以继续补充：`drain: false` 是否拒绝等待中的任务、任务最终失败时是否保留原始错误、退避时间是否带随机抖动，以及队列关闭时正在重试的任务应该怎样处理。

## 这只是一只内存队列

把代码跑通以后，不要急着把它放进支付、发货或消息消费系统。这个实现故意没有解决几个更大的问题：

- 进程崩溃后，内存里的任务和结果都会丢失；
- 多个进程各自维护自己的队列，无法共享并发上限；
- 任务执行到一半崩溃，重启后可能重复执行；
- 重试没有持久化记录，也没有死信队列；
- `close()` 不能替你保证外部副作用已经回滚。

如果需要这些能力，下一步不是继续往这个类里堆字段，而是引入持久化存储、唯一任务 ID、幂等处理和可观测日志。Redis、数据库或专门的消息队列可以解决一部分问题，但它们也会带来确认、重复投递和一致性的新问题。

从零实现这个小队列的意义，不是替代那些成熟工具，而是先把“并发限制”“超时通知”“失败重试”和“任务完成”这几个词分别弄明白。异步代码真正难的地方，往往不是把函数写成 `async`，而是知道它失败以后，系统还会不会保持清醒。

相关文档：

- [Node.js Timers](https://nodejs.org/api/timers.html)
- [Node.js Test Runner](https://nodejs.org/api/test.html)
- [Node.js Events](https://nodejs.org/api/events.html)
