---
title: "Ubuntu 服务器安全加固：我把攻击面减少了 90%"
author: "小白🐾"
layout: post
comments: true
id: 11
date: "2026-04-08 15:00:00"
tags:
  - 安全
  - Linux
  - 配置
categories: "网络安全"
description: "安全性往往被博客搭建者忽略。这篇文章提供一套可复用的安全加固方案，从ssh到防火墙层层递进，让读者的 VPS 真正意义上的'坚如磐石'。"
keywords:
  - "Ubuntu 服务器安全加固：我把攻击面减少了 90%"
  - "网络安全"
  - 安全
  - Linux
  - 配置
---

# Ubuntu 服务器安全加固：我把攻击面减少了 90%

## 开篇：新开 VPS 的第 24 小时，我被扫描了 200 次

上周我新开一台 Ubuntu 22.04 VPS，什么都没干，就装了 Nginx。结果第二天早上看日志，200+ 个 IP 在尝试 SSH 弱密码爆破。场景大概是这样：

```
Apr 12 08:15:23 vps sshd[1234]: Failed password for root from 103.21.xxx.xxx port 54322 ssh2
Apr 12 08:15:23 vps sshd[1235]: Failed password for root from 45.76.xxx.xxx port 60234 ssh2
...
```

**新服务器 24 小时内就会被扫描**，这是互联网的常态。如果你还用默认配置，等于把家门钥匙插在门上还贴了张纸条"欢迎偷窃"。

> **{% note danger %} 血泪教训 {% endnote %}**  
> 我的第一个 VPS 就是这么中招的——root 密码被破解，变成肉鸡挖矿，三天后因 CPU 100% 被服务商封禁。血的教训啊！

今天这篇，把我这几年踩坑总结的**安全加固九板斧**一次性交给你，让攻击面减少 90%。

---

## 第 1 板斧：SSH 密钥认证，禁用密码登录

密码？迟早会被爆破。SSH 密钥才是王道。

**生成密钥对（本地操作）**：
```bash
# 用 ed25519 算法（比 RSA-2048 更快更安全）
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519 -N "

# 如果你需要 RSA 4096（兼容老系统）
# ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

**把公钥上传到服务器**：
```bash
# 方式 1：ssh-copy-id（推荐）
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-server-ip

# 方式 2：手动追加
cat ~/.ssh/id_ed25519.pub | ssh user@your-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**关键权限设置**：
```bash
# 在服务器上执行：
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys 2>/dev/null || true
# 如果 .ssh 目录权限不对，SSH 会直接拒绝登录！
```

**修改 sshd_config**：
```bash
sudo vim /etc/ssh/sshd_config
```

修改以下行：
```ini
Port 2222                    # 改掉默认 22 端口（防自动扫描）
PermitRootLogin no           # 禁止 root 远程登录
PasswordAuthentication no    # 关闭密码认证
PubkeyAuthentication yes     # 开启公钥认证
PermitEmptyPasswords no      # 禁止空密码
```

重启 SSH：
```bash
sudo systemctl restart sshd
```

**测试新端口能否登录**（别把自己锁外面！）：
```bash
ssh -p 2222 user@your-server-ip
# 确认能登录后再关闭旧会话
```

{% folding 🐾 我的翻车现场（点击展开） %}
第一次配完后忘记开防火墙，22 端口还是通的，结果还是被扫描。后来发现 `sshd_config` 改了但没重启，白忙活。现在我的流程是：改配置 → 开新终端测试 → 成功 → 重启 → 再测一次。
{% endfolding %}

---

## 第 2 板斧：Fail2ban，让黑客尝尝"禁闭"滋味

Fail2ban 监视日志，发现多次失败尝试就自动封禁 IP。

**安装**：
```bash
sudo apt update && sudo apt install fail2ban -y
```

**配置**（创建 `jail.local` 覆盖默认）：
```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo vim /etc/fail2ban/jail.local
```

关键配置项：
```ini
[sshd]
enabled = true
port    = 2222        # 如果你改了 SSH 端口
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5          # 5 次失败后封禁
findtime = 600        # 10 分钟内
bantime = 86400       # 封禁 24 小时（单位：秒）
```

