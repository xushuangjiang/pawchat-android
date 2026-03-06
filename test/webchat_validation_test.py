#!/usr/bin/env python3
"""
WebChat 功能验证测试
基于 OpenClaw WebChat 源代码分析验证 PawChat 功能完整性
"""

import websocket
import json
import sys
import time
import threading

GATEWAY_URL = "ws://192.168.0.213:18789"
TOKEN = "989674d657564edbc29ef906489fba9e742f5b782273d331"

class WebChatValidator:
    def __init__(self):
        self.ws = None
        self.connected = False
        self.errors = []
        self.test_results = {}
        self._pending_tests = []
        self._test_index = 0
        
    def validate_all(self):
        print("="*70)
        print("PawChat WebChat 功能验证")
        print("基于 OpenClaw Control-UI 源代码分析")
        print("="*70)
        
        self._pending_tests = [
            ("health", {}),
            ("status", {}),
            ("sessions.list", {"limit": 10}),
            ("config.get", {}),
            ("config.schema", {}),
            ("models.list", {}),
            ("agents.list", {}),
            ("node.list", {}),
            ("channels.status", {}),
            ("cron.list", {}),
            ("cron.status", {}),
        ]
        
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
            print(f"❌ 异常: {e}")
            return False
            
        return self.connected
    
    def _on_open(self, ws):
        print("✓ WebSocket 已连接")
        
    def _on_message(self, ws, message):
        data = json.loads(message)
        msg_type = data.get('type')
        event = data.get('event')
        
        # 处理 challenge
        if msg_type == 'event' and event == 'connect.challenge':
            self._send_connect()
            return
            
        # 处理 connect 响应
        if msg_type == 'res' and str(data.get('id', '')).startswith('connect'):
            if data.get('ok'):
                print("✅ 连接成功！")
                self.connected = True
                # 延迟后开始测试
                threading.Timer(1.0, self._run_next_test).start()
            else:
                print(f"❌ 连接失败: {data.get('error')}")
                ws.close()
            return
                
        # 处理测试响应
        if msg_type == 'res':
            self._handle_response(data)
            # 继续下一个测试
            threading.Timer(0.5, self._run_next_test).start()
    
    def _run_next_test(self):
        if self._test_index < len(self._pending_tests):
            method, params = self._pending_tests[self._test_index]
            self._test_index += 1
            self._test_method(method, params)
        else:
            # 所有测试完成
            threading.Timer(2.0, lambda: self.ws.close()).start()
        
    def _on_error(self, ws, error):
        print(f"❌ WebSocket 错误: {error}")
        self.errors.append(str(error))
        
    def _on_close(self, ws, code, msg):
        print(f"\n{'='*70}")
        print(f"✓ WebSocket 已关闭")
        self._print_summary()
        
    def _send_connect(self):
        request = {
            "type": "req",
            "id": "connect-1",
            "method": "connect",
            "params": {
                "minProtocol": 3,
                "maxProtocol": 3,
                "client": {
                    "id": "cli",
                    "version": "0.2.3",
                    "platform": "android",
                    "mode": "cli"
                },
                "role": "operator",
                "scopes": ["operator.read", "operator.write", "operator.admin", 
                          "operator.approvals", "operator.pairing"],
                "caps": [],
                "commands": [],
                "permissions": {},
                "auth": {"token": TOKEN},
                "locale": "zh-CN",
                "userAgent": "PawChat/0.2.3"
            }
        }
        print(f"\n→ 发送 connect 请求")
        self.ws.send(json.dumps(request))
    
    def _test_method(self, method, params):
        request = {
            "type": "req",
            "id": f"test-{method}",
            "method": method,
            "params": params
        }
        print(f"→ 测试: {method}")
        self.ws.send(json.dumps(request))
    
    def _handle_response(self, data):
        req_id = data.get('id', '')
        ok = data.get('ok', False)
        
        if str(req_id).startswith('test-'):
            method = req_id.replace('test-', '')
            if ok:
                print(f"  ✅ {method}")
                self.test_results[method] = "✅ 通过"
            else:
                error = data.get('error', 'Unknown error')
                if isinstance(error, dict):
                    error_msg = error.get('message', str(error))
                else:
                    error_msg = str(error)
                print(f"  ⚠️  {method}: {error_msg[:50]}")
                self.test_results[method] = f"⚠️  {error_msg[:30]}"
    
    def _print_summary(self):
        print("\n" + "="*70)
        print("测试结果摘要")
        print("="*70)
        
        passed = sum(1 for v in self.test_results.values() if v.startswith("✅"))
        total = len(self.test_results)
        
        for method, result in sorted(self.test_results.items()):
            status = "✅" if result.startswith("✅") else "⚠️ "
            print(f"  {status} {method:25s}")
        
        print("-"*70)
        print(f"总计: {passed}/{total} 通过")
        
        if passed == total:
            print("\n🎉 所有测试通过！PawChat 功能与 WebChat 完全兼容。")
        else:
            print(f"\n⚠️  {total - passed} 个测试需要检查权限或配置。")
        
        print("="*70)


def main():
    print("WebChat 功能验证测试")
    print(f"Gateway: {GATEWAY_URL}")
    print()
    
    validator = WebChatValidator()
    validator.validate_all()
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
