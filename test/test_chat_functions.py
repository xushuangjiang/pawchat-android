#!/usr/bin/env python3
"""
测试聊天功能：
1. 连接 Gateway
2. 获取历史消息
3. 发送消息
4. 接收流式响应
"""

import websocket
import json
import sys
import time

GATEWAY_URL = "ws://192.168.0.213:18789"
TOKEN = "989674d657564edbc29ef906489fba9e742f5b782273d331"

class ChatTester:
    def __init__(self):
        self.ws = None
        self.connected = False
        self.session_key = None
        self.messages = []
        self.streaming_content = ""
        
    def test_full_flow(self):
        """测试完整流程"""
        print("="*60)
        print("测试聊天功能")
        print("="*60)
        
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
        
        print(f"\n← 收到 [{msg_type}]:")
        print(f"  {json.dumps(data, indent=2)[:300]}...")
        
        # 处理 challenge
        if msg_type == 'event' and event == 'connect.challenge':
            self._send_connect()
            
        # 处理 connect 响应
        elif msg_type == 'res' and data.get('id', '').startswith('connect'):
            if data.get('ok'):
                print("✅ 连接成功！")
                self.connected = True
                # 延迟后获取历史消息
                time.sleep(1)
                self._get_history()
                # 延迟后发送测试消息
                time.sleep(2)
                self._send_message("你好，这是一条测试消息")
            else:
                print(f"❌ 连接失败: {data.get('error')}")
                ws.close()
                
        # 处理历史消息响应
        elif msg_type == 'res' and data.get('id', '').startswith('history'):
            if data.get('ok'):
                history = data.get('payload', {}).get('history', [])
                print(f"✅ 获取到 {len(history)} 条历史消息")
                for msg in history[:3]:  # 只显示前3条
                    print(f"  - {msg.get('role')}: {msg.get('content', '')[:50]}...")
            else:
                print(f"❌ 获取历史消息失败: {data.get('error')}")
                
        # 处理发送消息响应
        elif msg_type == 'res' and data.get('id', '').startswith('send'):
            if data.get('ok'):
                print("✅ 消息发送成功")
            else:
                print(f"❌ 消息发送失败: {data.get('error')}")
                
        # 处理流式响应
        elif msg_type == 'event' and event == 'chat.chunk':
            content = data.get('payload', {}).get('content', '')
            self.streaming_content += content
            print(f"📝 流式响应: {content[:50]}...")
            
        # 处理完成响应
        elif msg_type == 'event' and event == 'chat.complete':
            content = data.get('payload', {}).get('content', '')
            print(f"✅ 响应完成: {content[:100]}...")
            # 测试完成，关闭连接
            time.sleep(1)
            ws.close()
            
        # 处理错误
        elif msg_type == 'event' and event == 'chat.error':
            error = data.get('payload', {}).get('error', 'Unknown error')
            print(f"❌ 聊天错误: {error}")
    
    def _on_error(self, ws, error):
        print(f"❌ WebSocket 错误: {error}")
        
    def _on_close(self, ws, code, msg):
        print(f"\n{'='*60}")
        print(f"✓ WebSocket 已关闭")
        print(f"{'='*60}")
        
    def _send_connect(self):
        """发送 connect 请求"""
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
                "scopes": ["operator.read", "operator.write"],
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
    
    def _get_history(self):
        """获取历史消息"""
        self.session_key = f"session-{int(time.time() * 1000)}"
        request = {
            "type": "req",
            "id": "history-1",
            "method": "chat.history",
            "params": {
                "sessionKey": self.session_key,
                "limit": 50
            }
        }
        print(f"\n→ 获取历史消息 (session: {self.session_key})")
        self.ws.send(json.dumps(request))
    
    def _send_message(self, content):
        """发送消息"""
        request = {
            "type": "req",
            "id": "send-1",
            "method": "chat.send",
            "params": {
                "content": content,
                "sessionKey": self.session_key
            }
        }
        print(f"\n→ 发送消息: {content}")
        self.ws.send(json.dumps(request))


def main():
    print("PawChat 聊天功能测试")
    print(f"Gateway: {GATEWAY_URL}")
    print()
    
    tester = ChatTester()
    success = tester.test_full_flow()
    
    if success:
        print("\n✅ 测试完成")
        return 0
    else:
        print("\n❌ 测试失败")
        return 1


if __name__ == "__main__":
    sys.exit(main())
