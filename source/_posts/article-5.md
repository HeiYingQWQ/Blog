---
id: 5
date: "2026-04-06 15:00:00"
title: "Stellar 主题安装与基础定制：让博客颜值起飞"
author: "小白🐾"
layout: post
comments: true
tags:
  - 主题
  - 建站
  - 配置
categories: "网站搭建"
description: "在 Hexo 基础搭建后，读者最需要的是主题美化。Stellar 功能丰富但配置分散，这篇能快速上手并个性化。"
keywords:
  - "Stellar 主题安装与基础定制：让博客颜值起飞"
  - "网站搭建"
  - 主题
  - 建站
  - 配置
---

# Stellar 主题安装与基础定制：让博客颜值起飞

## 开篇：从“丑小鸭”到“白天鹅”的蜕变

昨天我看了下自己的博客，差点没认出来——那界面还是 Hexo 默认的 Landscape 主题，绿油油的，像极了刚学编程时的终端配色。😅 说好的“爪印博客”要有“爪印的格调”呢？果断换主题！

试过好几个（NexT、Icarus、Butterfly），最后还是看上了 **Stellar**——功能齐全、文档友好、而且那种简约科技风，跟我这只“代码小狗”的气质莫名搭调。✨

这篇就来手把手教你：怎么把 Stellar 从“安装包”变成“你的博客颜值担当”。🐾

---

## 一、主题安装：npm vs Git，哪种更适合你？

### 方案A：npm 安装（推荐新手）

{% note info %}
**小白的笔记**：npm 安装会自动处理依赖，升级也方便（`npm update`）。适合大多数场景。
{% endnote %}

```bash
# 进入博客根目录
cd /path/to/your/blog

# 安装 Stellar（如果报错，先 npm install hexo-cli -g）
npm install hexo-theme-stellar

# 验证安装
npm list hexo-theme-stellar
```

安装完别急着 `hexo s`，还有一步——**启用主题**。

修改根目录 `_config.yml`：

```yaml
# _config.yml
theme: stellar  # 把 landscape 改成 stellar
```

保存后跑一下：

```bash
hexo clean  # 清理缓存
hexo s      # 本地预览
```

打开 `http://localhost:4000`，你应该能看到一个简洁的首页，带导航栏和文章列表——恭喜，主题已就位！

### 方案B：Git clone（适合想魔改的同学）

如果你打算深度定制（后面会讲），建议用 Git 方式 fork 一份到自己的仓库：

```bash
# 删除已安装的 npm 主题（如果有）
npm uninstall hexo-theme-stellar

# 克隆官方仓库到 themes/ 目录
git clone https://github.com/xaoxuu/hexo-theme-stellar.git themes/stellar
```

这样你可以随意修改源码，还能提交 PR 给官方。不过要注意：**官方更新后需要手动 pull**。

{% folding 🐾 踩坑记录（点击展开） %}
我第一次用 npm 安装时，因为网络卡在 "python 编译" 步骤，还以为是命令错了……其实是 npm 源太慢。换淘宝镜像：`npm config set registry https://registry.npmmirror.com` 立刻解决。
{% endfolding %}

---

## 二、配置文件详解：让你的博客“有个性”

主题装好了，但千篇一律可不行。Stellar 的配置集中在 `themes/stellar/_config.yml`（注意：是主题目录下的，不是根目录！）。

### 1. 菜单与导航

```yaml
# themes/stellar/_config.yml
menu:
  Home: /
  Archives: /archives
  Categories: /categories
  Tags: /tags
  # 自定义页面
  关于我: /about
  友情链接: /friends
```

{% note success %}
✅ **小白亲测好用**：菜单图标会自动匹配（Home 是🏠，Archives 是📚），但如果你想自定义图标，在键值对里加 `icon: 图标名` 就行，比如 `Home: { link: /, icon: home }`。
{% endnote %}

### 2. 社交链接与大头像

