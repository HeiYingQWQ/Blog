---
id: 7
date: "2026-04-07 10:00:00"
title: "Stellar 主题深度定制：修改布局与添加自定义区块"
author: "小白🐾"
layout: post
comments: true
tags:
  - 主题
  - 配置
  - 工具
categories: "网站搭建"
description: "Stellar 主题虽然功能丰富，但用户常有个性化需求。这篇讲透模板修改与自定义区块，让博客独一无二。"
keywords:
  - "Stellar 主题深度定制：修改布局与添加自定义区块"
  - "网站搭建"
  - 主题
  - 配置
  - 工具
---

# Stellar 主题深度定制：修改布局与添加自定义区块

## 开篇：当“现成主题”不再满足你

用了两周 Stellar，我已经把配色、字体、菜单都调顺了。可是看着首页，总觉得缺点什么——我想加一个“最新评论”侧边栏，还想在文章底部放个“版权声明+分享按钮”。🤔

翻遍官方文档，没找到开关。这才明白：**真正个性化，得自己改代码**。

这篇就来“解剖”Stellar 的布局系统，手把手教你加区块、改结构、甚至暗色模式。准备好了吗？戴上手套，我们开拆！

---

## 一、主题结构解析：layout/partial/ 是什么？

进入 `themes/stellar/`，你会看到这些文件夹：

```
layout/          # 模板文件（.ejs）
partial/        # 可复用小组件（header, footer, sidebar）
source/         # 静态资源（CSS, JS, 图片）
scripts/        # 主题自带脚本
_config.yml     # 主题配置文件
```

### 1.1 EJS 模板继承机制

Stellar 用 **EJS**（Embedded JavaScript）写模板，核心是 `block` 和 `include`。

看 `layout/_partial/header.ejs`：

```ejs
<!DOCTYPE html>
<html lang="<%= config.language %>">
<head>
  <%- partial('_partial/head') %>  <!-- 引入 head 区块 -->
</head>
<body class="<%= bodyClass %>">
  <div id="container">
    <header class="site-header">
      <%- partial('_partial/nav') %>   <!-- 导航栏 -->
    </header>
    <%- body %>  <!-- 这是主要内容占位符，由具体页面填充 -->
    <footer class="site-footer">
      <%- partial('_partial/footer') %>
    </footer>
  </div>
</body>
</html>
```

`<%- body %>` 就是“挖了个洞”，不同的页面（首页、文章页、归档页）会把内容填到这里。

### 1.2 Block 覆盖

如果你想让某个页面插入额外内容，可以用 `block`。比如 `layout/_partial/post.ejs`：

```ejs
<article class="post">
  <header class="post-header">
    <h1><%= page.title %></h1>
    <%- partial('_partial/post-meta') %>
  </header>

  <div class="post-content">
    <%- page.content %>
  </div>

  <% block('post-footer') %>  <!-- 可扩展区域 -->
    <%- partial('_partial/post-tags') %>
  <% endblock %>
</article>
```

如果你想在文章页底部插入广告代码，只需在 `source/_data/custom.ejs`（或者新建一个 `custom-footer.ejs`）里覆盖这个 block。

---

## 二、侧边栏与页脚定制：加个“最新文章”小组件

默认侧边栏有“分类”“标签”“归档”。我想加个“最新文章 5 篇”。

### 2.1 创建小组件

在 `themes/stellar/layout/_partial/sidebar/` 创建 `recent-posts.ejs`：

```ejs
<% if (site.posts.length) { %>
  <div class="sidebar-group recent-posts">
    <h3 class="sidebar-title">最新文章</h3>
    <ul class="post-list">
      <% site.posts.sort('date', -1).limit(5).each(function(post) { %>
        <li class="post-item">
          <a href="<%= url_for(post.path) %>"><%= post.title %></a>
          <span class="post-date"><%= date(post.date, 'MM-DD') %></span>
        </li>
      <% }) %>
    </ul>
  </div>
<% } %>
```

