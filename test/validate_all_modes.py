#!/usr/bin/env python3
"""
验证所有可能的 client.mode 值
"""

import websocket
import json
import sys

GATEWAY_URL = "ws://192.168.0.213:18789"
TOKEN = "989674d657564edbc29ef906489fba9e742f5b782273d331"

# 测试所有可能的 mode 值
MODES_TO_TEST = [
    "operator",
    "node", 
    "headless",
    "cli",
    "control",
    "web",
    "android",
    "mobile"
]

def test_mode(mode):
    """测试特定的 mode"""
    print(f"\n{'='*60}")
    print(f"测试 mode: '{mode}'")
    print(f"{'='*60}")
    
    result = {"success": False, "error": None}
    
    def on_message(ws, message):
        data = json.loads(message)
        print(f"← {json.dumps(data, indent=2)[:200]}...")
        
        if data.get('type') == 'event' and data.get('event') == 'connect.challenge':
            # 发送 connect 请求
            connect_req = {
                "type": "req",
                "id": f"test-{mode}",
                "method": "connect",
                "params": {
                    "minProtocol": 3,
                    "maxProtocol": 3,
                    "client": {
                        "id": "cli",
                        "version": "0.2.1",
                        "platform": "android",
                        "mode": mode
                    },
                    "role": "operator",
                    "scopes": ["operator.read", "operator.write"],
                    "caps": [],
                    "commands": [],
                    "permissions": {},
                    "auth": {"token": TOKEN},
                    "locale": "zh-CN",
                    "userAgent": "PawChat/0.2.1"
                }
            }
            ws.send(json.dumps(connect_req))
            
        elif data.get('type') == 'res':
            if data.get('ok'):
                print(f"✅ SUCCESS! mode='{mode}' 工作正常！")
                result["success"] = True
                ws.close()
            else:
                error = data.get('error', {})
                result["error"] = error.get('message', 'Unknown error')
                print(f"❌ FAILED: {result['error'][:100]}")
                ws.close()
    
    def on_error(ws, error):
        result["error"] = str(error)
        
    def on_close(ws, code, msg):
        pass
        
    def on_open(ws):
        pass
    
    ws = websocket.WebSocketApp(
        GATEWAY_URL,
        on_open=on_open,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close
    )
    
    try:
        ws.run_forever()
    except:
        pass
    
    return result

def main():
    print("PawChat Gateway Mode 验证")
    print(f"Gateway: {GATEWAY_URL}")
    print(f"测试 {len(MODES_TO_TEST)} 个 mode 值...")
    
    working_modes = []
    
    for mode in MODES_TO_TEST:
        result = test_mode(mode)
        if result["success"]:
            working_modes.append(mode)
    
    print(f"\n{'='*60}")
    print("验证结果:")
    print(f"{'='*60}")
    
    if working_modes:
        print(f"✅ 可用的 mode: {working_modes}")
        return 0
    else:
        print("❌ 所有 mode 都失败了")
        print("\n建议:")
        print("1. 检查 Gateway 版本是否支持 Protocol v3")
        print("2. 查看 OpenClaw 源码找正确的 mode 常量")
        print("3. 可能需要 device 签名验证")
        return 1

if __name__ == "__main__":
    sys.exit(main())
