import 'package:flutter/material.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sessions/sessions_screen.dart';

/// 应用路由配置
class AppRoutes {
  static const String chat = '/';
  static const String settings = '/settings';
  static const String sessions = '/sessions';
  
  static Map<String, WidgetBuilder> get routes => {
    chat: (_) => const ChatScreen(),
    settings: (_) => const SettingsScreen(),
    sessions: (_) => const SessionsScreen(),
  };
}

/// 占位页面
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({super.key, required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              '$title 开发中...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '功能即将上线',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