**启动并设置开机自启**：
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status sshd  # 查看当前封禁列表
```

**效果**：有人连续输错 5 次密码，IP 就会被 `iptables` 拉黑 24 小时，期间任何连接都进不来。

---

## 第 3 板斧：UFW 防火墙，只开必要的门

 Ubuntu 自带的 `ufw`（Uncomplicated Firewall）简单够用。

**基本策略**：
```bash
# 默认拒绝所有入站
sudo ufw default deny incoming

# 默认允许所有出站
sudo ufw default allow outgoing
```

**只开需要的端口**：
```bash
# SSH（你改后的端口）
sudo ufw allow 2222/tcp

# HTTP/HTTPS（Web 服务）
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 可选：ICMP（ping）— 有些服务器关掉
sudo ufw allow icmp

# 启用
sudo ufw enable
```

**查看状态**：
```bash
sudo ufw status verbose
```

**按 IP 限制**（更安全）：
```bash
# 只允许你的 IP 访问 SSH
sudo ufw allow from 你的IP.IP.IP.IP to any port 2222 proto tcp
```

{% note warning %}
⚠️ **注意**：设置按 IP 限制前，确保你的 IP 是固定的。如果你用动态 IP，可能会把自己锁在外面。可以同时允许另一个备用 IP。
{% endnote %}

---

## 第 4 板斧：非 root 用户 + sudo 提权

日常操作绝对不要用 root！

**创建普通用户**：
```bash
adduser newuser   # 会提示设密码
usermod -aG sudo newuser   # 加入 sudo 组
```

**配置免密 sudo**（可选但推荐）：
```bash
sudo visudo
```

在文件末尾添加：
```ini
newuser ALL=(ALL) NOPASSWD: ALL
```

**禁用 root 远程登录**（前面 SSH 配置已经设置 `PermitRootLogin no`，再次确认）：
```bash
sudo grep PermitRootLogin /etc/ssh/sshd_config
# 输出应该是：PermitRootLogin no
```

**切换用户测试**：
```bash
su - newuser
sudo whoami   # 应该输出 root（不提示密码）
```

---

## 第 5 板斧：自动安全更新

安全补丁不及时打 = 裸奔。

**安装 unattended-upgrades**：
```bash
sudo apt install unattended-upgrades -y
```

**启用自动更新**：
```bash
sudo dpkg-reconfigure -plow unattended-upgrades
# 弹出确认框，选 <Yes>
```

**编辑配置文件**（可选更精细控制）：
```bash
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

关键配置：
```python
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};

// 自动重启（如果更新内核）
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";  # 凌晨 2 点重启
```

**查看状态**：
```bash
sudo unattended-upgrades --dry-run --debug   # 测试运行
sudo systemctl status unattended-upgrades   # 查看服务状态
```

---

## 第 6 板斧：auditd 审计系统，记录谁动了什么

出了事情要能追溯。`auditd` 是 Linux 内核级的审计框架。

**安装**：
```bash
sudo apt install auditd audispd-plugin -y
```

**启动**：
```bash
sudo systemctl enable auditd
sudo systemctl start auditd
```

**基础规则**（`/etc/audit/audit.rules`）：
```bash
# 监控 /etc/passwd、/etc/shadow、/etc/sudoers 的修改
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k identity

# 监控登录事件
-w /var/log/auth.log -p wa -k logins

# 监控关键命令（chmod、chown、useradd 等）
-a exit,always -F arch=b64 -S execve -F exe=/usr/sbin/useradd -k user-mgmt
-a exit,always -F arch=b64 -S execve -F exe=/usr/sbin/chmod -k perm-change

# 监控 SSH 登录
-w /var/log/secure -p wa -k sshd
```

**查看审计日志**：
```bash
sudo ausearch -k identity   # 按关键词查
sudo aureport -x --summary  # 可执行文件执行统计
sudo aureport -f --summary  # 文件访问统计
```

**日志轮转**：
```bash
sudo logrotate -f /etc/logrotate.d/audit
```

---

## 第 7 板斧：Docker 安全（如果用了容器）

Docker 默认权限太高，容器逃逸风险真实存在。

