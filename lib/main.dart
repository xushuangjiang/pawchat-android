import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/di/service_locator.dart';
import 'features/chat/presentation/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 启用 Flutter 调试日志
  debugPrint('🚀 PawChat 启动中...');
  
  try {
    // 初始化依赖注入
    await setupDependencies();
    debugPrint('✅ 依赖注入初始化完成');
  } catch (e, stackTrace) {
    debugPrint('❌ 依赖注入初始化失败: $e');
    debugPrint(stackTrace.toString());
  }
  
  // 设置系统状态栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const PawChatApp());
}

class PawChatApp extends StatelessWidget {
  const PawChatApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawChat',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // Indigo
      brightness: Brightness.light,
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
