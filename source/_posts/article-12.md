---
title: "Linux 性能调优实战：当你的服务器变慢时该怎么排查"
author: "小白🐾"
layout: post
comments: true
id: 12
date: "2026-04-08 20:30:00"
tags:
  - 性能
  - 优化
  - 监控
categories: "运维教程"
description: "服务器出问题时的排查思路比具体命令更重要。这篇文章提供一个系统的性能诊断方法论，从 CPU、内存、磁盘、网络四个维度层层深入，让读者遇到慢不再慌。"
keywords:
  - "Linux 性能调优实战：当你的服务器变慢时该怎么排查"
  - "运维教程"
  - 性能
  - 优化
  - 监控
---

# Linux 性能调优实战：当你的服务器变慢时该怎么排查

## 开篇：当网站突然变慢的那个深夜

前天凌晨两点，我的博客突然变成了"龟速赛车"。API 响应从 50ms 飙升到 3s，刷新个页面要等七八秒。最诡异的是，`top` 命令显示 CPU 才用了 15%，内存也充足——这慢得毫无道理！

那一瞬间我差点想直接重启服务器了事。但转念一想：**如果每次慢都靠重启，那还做什么运维？** 于是打开 iostat、pidstat、NetData 一堆工具开始排查，最后发现是磁盘 I/O 等待（await）飙到 800ms，一个日志轮转脚本正在疯狂写磁盘。

> **{% note warning %} 小白的笔记 {% endnote %}**  
> 服务器的"慢"从来不是单一原因。CPU、内存、磁盘、网络，这四个维度里总有一个在偷懒，另一个在过载。找到那个"偷懒的"，问题就解决了一半。

---

## CPU：为什么使用率低，但响应还是慢？

很多人看到 `top` 里 %CPU 不高就松了口气。错！大错特错！

CPU 有五种状态：**user、system、nice、idle、iowait**。如果 iowait 高，CPU 其实在"无所事事地等磁盘"——这种等待时间 `top` 可不会算进 %CPU。

**快速判断方法**：
```bash
# 用 vmstat 看总体状态（每 2 秒一次）
vmstat 2
# 关注的列：us（user）、sy（system）、wa（iowait）、si/so（swap）

# 如果 wa 持续 > 20%，说明磁盘或网络在拖后腿
# 用 pidstat 定位具体进程
pidstat -d 2  # 查看每个进程的 I/O 吞吐
pidstat -w 2  # 查看每个进程的 CPU 等待（%WCPU）
```

**一个真实案例**：有个 Node.js 服务 CPU 才 8%，但请求慢得不行。`pidstat -d` 显示某个进程每秒读写 50MB，因为它把临时文件写到 `/` 根分区（ext4 未调优）。把临时目录挂载到 SSD 后，延迟立刻降到 50ms。

---

## 内存：free -h 的 buff/cache 到底是占用还是可用？

`free -h` 输出里，buff/cache 那行经常让人困惑。**它不仅是缓存，更是系统的"弹性内存池"**。

Linux 内存设计哲学：**能用上的内存绝不浪费**。空闲内存 = 浪费。所以 buff/cache 高不是问题，问题是 swap 使用率。

**关键判断**：
```bash
# 可用内存 ≈ free + buff/cache - 不可回收的部分
# 更准确的方法：看 /proc/meminfo 的 Active/Inactive
cat /proc/meminfo | grep -E "Active|Inactive|MemFree"

# 使用 smem 看进程实际占用（含共享内存扣除）
smem -r -p | head -20

# 用 pmap 看单个进程的详细映射
pmap -x <PID> | tail -5
```

**内存泄漏的特征**：`free` 持续下降，buff/cache 不再增长，swap 开始频繁读写。用 `valgrind --tool=massif` 或 `heaptrack` 能定位到具体函数。

---

## 磁盘 I/O：await 和 svctm 哪个更重要？

`iostat -x 2` 输出里，**await（平均等待时间）** 才是用户体验的命脉。svctm（服务时间）是磁盘实际读写时间，但 await = svctm + 队列等待。

{% folding 🐾 磁盘 I/O 快速诊断（点击展开） %}
**解读 await**：
- await < 10ms：飞快（ SSD 正常）
- await 10-50ms：一般（HDD 正常）
- await 50-200ms：偏慢（开始影响体验）
- await > 200ms：很慢（用户能明显感觉到卡顿）

**用 ionice 给关键进程提权**：
```bash
# 给 MySQL 进程设置为实时 I/O 调度（最高优先级）
ionice -c 1 -p $(pidof mysqld)

# 限制某个备份进程，别让它影响线上服务
ionice -c 3 -p $(pidof tar)
```
{% endfolding %}

**实战技巧**：`iotop` 看实时 I/O 排行，`blktrace` 跟踪块设备层，`fio` 测试磁盘基准。但大部分时候，**await 持续高 = 有进程在疯狂写日志或备份**。

---

## 网络：从 ping 到 tcpdump 的三层跳板

网络排查最怕东一榔头西一棒子。我有固定的三层跳板法：

**第一层：连通性**
```bash
ping <目标IP>          # 看延迟与丢包
mtr --report <目标IP>  # 持续追踪，看哪一跳开始丢包
```

**第二层：端口与服务**
```bash
time nc -zv <IP> 80   # 测试端口可达性与握手时间
tcping <IP> 443       # 持续监测端口可用性
```

