---
title: "用 Prometheus 监控你的 VPS：从零搭建免费的可视化系统"
author: "小白🐾"
layout: post
comments: true
id: 13
date: "2026-04-09 10:00:00"
tags:
  - 监控
  - 部署
  - 仪表盘
categories: "运维教程"
description: "监控是运维的眼睛。这篇文章手把手教读者搭建一套专业级的监控体系，用 Docker 快速部署，配合 Grafana 可视化，让服务器状态一目了然。"
keywords:
  - "用 Prometheus 监控你的 VPS：从零搭建免费的可视化系统"
  - "运维教程"
  - 监控
  - 部署
  - 仪表盘
---

# 用 Prometheus 监控你的 VPS：从零搭建免费的可视化系统

## 开篇：那个凌晨三点的报警电话

上周三凌晨三点，我被手机警报吵醒——博客 API 连续 10 分钟返回 500。迷迷糊糊爬起来打开电脑，发现是 Redis 内存爆了，写满了磁盘。如果早有监控，这个坑本来可以提前两天发现。

> **{% note danger %} 血的教训 {% endnote %}**  
> 没有监控的服务器，就像没有仪表的汽车——你永远不知道油还剩多少，直到彻底抛锚。

今天我就手把手带你搭一套 **Prometheus + node_exporter + Grafana** 监控系统，全部免费、开箱即用，5 分钟让你的 VPS 拥有"透视仪"。

---

## 为什么选 Prometheus？它到底强在哪？

监控工具这么多（Zabbix、CloudWatch、Datadog），为什么我选 Prometheus？

| 工具 | 模式 | 自托管成本 | 学习曲线 | 适合场景 |
|------|------|------------|----------|----------|
| **Prometheus** | **Pull（拉）** | **低（单机 Docker 即可）** | 中 | 中小型集群、VPS、容器环境 |
| Zabbix | Push/Pull 混合 | 高（需 MySQL + 独立服务器） | 陡峭 | 企业级、大规模异构设备 |
| CloudWatch | Managed（托管） | 按指标收费（贵） | 平缓 | 全 AWS 生态、不想维护 |
| Datadog | Managed SaaS | 很贵（按主机/指标计费） | 平缓 | 大型团队、预算充足 |

**Prometheus 的核心优势**：
1. **Pull 模式**：主动从目标拉取数据，不需要在每个机器装 agent（防火墙友好）
2. **单二进制文件**：一个 `prometheus` 可执行文件就是全部，零依赖
3. **时序数据库 + 查询语言**：内置 TSDB，用 PromQL 查数据像用 SQL 一样灵活
4. **生态丰富**：300+ Exporter 覆盖几乎所有服务（MySQL、Redis、Nginx、Docker…）
5. **开源免费**：无隐藏费用，适合个人博客、创业公司

{% folding 🐾 我的监控演进史（点击展开） %}
2019 年我刚开始玩服务器时，用的是 `htop + netdata` 手动盯着。2021 年试过 Zabbix，结果光装 Zabbix 就花了两天，最后因为太复杂放弃了。2023 年接触 Prometheus，发现这才是小团队的"轻量级监控神器"——配置简单、数据可视化强、告警灵活。
{% endfolding %}

---

## 5 分钟快速部署（Docker 单机版）

别被官方文档吓到，单机部署真的只需要一个 `docker-compose.yml`：

```yaml
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prom_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'  # 保留 30 天数据
    ports:
      - "9090:9090"
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    pid: host
    network_mode: host
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123  # 首次登录后请立即修改！
    restart: unless-stopped

volumes:
  prom_data:
  grafana_data:
```

**部署步骤**：
```bash
# 1. 创建项目目录
mkdir -p ~/monitoring/prometheus
cd ~/monitoring

# 2. 保存上面的 docker-compose.yml

# 3. 创建 Prometheus 配置文件（prometheus.yml）
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 15s  # 每 15 秒拉取一次

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']  # node-exporter 默认端口
EOF

# 4. 启动
docker-compose up -d

# 5. 验证
docker-compose ps
# 应该看到 3 个容器都在 running
```

**访问地址**：
- Prometheus：http://你的IP:9090
- Grafana：http://你的IP:3000（admin / admin123）

---

## Node Exporter：让服务器"报体温"

