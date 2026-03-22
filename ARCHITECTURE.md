# 全自动博客系统架构设计

## 1. 技术栈选型

### 核心组件
| 组件 | 选型 | 理由 |
|------|------|------|
| 静态站点生成器 | **Hugo** |  blazing fast, single binary, 丰富的主题生态, 内置RSS/Atom支持 |
| 托管平台 | **GitHub Pages** | 免费、全球CDN、HTTPS、与GitHub Actions无缝集成 |
| CI/CD | **GitHub Actions** | 原生集成、无需外部服务、自动化部署 |
| 版本控制 | **Git** | 标准方案，支持分支管理 |
| 内容格式 | **Markdown** | 简单易用，工具链成熟 |

### 为什么选择 Hugo 而非 Hexo/Jekyll
- **性能**: Hugo 编译速度极快（毫秒级），适合大型站点
- **单一二进制**: 无需Node.js/Python环境，部署更简单
- **主题生态**: 丰富的高质量主题库 (https://themes.gohugo.io)
- **RSS/Atom**: 内置完整订阅支持，开箱即用
- **未来扩展**: 可通过Cloudflare Workers增强API功能

## 2. 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                     用户访问流程                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  GitHub Push → GitHub Actions CI → Hugo Build → Deploy │
│                                                         │
│  ┌─────────┐       ┌─────────────┐       ┌─────────┐   │
│  │  作者   │──────▶│   GitHub    │──────▶│  Pages  │   │
│  └─────────┘ 提交  └─────────────┘ 构建   └─────────┘   │
│       │              Actions Workflow        CDN       │
│       │                                              │
│       ▼                                              ▼
│  ┌─────────┐                                ┌─────────┐  │
│  │ 本地编辑 │                                │  用户   │  │
│  │ + 测试  │                                │  访问   │  │
│  └─────────┘                                └─────────┘  │
│                                                         │
│  RSS/Atom Feed  ←── Hugo 自动生成 ────┐               │
│  ( /index.xml )                        │               │
│                                        ▼               │
│                                 各种阅读器订阅           │
└─────────────────────────────────────────────────────────┘
```

### 工作流详解

1. **本地开发阶段**
   - 作者在本地创建 Markdown 内容
   - 运行 `hugo server` 实时预览
   - 通过 Git 提交到 GitHub 仓库

2. **CI/CD 自动化阶段**
   - GitHub Actions 监听 push/PR 事件
   - 安装 Hugo (extended 版本)
   - 执行 `hugo --gc --minify` 构建静态文件
   - 自动部署到 GitHub Pages

3. **部署与分发阶段**
   - GitHub Pages 托管生成的 `public/` 目录
   - 全球 CDN 分发静态资源
   - 域名支持 HTTPS (自动证书)
   - RSS/Atom 订阅源自动生成于根目录

## 3. 项目结构

```
blog/
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD 流水线配置
├── archetypes/                 # 内容模板
│   └── default.md
├── assets/                     # 静态资源源文件 (SCSS, images, JS)
│   ├── css/
│   ├── images/
│   └── js/
├── content/                    # Markdown 内容
│   ├── posts/                  # 博客文章
│   │   └── my-first-post.md
│   ├── about.md
│   └── projects/
├── layouts/                    # 自定义模板 (覆盖主题)
│   └── partials/
├── static/                     # 直接复制的静态文件 (favicon, robots.txt)
│   ├── favicon.ico
│   └── robots.txt
├── themes/                     # Git submodule 或直接仓库引用
│   └── papermod/               # 示例主题
├── config.toml                 # Hugo 配置文件
├── go.mod                      # Go modules (如果需要自定义组件)
├── netlify.toml                # 可选: Netlify 配置 (备用方案)
├── README.md                   # 项目说明
└── docs/                       # 文档目录 (可选)
```

## 4. 核心配置

### Hugo 配置要点 (config.toml)
- BaseURL 设置 (GitHub Pages URL)
- RSS/Atom 配置 (自动生成)
- 主题选择
-  permalinks 结构 (日期、slug)
- Markdown 扩展 (数学公式、脚注等)
- 多语言支持 (i18n)

### GitHub Actions 工作流
- **触发条件**: push 到 main 分支
- **环境**: Ubuntu + Hugo extended
- **构建命令**: `hugo --gc --minify`
- **部署**: peaceiris/actions-gh-pages 动作

### RSS/Atom 设置
Hugo 默认生成 RSS 2.0 格式的 feed。如需 Atom，需要在 config 中显式启用：
```toml
[outputs]
  home = ["HTML", "RSS", "Atom"]
```

## 5. 内容管理策略

### 文章元数据 (Front Matter)
```yaml
---
title: "文章标题"
date: 2025-03-22T03:46:00+00:00
draft: false
tags: ["技术", "博客"]
categories: ["教程"]
description: "文章摘要"
image: "featured-image.jpg"
---
```

### 草稿工作流
- 默认 `draft: true` 在 `content/drafts/`
- 使用 `hugo server --buildDrafts` 本地预览
- 推送到 `content/posts/` 并设置 `draft: false` 后发布

## 6. 自动化 API 扩展 (可选)

### Cloudflare Workers (Future)
- `/api/posts` - 获取文章 JSON API
- `/api/search` - 全文检索 API
- 避免静态文件直接暴露内容结构

## 7. 部署验证清单

- [ ] 域名解析正确 (CNAME 或 A 记录)
- [ ] HTTPS 证书生效
- [ ] 首页可访问
- [ ] 文章页可访问
- [ ] RSS/Atom 订阅地址有效
- [ ] 构建无错误
- [ ] 部署后 GitHub Pages 状态为 "Your site is published"
- [ ] 移动端响应式正常

## 8. 安全与性能

- **安全**: GitHub Pages 自动隔离，无服务器风险
- **性能**: Hugo 生成静态文件，CDN 加速，Lighthouse 评分 > 90
- **SEO**: 自动 sitemap.xml, robots.txt, meta tags
- **备份**: Git 版本控制 + GitHub 仓库

## 9. 后续扩展

- 评论系统: utterances (GitHub Issues 驱动) 或 giscus
- 分析: Google Analytics / Plausible
- 表单: Formspree 或静态表单 + Cloudflare Workers

---

**文档版本**: v1.0
**创建日期**: 2025-03-22
