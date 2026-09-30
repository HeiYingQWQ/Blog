---
id: 37
date: 2026-04-28 18:15:00
title: "Rust 入门教程：从 Hello World 到 Web 开发"
author: "小白🐾"
layout: post
comments: true
tags:
  - Rust
  - 编程
  - Web 开发
categories: "代码编程"
keywords:
  - Rust 入门教程：从 Hello World 到 Web 开发
  - 代码编程
  - Rust
  - 编程
  - Web 开发
description: "帮助读者快速入门 Rust 语言，掌握基础语法和 Web 开发技能。"
---

# Rust 入门教程：从 Hello World 到 Web 开发

## 核心要点

- 为什么 Rust 是 2024 年最值得学习的语言：安全性、性能、生态系统
- 开发环境搭建：Rustup、Cargo、编辑器的配置
- 基础语法：变量、函数、所有权、生命周期的理解
- 数据结构：数组、切片、向量、哈希表的使用
- Web 开发：Actix-web、Rocket、Axum 框架的对比
- 数据库集成：PostgreSQL、Redis、SQLite 的连接与操作

最近在群里看到很多人在讨论 Rust，有人说它是未来的语言，有人说它太难学了。作为一只喜欢折腾的小狗，我也忍不住好奇，想看看 Rust 到底有什么特别之处。

### 为什么选择 Rust？

{% note info %}
如果你是 Java、Python 或者 JavaScript 开发者，可能会觉得 Rust 语法奇怪，但一旦你理解了它的设计理念，就会发现它的强大之处。
{% endnote %}

Rust 最吸引人的地方在于它的安全性和性能。它通过所有权、借用和生命周期的概念，在编译时就可以检测出内存安全问题，而不需要像 C++ 那样依赖运行时检查。这意味着你可以写出既安全又高效的代码，而不必担心内存泄漏或段错误。

### 开发环境搭建

要学习 Rust，首先需要搭建开发环境。Rust 官方提供了 Rustup 工具链管理器，可以让你轻松安装和管理多个 Rust 版本。

**安装 Rustup：**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

安装完成后，你需要配置环境变量，以便终端可以找到 Rust 相关的命令。

**配置环境变量：**
```bash
source $HOME/.cargo/env
```

现在，你可以使用 `rustc` 编译器和 `cargo` 包管理器了。

### Hello World 程序

让我们从最简单的 Hello World 程序开始。

**创建 Hello World 程序：**
```bash
cargo new hello_world
cd hello_world
```

这会创建一个新的 Rust 项目，包含一个 `src/main.rs` 文件。

**src/main.rs 文件内容：**
```rust
fn main() {
    println!("Hello, World!");
}
```

**编译并运行程序：**
```bash
cargo run
```

你会看到控制台输出 "Hello, World!"。

### 基础语法

Rust 的语法和 C++ 类似，但有一些重要的区别。

**变量声明：**
```rust
let x = 5; // 不可变变量
let mut y = 10; // 可变变量
```

**函数定义：**
```rust
fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

**所有权：**
```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1; // 所有权转移
    // println!("{}", s1); // 报错，s1 已经没有所有权
}
```

### 数据结构

Rust 提供了多种数据结构，包括数组、切片、向量、哈希表等。

**数组：**
```rust
let arr = [1, 2, 3, 4, 5];
println!("{}", arr[0]); // 输出 1
```

**向量：**
```rust
let mut vec = Vec::new();
vec.push(1);
vec.push(2);
println!("{}", vec[0]); // 输出 1
```

**哈希表：**
```rust
use std::collections::HashMap;

let mut map = HashMap::new();
map.insert("key1", "value1");
map.insert("key2", "value2");
println!("{}", map.get("key1").unwrap()); // 输出 value1
```

### Web 开发

Rust 也可以用于 Web 开发。目前比较流行的 Web 框架有 Actix-web、Rocket 和 Axum。

**Actix-web：**
Actix-web 是一个基于异步的 Web 框架，性能非常高。
```rust
use actix_web::{web, App, HttpResponse, HttpServer};

async fn index() -> HttpResponse {
    HttpResponse::Ok().body("Hello, Actix-web!")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .route("/", web::get().to(index))
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}
```

**Rocket：**
Rocket 是一个基于同步的 Web 框架，易用性非常高。
```rust
#[macro_use] extern crate rocket;

#[get("/")]
fn index() -> &'static str {
    "Hello, Rocket!"
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![index])
}
```

**Axum：**
Axum 是一个基于异步的 Web 框架，由 Tokio 团队开发，设计理念简单。
```rust
use axum::{
    routing::get,
    Router,
};

async fn index() -> &'static str {
    "Hello, Axum!"
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(index));

    axum::Server::bind(&"127.0.0.1:8080".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
```

### 数据库集成

Rust 也可以连接各种数据库，包括 PostgreSQL、Redis 和 SQLite。

**连接 PostgreSQL：**
```rust
use sqlx::PgPool;

#[tokio::main]
async fn main() {
    let pool = PgPool::connect("postgres://username:password@localhost:5432/database").await.unwrap();

    let result = sqlx::query("SELECT * FROM users")
        .fetch_all(&pool)
        .await;

    match result {
        Ok(users) => {
            for user in users {
                println!("{}", user.get("name"));
            }
        }
        Err(e) => println!("Error: {}", e),
    }
}
```

### 结语

Rust 是一门非常有潜力的语言，它的安全性和性能使其在系统编程、网络编程和 Web 开发等领域都有广泛的应用。虽然它的学习曲线比较陡峭，但一旦你掌握了它的核心概念，就会发现它的强大之处。

如果你想深入学习 Rust，可以参考官方文档或在线教程。祝你学习愉快！