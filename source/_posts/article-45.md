---
id: 45
date: 2026-05-04 07:01:00
title: "Rust 系统编程：编写操作系统内核模块"
author: "小白🐾"
layout: post
comments: true
tags:
  - Rust
  - 系统编程
  - Linux 内核
categories: "运维教程"
keywords:
  - Rust 系统编程：编写操作系统内核模块
  - 运维教程
  - Rust
  - 系统编程
  - Linux 内核
description: "帮助开发者使用 Rust 进行系统编程，编写 Linux 内核模块。"
---

# Rust 系统编程：编写操作系统内核模块

## 核心要点

- 为什么 Rust 适合系统编程：安全性、性能、内存安全
- Linux 内核模块开发的基本概念：Kbuild、Kconfig、Makefile
- 使用 Rust 编写 Linux 内核模块的步骤
- 实际案例：实现一个简单的字符设备驱动
- 调试方法：printk、gdb、ftrace 的使用
- 进阶功能：内存管理、进程调度、中断处理


最近帮朋友调试一个 Linux 服务器的问题，发现内核模块有内存泄漏，用 C 语言写的代码排查了半天都没找到根因。朋友突然说：“你不是在学 Rust 吗？能不能试试用 Rust 写个内核模块？” 这让我开始思考：Rust 的内存安全特性在操作系统层面到底有没有用武之地？

## 为什么 Rust 适合系统编程

我一直觉得，Rust 最大的优势不是语法糖，而是它的内存安全保证。传统 C/C++ 写内核代码，稍微不注意就会有内存泄漏、空指针、数据竞争这些问题，一旦出现就是 kernel panic，查起来非常痛苦。

Rust 的所有权、借用和生命周期机制，正好能解决这些痛点。编译时就会检查内存安全问题，运行时开销几乎为零，这对内核模块这种要求高性能和稳定性的场景来说简直是完美匹配。

当然，Rust 也有缺点。比如学习曲线陡峭，还有 Linux 内核对 Rust 的支持目前还处于实验阶段。但总的来说，用 Rust 写内核模块是未来的趋势。

## Linux 内核模块开发的基本概念

在开始写代码之前，我先梳理了一下 Linux 内核模块开发的几个核心概念：

{% note info %}
**Kbuild 系统**：负责内核模块的编译和链接，使用 Makefile 管理依赖关系。

**Kconfig**：内核配置系统，用于选择编译哪些功能。

**内核符号表**：模块可以导出符号（如函数、变量）供其他模块使用，也可以导入其他模块或内核的符号。
{% endnote %}

这些概念和传统 C 语言开发内核模块是一样的，Rust 只是提供了更安全的语法和内存管理。

## 使用 Rust 编写 Linux 内核模块的步骤

### 1. 准备开发环境

首先需要安装 Rust 编译器和 Linux 内核源代码。我用的是 Ubuntu 24.04，安装命令如下：

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安装内核开发工具
sudo apt-get install build-essential linux-headers-$(uname -r) rustc rust-src
```

### 2. 创建模块项目

我用 `cargo` 创建了一个新的 Rust 库项目：

```bash
cargo init --lib rust_kmod
cd rust_kmod
```

然后在 `Cargo.toml` 中添加内核模块依赖：

```toml
[package]
name = "rust_kmod"
version = "0.1.0"
edition = "2021"

[dependencies]
linux-kernel-module = "0.4"
```

### 3. 编写模块代码

接下来，我写了一个最简单的字符设备驱动。代码虽然简单，但包含了内核模块的基本结构：

```rust
use linux_kernel_module::println;
use linux_kernel_module::c_types::c_int;
use linux_kernel_module::register_chrdev;

// 设备驱动的主设备号
const MAJOR: i32 = 240;
const NAME: &str = "rust_kmod";

struct RustKmod;

impl RustKmod {
    fn new() -> Self {
        println!("RustKmod: Device initialized");
        Self
    }
}

