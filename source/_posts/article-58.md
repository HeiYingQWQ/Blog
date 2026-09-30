---
id: 58
date: 2026-05-17 07:03:00
title: "Kubernetes 入门：从部署到管理"
author: "小白🐾"
layout: post
comments: true
tags:
  - Kubernetes
  - 容器编排
  - 管理
categories: "运维教程"
keywords:
  - Kubernetes 入门：从部署到管理
  - 运维教程
  - Kubernetes
  - 容器编排
  - 管理
description: "帮助开发者和运维人员快速入门 Kubernetes，掌握基础的部署和管理技能。"
---

# Kubernetes 入门：从部署到管理

## 核心要点

- Kubernetes 介绍：架构、核心概念
- 集群部署：Minikube、kubeadm 的使用
- 核心资源：Pod、Deployment、Service、Volume
- 网络配置：ClusterIP、NodePort、LoadBalancer
- 存储管理：PersistentVolume、PersistentVolumeClaim
- 监控与日志：Prometheus、Grafana、EFK Stack

最近在帮朋友部署一个简单的Web应用，他之前一直用Docker Compose，觉得这玩意儿已经够好用了。结果上线后没几天就出问题了——服务器挂了，应用直接瘫痪，恢复了半天才好。

我问他为什么不考虑用容器编排工具，比如Kubernetes。他说听起来太复杂了，怕学不会。

其实Kubernetes没那么可怕。它就像一个智能管家，帮你管理所有的容器应用，确保它们始终健康运行。

## Kubernetes 是什么？

Kubernetes，通常简称K8s，是一个开源的容器编排平台。它可以帮你：

- 自动部署和升级应用
- 自动扩缩容（根据流量自动调整容器数量）
- 自动修复失败的容器
- 管理容器之间的网络和存储

简单来说，有了Kubernetes，你就不用再手动管理一堆Docker容器了。

## 核心架构

Kubernetes的架构主要由以下几个部分组成：

- **Master节点**：负责管理整个集群，包括调度、监控、存储等。
- **Worker节点**：负责运行容器应用，每个Worker节点上都有kubelet（管理容器）和kube-proxy（管理网络）。
- **Pods**：Kubernetes中最小的部署单位，一个Pod可以包含一个或多个容器。
- **Deployments**：负责管理Pods的部署和升级。
- **Services**：负责暴露Pods的网络地址，让其他应用可以访问。

## 快速部署集群

### 1. Minikube（本地测试）

Minikube是一个轻量级的Kubernetes集群，适合本地测试和学习。

```bash
# 安装 Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

# 启动 Minikube 集群
minikube start

# 检查集群状态
kubectl cluster-info
```

### 2. kubeadm（生产环境）

kubeadm是官方推荐的生产环境部署工具。

```bash
# 安装 Docker、kubeadm、kubelet、kubectl
sudo apt-get update
sudo apt-get install -y docker.io kubeadm kubelet kubectl

# 初始化 Master 节点
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# 配置 kubectl 权限
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安装网络插件（Flannel）
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## 核心资源管理

### 1. Pods

Pods是Kubernetes中最小的部署单位。一个Pod可以包含一个或多个容器，它们共享网络和存储。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

### 2. Deployments

Deployments负责管理Pods的部署和升级。它会确保指定数量的Pods始终运行。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

### 3. Services

Services负责暴露Pods的网络地址，让其他应用可以访问。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: NodePort
```

## 监控与日志

Kubernetes提供了强大的监控和日志功能，帮助你及时发现和解决问题。

### 1. Prometheus + Grafana

Prometheus是一个开源的监控系统，Grafana是一个开源的可视化工具。

```bash
# 安装 Prometheus 和 Grafana
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.47/example/prometheus-operator-crd/
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.47/example/prometheus/
```

### 2. EFK Stack

EFK Stack是由Elasticsearch、Fluentd、Kibana组成的日志收集和分析系统。

```bash
# 安装 EFK Stack
kubectl apply -f https://raw.githubusercontent.com/elastic/examples/master/cloud-on-k8s/quickstart/elasticsearch/elasticsearch.yaml
kubectl apply -f https://raw.githubusercontent.com/elastic/examples/master/cloud-on-k8s/quickstart/kibana/kibana.yaml
kubectl apply -f https://raw.githubusercontent.com/elastic/examples/master/cloud-on-k8s/quickstart/fluentd/fluentd.yaml
```

## 总结

Kubernetes是一个强大的容器编排平台，它可以帮你管理所有的容器应用，确保它们始终健康运行。

虽然学习Kubernetes需要一定的时间，但它会让你的应用部署和管理变得更加简单和可靠。

如果你正在考虑使用容器编排工具，Kubernetes绝对是一个不错的选择。