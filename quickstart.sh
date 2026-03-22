#!/bin/bash

# 全自动博客系统 - 快速启动脚本
# 用法: ./quickstart.sh [your-github-username]

set -e

USERNAME="${1:-YOUR_USERNAME}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "全自动博客系统 - 快速启动"
echo "========================================"
echo ""

# 1. 检查 Hugo 是否安装
if ! command -v hugo &> /dev/null; then
    echo "[?] 未检测到 Hugo。是否安装？ (y/n)"
    read -r install_hugo
    if [[ $install_hugo =~ ^[Yy]$ ]]; then
        echo "[*] 安装 Hugo..."
        if command -v brew &> /dev/null; then
            brew install hugo
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install hugo -y
        else
            echo "[!] 请手动安装 Hugo: https://gohugo.io/installation/"
            exit 1
        fi
    else
        echo "[!] 需要 Hugo 才能本地预览。跳过本地预览设置。"
    fi
fi

# 2. 初始化 Hugo 模块
if [ -f "go.mod" ]; then
    echo "[*] 更新 Hugo 模块..."
    hugo mod get github.com/adityatelange/hugo-PaperMod || true
    hugo mod tidy || true
fi

# 3. 更新配置文件中的 username
echo "[*] 配置用户名: $USERNAME"
if [ -f "config.toml" ]; then
    sed -i.bak "s/YOUR_USERNAME/$USERNAME/g" config.toml || true
    sed -i "s/https:\/\/YOUR_USERNAME.github.io/https:\/\/$USERNAME.github.io/g" config.toml || true
fi

# 4. 创建 GitHub 仓库 (可选)
echo ""
echo "[?] 是否在 GitHub 创建新仓库并推送？(y/n)"
read -r create_repo
if [[ $create_repo =~ ^[Yy]$ ]]; then
    echo "[*] 创建 GitHub 仓库..."
    gh repo create "blog" --public --source=. --remote=origin --push || {
        echo "[!] 请确保已安装 gh CLI 并已登录。"
        echo "    或手动在 GitHub 创建仓库后运行:"
        echo "    git remote add origin https://github.com/$USERNAME/blog.git"
        echo "    git push -u origin main"
    }
else
    echo "[*] 跳过仓库创建。请手动推送代码。"
fi

# 5. 本地预览
echo ""
echo "[?] 是否启动本地预览服务器？ (y/n)"
read -r start_preview
if [[ $start_preview =~ ^[Yy]$ ]]; then
    if command -v hugo &> /dev/null; then
        echo "[*] 启动 Hugo 服务器..."
        echo "    访问 http://localhost:1313"
        hugo server -D
    else
        echo "[!] Hugo 未安装，无法启动预览。"
    fi
fi

echo ""
echo "✅ 设置完成！"
echo ""
echo "下一步："
echo "1. 编辑 content/posts/ 创建文章"
echo "2. 运行 'hugo server -D' 本地预览"
echo "3. git push 提交后自动部署到 GitHub Pages"
echo ""
