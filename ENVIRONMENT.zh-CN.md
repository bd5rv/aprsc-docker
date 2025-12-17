# 环境变量配置

[English](ENVIRONMENT.md) | [中文](ENVIRONMENT.zh-CN.md)

aprsc Docker 支持通过环境变量进行配置，使得无需配置文件即可轻松运行。

## 快速开始

无需任何配置即可运行（使用所有默认值）：

```bash
docker run -d -p 14580:14580 -p 14501:14501 aprsc-docker-aprsc
```

使用自定义呼号和密码运行：

```bash
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -p 14580:14580 -p 14501:14501 \
  aprsc-docker-aprsc
```

## 配置优先级

1. **配置文件**（如果挂载到 `/etc/aprsc/aprsc.conf`）
2. **环境变量**
3. **默认值**

## 可用的环境变量

### 服务器标识

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_SERVER_ID` | `NOCALL` | 你的业余无线电呼号（生产环境必需） |
| `APRSC_PASSCODE` | `-1` | 服务器密码（从 https://apps.magicbug.co.uk/passcode/ 获取） |
| `APRSC_MY_ADMIN` | `Docker User` | 管理员姓名 |
| `APRSC_MY_EMAIL` | `root@localhost` | 管理员邮箱 |

### 目录

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_RUN_DIR` | `/var/run/aprsc` | 运行时数据目录 |

### 日志

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_LOG_ROTATE` | `10 5` | 日志轮换：\"兆字节 文件数量\" |

### 超时

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_UPSTREAM_TIMEOUT` | `15s` | 上游服务器超时时间 |
| `APRSC_CLIENT_TIMEOUT` | `48h` | 客户端连接超时时间 |

### 资源限制

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_MAX_CLIENTS` | `500` | 最大同时客户端数 |
| `APRSC_FILE_LIMIT` | `10000` | 最大打开文件数 |

### 监听端口

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_ENABLE_FULL_FEED` | `yes` | 启用全服务端口 |
| `APRSC_FULL_FEED_PORT` | `10152` | 全服务端口号 |
| `APRSC_ENABLE_IGATE` | `yes` | 启用 iGate/客户端端口 |
| `APRSC_IGATE_PORT` | `14580` | iGate/客户端端口号 |
| `APRSC_ENABLE_UDP_SUBMIT` | `yes` | 启用 UDP 数据包提交 |
| `APRSC_UDP_SUBMIT_PORT` | `8080` | UDP 提交端口号 |

### HTTP 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_HTTP_STATUS_PORT` | `14501` | HTTP 状态页面端口 |
| `APRSC_HTTP_UPLOAD_PORT` | `8080` | HTTP 位置上传端口 |

### 上行链路配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APRSC_UPLINK_ENABLED` | `no` | 启用连接到上游服务器 |
| `APRSC_UPLINK_SERVER` | `rotate.aprs2.net` | 上游服务器地址 |
| `APRSC_UPLINK_PORT` | `10152` | 上游服务器端口 |
| `APRSC_UPLINK_TYPE` | `full` | 上行链路类型：`full` 或 `ro`（只读） |

## 使用示例

### 最小配置

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=12345 \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

### 连接上游服务器

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_UPLINK_ENABLED=yes \
  -e APRSC_UPLINK_SERVER=rotate.aprs2.net \
  -e APRSC_UPLINK_PORT=10152 \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

### 只读模式

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=-1 \
  -e APRSC_UPLINK_ENABLED=yes \
  -e APRSC_UPLINK_TYPE=ro \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

### 自定义端口

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_IGATE_PORT=24580 \
  -e APRSC_HTTP_STATUS_PORT=24501 \
  -p 24580:24580 \
  -p 24501:24501 \
  aprsc-docker-aprsc
```

### 使用 .env 文件

1. 复制示例文件：
```bash
cp .env.example .env
```

2. 编辑 `.env` 文件设置你的配置：
```bash
vim .env
```

3. 使用 docker-compose 运行（自动加载 `.env`）：
```bash
docker-compose up -d
```

## Docker Compose 示例

```yaml
version: '3.8'

services:
  aprsc:
    image: aprsc-docker-aprsc
    environment:
      - APRSC_SERVER_ID=N0CALL
      - APRSC_PASSCODE=12345
      - APRSC_MY_ADMIN=你的名字
      - APRSC_MY_EMAIL=you@example.com
      - APRSC_UPLINK_ENABLED=yes
    ports:
      - "14580:14580"
      - "14501:14501"
    volumes:
      - ./logs:/var/log/aprsc
    restart: unless-stopped
```

## 查看生成的配置

查看生成的配置文件：

```bash
docker exec <容器名称> cat /etc/aprsc/aprsc.conf
```

## 警告信息

使用默认值时，你会看到警告信息：

```
WARNING: Using default callsign 'NOCALL'
Please set APRSC_SERVER_ID environment variable to your callsign

WARNING: Using invalid passcode
Please set APRSC_PASSCODE environment variable
Generate at: https://apps.magicbug.co.uk/passcode/
```

这些是提醒你为生产环境正确配置服务器的信息。

## 混合配置方法

你可以结合使用配置文件和环境变量：

1. **挂载部分配置文件** 包含基本设置
2. **使用环境变量覆盖特定值**
3. **配置文件优先于环境变量**

示例：
```bash
docker run -d \
  -v ./aprsc.conf:/etc/aprsc/aprsc.conf:ro \
  -e APRSC_UPLINK_ENABLED=yes \
  -p 14580:14580 \
  aprsc-docker-aprsc
```

在这种情况下，将使用挂载的 `aprsc.conf`，环境变量将被忽略。
