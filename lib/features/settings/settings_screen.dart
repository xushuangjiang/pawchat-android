import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _tokenController;
  bool _useSecure = false;
  bool _autoConnect = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController = TextEditingController(
        text: prefs.getString('gateway_url') ?? '192.168.1.100',
      );
      _tokenController = TextEditingController(
        text: prefs.getString('gateway_token') ?? '',
      );
      _useSecure = prefs.getBool('gateway_secure') ?? false;
      _autoConnect = prefs.getBool('auto_connect') ?? false;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gateway_url', _urlController.text.trim());
    await prefs.setString('gateway_token', _tokenController.text.trim());
    await prefs.setBool('gateway_secure', _useSecure);
    await prefs.setBool('auto_connect', _autoConnect);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          duration: Duration(seconds: 2),
        ),
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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gateway 配置卡片
          _buildSectionCard(
            context,
            title: 'Gateway 配置',
            icon: Icons.cloud,
            children: [
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  hintText: '192.168.1.100 或 your-device.ts.net',
                  prefixIcon: Icon(Icons.dns),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('使用加密连接 (WSS)'),
                subtitle: const Text('推荐用于远程连接'),
                value: _useSecure,
                onChanged: (value) {
                  setState(() => _useSecure = value);
                },
              ),
              const Divider(),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: '认证 Token',
                  hintText: '可选，留空使用密码认证',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                obscureText: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 连接选项卡片
          _buildSectionCard(
            context,
            title: '连接选项',
            icon: Icons.settings_ethernet,
            children: [
              SwitchListTile(
                title: const Text('自动连接'),
                subtitle: const Text('启动应用时自动连接 Gateway'),
                value: _autoConnect,
                onChanged: (value) {
                  setState(() => _autoConnect = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 关于卡片
          _buildSectionCard(
            context,
            title: '关于',
            icon: Icons.info_outline,
            children: [
              ListTile(
                title: const Text('PawChat'),
                subtitle: const Text('版本 1.0.0'),
                trailing: const Text('🐾', style: TextStyle(fontSize: 24)),
              ),
              const Divider(),
              ListTile(
                title: const Text('OpenClaw 文档'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  // TODO: 打开文档链接
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('打开文档功能开发中...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 保存按钮
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('保存设置'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          // 测试连接按钮
          OutlinedButton.icon(
            onPressed: () {
              _testConnection();
            },
            icon: const Icon(Icons.cloud_sync),
            label: const Text('测试连接'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  void _testConnection() {
    // TODO: 实现连接测试逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('连接测试功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