### 2.2 注入侧边栏

编辑 `themes/stellar/layout/_partial/sidebar.ejs`，在适当位置插入：

```ejs
<%- partial('sidebar/recent-posts') %>
```

刷新页面，侧边栏就会出现“最新文章”列表。🎉

{% note info %}
**样式建议**：为了不挤占空间，可以加个折叠功能——点击标题展开列表。用一点 JS + CSS 就能实现：
```javascript
document.querySelector('.recent-posts .sidebar-title').addEventListener('click', function(){
  this.nextElementSibling.classList.toggle('collapsed')
})
```
{% endnote %}

---

## 三、文章页增强：底部加广告和版权声明

### 3.1 插入自定义区块

打开 `themes/stellar/layout/_partial/post.ejs`，找到 `</article>` 前的位置，插入：

```ejs
<% if (theme.post_footer.enable) { %>
  <div class="post-footer">
    <%- partial('_partial/post-copyright') %>  <!-- 版权声明 -->
    <%- partial('_partial/post-share') %>      <!-- 分享按钮 -->
  </div>
<% } %>
```

### 3.2 创建版权组件 `post-copyright.ejs`

```ejs
<div class="copyright-notice">
  <p>© <%= date(new Date(), 'YYYY') %> <%= config.author %> </p>
  <p>本文链接：<a href="<%= config.url + page.permalink %>"><%= config.url + page.permalink %></a></p>
  <p>版权声明：本博客所有文章除特别声明外，均采用 CC BY-NC-SA 4.0 许可协议。转载请注明出处！</p>
</div>
```

### 3.3 分享按钮（模板）

你可用 `hexo-tag-common` 插件，或直接写 HTML：

```ejs
<div class="share-buttons">
  <a href="https://twitter.com/intent/tweet?url=<%= config.url + page.permalink %>" target="_blank">Tweet</a>
  <a href="https://www.facebook.com/sharer/sharer.php?u=<%= config.url + page.permalink %>" target="_blank">Share</a>
  <a href="javascript:void(0)" onclick="copyToClipboard('<%= config.url + page.permalink %>')">复制链接</a>
</div>
```

再加一段 JS 实现 `copyToClipboard` 功能（放到 `themes/stellar/source/js/main.js` 或内联）。

{% folding 🐾 广告位投放经验分享（点击展开） %}
我第一次放 Google AdSense，直接把代码塞进 `post.ejs`，结果每篇文章底部都出现 300x250 的矩形广告，移动端直接错位。后来改用 `if (page.layout === 'post')` 判断只在文章页显示，再通过 CSS 媒体查询控制广告容器宽度，才搞定。**记住：广告别放太靠前，影响阅读体验会很掉分。**
{% endfolding %}

---

## 四、移动端适配检查：用 DevTools 调参

### 4.1 响应式断点

Stellar 用媒体查询适配移动端，关键断点在 `themes/stellar/source/css/_responsive.styl`：

```stylus
// 手机（< 768px）
@media (max-width: 767px)
  .post-content
    padding 1rem

// 平板（768px ~ 1023px）
@media (min-width: 768px) and (max-width: 1023px)
  .sidebar
    display none  // 平板隐藏侧边栏

// 桌面（≥ 1024px）
@media (min-width: 1024px)
  .container
    width 80%
    margin 0 auto
```

### 4.2 自定义 CSS 覆盖

如果你想改某个元素的移动端样式，不要直接改 `_responsive.styl`（升级会冲突）。在 `themes/stellar/source/css/custom.styl` 里追加：

```stylus
@media (max-width: 767px)
  .post-header
    font-size 1.2rem
  .sidebar
    display none !important
```

### 4.3 实战调参步骤