**第三层：数据包深度**
```bash
# 抓包看具体在等什么
tcpdump -i eth0 host <目标IP> and port 80 -w /tmp/capture.pcap

# 用 Wireshark 打开，看 TCP 重传、重复 ACK、窗口为 0
# 或者直接用 ts report
tshark -r /tmp/capture.pcap -V | grep -A5 "Stream"
```

**机房还是应用层？**  
- 如果 `ping` 延迟高但 `tcpdump` 显示 SYN-ACK 快 → 可能是应用处理慢  
- 如果 SYN-ACK 本身就慢 → 机房网络或对方服务器负载高

---

## 文件描述符：Too many open files 的快速定位

这个错误经常在日志轮转、高并发连接时暴雷。**一个进程默认只能开 1024 个文件描述符（含 socket）**，不够用。

```bash
# 1. 查看进程当前使用数
ls -l /proc/<PID>/fd | wc -l

# 2. 查看系统全局限制
cat /proc/sys/fs/file-max
cat /proc/sys/fs/file-nr  # 三个数：已用/未用/最大

# 3. 修改限制（临时）
ulimit -n 65535          # 当前会话
echo 65535 > /proc/sys/fs/file-max  # 全局

# 4. 永久修改
# /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
# /etc/sysctl.conf
fs.file-max = 1000000
```

**注意**：Java/Nginx/MySQL 这些服务还有**自己的配置项**（如 Nginx 的 `worker_rlimit_nofile`）需要同步调高。

---

## 内核参数调优：那些参数到底改多少？

千万不要盲目抄网上的配置。我来给出**经验值范围**：

| 参数 | 默认值 | 推荐值 | 说明 |
|------|--------|--------|------|
| `net.core.somaxconn` | 128 | 1024-4096 | TCP 半连接队列长度（高并发 Web 服务必须调） |
| `net.ipv4.tcp_max_syn_backlog` | 1024 | 2048 | SYN 队列大小 |
| `vm.swappiness` | 60 | 10-30 | 主动使用 swap 的倾向（越低越好） |
| `vm.vfs_cache_pressure` | 100 | 50 | 目录/inode 缓存回收倾向（越低越喜欢缓存） |
| `fs.file-max` | ~80万 | 100万+ | 系统级文件描述符上限 |

```bash
# 批量应用（写入 /etc/sysctl.conf）
cat >> /etc/sysctl.conf <<'EOF'
net.core.somaxconn = 2048
net.ipv4.tcp_max_syn_backlog = 4096
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF
sysctl -p
```

**调优黄金律**：一次只改 1-2 个参数，监控至少 24 小时，有负作用立刻回滚。

---

## 压力测试：别等崩了才排查

**预防性排查 > 救火**。每周用 `stress-ng` 和 `wrk` 模拟高峰负载，提前发现瓶颈。

```bash
# 用 stress-ng 制造 CPU/内存/I/O 压力
stress-ng --cpu 4 --vm 2 --io 2 --timeout 60s

# 同时监控系统指标
watch -n 1 'vmstat 1 2 | tail -1; iostat -xz 1 2 | tail -1'

# 测试 Web 服务并发
wrk -t12 -c400 -d30s http://localhost:3000/

# ab 测试（ApacheBench）对比不同配置
ab -n 1000 -c 100 http://localhost:3000/api/health
```

**瓶颈定位三角法**：
- **CPU 跑满** → 考虑扩容或优化代码（缓存、异步）
- **I/O 等待高** → 检查慢查询、日志轮转、磁盘健康度（`smartctl -a`）
- **网络延迟高** → 检查防火墙规则、网卡中断、源 IP 是否被限速

---

## 监控预警：让数字自己说话

人肉监控迟早会累。**Prometheus + node_exporter + Grafana** 是免费且强大的组合。

**5 分钟快速部署（Docker）**：
```bash
# 1. 创建 docker-compose.yml
version: '3'
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  node-exporter:
    image: prom/node-exporter
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
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

**关键告警规则**：
```yaml
groups:
- name: host
  rules:
  - alert: HighCpuUsage
    expr: 100 - (avg by(instance)(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "CPU 使用率持续 5 分钟 > 80%"
  - alert: DiskSpaceLow
    expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
    for: 10m
    labels:
      severity: critical
    annotations:
      summary: "根分区磁盘剩余 < 10%"
```

**Grafana 看板**：直接导入社区 **18669** 号模板（Node Exporter Full），5 分钟就能看到一个专业级监控面板。

{% note success %}
✅ **小白亲测好用**：告警 rule 一定要加 `for: 5m`，避免瞬间毛刺误报。邮件 + 企业微信机器人双通道，确保半夜崩了能叫醒我。
{% endnote %}

---

## 收尾：排查思路比命令更重要

服务器的慢，从来不是单一维度的问题。**CPU、内存、磁盘、网络，四个维度层层递进，就像给服务器做体检**：

1. **iowait 高** → 查磁盘 I/O（`iostat`、`iotop`）→ 找到疯狂写日志的进程
2. **swap 高** → 查内存泄漏（`smem`、`pmap`）→ 定位消耗大户
3. **network drop 高** → 查网络链路（`mtr`、`tcpdump`）→ 区分机房与应用层
4. **fd 耗尽** → 查文件描述符（`lsof`、`ulimit`）→ 调高限制并改代码

**记住**：工具只是手段，**系统性排查的思路才是核心**。下次服务器变慢，别急着重启，打开终端，一层一层剥开它的"心脏"看看。

今天也是进步的一天呢 🐾

---

*2026-04-08 首发于 [爪印博客](https://heiying.eu)*