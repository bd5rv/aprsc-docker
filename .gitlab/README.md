# GitLab CI/CD 配置说明

本目录包含 GitLab CI/CD 所需的脚本和配置文件。

## 目录结构

```
.gitlab/
├── scripts/
│   ├── detect-upstream.sh       # 检测上游 hessu/aprsc 更新
│   ├── test-container.sh        # 基础容器测试
│   ├── test-aprs-is.sh          # APRS-IS 连接测试
│   ├── test-web.sh              # Web 界面测试
│   └── sync-to-github.sh        # 同步代码到 GitHub
├── upstream-state.txt           # 上游 commit SHA 跟踪（自动生成）
└── build-flags.env              # 构建标志（自动生成）
```

## 脚本说明

### detect-upstream.sh
检测上游 hessu/aprsc 仓库是否有新的提交。
- 输入：无
- 输出：`build-flags.env` 文件，包含 `UPSTREAM_CHANGED=true/false`

### test-container.sh
测试容器基础功能。
- 检查进程运行
- 验证版本
- 检查配置文件
- 验证端口监听

### test-aprs-is.sh
测试 APRS-IS 核心功能。
- 测试 uplink 连接
- 测试客户端登录
- 验证数据接收

### test-web.sh
测试 Web 监控界面。
- HTTP 状态页
- JSON API
- 关键数据字段验证

### sync-to-github.sh
同步代码到 GitHub 镜像仓库。
- 推送所有分支
- 推送所有标签
- 验证同步成功

## CI/CD 工作流

完整的 Pipeline 包含 5 个阶段：

1. **detect** - 检测上游更新
2. **build** - 构建多架构镜像
3. **test** - 运行完整测试套件
4. **push** - 推送到 Docker Hub
5. **sync** - 同步到 GitHub

详见根目录的 `.gitlab-ci.yml` 文件。
