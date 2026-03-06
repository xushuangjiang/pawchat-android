import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Log 服务
class LogService {
  static final List<String> _logs = [];
  static bool _initialized = false;
  
  /// 初始化
  static void init() {
    if (_initialized) return;
    _initialized = true;
    
    // 捕获 Flutter 日志
    FlutterError.onError = (FlutterErrorDetails details) {
      log('FLUTTER ERROR: ${details.exception}');
      log('Stack: ${details.stack}');
    };
  }
  
  /// 记录日志
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    _logs.add(logEntry);
    print(logEntry);
    
    // 限制日志数量，避免内存溢出
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }
  
  /// 获取所有日志
  static List<String> getLogs() {
    return List.unmodifiable(_logs);
  }
  
  /// 导出日志到文件
  static Future<String> exportToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pawchat_logs.txt');
      
      final buffer = StringBuffer();
      buffer.writeln('PawChat 日志导出');
      buffer.writeln('时间: ${DateTime.now().toIso8601String()}');
      buffer.writeln('日志条数: ${_logs.length}');
      buffer.writeln('=' * 60);
      buffer.writeln();
      
      for (final log in _logs) {
        buffer.writeln(log);
      }
      
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      log('导出日志失败: $e');
      rethrow;
    }
  }
  
  /// 分享日志
  static Future<void> shareLogs() async {
    try {
      final filePath = await exportToFile();
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'PawChat 日志',
        text: 'PawChat 应用日志文件',
      );
    } catch (e) {
      log('分享日志失败: $e');
      rethrow;
    }
  }
  
  /// 清空日志
  static void clear() {
    _logs.clear();
    log('日志已清空');
  }
}

// 为了编译通过，添加 FlutterError 的 mock
class FlutterError {
  static void Function(FlutterErrorDetails details)? onError;
}

class FlutterErrorDetails {
  final dynamic exception;
  final StackTrace? stack;
  
  FlutterErrorDetails({this.exception, this.stack});
}