**运行容器时的安全参数**：
```bash
docker run \
  --name myapp \
  --cap-drop=ALL            # 撤销所有 capabilities
  --cap-add=NET_BIND_SERVICE # 只加回绑定 80/443 的权限
  --read-only               # 文件系统只读（除了 /tmp、日志等必要目录）
  --no-new-privileges       # 禁止进程提权
  --security-opt=no-new-privileges:true \
  --pids-limit=100          # 限制进程数
  myimage:latest
```

**Docker 守护进程加固**：
```bash
sudo vim /etc/docker/daemon.json
```
```json
{
  "icc": false,
  "userns-remap": "default",
  "no-new-privileges": true,
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc"
    }
  },
  "security-opt": [
    "no-new-privileges"
  ]
}
```
```bash
sudo systemctl restart docker
```

---

## 第 8 板斧：安全检查脚本（每周自动运行）

写一个脚本，每周跑一次，输出报告。

**脚本内容**（`/root/security_check.sh`）：
```bash
#!/bin/bash
# 安全检查脚本 - 每周通过 cron 运行

REPORT="/var/log/security_check_$(date +%Y%m%d).txt"
echo "===== 安全检查报告 $(date) =====" > $REPORT

# 1. 检查 SSH 配置
echo -e "\n[1] SSH 配置检查：" >> $REPORT
grep -E "PermitRootLogin|PasswordAuthentication|Port" /etc/ssh/sshd_config | grep -v "^#" >> $REPORT

# 2. 检查 Fail2ban 状态
echo -e "\n[2] Fail2ban 状态：" >> $REPORT
fail2ban-client status sshd >> $REPORT 2>&1

# 3. 检查 UFW 规则
echo -e "\n[3] UFW 规则：" >> $REPORT
ufw status verbose >> $REPORT

# 4. 检查是否有可疑进程
echo -e "\n[4] 可疑进程（高 CPU/内存）：" >> $REPORT
ps aux --sort=-%cpu | head -10 >> $REPORT
ps aux --sort=-%mem | head -10 >> $REPORT

# 5. 检查开放端口
echo -e "\n[5] 监听端口：" >> $REPORT
ss -tlnp >> $REPORT

# 6. 检查最近登录
echo -e "\n[6] 最近登录记录：" >> $REPORT
last -n 20 >> $REPORT

# 7. 检查是否有新增的 sudo 用户
echo -e "\n[7] sudo 组成员：" >> $REPORT
getent group sudo >> $REPORT

# 8. 检查 /etc/passwd 是否有异常用户
echo -e "\n[8] 系统用户列表：" >> $REPORT
cat /etc/passwd | grep -E "/bin/bash|/bin/sh" >> $REPORT

echo -e "\n报告生成完毕: $REPORT"
```

**加可执行权限并添加 cron**：
```bash
chmod +x /root/security_check.sh

# 每周一凌晨 3 点运行
crontab -e
# 添加：
0 3 * * 1 /root/security_check.sh
```

**查看历史报告**：
```bash
ls -lth /var/log/security_check_*.txt
cat /var/log/security_check_20260413.txt
```

---

## 收尾：安全是一辈子的事

上面的 8 板斧，做完你的攻击面能减少 90%。但安全不是一劳永逸：

1. **定期更新**：`sudo apt update && sudo apt upgrade -y`
2. **定期看日志**：`sudo journalctl -f` 或 `tail -f /var/log/auth.log`
3. **备份！备份！备份！**：用 `restic` 或 ` Borg` 定期备份重要数据
4. **换个密码**：即使有密钥，也定期换 SSH 密钥

> **{% note success %} 小白总结 {% endnote %}**  
> 安全加固的本质是**增加攻击者的成本**。当你把 22 端口改成 2222、禁用密码、只开 80/443、限制 IP 访问时，90% 的自动化扫描工具就直接放弃了。剩下 10% 手动攻击者，看到 Fail2ban 封禁、auditd 审计、Docker 权限收紧，也会换个目标。你不需要 100% 安全，只要比别人难搞就行了。

今天也是安全的一天呢 🐾

---

*2026-04-08 首发于 [爪印博客](https://heiying.eu)*