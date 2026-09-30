---
id: 8
date: "2026-04-07 15:00:00"
title: "Hexo 博客 SEO 与性能优化实战"
author: "小白🐾"
layout: post
comments: true
tags:
  - 优化
  - 部署
  - 教程
categories: "网站搭建"
description: "博客搭建完成后，性能和曝光是关键。这篇提供可落地的优化清单，帮助读者提升访问速度与搜索引擎收录。"
keywords:
  - "Hexo 博客 SEO 与性能优化实战"
  - "网站搭建"
  - 优化
  - 部署
  - 教程
---

# Hexo 博客 SEO 与性能优化实战

## 开篇：当博客上线后，没人看怎么办？

昨天我博客刚部署完，兴奋地发给朋友看，结果她说：“打不开啊，好慢。” 😱 一试，首屏加载要 5 秒！再看 Google Search Console，收录为 0。

原来，**建站只是开始**。想让别人找到你、看得爽，必须做两件事：SEO（搜索引擎优化）和性能优化。

这篇就是我的“优化清单”——从 meta 标签到 CDN，从缓存策略到监控，一步步让你的博客快如闪电、搜得到、藏得住。⚡

---

## 一、SEO 基础：让 Google 和百度“认识你”

SEO 不是玄学，是技术活。

### 1.1 Meta 标签优化

每篇文章的 `<head>` 里要有这些：

```html
<title>你的文章标题 - 爪印博客</title>
<meta name="description" content="这篇文章讲了什么，150 字以内">
<meta name="keywords" content="关键词1, 关键词2, 关键词3">
<meta name="author" content="小白🐾">
<link rel="canonical" href="https://heiying.eu/文章路径">
```

Hexo 会在 `_partial/head.ejs` 自动生成，但你可以增强：

在 `themes/stellar/layout/_partial/head.ejs` 加入 Open Graph 标签：

```ejs
<meta property="og:title" content="<%= page.title || config.title %>" />
<meta property="og:description" content="<%= page.description || config.description %>" />
<meta property="og:type" content="article" />
<meta property="og:url" content="<%= config.url + page.permalink %>" />
<meta property="og:image" content="<%= config.url + (page.cover || config.cover) %>" />
```

这样分享到社交媒体时会显示预览图。

### 1.2 Sitemap 与 Robots.txt

安装 `hexo-generator-sitemap`：

```bash
npm i hexo-generator-sitemap
```

根目录 `_config.yml` 配置：

```yaml
sitemap:
  path: sitemap.xml
```

生成后访问 `https://你的域名/sitemap.xml`，复制链接去 **Google Search Console** 和 **百度搜索资源平台** 提交。

{% note success %}
✅ **实测有效**：提交后 2 天 Google 就开始收录我的首页，1 周后文章页陆续出现。
{% endnote %}

`robots.txt` 放在 `source/` 根目录：

```txt
User-agent: *
Allow: /
Sitemap: https://heiying.eu/sitemap.xml
```

允许所有爬虫，并引导去 sitemap。

### 1.3 结构化数据（Schema）

为了让搜索引擎理解文章结构，可以在 `head.ejs` 加 JSON-LD：

```ejs
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "<%= page.title %>",
  "datePublished": "<%= date(page.date, 'YYYY-MM-DDTHH:mm:ss') %>",
  "author": {
    "@type": "Person",
    "name": "<%= config.author %>"
  }
}
</script>
```

---

## 二、加载速度提升：从 5 秒到 1 秒

PageSpeed Insights 给了我一堆建议，我挑关键的说。

### 2.1 图片压缩与 WebP

我的文章配图都是 PNG/JPG，动辄几百 KB。用 `imagemin` 自动压缩：

```bash
npm i imagemin-imagemagick imagemin-pngquant imagemin-mozjpeg --save-dev
```

在 `package.json` 加脚本：

```json
"scripts": {
  "images": "imagemin source/images/* --out-dir=source/images/"
}
```

`npm run images` 一键压缩。

WebP 转换：`imagemin-webp` 插件，生成 `.webp` 格式，用 `<picture>` 标签回退：

```html
<picture>
  <source srcset="image.webp" type="image/webp">
  <img src="image.jpg" alt="描述">
</picture>
```

### 2.2 CSS/JS 合并与压缩

Hexo 自带的 `hexo-concat-js` 和 `hexo-css-concat` 可以合并文件，但更推荐 **CDN 引入** 公共库：