```yaml
social:
  GitHub: https://github.com/你的用户名
  Twitter: https://twitter.com/你的账号
  E-Mail: mailto:your@email.com

# 头像设置（放 themes/stellar/source/img/ 里）
avatar:
  enable: true
  url: /img/你的头像文件名.png
  rounded: true  # 圆形头像，false 是方形
```

头像图片建议尺寸 200x200 像素，PNG 格式。如果没生效，记得重启 `hexo s`。

### 3. Favicon 与网站图标

```yaml
favicon:
  enable: true
  link: /favicon.ico  # 放在 themes/stellar/source/ 根目录
```

生成 Favicon 可以用 [RealFaviconGenerator](https://realfavicongenerator.net/) 在线做，然后下载所有图标丢进 `source/` 目录。

---

## 三、样式微调：三分钟换肤术

Stellar 用 **Stylus** 写样式，变量全在 `themes/stellar/source/css/_variables.styl`。

### 改主题色

```stylus
// 找到 color 相关变量
$color-primary = #2F80ED  // 主色调（蓝色）
$color-accent  = #F2C94C  // 强调色（黄色）
```

改成你喜欢的颜色，比如紫色系：

```stylus
$color-primary = #8B5CF6
$color-accent  = #EC4899
```

保存后 `hexo s` 刷新看看——是不是瞬间“小清新”了？

### 调字体与圆角

```stylus
$font-family-base = "Noto Sans SC", "Helvetica Neue", Arial, sans-serif
$border-radius    = 8px  # 默认 4px，改成 8px 更圆润
```

{% note warning %}
⚠️ **注意**：修改完变量后，如果样式没生效，可能是缓存问题。执行 `hexo clean` 再预览。
{% endnote %}

---

## 四、组件选择：精简你的博客

Stellar 内置很多组件，但不是每个都需要。在 `_config.yml` 里关掉不用的：

```yaml
# 文章目录（右侧）
toc:
  enable: true

# 代码块高亮主题
codeblock:
  theme: default  # 可选: default, dark, github, dracula

# 返回顶部按钮
back2top:
  enable: true
  position: right  # left / right

# 阅读进度条
reading_progress:
  enable: true
  color: $color-primary  # 使用主色调
```

我个人把“返回顶部”和“进度条”都开了，但“文章目录”只在长文（>3000 字）时才显示——你可以用 `toc.max_percent` 控制。

---

## 五、多语言支持：中文站配置 checklist

如果你只写中文，需要调整几个地方：

1. **日期格式**（`themes/stellar/_config.yml`）：

```yaml
date_format:
  en: MMM D, YYYY
  zh: YYYY年MM月DD日  # 中文习惯
```

2. **时区设置**（根目录 `_config.yml`）：

```yaml
timezone: Asia/Shanghai
```

3. **隐藏英文界面入口**（可选）：

如果你不需要中英文切换，可以直接删掉 `languages/` 目录下的 `en.yml`，或者在菜单里只留中文页面。

---

## 六、性能优化：让博客快如闪电

开了这么多功能，会不会变慢？Stellar 本身很轻量，但我们还能榨干最后一点性能：

- **图片懒加载**：已内置，确保 `lazyload.enable: true`
- **CDN 引入**：`themes/stellar/_config.yml` 里可以填 `cdn: https://cdn.jsdelivr.net/gh/你的用户名/hexo-theme-stellar@version/`，但国内访问有时不稳定，建议保留本地。
- **gzip 压缩**：根目录 `_config.yml` 加：

```yaml
gzip:
  enable: true
```

- **Hexo 生成速度调优**：如果文章多了 `hexo g` 变慢，可以：

```bash
# 只生成修改过的文章（增量）
hexo generate --watch
```

或者用 `hexo generate --deploy --silent` 减少日志输出。

---

## 结语

主题安装只是第一步，后续的深度定制（比如改布局、加广告、暗色模式）会更刺激。今天你先搞定基础配置，让博客“像模像样”——等你看顺眼了，咱们再来玩高级的。🐾

*2026-04-06 首发于 [爪印博客](https://heiying.eu)*