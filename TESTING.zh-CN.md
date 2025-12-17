# APRS-IS 连接测试指南

[English](TESTING.md) | [中文](TESTING.zh-CN.md)

本指南介绍如何使用 telnet 和其他工具测试 APRS-IS 连接。

## 快速测试

### 测试本地 aprsc 服务器

```bash
# 使用测试脚本
./test-aprs-connection.sh localhost 14580 N0CALL

# 或手动测试
telnet localhost 14580
```

连接后输入：
```
user N0CALL pass -1 vers test 1.0
```

你应该能看到 APRS 数据流。

## 连接参数

### 登录字符串格式

```
user <callsign> pass <passcode> vers <software> <version> [filter <filter>]
```

**参数说明：**
- `callsign`: 你的业余无线电呼号（测试时可使用任意呼号）
- `passcode`:
  - `-1` 表示只读访问
  - 有效密码用于完整访问（从 https://apps.magicbug.co.uk/passcode/ 获取）
- `software`: 软件名称
- `version`: 版本号
- `filter`: （可选）数据过滤器

### 常用端口

| 端口 | 类型 | 说明 |
|------|------|------|
| 14580 | TCP | 标准客户端端口（可过滤） |
| 10152 | TCP | 完整数据端口（无过滤） |
| 8080 | UDP | 数据包提交端口 |

## 测试场景

### 1. 测试本地服务器（只读模式）

```bash
telnet localhost 14580
```

登录：
```
user TEST pass -1 vers telnet-test 1.0
```

### 2. 使用地理位置过滤器测试

```bash
telnet localhost 14580
```

带过滤器登录：
```
user TEST pass -1 vers telnet-test 1.0 filter r/35.6/139.7/100
```

这将接收东京（35.6°N, 139.7°E）周围 100 公里内的数据包。

### 3. 使用呼号过滤器测试

```bash
telnet localhost 14580
```

登录：
```
user TEST pass -1 vers telnet-test 1.0 filter b/CALLSIGN1/CALLSIGN2
```

这将只接收指定呼号的数据包。

### 4. 测试上游服务器

```bash
# 测试连接到上游 APRS-IS 服务器
telnet rotate.aprs2.net 14580
```

登录：
```
user N0CALL pass -1 vers test 1.0
```

### 5. 测试完整数据端口

```bash
telnet localhost 10152
```

登录：
```
user TEST pass -1 vers test 1.0
```

注意：完整数据端口会发送所有数据包（流量很大）。

## 过滤器类型

### 范围过滤器（地理位置）
```
filter r/lat/lon/radius
```
示例：`filter r/35.6/139.7/100`（东京周围 100 公里）

### 好友过滤器（呼号）
```
filter b/CALL1/CALL2/CALL3
```
示例：`filter b/N0CALL/W1AW`（只接收这些呼号）

### 前缀过滤器
```
filter p/PREFIX1/PREFIX2
```
示例：`filter p/CQ/JA`（呼号以 CQ 或 JA 开头）

### 类型过滤器
```
filter t/poimqstunw
```
- `p` = 位置
- `o` = 对象
- `i` = 项目
- `m` = 消息
- `q` = 查询
- `s` = 状态
- `t` = 遥测
- `u` = 用户自定义
- `n` = NWS 格式
- `w` = 天气

### 入口站过滤器
```
filter e/CALL1/CALL2
```
只接收通过指定 igate 进入的数据包。

### 组过滤器
```
filter g/GROUP
```
示例：`filter g/TELEM`（遥测组）

## 使用测试脚本

### 基本用法

```bash
# 测试本地服务器
./test-aprs-connection.sh

# 测试指定服务器和端口
./test-aprs-connection.sh rotate.aprs2.net 14580

# 使用自定义呼号测试
./test-aprs-connection.sh localhost 14580 YOUR-CALL
```

### 交互式测试

连接后，可以输入过滤器命令：
```
filter r/35.6/139.7/100
filter b/N0CALL
filter p/JA
```

按 Ctrl+C 退出。

## 使用 netcat (nc) 测试

telnet 的替代方案：

```bash
echo "user TEST pass -1 vers test 1.0" | nc localhost 14580
```

带超时：
```bash
echo "user TEST pass -1 vers test 1.0" | nc -w 10 localhost 14580
```

## 验证服务器是否正常工作

### 检查服务器是否接受连接

```bash
nc -zv localhost 14580
nc -zv localhost 10152
nc -zv localhost 14501
```

### 检查 HTTP 状态页面

```bash
curl http://localhost:14501/
curl http://localhost:14501/status.json
```

### 使用 wget 检查

```bash
wget -qO- http://localhost:14501/status.json | jq
```

## 常见问题

### 连接被拒绝

**症状：** `Connection refused` 或 `Unable to connect`

**解决方案：**
1. 检查容器是否运行：`docker ps`
2. 检查端口是否暴露：`docker port aprsc`
3. 检查防火墙设置
4. 验证配置中的端口

### 登录后没有数据

**症状：** 登录成功但没有收到数据包

**解决方案：**
1. 检查是否启用了上行链路：`APRSC_UPLINK_ENABLED=yes`
2. 在日志中验证上行链路配置：`docker logs aprsc`
3. 尝试使用完整数据端口（10152）而不是过滤端口
4. 检查服务器是否有活动的上行链路连接

### 无效密码

**症状：** `Login failed` 或 `Invalid passcode`

**解决方案：**
1. 使用 `-1` 进行只读访问（无需验证）
2. 在 https://apps.magicbug.co.uk/passcode/ 生成有效密码
3. 检查呼号拼写

## 预期输出

### 成功连接

```
$ telnet localhost 14580
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
# aprsc 2.1.19-g6d55570 fbn02lzp 17 Dec 2025 11:39:19 GMT NOCALL
user TEST pass -1 vers test 1.0
# logresp TEST verified, server NOCALL
N0CALL>APRS,TCPIP*,qAC,NOCALL:>Test packet
...
```

### 带过滤器

```
user TEST pass -1 vers test 1.0 filter r/35.6/139.7/100
# logresp TEST verified, server NOCALL
# filter r/35.6/139.7/100 active
JA1YOE>APRS,TCPIP*:=3542.71N/13941.25E-PHG7130
...
```

## 自动化测试脚本

创建简单的测试脚本：

```bash
#!/bin/bash
# test-aprs-data.sh

{
    sleep 1
    echo "user TEST pass -1 vers test 1.0"
    sleep 10
} | telnet localhost 14580 | head -20
```

这会连接、登录、等待 10 秒，然后显示前 20 行。

## 性能测试

### 测试连接数

```bash
for i in {1..10}; do
    (echo "user TEST$i pass -1 vers test 1.0"; sleep 30) | \
    nc localhost 14580 &
done
```

检查连接数：
```bash
curl -s http://localhost:14501/status.json | jq '.clients.clients_cur'
```

### 监控流量

```bash
# 实时查看数据包速率
watch -n 1 'curl -s http://localhost:14501/status.json | jq ".totals"'
```

## 参考文档

- [APRS-IS 协议文档](http://www.aprs-is.net/javAPRSFilter.aspx)
- [aprsc 文档](http://he.fi/aprsc/)
- [APRS 过滤器指南](http://www.aprs-is.net/javAPRSFilter.aspx)
