# PawChat 代码验证规范

## 验证流程

### 1. 协议验证（Python 脚本）
```bash
python3 test/gateway_protocol_test.py
```

### 2. 代码静态检查
```bash
flutter analyze
```

### 3. 构建验证
```bash
flutter build apk --release
```

## Gateway Connect 参数规范

基于 OpenClaw Protocol v3：

```json
{
  "type": "req",
  "id": "...",
  "method": "connect",
  "params": {
    "minProtocol": 3,
    "maxProtocol": 3,
    "client": {
      "id": "cli",
      "version": "x.x.x",
      "platform": "android",
      "mode": "?"  // 需要确定正确值
    },
    "role": "operator",
    "scopes": ["operator.read", "operator.write"],
    "caps": [],
    "commands": [],
    "permissions": {},
    "auth": {"token": "..."},
    "locale": "zh-CN",
    "userAgent": "PawChat/x.x.x"
  }
}
```

## 待验证问题

1. `client.mode` 的正确值是什么？
2. 是否需要 `device` 字段？
3. 如何处理 `connect.challenge`？
