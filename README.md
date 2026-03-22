# 全自动博客系统

[![Deploy to GitHub Pages](https://github.com/HeiYingQWQ/blog/workflows/Deploy%20Hugo%20site%20to%20GitHub%20Pages/badge.svg)](https://github.com/HeiYingQWQ/blog/actions)

基于 **Hugo** 和 **GitHub Pages** 构建的现代化、全自动化博客系统。

## ✨ 特性

- 🚀 **极速构建** - Hugo 生成静态站点，毫秒级编译
- 🤖 **全自动部署** - GitHub Actions 自动构建发布
- 📝 **简洁写作** - Markdown 格式，本地实时预览
- 📡 **RSS/Atom** - 内置订阅源，自动生成
- 🎨 **现代化主题** - PaperMod 主题，支持暗黑模式
- 🌍 **全球分发** - GitHub Pages CDN 加速
- 🔒 **HTTPS** - 自动 SSL 证书
- 📱 **响应式** - 完美适配移动端

## 📦 技术栈

| 技术 | 用途 |
|------|------|
| Hugo | 静态站点生成器 |
| GitHub Pages | 托管和 CDN |
| GitHub Actions | CI/CD 自动化 |
| Markdown | 内容格式 |
| PaperMod | 主题模板 |

## 🚦 快速开始

### 1. 复刻仓库

点击右上角 **Fork** 按钮复制本仓库到你的 GitHub 账号。

### 2. 启用 GitHub Pages

在你的仓库设置中：

1. 进入 **Settings** → **Pages**
2. Source 选择 **GitHub Actions**
3. 保存设置

### 3. 自定义配置

编辑 `config.toml` 文件：

```toml
baseURL = "https://YOUR_USERNAME.github.io/"
title = "你的博客标题"
author = "你的名字"

[[params.socialIcons]]
  name = "github"
  url = "https://github.com/YOUR_USERNAME"
```

### 4. 开始写作

#### 创建新文章

```bash
# 本地需要安装 Hugo (https://gohugo.io/installation/)
hugo new posts/我的新文章.md
```

编辑 `content/posts/我的新文章.md` ：

```yaml
---
title: "我的新文章"
date: 2025-03-22T12:00:00+08:00
draft: false
tags: ["标签"]
categories: ["分类"]
---
```

#### 本地预览

```bash
hugo server -D
```

访问 http://localhost:1313 查看效果。

### 5. 发布

```bash
git add .
git commit -m "feat: add new post"
git push origin main
```

等待几秒，GitHub Actions 会自动构建并部署。访问你的 GitHub Pages URL 查看新文章。

## 📁 项目结构

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml    # CI/CD 配置
├── archetypes/           # 内容模板
├── assets/              # SCSS, images, JS 源文件
├── content/             # Markdown 内容
│   ├── posts/           # 博客文章
│   ├── about.md         # 关于页面
│   └── projects/        # 项目页面
├── layouts/             # 自定义模板 (覆盖主题)
├── static/              # 静态文件 (favicon, robots.txt)
├── themes/              # 主题 (git submodule)
├── config.toml          # Hugo 配置
├── go.mod               # Go modules
└── README.md
```

## 🔧 配置说明

详细配置参考 [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)。

### 核心配置

- **baseURL**: 你的博客网址
- **theme**: 主题名称 (默认 papermod)
- **title**: 博客标题
- **author**: 作者名
- **outputs**: 输出格式 (HTML, RSS, Atom)

### RSS/Atom

Hugo 自动生成 RSS 订阅源 (`/index.xml`)。如需 Atom，在 `config.toml` 中启用：

```toml
[outputs]
  home = ["HTML", "RSS", "Atom"]
```

订阅地址: `https://YOUR_USERNAME.github.io/index.xml` 或 `/atom.xml`

## 🌐 自定义域名 (可选)

1. 在仓库 **Settings** → **Pages** 中，Custom domain 输入你的域名
2. 在 DNS 添加 `CNAME` 记录指向 `YOUR_USERNAME.github.io`
3. GitHub 会自动申请 HTTPS 证书 (约 10-30 分钟)

## 📝 写作技巧

### Front Matter

每篇文章以 YAML front matter 开头：

```yaml
---
title: "文章标题"
date: 2025-03-22T12:00:00+08:00
draft: false
tags: ["技术", "Hugo"]
categories: ["教程"]
description: "文章摘要"
image: "images/cover.jpg"
---
```

### 草稿管理

- 新建文章默认 `draft: true`，位于 `content/posts/` 或 `content/drafts/`
- 本地预览草稿: `hugo server -D` (`-D` 包含草稿)
- 发布时设置 `draft: false` 并推送到 GitHub

### 代码高亮

Hugo 内置代码高亮，使用 fenced code blocks：

```python
def hello():
    print("Hello!")
```

## 🛠️ 常用命令

```bash
# 安装 Hugo (macOS)
brew install hugo

# 创建新文章
hugo new posts/文章名.md

# 本地开发服务器 (实时预览)
hugo server -D

# 生产构建
hugo --gc --minify

# 测试构建
hugo --gc --minify --cleanDestinationDir
```

## 📚 资源链接

- [Hugo 官方文档](https://gohugo.io/documentation/)
- [PaperMod 主题文档](https://theme-asme.xyz/)
- [GitHub Pages 文档](https://docs.github.com/en/pages)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

## 📄 许可证

MIT License - 自由使用、修改、分发。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**开始你的博客之旅吧！** 🎉
