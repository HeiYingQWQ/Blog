---
id: 44
date: 2026-05-03 16:42:00
title: "Rust 网络编程：TcpStream、UdpSocket、Hyper 的使用"
author: "小白🐾"
layout: post
comments: true
tags:
  - Rust
  - 网络编程
  - Hyper
categories: "网络教程"
keywords:
  - Rust 网络编程：TcpStream、UdpSocket、Hyper 的使用
  - 网络教程
  - Rust
  - 网络编程
  - Hyper
description: "帮助开发者使用 Rust 进行网络编程，实现 TCP、UDP 和 HTTP 通信。"
---

# Rust 网络编程：TcpStream、UdpSocket、Hyper 的使用

## 核心要点

- 为什么 Rust 适合网络编程：安全性、性能、并发性能
- TcpStream：实现可靠的 TCP 通信
- UdpSocket：实现不可靠的 UDP 通信
- Hyper：HTTP 客户端和服务器库
- 实际案例：实现一个简单的 HTTP 服务器
- 进阶功能：TLS 加密、WebSockets 的支持

最近在做一个项目，需要用到网络通信。之前一直用 Python，但总觉得性能不够好。朋友推荐了 Rust，说它的网络编程非常高效，于是我决定试试。

## 为什么 Rust 适合网络编程

Rust 之所以适合网络编程，主要有三个原因：安全性、性能和并发性能。

首先是安全性。Rust 的所有权、借用和生命周期机制可以在编译阶段防止空指针、悬垂引用等常见问题，这意味着你可以写出既安全又高效的代码，而不必担心内存泄漏或段错误。

其次是性能。Rust 是一门编译型语言，运行时开销非常小，比 Python 快得多。在网络编程中，性能是非常重要的，因为网络通信通常需要处理大量的请求和响应。

最后是并发性能。Rust 的异步编程模型非常强大，可以让你轻松地处理大量的并发请求。异步编程可以提高程序的响应速度，减少资源浪费。

## TcpStream：实现可靠的 TCP 通信

TCP 是一种可靠的传输协议，适合传输大量数据。Rust 标准库中的 `TcpStream` 和 `TcpListener` 可以让你轻松地实现 TCP 通信。

我尝试用 `TcpStream` 实现一个简单的客户端和服务器。服务器端监听端口，接受客户端的连接，然后发送数据。客户端连接到服务器，接收数据。

**服务器端代码：**
```rust
use std::io::Write;
use std::net::TcpListener;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:8080").unwrap();
    println!("服务器正在监听端口 8080...");

    for stream in listener.incoming() {
        let mut stream = stream.unwrap();
        println!("客户端连接成功");

        let message = "Hello, Client!";
        stream.write_all(message.as_bytes()).unwrap();
        println!("已发送消息：{}", message);
    }
}
```

**客户端代码：**
```rust
use std::io::{Read, Write};
use std::net::TcpStream;

fn main() {
    let mut stream = TcpStream::connect("127.0.0.1:8080").unwrap();
    println!("已连接到服务器");

    let mut buffer = [0; 1024];
    stream.read(&mut buffer).unwrap();
    println!("收到消息：{}", String::from_utf8_lossy(&buffer));
}
```

这两段代码非常简单，但它们已经可以实现基本的 TCP 通信。当客户端连接到服务器时，服务器会发送 "Hello, Client!" 消息，客户端会接收并打印出来。

## UdpSocket：实现不可靠的 UDP 通信

UDP 是一种不可靠的传输协议，但它的速度比 TCP 快得多，适合传输实时数据，如音频和视频。Rust 标准库中的 `UdpSocket` 可以让你实现 UDP 通信。

我尝试用 `UdpSocket` 实现一个简单的客户端和服务器。服务器端监听端口，接收客户端的数据包，然后发送响应。客户端发送数据包到服务器，接收响应。

**服务器端代码：**
```rust
use std::io::Error;
use std::net::UdpSocket;

fn main() -> Result<(), Error> {
    let socket = UdpSocket::bind("127.0.0.1:8080")?;
    println!("服务器正在监听端口 8080...");

    let mut buffer = [0; 1024];
    loop {
        let (size, src) = socket.recv_from(&mut buffer)?;
        println!("收到来自 {:?} 的数据包：{}", src, String::from_utf8_lossy(&buffer[..size]));

        let message = "Hello, Client!";
        socket.send_to(message.as_bytes(), src)?;
        println!("已发送消息：{}", message);
    }
}
```

**客户端代码：**
```rust
use std::io::Error;
use std::net::UdpSocket;

fn main() -> Result<(), Error> {
    let socket = UdpSocket::bind("127.0.0.1:0")?;
    let server_addr = "127.0.0.1:8080";

    let message = "Hello, Server!";
    socket.send_to(message.as_bytes(), server_addr)?;
    println!("已发送消息：{}", message);

    let mut buffer = [0; 1024];
    let (size, src) = socket.recv_from(&mut buffer)?;
    println!("收到来自 {:?} 的数据包：{}", src, String::from_utf8_lossy(&buffer[..size]));

    Ok(())
}
```

这两段代码也非常简单，但它们已经可以实现基本的 UDP 通信。当客户端发送数据包到服务器时，服务器会发送 "Hello, Client!" 响应，客户端会接收并打印出来。

