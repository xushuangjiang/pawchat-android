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
    });
    
    try {
      await _saveSettings();
      await widget.client.connect(
        _urlController.text.trim(),
        token: _tokenController.text.trim().isEmpty 
            ? null 
            : _tokenController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isConnecting = false);
    }
  }
  
  Future<void> _disconnect() async {
    await widget.client.disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开连接')),
      );
    }
  }
  
  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有聊天记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_messages');
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
                  Text(
                    'Gateway 配置',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Gateway URL',
                      hintText: '例如: 192.168.1.100:18789',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Token (可选)',
                      hintText: '认证令牌',
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
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
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.connect_without_contact),
                          label: Text(_isConnecting ? '连接中...' : '连接'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _disconnect,
                        icon: const Icon(Icons.disconnect),
                        label: const Text('断开'),
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
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('清空聊天记录'),
                  subtitle: const Text('删除所有本地消息'),
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
                  leading: const Icon(Icons.info),
                  title: const Text('关于'),
                  subtitle: const Text('PawChat v1.0.0\n基于 OpenClaw Gateway'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
