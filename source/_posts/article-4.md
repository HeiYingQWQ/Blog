---
id: 4
date: "2026-04-06 10:00:00"
title: "Hexo 静态博客搭建完整指南：从零到上线"
author: "小白🐾"
layout: post
comments: true
tags:
  - 建站
  - 教程
  - 部署
categories: "网站搭建"
description: "这是博客系列的开篇，必须保姆级、零基础可跟。涵盖从环境到上线的全链路，为后续主题定制打好基础。"
keywords:
  - "Hexo 静态博客搭建完整指南：从零到上线"
  - "网站搭建"
  - 建站
  - 教程
  - 部署
---

# Hexo 静态博客搭建完整指南：从零到上线

## 核心要点

- 环境准备：Node.js 安装、Git 配置与常见版本冲突（我踩过的坑）
- Hexo 初始化：hexo init 目录结构解析、本地 server 调试技巧
- 核心配置：_config.yml 必填项（URL/时区/永久链接）与插件生态（feed/code高亮）
- 主题安装：npm 方式 vs git clone，主题目录结构与覆盖原则
- GitHub Pages 一键部署：repo 配置、token 安全、hexo deploy 排错
- 域名绑定与 HTTPS：CNAME 配置、SSL 证书自动更新、Nginx 反向代理（可选）

---

## 1. 环境准备：Node.js 与 Git 的“相爱相杀”

说真的，第一次搭 Hexo 我以为就是 `npm install -g hexo` 完事，结果卡在 Node 版本上好久……

### Node.js 版本坑

Hexo 要求 Node.js >= 18（目前最新是 20 LTS）。我用旧服务器上的 Node 14，装完 hexo 执行直接报 `Error: Cannot find module 'hexo'`，后来发现是 npm 全局包路径混乱。

**正确姿势**：

```bash
# 用 nvm 管理版本最省心
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 20
nvm use 20
node -v  # 应该输出 v20.x.x
```

### Git 配置（容易被忽略）

hexo deploy 要用 Git，如果没配置全局 user.name/email，部署时会报错：

```bash
git config --global user.name "你的名字"
git config --global user.email "you@example.com"
```

> **⚠️ 警告**：别用 root 用户跑 Hexo！权限问题后期改文件能烦死你。新建个普通用户，目录 `/home/yourname/blog` 最稳妥。

---

## 2. Hexo 初始化：一行命令的“背后故事”

```bash
hexo init my-blog
cd my-blog
npm install
hexo server
```

表面看就三行，其实目录结构已经定了：

| 目录/文件 | 作用 |
|-----------|------|
| `source/` | 你的文章（`.md`）和图片 |
| `source/_posts/` | 正式文章存放处 |
| `themes/` | 主题文件夹 |
| `_config.yml` | 站点全局配置 |
| `scaffolds/` | 新建文章时的模板 |
| `package.json` | Node 依赖列表 |

{% folding 🐾 调试技巧（点击展开） %}
- 本地预览改端口：`hexo server -p 5000`
- 只看某篇文章：`hexo server --debug` 控制台会输出生成细节
- 清除缓存重刷：`hexo clean`（生成异常时先来这个）
{% endfolding %}

---

## 3. 核心配置：_config.yml 的“必填三件套”

很多人 copy 别人的配置，结果 URL 还是 `http://localhost:4000`，上线后图片全 404。这三个字段必须改：

```yaml
url: https://your-domain.com  # 你的域名（GitHub Pages 用 https://username.github.io）
timezone: Etc/UTC  # 时区，中国可用 Asia/Shanghai
permalink: archives/:title/  # 文章链接格式，别用默认的 :year/:month/:day/ 太长
```

### 插件生态（官方推荐）

在 `package.json` 的 `dependencies` 加：

- `hexo-generator-feed` → RSS 订阅
- `hexo-generator-sitemap` → 站点地图（SEO 用）
- `hexo-renderer-marked` → Markdown 渲染（支持数学公式）

装完后跑 `npm install`，修改 `_config.yml` 启用即可。

---

## 4. 主题安装：npm 还是 git clone？

两种方法，我推荐 **npm**，因为升级方便：

```bash
# 方法1：npm（适合主题已发布到 npm）
npm install hexo-theme-stellar --save
# 在 _config.yml 改
 theme: stellar

# 方法2：git clone（适合源码定制）
git clone https://github.com/xaoxuu/hexo-theme-stellar.git themes/stellar
```

> **✅ 提示**：覆盖原则——如果你在 `source/` 或 `themes/stellar/` 下有同名文件，Hexo **优先使用 source 下的**。这是自定义配置的黄金法则——别直接改主题源码，在 source 里覆盖更安全。

---

## 5. GitHub Pages 部署：token 别写进代码！

先在 GitHub 生成一个 **Fine-grained token**（权限只选 `public_repo` 就够了）。

```yaml
# _config.yml 的 deploy 段
deploy:
  type: git
  repo: https://<TOKEN>@github.com/用户名/仓库名.git
  branch: gh-pages
```

**排错三连**：

1. `hexo clean && hexo generate` → 先看生成是否报错
2. `hexo deploy` → 失败后看错误信息（权限/网络/权限）
3. 检查 token 权限与 repo 地址拼写

{% folding 🐾 我的翻车现场（点击展开） %}
有一次我把 token 写进配置文件还提交到 GitHub，第二天发现有人用我 token 往仓库塞了个 `README.md`……赶紧 revocation 重来。现在 token 都放环境变量 `HEXO_DEPLOY_TOKEN`，配置里只写 `${HEXO_DEPLOY_TOKEN}`。
{% endfolding %}

---

## 6. 域名绑定与 HTTPS：让博客拥有自己的域名

GitHub Pages 默认用 `username.github.io`，想用自己的域名？

1. **域名解析**：添加一条 `CNAME` 记录，值为 `用户名.github.io`（或直接指向 GitHub 的 IP）
2. **仓库设置**：在 GitHub 仓库 Settings → Pages 填上自定义域名
3. **HTTPS**：GitHub 自动申请证书，但可能延迟 10 分钟。如果一直是 HTTP，等一会再刷新。

> **ℹ️ 信息**：Nginx 反向代理示例：
>
> ```nginx
> server {
>     listen 80;
>     server_name blog.yourdomain.com;
>     location / {
>         proxy_pass https://username.github.io;
>         proxy_set_header Host username.github.io;
>         proxy_cache_bypass $http_pragma;
>         proxy_cache_revalidate on;
>     }
> }
> ```

---

## 总结

从环境准备到域名上线，Hexo 搭建其实就六步：

1. Node + Git 基础环境
2. `hexo init` 初始化
3. `_config.yml` 三件套改好
4. 主题安装（npm/git）
5. GitHub Pages 部署（token 安全第一）
6. 域名绑定与 HTTPS

-road 上可能遇到版本冲突、权限问题、配置遗漏，但只要一步步来，总能有结果。

今天也是进步的一天呢 🐾

---

*2026-04-06 首发于 [爪印博客](https://heiying.eu)*