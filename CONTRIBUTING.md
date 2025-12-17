# Contributing to aprsc-docker

感谢您对 aprsc-docker 项目的关注！

## 开发工作流

本项目使用 **双仓库架构**：

- **GitLab（http://dev.myhamplace.com）**：主开发仓库，运行所有 CI/CD
- **GitHub（https://github.com/bd5rv/aprsc-docker）**：公开镜像仓库，用于社区展示和接受 PR

## 内部开发者工作流（GitLab）

### 1. 克隆仓库

```bash
git clone http://dev.myhamplace.com/michael.chen/aprsc-docker.git
cd aprsc-docker
```

### 2. 创建功能分支

```bash
git checkout -b feature/your-feature-name
```

### 3. 进行开发

```bash
# 编辑文件...
git add .
git commit -m "feat: Add your feature description"
```

### 4. 本地测试

在推送前，务必进行本地测试：

```bash
# 构建镜像
docker compose build

# 启动测试
docker compose up -d

# 检查日志
docker compose logs -f

# 测试 APRS 连接
./test-aprs-connection.sh localhost 14580 TEST

# 测试 Web 界面
curl http://localhost:14501/status.json

# 清理
docker compose down
```

### 5. 推送到 GitLab

```bash
git push origin feature/your-feature-name
```

### 6. 创建 Merge Request

1. 访问 http://dev.myhamplace.com/michael.chen/aprsc-docker
2. 点击 "Create merge request"
3. 填写描述和相关信息
4. 等待 CI/CD 自动运行测试
5. Merge 后会自动同步到 GitHub

## 社区贡献者工作流（GitHub PR）

### 1. Fork 仓库

在 GitHub 上 Fork https://github.com/bd5rv/aprsc-docker

### 2. 克隆您的 Fork

```bash
git clone https://github.com/YOUR_USERNAME/aprsc-docker.git
cd aprsc-docker
```

### 3. 创建功能分支

```bash
git checkout -b feature/your-feature-name
```

### 4. 进行开发和测试

同内部开发者工作流的步骤 3-4

### 5. 推送到您的 Fork

```bash
git push origin feature/your-feature-name
```

### 6. 创建 Pull Request

1. 访问您的 Fork 页面
2. 点击 "New Pull Request"
3. 填写 PR 描述
4. 提交 PR

### 7. PR 处理流程

- 维护者会审查您的 PR
- 可能会要求修改或提供反馈
- 审查通过后，维护者会将您的更改手动合并到 GitLab 仓库
- GitLab CI/CD 会自动运行测试和构建
- 成功后会自动同步回 GitHub，您的 PR 会被自动关闭

**注意**：GitHub 上的 PR 不会被直接合并，而是会在 GitLab 处理后通过自动同步关闭。

## Pull Request 指南

### 标题格式

使用 Conventional Commits 格式：

- `feat:` 新功能
- `fix:` Bug 修复
- `docs:` 文档更新
- `refactor:` 代码重构
- `test:` 测试相关
- `chore:` 构建或工具相关

### 描述要求

请在 PR 描述中包含：

- 清晰的变更说明
- 变更的动机和背景
- 任何破坏性变更的说明
- 相关的 Issue 编号（使用 `Fixes #123`）

### 测试要求

提交前请确保：

- [ ] 本地构建成功：`docker compose build`
- [ ] 容器正常运行：`docker compose up -d`
- [ ] 日志无错误：`docker compose logs`
- [ ] APRS 连接正常：`./test-aprs-connection.sh localhost 14580 TEST`
- [ ] Web 界面可访问：http://localhost:14501/

## 代码风格

### Shell 脚本

- 使用 `#!/bin/bash` shebang
- 使用 `set -e` 进行错误处理
- 为复杂逻辑添加注释
- 使用有意义的变量名
- 遵循现有脚本的模式

### Docker

- 保持镜像精简
- 使用多阶段构建
- 文档化暴露的端口
- 使用 ARG 进行构建时配置
- 使用 ENV 进行运行时配置

### 文档

- 用户可见的变更需更新 README.md
- 代码变更需更新相关注释
- 新功能需添加使用示例

## CI/CD Pipeline

### 自动检查

所有 PR 和 Merge Request 都会触发自动检查：

1. 多架构构建（AMD64、ARM64、ARMv7）
2. 基础容器测试
3. APRS-IS 连接测试
4. Web 界面测试

### 构建时间

完整 Pipeline 预计耗时 ~35-45 分钟：

- 构建：20-25 分钟
- 测试：5-8 分钟
- 推送：5-10 分钟
- 同步：1-2 分钟

### 手动构建

如需手动测试多架构构建：

```bash
# 构建单一架构
./test-multiarch-build.sh linux/amd64

# 构建所有架构（本地测试）
./test-multiarch-build.sh

# 推送到 Docker Hub（需要凭据）
./push-to-dockerhub.sh
```

## 上游更新监控

本项目自动监控 [hessu/aprsc](https://github.com/hessu/aprsc) 的更新：

- 每日自动检测（UTC 02:00）
- 检测到上游更新时自动构建
- 版本号从编译后的二进制动态提取
- 自动推送到 Docker Hub

## 处理 GitHub Pull Requests（维护者）

当收到 GitHub PR 时，维护者需要：

### 1. 获取 PR 到本地

```bash
# 获取 PR #123
git fetch https://github.com/bd5rv/aprsc-docker.git pull/123/head:pr-123

# 检出 PR 分支
git checkout pr-123
```

### 2. 本地审查和测试

```bash
# 审查代码
git diff main...pr-123

# 本地测试
docker compose build
docker compose up -d
./test-aprs-connection.sh localhost 14580 TEST
```

### 3. 合并到 GitLab

```bash
# 切回主分支
git checkout main

# 合并 PR
git merge --no-ff pr-123 -m "Merge pull request #123: Feature description

Description of changes

Co-authored-by: GitHub User <user@example.com>"

# 推送到 GitLab
git push origin main
```

### 4. 自动同步

- GitLab CI/CD 会自动运行完整测试
- 测试通过后自动构建多架构镜像
- 推送到 Docker Hub
- 自动同步回 GitHub
- GitHub PR 会被自动关闭

### 5. 清理

```bash
git branch -d pr-123
```

## 问题反馈

- 在 GitHub 上提交 Issue：https://github.com/bd5rv/aprsc-docker/issues
- 联系维护者

## 许可证

通过贡献代码，您同意您的贡献将使用 MIT License 授权。

---

**感谢您的贡献！** 🎉