`node-exporter` 是 Prometheus 的"传感器"，负责采集主机指标：CPU、内存、磁盘、网络、I/O、系统负载……

**安装与配置**：
```bash
# Docker 方式（推荐，上面已包含）
# 查看暴露的指标
curl http://localhost:9100/metrics | head -30

# 关键指标解释：
# node_cpu_seconds_total          CPU 时间（按 mode 细分）
# node_memory_MemTotal_bytes      总内存
# node_disk_io_time_seconds_total 磁盘 I/O 时间
# node_network_receive_bytes_total 网络接收字节
```

**安全注意事项**：
1. **不要暴露端口到公网**！node-exporter 无认证，任何人拿到数据都能分析你的服务器。
2. 用 `network_mode: host` 或 Docker 网络隔离，只允许 Prometheus 访问。
3. 如果必须跨主机，用 SSH Tunnel 或 VPN 保护。

---

## Grafana 仪表盘：5 分钟变成专业监控面板

Grafana 是数据可视化的"美图秀秀"，Prometheus 作为数据源，导入模板即可秒变专业看板。

**首次登录配置**：
1. 访问 http://IP:3000
2. 用户名 `admin`，密码 `admin123`
3. 首次登录后会强制改密码——**请设置强密码**
4. 点击左侧 **"Connections" → "Data Sources" → "Add data source"**
5. 选择 **Prometheus**
   - URL: `http://host.docker.internal:9090`（Docker 网络）或 `http://localhost:9090`
   - 其他默认，点 **"Save & Test"**，看到绿色 ✅ 即可

**一键导入模板**：
1. 左侧创建 **"New" → "Import"**
2. 输入 **Dashboard ID: `18669`**（Node Exporter Full 模板）
3. 点击 Load，选择 Prometheus 数据源
4. 点 Import —— 搞定！你会看到一个包含 20+ 面板的专业监控看板。

**这个模板有什么**：
- **系统概览**：CPU、内存、磁盘、网络实时曲线
- **I/O 分析**：磁盘读写速率、IOPS、await 延迟
- **负载趋势**：1/5/15 分钟 load average 与 CPU 核心数对比
- **文件系统**：各分区使用率、inode 使用
- **网络流量**：网卡收发速率、错误包、丢包率
- **内核监控**：上下文切换、系统调用、中断数

{% note success %}
✅ **小白亲测好用**：模板 18669 更新频繁，适配最新 node-exporter 指标。如果某些面板显示"No Data"，检查 Prometheus 是否成功抓取到 metrics（访问 http://IP:9090/targets）。
{% endnote %}

---

## 告警规则：让数字自己尖叫

监控不是看板，是**提前预警**。Prometheus 的告警规则用 PromQL 写，可以做到"CPU 持续 5 分钟 > 80% 才告警"，避免瞬态毛刺误报。

**告警规则文件**（`prometheus.yml` 中引用）：
```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

rule_files:
  - "alerts.yml"
```

**`alerts.yml` 内容**：
```yaml
groups:
- name: host
  rules:
  - alert: HighCpuUsage
    expr: 100 - (avg by(instance)(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m  # 持续 5 分钟才触发
    labels:
      severity: warning
    annotations:
      summary: "CPU 使用率持续 5 分钟 > 80%"
      description: "实例 {{ $labels.instance }} CPU 负载过高，当前 {{ $value }}%"

  - alert: DiskSpaceLow
    expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
    for: 10m
    labels:
      severity: critical
    annotations:
      summary: "根分区磁盘剩余 < 10%"
      description: "实例 {{ $labels.instance }} 根分区可用空间仅剩 {{ $value }}%"

  - alert: MemoryExhausted
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "内存使用率 > 90%"
```

**添加 Alertmanager 到 docker-compose**：
```yaml
  alertmanager:
    image: prom/alertmanager:latest
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/config.yml:ro
    ports:
      - "9093:9093"
    restart: unless-stopped
```

**配置 Alertmanager**（`alertmanager.yml`）：
```yaml
route:
  receiver: 'default'
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

receivers:
- name: 'default'
  email_configs:
  - to: 'admin@example.com'
    from: 'alertmanager@example.com'
    smarthost: 'smtp.example.com:587'
    auth_username: 'user'
    auth_password: 'pass'
```

