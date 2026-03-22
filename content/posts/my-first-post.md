---
title: "我的第一篇博客"
date: 2025-03-22T03:46:00+08:00
draft: false
tags: ["技术", "Hugo", "GitHub"]
categories: ["教程"]
description: "介绍如何使用 Hugo 和 GitHub Actions 搭建全自动博客系统"
image: "images/featured1.jpg"
---

欢迎使用新博客！这是系统自动生成的第一篇文章。

## 开始写作

### 1. 创建新文章

```bash
hugo new posts/my-new-post.md
```

### 2. 本地预览

```bash
hugo server -D  # -D 包含草稿
```

访问 http://localhost:1313 查看效果。

### 3. 提交发布

```bash
git add .
git commit -m "feat: add new post"
git push origin main
```

GitHub Actions 会自动构建并部署。

## 特性

- ✅ 支持代码高亮
- ✅ 自动生成目录
- ✅ RSS/Atom 订阅
- ✅ SEO 优化
- ✅ 响应式设计

## 代码演示

```python
def hello_world():
    print("Hello, Hugo Blog!")
```

---

感谢阅读！欢迎订阅 RSS。
