import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/gateway_client.dart';

class SettingsScreen extends StatefulWidget {
  final GatewayClient client;
  
  const SettingsScreen({super.key, required this.client});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isConnecting = false;
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
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gateway_url', _urlController.text.trim());
    await prefs.setString('gateway_token', _tokenController.text.trim());
  }
  
  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
      _successMessage = null;
    });
    
    try {
      await _saveSettings();
      await widget.client.connect(
        _urlController.text.trim(),
        token: _tokenController.text.trim().isEmpty 
            ? null 
            : _tokenController.text.trim(),
      );
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
      await prefs.remove('current_session');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('聊天记录已清空')),
        );
        Navigator.pop(context, true);
      }
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
          Card(
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
          ),
          
          const SizedBox(height: 16),
          
          // 数据管理
          Card(
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
          ),
          
          const SizedBox(height: 16),
          
          // 关于
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于 PawChat'),
                  subtitle: const Text('版本 v0.1.1\n基于 OpenClaw Gateway'),
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
          ),
        ],
      ),
    );
  }
}