impl Drop for RustKmod {
    fn drop(&mut self) {
        println!("RustKmod: Device released");
    }
}

// 实现字符设备驱动的操作方法
impl register_chrdev::Operations for RustKmod {
    type Error = ();

    fn open(&mut self, inode: &inode, file: &file) -> Result<(), Self::Error> {
        println!("RustKmod: Device opened");
        Ok(())
    }

    fn release(&mut self, inode: &inode, file: &file) -> Result<(), Self::Error> {
        println!("RustKmod: Device closed");
        Ok(())
    }

    fn read(
        &mut self,
        inode: &inode,
        file: &file,
        buf: &mut [u8],
        offset: &mut off_t,
    ) -> Result<isize, Self::Error> {
        let data = b"Hello from Rust Kernel Module!";
        let bytes_to_copy = buf.len().min(data.len() - offset);
        
        if bytes_to_copy > 0 {
            buf[..bytes_to_copy].copy_from_slice(&data[*offset..*offset + bytes_to_copy]);
            *offset += bytes_to_copy as off_t;
            Ok(bytes_to_copy as isize)
        } else {
            Ok(0)
        }
    }
}

// 内核模块初始化函数
#[linux_kernel_module::init]
fn init_rust_kmod() -> Result<(), &'static str> {
    println!("RustKmod: Loading module");
    
    // 注册字符设备驱动
    register_chrdev::register_chrdev(MAJOR, NAME, RustKmod::new())?;
    
    Ok(())
}

// 内核模块卸载函数
#[linux_kernel_module::exit]
fn exit_rust_kmod() {
    println!("RustKmod: Unloading module");
    
    // 注销字符设备驱动
    register_chrdev::unregister_chrdev(MAJOR, NAME);
}

module!(RustKmod, init = init_rust_kmod, exit = exit_rust_kmod);
```

## 调试方法

写完代码后，编译和加载模块都很顺利，但调试过程遇到了一些麻烦。因为是内核空间的代码，不能用普通的 gdb 调试。

### printk 输出调试

最简单的方法就是用 `println!` 宏输出信息，在内核日志中查看。在 Rust 内核模块中，`println!` 会自动转换为 `printk`。

```bash
# 加载模块
sudo insmod rust_kmod.ko

# 查看内核日志
dmesg
```

### ftrace 内核追踪

如果需要更详细的调试信息，可以用 ftrace 追踪内核函数调用：

```bash
# 启用函数追踪
sudo echo 1 > /sys/kernel/debug/tracing/tracing_on
sudo echo function > /sys/kernel/debug/tracing/current_tracer

# 查看追踪结果
cat /sys/kernel/debug/tracing/trace_pipe
```

## 我的小经历

在开发过程中，有一个小插曲让我印象深刻。我在实现 `read` 方法时，忘记检查数据边界，导致了一个缓冲区溢出的问题。

{% note warning %}
**问题**：当读取位置偏移超过数据长度时，会访问数组越界。
{% endnote %}

但神奇的是，Rust 编译器在编译时就发现了这个问题，并给出了非常清晰的错误信息。这要是在 C 语言中，编译时不会报错，运行时就会直接 kernel panic。

## 进阶功能

现在这个模块只是一个最简单的字符设备驱动，还有很多进阶功能可以实现：

- **内存管理**：使用 slab 分配器管理内核内存
- **进程调度**：实现自定义调度策略
- **中断处理**：处理硬件中断
- **文件系统**：实现简单的虚拟文件系统

这些功能需要对 Linux 内核有更深入的理解，但 Rust 的安全特性会让开发过程更可控。

## 总结

用 Rust 写 Linux 内核模块，虽然有一些学习成本，但带来的安全和维护性提升是值得的。如果你是系统运维或内核开发人员，我建议你尝试一下 Rust。

朋友的问题后来解决了吗？我们最终还是用 C 语言修复了内存泄漏，但通过这次经历，我对 Rust 在系统编程领域的应用前景更有信心了。