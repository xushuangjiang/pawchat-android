import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/gateway_client.dart';
import '../../core/reconnection_manager.dart';
import '../../core/session_manager.dart';
import '../../core/version.dart';

class SettingsScreen extends StatefulWidget {
  final GatewayClient client;
  final ReconnectionManager reconnectionManager;
  final SessionManager sessionManager;
  
  const SettingsScreen({
    super.key,
    required this.client,
    required this.reconnectionManager,
    required this.sessionManager,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isConnecting = false;
  bool _autoReconnect = true;
  String? _error;
  String? _successMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('gateway_url') ?? '';
      _tokenController.text = prefs.getString('gateway_token') ?? '';
      _autoReconnect = prefs.getBool('auto_reconnect') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gateway_url', _urlController.text.trim());
    await prefs.setString('gateway_token', _tokenController.text.trim());
    await prefs.setBool('auto_reconnect', _autoReconnect);
  }
  
  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
      _successMessage = null;
    });
    
    try {
      await _saveSettings();
      final url = _urlController.text.trim();
      final token = _tokenController.text.trim().isEmpty 
          ? null 
          : _tokenController.text.trim();
      
      await widget.client.connect(url, token: token);
      
      // 启用自动重连
      if (_autoReconnect) {
        widget.reconnectionManager.enable(url, token: token);
      }
      
      setState(() {
        _successMessage = '连接成功！';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isConnecting = false);
    }
  }
  
  Future<void> _disconnect() async {
    widget.reconnectionManager.disable();
    await widget.client.disconnect();
    setState(() {
      _successMessage = '已断开连接';
    });
  }
  
  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有聊天记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_messages');
      await widget.sessionManager.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('聊天记录已清空')),
        );
        Navigator.pop(context, true);
      }
    }
  }
  
  Future<void> _syncSessions() async {
    try {
      widget.client.getSessions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在同步会话...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步失败: $e')),
      );
    }
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gateway 配置
          _buildGatewayCard(),
          
          const SizedBox(height: 16),
          
          // 连接设置
          _buildConnectionSettingsCard(),
          
          const SizedBox(height: 16),
          
          // 数据管理
          _buildDataManagementCard(),
          
          const SizedBox(height: 16),
          
          // 关于
          _buildAboutCard(),
        ],
      ),
    );
  }
  
  Widget _buildGatewayCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hub,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gateway 配置',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '配置 OpenClaw Gateway 连接信息',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Gateway URL',
                hintText: '例如: 192.168.1.100:18789',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Token (可选)',
                hintText: '认证令牌',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnecting ? null : _connect,
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.connect_without_contact),
                    label: Text(_isConnecting ? '连接中...' : '连接'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('断开'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionSettingsCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.autorenew,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('自动重连'),
            subtitle: const Text('断开连接后自动尝试重连'),
            value: _autoReconnect,
            onChanged: (value) {
              setState(() => _autoReconnect = value);
              _saveSettings();
              if (value) {
                widget.reconnectionManager.enable(
                  _urlController.text.trim(),
                  token: _tokenController.text.trim().isEmpty
                      ? null
                      : _tokenController.text.trim(),
                );
              } else {
                widget.reconnectionManager.disable();
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.sync,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('同步会话'),
            subtitle: const Text('从 Gateway 获取会话列表'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _syncSessions,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataManagementCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Colors.red.shade400,
            ),
            title: const Text('清空聊天记录'),
            subtitle: const Text('删除所有本地消息，不可恢复'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearHistory,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAboutCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于 PawChat'),
            subtitle: Text('版本 ${AppVersion.fullVersion}\n基于 OpenClaw Gateway'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('开源协议'),
            subtitle: const Text('MIT License'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              // TODO: 打开 GitHub 仓库
            },
          ),
        ],
      ),
    );
  }
}
