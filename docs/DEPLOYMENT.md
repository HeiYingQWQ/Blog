# 部署与配置指南

本文档详细说明全自动博客系统的配置、部署和验证流程。

## 目录

- [前置要求](#前置要求)
- [安装配置](#安装配置)
- [GitHub 设置](#github-设置)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [RSS/Atom 配置](#rssatom-配置)
- [自定义主题](#自定义主题)
- [自定义域名](#自定义域名)
- [验证清单](#验证清单)
- [故障排除](#故障排除)

## 前置要求

- GitHub 账号
- 本地已安装 Git
- (可选) 本地已安装 Hugo 用于开发预览

### 安装 Hugo

```bash
# macOS
brew install hugo

# Ubuntu/Debian
sudo apt update && sudo apt install hugo

# Windows
# 从 https://github.com/gohugoio/hugo/releases 下载

# 其他平台见: https://gohugo.io/installation/
```

验证安装：

```bash
hugo version
# Hugo Static Site Generator v0.128.0-... extended ...
```

## 安装配置

1. **Fork 本仓库**到你的 GitHub 账号

2. **克隆到本地**：

```bash
git clone https://github.com/YOUR_USERNAME/blog.git
cd blog
```

3. **修改配置文件** `config.toml`：

```toml
baseURL = "https://YOUR_USERNAME.github.io/"  # 或你的自定义域名
title = "我的博客"
author = "你的名字"
theme = "papermod"

[[params.socialIcons]]
  name = "github"
  url = "https://github.com/YOUR_USERNAME"
```

4. **(可选) 获取主题**：

主题通过 go.mod 管理，运行：

```bash
hugo mod get github.com/adityatelange/hugo-PaperMod
hugo mod tidy
```

或在 CI 中自动下载。

5. **本地预览**：

```bash
hugo server -D
```

访问 http://localhost:1313 查看。

## GitHub 设置

### 创建 GitHub Pages

1. 进入仓库 **Settings** → **Pages**
2. **Build and deployment** → Source: 选择 **GitHub Actions**
3. 保存

### 创建 GitHub Token (仅需要额外权限时)

默认 `GITHUB_TOKEN` 已足够部署。如果需要其他仓库访问权限：

1. Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. 勾选 `repo` 权限
4. 复制 token
5. 在仓库 Settings → Secrets and variables → Actions → New repository secret
6. Name: `PAT_TOKEN`，Value: 粘贴 token

修改 `.github/workflows/deploy.yml`，将 `secrets.GITHUB_TOKEN` 改为 `secrets.PAT_TOKEN`

## GitHub Actions CI/CD

工作流文件位于 `.github/workflows/deploy.yml`。

### 触发器

- `push` 到 `main` 分支
- `pull_request` 到 `main` 分支

### 工作流步骤

1. **Checkout**: 检出代码，包含子模块
2. **Setup Hugo**: 使用 peaceiris/actions-hugo 安装 Hugo extended
3. **Build**: 运行 `hugo --gc --minify` 构建静态文件到 `public/`
4. **Deploy**: 使用 peaceiris/actions-gh-pages 推送到 `gh-pages` 分支

### 构建缓存 (优化)

可在 workflow 中添加缓存：

```yaml
- name: Cache Hugo modules
  uses: actions/cache@v3
  with:
    path: /tmp/hugo_cache
    key: ${{ runner.os }}-hugomod-${{ hashFiles('go.sum') }}
    restore-keys: ${{ runner.os }}-hugomod-
```

## RSS/Atom 配置

Hugo 默认生成 RSS 2.0 格式。启用 Atom：

```toml
[outputs]
  home = ["HTML", "RSS", "Atom"]
```

订阅地址：

- RSS: `https://YOUR_USERNAME.github.io/index.xml`
- Atom: `https://YOUR_USERNAME.github.io/atom.xml`

### 自定义 Feed 模板 (可选)

在 `layouts/_default/` 创建 `rss.xml` 或 `atom.xml` 覆盖默认模板。

## 自定义主题

PaperMod 主题配置详见 `config.toml` 中的 `[params]` 部分。

### 常用 PaperMod 设置

```toml
[params]
  defaultTheme = "auto"     # auto | dark | light
  ShowReadingTime = true
  ShowShareButtons = true
  ShowPostNavLinks = true
  ShowBreadCrumbs = true
  ShowCodeCopyButtons = true
  ShowWordCount = true

  # 个人资料模式
  [[params.profileMode]]
    enabled = true
    title = "博客标题"
    subtitle = "个人简介"

  # 社交链接
  [[params.socialIcons]]
    name = "github"
    url = "https://github.com/USERNAME"
```

### 覆盖主题模板

在 `layouts/` 创建与主题相同的路径结构即可覆盖。例如：

- 覆盖首页模板: `layouts/index.html`
- 覆盖文章页模板: `layouts/_default/single.html`
- 覆盖列表页模板: `layouts/_default/list.html`

### 添加自定义 CSS

在 `assets/css/` 创建 `custom.css`，在 `config.toml` 中引用：

```toml
[params]
  customCSS = ["css/custom.css"]
```

或在主题 head 中引入。

## 自定义域名

### DNS 配置

添加 `CNAME` 记录：

| 类型 | 主机/名称 | 值/指向 |
|------|-----------|---------|
| CNAME | @ 或 www | YOUR_USERNAME.github.io. |

或使用 A 记录：

| 类型 | 主机 | 值 |
|------|------|----|
| A | @ | 185.199.108.153 |
| A | @ | 185.199.109.153 |
| A | @ | 185.199.110.153 |
| A | @ | 185.199.111.153 |

### 仓库配置

1. Settings → Pages → Custom domain: 输入你的域名
2. 勾选 **Enforce HTTPS** (证书生成后生效，约 10-30 分钟)
3. 提交一次代码触发构建

### CDN 缓存清理

首次切换域名后，可能需要等待 DNS 全球生效 (几分钟到几小时)。

## 验证清单

完成部署后，对照以下清单验证：

- [ ] **GitHub Pages 状态**: Settings → Pages 显示 "Your site is published at https://..."
- [ ] **HTTPS**: 网址显示 🔒 锁标记，无证书错误
- [ ] **首页**: 访问根路径可加载，样式正常
- [ ] **文章页**: 点击任意文章可阅读
- [ ] **关于页**: `/about/` 可访问
- [ ] **RSS**: `/index.xml` 内容类型为 `application/rss+xml`
- [ ] **Atom**: `/atom.xml` (如果启用) 正常
- [ ] **移动端**: 在手机/平板上显示正常，响应式生效
- [ ] **代码高亮**: 文章中的代码块有语法高亮
- [ ] **SEO**: 查看网页源代码，存在 meta description, Open Graph tags
- [ ] **sitemap**: `/sitemap.xml` 存在且包含正确 URL
- [ ] **robots.txt**: `/robots.txt` 存在且允许爬取

## 故障排除

### 部署后 404

- 检查 GitHub Pages Source 是否为 GitHub Actions
- 确认 `baseURL` 配置正确
- 查看 Actions 日志是否有错误

### 样式丢失

- 确认主题模块已正确下载: `hugo mod get && hugo mod tidy`
- 检查 CSS 文件路径是否正确
- 清除浏览器缓存或开隐私模式访问

### RSS 不生成

- 检查 `config.toml` 中 `[outputs]` 配置
- 构建时查看 `public/index.xml` 是否存在
- 确保 `canonifyurls = true` (可选)

### GitHub Actions 失败

```bash
# 常见错误: Hugo 安装失败
# 解决: 修改 workflow 使用特定版本
- name: Setup Hugo
  uses: peaceiris/actions-hugo@v2
  with:
    hugo-version: '0.128.0'  # 指定稳定版本
```

### 自定义域名不生效

- 确认 DNS 已正确指向 GitHub Pages
- 等待 DNS 传播完成 (使用 `dig CNAME your-domain.com` 检查)
- 在仓库 Settings → Pages 中重新保存 Custom domain

### 本地构建与 CI 不一致

- 确保本地 Hugo 版本与 CI 一致
- 使用 `hugo mod get` 保证主题版本一致
- 注意操作系统差异 (特别是 extended 版本)

---

如有其他问题，请查阅 [Hugo Docs](https://gohugo.io/documentation/) 或 [PaperMod Wiki](https://github.com/adityatelange/hugo-PaperMod/wiki)。
