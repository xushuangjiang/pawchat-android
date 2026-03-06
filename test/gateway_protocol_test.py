#!/usr/bin/env python3
"""
PawChat Gateway 协议验证脚本
用于验证 connect 请求格式是否正确
"""

import websocket
import json
import sys
import time

# 测试配置
GATEWAY_URL = "ws://192.168.0.213:18789"
TOKEN = "989674d657564edbc29ef906489fba9e742f5b782273d331"

class GatewayTester:
    def __init__(self):
        self.ws = None
        self.challenge_nonce = None
        self.connected = False
        self.errors = []
        
    def test_connect(self, client_params):
        """测试 connect 请求"""
        print(f"\n{'='*60}")
        print(f"测试: {client_params.get('client', {}).get('mode', 'unknown')}")
        print(f"{'='*60}")
        
        try:
            self.ws = websocket.WebSocketApp(
                GATEWAY_URL,
                on_open=self._on_open,
                on_message=self._on_message,
                on_error=self._on_error,
                on_close=self._on_close
            )
            self.ws.run_forever()
            
        except Exception as e:
            self.errors.append(str(e))
            print(f"❌ 异常: {e}")
            return False
            
        return self.connected
    
    def _on_open(self, ws):
        print("✓ WebSocket 已连接")
        
    def _on_message(self, ws, message):
        data = json.loads(message)
        print(f"← 收到: {json.dumps(data, indent=2, ensure_ascii=False)}")
        
        if data.get('type') == 'event' and data.get('event') == 'connect.challenge':
            self.challenge_nonce = data.get('payload', {}).get('nonce')
            self._send_connect()
            
        elif data.get('type') == 'res':
            if data.get('ok'):
                print("✅ 连接成功！")
                self.connected = True
                ws.close()
            else:
                error = data.get('error', {})
                print(f"❌ 连接失败: {error.get('code')} - {error.get('message')}")
                self.errors.append(error.get('message'))
                ws.close()
    
    def _on_error(self, ws, error):
        print(f"❌ WebSocket 错误: {error}")
        self.errors.append(str(error))
        
    def _on_close(self, ws, code, msg):
        print(f"✓ WebSocket 已关闭")
        
    def _send_connect(self):
        """发送 connect 请求"""
        request = {
            "type": "req",
            "id": "test-1",
            "method": "connect",
            "params": {
                "minProtocol": 3,
                "maxProtocol": 3,
                "client": {
                    "id": "cli",
                    "version": "0.2.1",
                    "platform": "android",
                    "mode": "cli"
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
        
        # 注意：device 字段需要签名验证，暂不发送
        # if self.challenge_nonce:
        #     request["params"]["device"] = {
        #         "id": "test-device",
        #         "nonce": self.challenge_nonce
        #     }
        
        print(f"→ 发送: {json.dumps(request, indent=2, ensure_ascii=False)}")
        self.ws.send(json.dumps(request))


def main():
    print("PawChat Gateway 协议验证")
    print(f"Gateway: {GATEWAY_URL}")
    
    tester = GatewayTester()
    
    # 测试当前配置
    success = tester.test_connect({
        "client": {"mode": "operator"}
    })
    
    print(f"\n{'='*60}")
    if success:
        print("✅ 所有测试通过！可以编译发布。")
        return 0
    else:
        print("❌ 测试失败，请修复以下问题：")
        for error in tester.errors:
            print(f"  - {error}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