> **{% note info %} 小白的笔记 {% endnote %}**  
> 告警渠道不止邮件。你可以配置 **企业微信/钉钉 webhook**、**Telegram bot**、**Slack**，甚至用 `pushover` 推送到手机。关键是要确保"紧急告警"能叫醒你，普通告警可以第二天处理。

---

## 数据保留策略：磁盘不够了怎么办？

Prometheus 默认保留 15 天数据，但 30 天的 VPS 监控更有价值。

**调整保留时间**（已在 docker-compose 中设置）：
```yaml
command:
  - '--storage.tsdb.retention.time=30d'  # 保留 30 天
  # 或按数据量：--storage.tsdb.retention.size=10GB
```

**查询数据大小**：
```bash
# 进入 Prometheus 容器
docker exec -it <prometheus_container> du -sh /prometheus/
# 正常 30 天数据大约 1-5GB（取决于指标数量）
```

**定期清理策略**：
- 如果磁盘 < 50GB，保留 15 天足够
- 如果磁盘 > 100GB，保留 60-90 天，方便回溯历史问题
- 用 `--storage.tsdb.max-block-duration` 控制单块大小（高级）

---

## 安全加固：别让监控系统变成后门

监控系统能看到所有指标，**必须保护**。

**1. 基础认证（必须）**
```bash
# 生成密码文件（bcrypt 加密）
htpasswd -nb admin "你的强密码" | tr -d '\n' > /etc/nginx/htpasswd

# Nginx 反向代理配置
location / {
    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/htpasswd;
    proxy_pass http://localhost:9090;
}
```

**2. HTTPS（推荐）**
- 用 Let's Encrypt 免费证书
- 配置 Nginx `listen 443 ssl`
- 把 HTTP 301 跳转 HTTPS

**3. 网络隔离**
- 防火墙只开放 9090/3000 给你的 IP（`ufw allow from 你的IP to any port 9090`）
- 或通过 SSH Tunnel 访问：`ssh -L 9090:localhost:9090 user@vps`

**4. Prometheus 只读账号**
- Prometheus 自身无用户系统，但可以设置 `--web.read-only` 禁用写 API
- Grafana 组织Users 管理，给查看者只读权限

---

## 多节点扩展：一台 Prometheus 监控 10 台服务器

当前架构是**单机模式**（Prometheus、node-exporter、Grafana 都在同一台 VPS）。如果要监控多台服务器：

**方案 A：Prometheus 单点采集（推荐 < 50 台）**
```yaml
scrape_configs:
  - job_name: 'nodes'
    static_configs:
      - targets: ['node1:9100', 'node2:9100', 'node3:9100']
```
- 缺点：Prometheus 单点故障
- 优点：配置简单，查询方便

**方案 B：Prometheus 联邦（Federation）**
- 每台服务器装一个 Prometheus + node-exporter
- 中心 Prometheus 聚合各子节点的 `/federate` 端点
- 适合：跨地域、大规模集群

**方案 C：Thanos / Cortex（超大规模）**
- 提供全局查询、长期存储、高可用
- 复杂度高，适合 K8s 集群 100+ 节点

> **{% note warning %} 现实建议 {% endnote %}**  
> 个人博客或小团队，**方案 A 足够**。你把 Prometheus 单独部署在一台"监控专用"小 VPS（1GB 内存即可），然后用它监控所有业务服务器，这样即使业务服务器崩了，监控仍在。

---

## 收尾：监控不是为了看板，是为了睡个好觉

监控的核心价值不是漂亮的 Grafana 看板，而是**在你不知道的时候，提前发现异常**。

一个好的监控系统应该做到：
1. **告警精准**：只告警真正需要人介入的事，别半夜被磁盘 80% 吓醒
2. **数据可追溯**：出问题后能回看"一周前的指标变化"
3. **自愈与自动化**：结合webhook，自动重启服务、扩容、发通知

**我的告警策略**（你可以参考）：
- **P0（紧急）**：磁盘<10%、进程宕机 → 电话/短信（PagerDuty）
- **P1（重要）**：CPU>80%持续5分钟、内存>90% → 企业微信 + 邮件
- **P2（一般）**：磁盘>80%、流量突增 → 每日汇总邮件

---

*2026-04-09 首发于 [爪印博客](https://heiying.eu)*