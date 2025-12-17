# aprsc Docker

[English](README.md) | [中文](README.zh-CN.md)

这是一个用于运行 [aprsc](https://github.com/hessu/aprsc)（APRS-IS 服务器）的 Docker 配置。

## 特点

- **超小镜像**：运行镜像仅 11.2 MB
- **多阶段构建**：两个阶段均基于 Alpine Linux，确保最佳兼容性
- **安全运行**：使用非 root 用户（aprsc）运行服务
- **完整功能**：包含 Web 监控界面和所有 APRS-IS 功能
- **易于部署**：提供 Docker Compose 和 Makefile 支持

## 快速开始

### 零配置启动

最简单的启动方式 - 无需配置文件！

```bash
# 拉取并运行（使用默认值）
docker compose up -d

# 或使用自定义环境变量
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

容器将会：
- ✅ 无需任何配置文件即可立即启动
- ✅ 使用合理的默认设置
- ✅ 显示警告提醒你设置呼号和密码

**参见 [ENVIRONMENT.zh-CN.md](ENVIRONMENT.zh-CN.md) 了解所有可用的环境变量和示例。**

### 高级：使用配置文件（可选）

如果你更喜欢使用配置文件，可以创建 `aprsc.conf` 文件。你可以从构建的镜像中提取示例配置：

```bash
# 构建镜像
docker compose build

# 提取示例配置
docker run --rm aprsc-docker-aprsc cat /etc/aprsc/aprsc.conf.example > aprsc.conf
```

或者从 GitHub 下载示例配置：

```bash
wget -O aprsc.conf https://raw.githubusercontent.com/hessu/aprsc/master/src/aprsc.conf
```

### 2. 编辑配置文件

编辑 `aprsc.conf` 文件，**必须配置以下项**：

#### 基本配置

```conf
# 你的服务器呼号
ServerId YOUR-CALLSIGN

# 服务器密码（从 https://apps.magicbug.co.uk/passcode/ 获取）
PassCode 12345

# 管理员信息
MyAdmin "Your Name, YOUR-CALLSIGN"
MyEmail your.email@example.com

# 运行目录（必须使用绝对路径）
RunDir /var/run/aprsc
```

#### 监听端口配置

```conf
# 全服务端口
Listen "Full feed"              fullfeed tcp ::  10152
Listen ""                       fullfeed udp ::  10152

# 客户端过滤端口
Listen "Client-Defined Filters" igate tcp ::  14580
Listen ""                       igate udp ::  14580

# UDP 数据包提交端口
Listen "UDP submit"             udpsubmit udp :: 8080

# HTTP 状态页面
HTTPStatus 0.0.0.0 14501

# HTTP 位置上传
HTTPUpload 0.0.0.0 8080
```

#### 重要提醒

⚠️ **删除测试指令**：配置文件中包含一个故意的错误指令 `MagicBadness`（通常在 124 行），你必须删除或注释掉它才能启动服务：

```conf
# 删除或注释掉这一行：
# MagicBadness	42.7
```

### 3. 启动服务

使用 Docker Compose：

```bash
docker compose up -d
```

或直接使用 Docker：

```bash
docker build -t aprsc-docker-aprsc .
docker run -d \
  --name aprsc \
  -p 14580:14580 \
  -p 10152:10152 \
  -p 8080:8080/udp \
  -p 8080:8080/tcp \
  -p 14501:14501 \
  -v $(pwd)/aprsc.conf:/etc/aprsc/aprsc.conf:ro \
  -v $(pwd)/logs:/var/log/aprsc \
  --restart unless-stopped \
  aprsc-docker-aprsc
```

### 4. 查看状态

#### Web 监控界面

打开浏览器访问：**http://localhost:14501/**

你将看到完整的 aprsc 状态监控页面，包括：
- 服务器运行状态
- 连接的客户端列表
- 流量统计
- 上行链路状态

#### 查看日志

```bash
# 使用 docker compose
docker compose logs -f

# 或使用 docker
docker logs -f aprsc

# 查看持久化的日志文件
tail -f logs/aprsc.log
```

## 使用 Makefile（推荐）

项目提供了 Makefile 来简化常用操作：

### 完整部署流程

```bash
# 一键部署（会自动提取配置文件模板）
make deploy

# 编辑配置文件（记得删除 MagicBadness 行！）
vim aprsc.conf

# 启动服务
make run
```

### 常用命令

```bash
# 构建镜像
make build

# 启动容器（使用 docker compose）
make run

# 停止容器
make stop

# 查看日志（实时）
make logs

# 进入容器 shell
make shell

# 提取示例配置文件（不会覆盖已存在的文件）
make config-example

# 清理容器、卷和镜像
make clean
```

### 典型工作流

```bash
# 1. 首次部署
make deploy          # 获取配置文件模板
vim aprsc.conf       # 编辑配置（删除 MagicBadness！）
make run             # 启动服务

# 2. 验证运行
make logs            # 查看日志
# 浏览器访问 http://localhost:14501/

# 3. 日常操作
make stop            # 停止服务
make run             # 重启服务

# 4. 完全清理
make clean           # 清理所有资源
```

## 端口说明

默认配置暴露的端口：

| 端口 | 协议 | 用途 | 说明 |
|------|------|------|------|
| **14580** | TCP/UDP | APRS-IS 客户端端口 | 用户可自定义过滤器 |
| **10152** | TCP/UDP | APRS-IS 全服务端口 | Full feed（完整数据流） |
| **8080** | UDP | UDP 数据包提交 | 用于接收 APRS 数据包 |
| **8080** | TCP | HTTP 位置上传 | 通过 HTTP POST 上传位置 |
| **14501** | TCP | Web 状态监控页面 | 实时查看服务器状态 |

根据你的配置文件调整需要暴露的端口。

## 目录结构

```
aprsc-docker/
├── Dockerfile           # Docker 构建文件
├── docker-compose.yml   # Docker Compose 配置
├── Makefile            # 便捷命令集合
├── aprsc.conf          # aprsc 配置文件（需要自己创建）
├── aprsc.conf.template # 配置文件模板（可选）
├── logs/               # 日志目录（自动创建）
└── README.md           # 本文件
```

## 镜像大小

最终 Docker 镜像极其小巧：

- **运行镜像**: **11.2 MB** 🎉
- 构建阶段镜像: ~370 MB（构建后丢弃）

### 大小分解

| 组件 | 大小 | 说明 |
|------|------|------|
| Alpine Linux 基础镜像 | 8.44 MB | 极简 Linux 发行版 |
| aprsc 程序和 Web 文件 | 1.78 MB | 服务器主程序和监控界面 |
| 运行时依赖 | 981 KB | libevent, openssl, libcap, tini |
| 配置和用户 | ~8 KB | 配置文件模板和用户设置 |

### 为什么这么小？

- **Alpine Linux**: 使用 musl libc 替代 glibc，基础镜像仅 8.44 MB
- **多阶段构建**: 构建工具（gcc, make 等）不包含在最终镜像中
- **精简依赖**: 只安装运行时必需的库
- **高效编译**: aprsc 是优化良好的 C 程序

这使得镜像非常适合：
- 🚀 快速部署和分发
- 💾 资源受限的环境
- 🌐 边缘设备和树莓派
- ⚡ 快速容器启动

## 高级配置

### 自定义构建参数

如果需要修改安装路径等参数，可以编辑 Dockerfile 中的 `configure` 选项：

```dockerfile
RUN ./configure \
        --prefix=/opt/aprsc \
        --sysconfdir=/etc/aprsc \
        --localstatedir=/var
```

### 性能优化

在 `docker-compose.yml` 中已包含资源限制配置，可根据需要调整：

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 128M
```

### 连接到上游服务器

如果你的服务器需要连接到 APRS-IS 核心网络，在配置文件中取消注释并配置上游服务器：

```conf
# 连接到核心旋转地址（推荐）
Uplink "Core rotate" full tcp rotate.aprs.net 10152

# 或只读模式
# Uplink "Core rotate" ro tcp rotate.aprs.net 10152
```

### 网络配置

如果需要使用 host 网络模式（更好的性能，但会直接暴露所有端口）：

```bash
docker run -d \
  --name aprsc \
  --network host \
  -v $(pwd)/aprsc.conf:/etc/aprsc/aprsc.conf:ro \
  aprsc-docker-aprsc
```

## 故障排除

### 容器启动后立即退出

**症状**：容器不断重启，日志显示配置错误。

**原因**：配置文件中的 `MagicBadness` 测试指令未删除。

**解决方案**：

```bash
# 编辑配置文件
vim aprsc.conf

# 删除或注释掉包含 MagicBadness 的行（通常在第 124 行）
# MagicBadness	42.7

# 重启容器
docker compose restart
```

### Web 监控页面显示 404

**症状**：访问 http://localhost:14501/ 显示 404 Not Found。

**原因**：Web 文件路径未正确映射。

**解决方案**：

```bash
# 检查容器中的符号链接是否存在
docker compose exec aprsc ls -la /var/run/aprsc/web

# 如果不存在，重新构建镜像
docker compose down
docker compose build --no-cache
docker compose up -d
```

### 配置文件错误

如果启动失败，可以验证配置文件语法：

```bash
docker run --rm -v $(pwd)/aprsc.conf:/etc/aprsc/aprsc.conf:ro aprsc-docker-aprsc \
  /opt/aprsc/sbin/aprsc -c /etc/aprsc/aprsc.conf -y
```

### 权限问题

确保日志目录有正确的权限：

```bash
chmod 755 logs
```

### "No such file or directory" 错误（Exit 127）

**症状**：容器启动失败，错误信息：
```
[FATAL tini (7)] exec /opt/aprsc/sbin/aprsc failed: No such file or directory
aprsc exited with code 127
```

**原因**：这通常是由于二进制文件与运行环境不兼容（glibc vs musl libc）。

**解决方案**：本项目已修复此问题。如果遇到，请确保：
1. 使用最新的 Dockerfile（两个阶段都使用 Alpine）
2. 重新构建镜像：`docker compose build --no-cache`

### 端口冲突

如果遇到端口被占用的错误，修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "24580:14580"  # 将主机端口改为 24580
```

## 监控和维护

### 查看服务器统计

访问 JSON API 获取详细统计信息：

```bash
curl http://localhost:14501/status.json | jq
```

### 日志轮换

配置文件中已启用日志轮换：

```conf
LogRotate 10 5  # 保持 5 个 10MB 的日志文件
```

### 健康检查

添加健康检查到 `docker-compose.yml`：

```yaml
healthcheck:
  test: ["CMD", "nc", "-z", "localhost", "14580"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## 参考文档

- [aprsc 官方文档](http://he.fi/aprsc/)
- [aprsc GitHub](https://github.com/hessu/aprsc)
- [APRS-IS 协议](http://www.aprs-is.net/)
- [APRS Passcode 生成器](https://apps.magicbug.co.uk/passcode/)

## 技术细节

### 构建架构

- **第一阶段（builder）**：在 Alpine Linux 上编译 aprsc
- **第二阶段（runtime）**：复制编译好的二进制到干净的 Alpine Linux 镜像
- 使用 `tini` 作为 init 进程，确保信号正确处理
- 创建符号链接以便 Web 文件能被正确访问

### 安全性

- 使用非特权用户 `aprsc` 运行服务
- 配置文件以只读方式挂载
- 支持 POSIX capabilities 以便绑定低端口

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

- aprsc 软件遵循其原始许可证
- 本 Docker 配置文件采用 MIT 许可证