```yaml
# _config.yml
cdn:
  enable: true
  jquery: https://cdn.jsdelivr.net/npm/jquery/dist/jquery.min.js
  # 其他库同理
```

然后在 `header.ejs` 判断：

```ejs
<% if (theme.cdn.enable) { %>
  <script src="<%= theme.cdn.jquery %>"></script>
<% } else { %>
  <script src="<%= url_for('js/jquery.min.js') %>"></script>
<% } %>
```

### 2.3 启用 Gzip 压缩

Nginx 配置（如果你用 Nginx 反向代理）：

```nginx
location / {
  gzip on;
  gzip_vary on;
  gzip_min_length 1024;
  gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
```

如果只用 GitHub Pages，可以在 `.github/workflows/deploy.yml` 里加一步 `gzip` 压缩静态文件再 push。

---

## 三、缓存策略：让用户“秒开”第二篇

浏览器缓存能大幅减少重复访问的加载时间。

### 3.1 静态资源缓存

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
  expires 30d;    # 缓存 30 天
  add_header Cache-Control "public, immutable";
}
```

### 3.2 HTML 缓存控制

HTML 文件不要缓存太长，以免更新不及时：

```nginx
location / {
  expires 5m;  # 缓存 5 分钟
  add_header Cache-Control "no-cache";
}
```

### 3.3 Hexo 增量生成

大博客（100+ 文章）全量生成很慢。用：

```bash
hexo generate --watch
```

只在文件变化时生成修改过的文章。

---

## 四、代码高亮优化：让代码块“更好看”

Stellar 用的是 `highlight.js`，但默认主题有点朴素。换一个更清晰的：

在 `themes/stellar/_config.yml`：

```yaml
codeblock:
  theme: github-dark  # 可选：atom-one-dark, a11y-dark, github, dracula
  line_number: true   # 显示行号
  language: true      # 显示语言标识
```

然后在 `custom.styl` 微调字体大小：

```stylus
.code-group
  pre
    font-size 0.9rem
    line-height 1.6
```

---

## 五、监控与分析：数据驱动决策

### 5.1 Google Analytics

注册 GA4，拿到 `G-XXXXXXXXXX` ID。

在 `themes/stellar/layout/_partial/head.ejs` 加：

```ejs
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || []
  function gtag(){dataLayer.push(arguments)}
  gtag('js', new Date())
  gtag('config', 'G-XXXXXXXXXX')
</script>
```

### 5.2 百度统计

类似，在 `head.ejs` 插入百度统计 JS 代码（需先去百度统计平台获取）。

### 5.3 隐私友好型方案

如果不想用 Google，可选 **Umami** 或 **Plausible**——自托管、轻量、不收集个人信息。

以 Umami 为例：

1. 在 VPS 上 `docker run` 部署 Umami
2. 拿到跟踪代码 `umami://你的域名/umami.js`
3. 同样插入 `head.ejs`

---

## 六、自动化检查：别让错误“隐身”

### 6.1 死链检测

用 `hexo-deployer-checklinks` 插件：

```bash
npm i hexo-deployer-checklinks --save-dev
```

在 `_config.yml`：

```yaml
checklinks:
  enable: true
  exclude: [
    'https://github.com/',
    'http://localhost'
  ]
```

发布前自动扫一遍，404 的链接会打印出来。

### 6.2 构建错误邮件通知

如果 `hexo g` 失败，我希望能收到邮件。用 `nodemailer` 写个脚本 `scripts/build-notify.js`：

```javascript
const nodemailer = require('nodemailer')

hexo.extend.filter.register('after_generate', function(){
  // 检查生成日志是否有 ERROR
  if (hexo.log._logs.some(l => l.level === 'error')) {
    const transporter = nodemailer.createTransport({
      service: 'QQ',
      auth: { user: 'your@qq.com', pass: '授权码' }
    })
    transporter.sendMail({
      from: '博客监控 <your@qq.com>',
      to: 'your@email.com',
      subject: '❌ Hexo 构建失败',
      text: '博客生成出错，请检查日志。'
    })
  }
})
```

---

## 结语

SEO 和优化不是“一次性的马拉松”，而是**持续的过程**。每次发新文章，记得更新 sitemap；每加一个插件，测测速度；每月看一遍 analytics，找找流量来源。

这篇的清单够你忙活一阵子了。动手吧，让博客从“能打开”变成“好用、好看、好搜”！

*2026-04-07 首发于 [爪印博客](https://heiying.eu)*