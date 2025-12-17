#!/bin/bash
# 生成 GitLab CI/CD 所需的凭据

set -e

echo "=========================================="
echo "GitLab CI/CD 凭据生成脚本"
echo "=========================================="
echo ""

# 1. 生成 GitHub SSH Key
echo "1. 生成 GitHub SSH Key..."
ssh-keygen -t ed25519 -C "gitlab-ci@aprsc-docker" -f ~/.ssh/gitlab-ci-github -N ""

echo ""
echo "✓ SSH Key 生成成功！"
echo ""

# 2. 显示公钥
echo "=========================================="
echo "GitHub Deploy Key（公钥）"
echo "=========================================="
echo "请复制以下内容，添加到 GitHub："
echo "https://github.com/bd5rv/aprsc-docker/settings/keys"
echo ""
cat ~/.ssh/gitlab-ci-github.pub
echo ""
echo ""

# 3. 显示私钥位置
echo "=========================================="
echo "GitLab CI/CD Variable（私钥）"
echo "=========================================="
echo "私钥文件位置: ~/.ssh/gitlab-ci-github"
echo ""
echo "稍后需要在 GitLab 添加 CI/CD Variable:"
echo "- Variable name: GITHUB_SSH_PRIVATE_KEY"
echo "- Type: File"
echo "- Value: 复制下面的私钥内容"
echo ""
echo "--- 私钥开始 ---"
cat ~/.ssh/gitlab-ci-github
echo "--- 私钥结束 ---"
echo ""

# 4. Docker Hub Token 提示
echo "=========================================="
echo "Docker Hub Access Token"
echo "=========================================="
echo "请访问以下地址创建 Access Token:"
echo "https://hub.docker.com/settings/security"
echo ""
echo "创建步骤："
echo "1. 点击 'New Access Token'"
echo "2. Description: gitlab-ci-aprsc-docker"
echo "3. Access permissions: Read, Write, Delete"
echo "4. 点击 'Generate'"
echo "5. 复制生成的 token（只显示一次！）"
echo ""
echo "然后在 GitLab 添加 CI/CD Variable:"
echo "- Variable name: DOCKERHUB_TOKEN"
echo "- Type: Variable"
echo "- Value: 粘贴 Docker Hub token"
echo "- Flags: ✓ Protect variable, ✓ Mask variable"
echo ""

echo "=========================================="
echo "完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 添加公钥到 GitHub"
echo "2. 创建 Docker Hub token"
echo "3. 在 GitLab 配置 CI/CD Variables"
echo ""