## Hyper：HTTP 客户端和服务器库

如果你需要开发 HTTP 应用，Hyper 是一个非常好的选择。Hyper 是 Rust 社区最流行的 HTTP 库之一，支持异步编程。

我尝试用 Hyper 实现一个简单的 HTTP 服务器。服务器端监听端口，接受客户端的请求，然后返回响应。

**服务器端代码：**
```rust
use hyper::{Body, Request, Response, Server};
use hyper::service::{make_service_fn, service_fn};
use std::convert::Infallible;
use std::net::SocketAddr;

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    println!("收到请求：{}", req.uri());

    let response = Response::new(Body::from("Hello, World!"));
    Ok(response)
}

#[tokio::main]
async fn main() {
    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));

    let make_svc = make_service_fn(|_conn| {
        async {
            Ok::<_, Infallible>(service_fn(handle_request))
        }
    });

    let server = Server::bind(&addr).serve(make_svc);
    println!("服务器正在监听端口 8080...");

    if let Err(e) = server.await {
        eprintln!("服务器错误：{}", e);
    }
}
```

这段代码非常简单，但它已经可以实现基本的 HTTP 服务器。当客户端发送请求时，服务器会返回 "Hello, World!" 响应。

## 实际案例：实现一个简单的 HTTP 服务器

现在，我将结合前面的知识，实现一个简单的 HTTP 服务器。这个服务器会提供一个简单的 API，返回当前时间。

**代码：**
```rust
use hyper::{Body, Request, Response, Server};
use hyper::service::{make_service_fn, service_fn};
use std::convert::Infallible;
use std::net::SocketAddr;
use chrono::prelude::*;

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    println!("收到请求：{}", req.uri());

    let path = req.uri().path();
    let response = if path == "/time" {
        let now = Utc::now();
        let time_str = now.format("%Y-%m-%d %H:%M:%S").to_string();
        Response::new(Body::from(time_str))
    } else {
        Response::new(Body::from("404 Not Found"))
    };

    Ok(response)
}

#[tokio::main]
async fn main() {
    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));

    let make_svc = make_service_fn(|_conn| {
        async {
            Ok::<_, Infallible>(service_fn(handle_request))
        }
    });

    let server = Server::bind(&addr).serve(make_svc);
    println!("服务器正在监听端口 8080...");

    if let Err(e) = server.await {
        eprintln!("服务器错误：{}", e);
    }
}
```

这段代码使用了 `chrono` 库来获取当前时间。当客户端发送请求到 `/time` 路径时，服务器会返回当前时间；当发送到其他路径时，服务器会返回 404 响应。

## 进阶功能：TLS 加密、WebSockets 的支持

如果你需要更高级的功能，如 TLS 加密和 WebSockets 支持，Hyper 也提供了相应的功能。你可以使用 `hyper-tls` 库来实现 TLS 加密，使用 `hyper-websocket` 库来实现 WebSockets 支持。

### TLS 加密

**代码：**
```rust
use hyper::Server;
use hyper::service::{make_service_fn, service_fn};
use hyper_tls::HttpsConnector;
use std::net::SocketAddr;

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    println!("收到请求：{}", req.uri());

    let response = Response::new(Body::from("Hello, TLS!"));
    Ok(response)
}

#[tokio::main]
async fn main() {
    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));

    let make_svc = make_service_fn(|_conn| {
        async {
            Ok::<_, Infallible>(service_fn(handle_request))
        }
    });

    let server = Server::bind(&addr).serve(make_svc);
    println!("服务器正在监听端口 8080...");

    if let Err(e) = server.await {
        eprintln!("服务器错误：{}", e);
    }
}
```

### WebSockets 支持

**代码：**
```rust
use hyper::Server;
use hyper::service::{make_service_fn, service_fn};
use hyper_websocket::WebSocket;
use std::net::SocketAddr;

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    println!("收到请求：{}", req.uri());

    let ws = WebSocket::from_request(req).unwrap();
    let (mut sender, mut receiver) = ws.split();

    tokio::spawn(async move {
        let mut count = 0;
        loop {
            let message = format!("Message {}", count);
            sender.send(Message::Text(message)).await.unwrap();
            count += 1;
            tokio::time::sleep(std::time::Duration::from_secs(1)).await;
        }
    });

    Ok(Response::new(Body::empty()))
}

#[tokio::main]
async fn main() {
    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));

    let make_svc = make_service_fn(|_conn| {
        async {
            Ok::<_, Infallible>(service_fn(handle_request))
        }
    });

    let server = Server::bind(&addr).serve(make_svc);
    println!("服务器正在监听端口 8080...");

    if let Err(e) = server.await {
        eprintln!("服务器错误：{}", e);
    }
}
```

这些代码只是简单的示例，实际应用中你需要根据自己的需求进行修改。

## 结语

通过这几天的学习，我已经对 Rust 的网络编程有了初步的了解。Rust 的网络编程非常强大，它的安全性、性能和并发性能都非常出色。

如果你也想学习 Rust 的网络编程，我建议你从基本的 TCP 和 UDP 通信开始，然后逐步学习更高级的功能，如 HTTP、TLS 加密和 WebSockets 支持。

最后，我希望你能在学习过程中保持耐心和热情，因为 Rust 的学习曲线比较陡峭，但它的回报也是非常丰厚的。