1. Chrome 打开你的博客，按 `F12` 打开 DevTools
2. 点左上角“切换设备工具栏”（📱 图标）
3. 选 iPhone 12 或自定义尺寸，看布局是否错位
4. 在 Sources → Overrides 里临时改 CSS，调好后复制到 `custom.styl`
5. `hexo s` 刷新确认

常见问题：
- **侧边栏没隐藏**：检查 `.sidebar` 的 `display` 是否被其他样式覆盖（用“Computed”面板看优先级）
- **图片溢出**：`.post-content img { max-width: 100%; }` 加上

---

## 五、暗色模式实现：给博客一个“夜晚”

现在很多读者喜欢深色主题。Stellar 本身不支持，但我们可以用 **CSS 变量 + 媒体查询** 实现。

### 5.1 定义颜色变量

在 `themes/stellar/source/css/_variables.styl` 末尾加：

```stylus
// 浅色（默认）
:root
  --bg-color     = #ffffff
  --text-color   = #333333
  --link-color   = #2F80ED
  --code-bg     = #f5f5f5

// 深色（自动适配系统设置）
@media (prefers-color-scheme: dark)
  :root
    --bg-color     = #1a1a1a
    --text-color   = #e0e0e0
    --link-color   = #6BA5FF
    --code-bg     = #2d2d2d
```

### 5.2 替换硬编码颜色

在 `_variables.styl` 和 `_mixins.styl` 中，把硬编码颜色（如 `#ffffff`）改成 `var(--bg-color)`。你也可以在 `custom.styl` 里全局覆盖：

```stylus
body
  background var(--bg-color) !important
  color var(--text-color) !important
a
  color var(--link-color) !important
pre, code
  background var(--code-bg) !important
```

### 5.3 手动切换（可选）

如果想加个“手动切换按钮”，用 JS 监听点击：

```javascript
const toggle = document.getElementById('dark-mode-toggle')
const html = document.documentElement

if (localStorage.getItem('theme') === 'dark') {
  html.style.setProperty('color-scheme', 'dark')
}

toggle.addEventListener('click', () => {
  const isDark = html.style.getPropertyValue('color-scheme') === 'dark'
  html.style.setProperty('color-scheme', isDark ? 'light' : 'dark')
  localStorage.setItem('theme', isDark ? 'light' : 'dark')
})
```

按钮放在 `_partial/header.ejs` 里即可。

---

## 六、升级与维护：保留你的自定义

当你修改了主题源码，以后官方更新时怎么办？直接 `git pull` 会覆盖你的修改。

### 6.1 用 patch 管理

1. 把你修改过的文件列表记下来（或专门建个 `my-patches/` 文件夹）
2. 每次更新前，备份自己的改动：

```bash
cd themes/stellar
git diff > ../../my-stellar-patch.patch
```

3. 更新官方代码：

```bash
git pull origin main
```

4. 应用你的补丁：

```bash
git apply ../../my-stellar-patch.patch
```

冲突了？手动合并，然后生成新补丁。

### 6.2 更优雅的方案：Overrides

有些主题（包括 Stellar）支持 **覆盖机制**——你可以在 `source/` 目录下放同路径文件，它会优先于主题文件加载。

例如：
- 想改头部？在 `source/_partial/header.ejs` 写你的版本
- 想加 CSS？在 `source/css/custom.styl` 写

这样**你的文件独立于主题**，升级时完全无损。这是我最推荐的方式。

---

## 结语

布局定制就像“给博客装修”——一开始可能拆得乱七八糟，但装好后那种成就感，谁都替代不了。🏠

今天你学会了：
- 看懂 Stellar 的 `layout/partial/` 结构
- 用 EJS 模板加小组件
- 移动端调试与暗色模式实现
- 用 Overrides 和 patch 保护你的修改

下一篇，我们把这些技巧综合起来：**给博客加个“夜间模式开关”和“文章目录折叠”功能**。敬请期待！

*2026-04-07 首发于 [爪印博客](https://heiying.eu)*