import 'package:flutter/material.dart';

/// BuildContext 扩展
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get media => MediaQuery.of(this);
  double get width => media.size.width;
  double get height => media.size.height;
  
  /// 显示 SnackBar
  void showSnackBar(String message, {Duration? duration, Color? color}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }
  
  /// 显示错误 SnackBar
  void showError(String message) {
    showSnackBar(message, color: colorScheme.error);
  }
  
  /// 显示成功 SnackBar
  void showSuccess(String message) {
    showSnackBar(message, color: Colors.green);
  }
  
  /// 导航到新页面
  Future<T?> push<T>(Widget page) {
    return Navigator.push<T>(
      this,
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// 替换当前页面
  void pushReplacement(Widget page) {
    Navigator.pushReplacement(
      this,
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// 返回
  void pop<T>([T? result]) {
    Navigator.pop<T>(this, result);
  }
  
  /// 显示对话框
  Future<T?> showAlertDialog<T>({
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: this,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions ?? [
          TextButton(
            onPressed: () => pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 显示确认对话框
  Future<bool?> showConfirmDialog({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: this,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 显示加载对话框
  void showLoading({String message = '加载中...'}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
  
  /// 隐藏对话框
  void hideDialog() {
    Navigator.pop(this);
  }
}

/// DateTime 扩展
extension DateTimeX on DateTime {
  /// 格式化为相对时间
  String toRelativeTime() {
    final now = DateTime.now();
    final diff = now.difference(this);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return toFormattedDate();
    }
  }
  
  /// 格式化为日期时间
  String toFormattedDate() {
    final year = this.year;
    final month = this.month.toString().padLeft(2, '0');
    final day = this.day.toString().padLeft(2, '0');
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    
    return '$year-$month-$day $hour:$minute';
  }
  
  /// 格式化为时间
  String toFormattedTime() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// 是否是今天
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// 是否是昨天
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}

/// String 扩展
extension StringX on String {
  /// 检查是否为空或空白
  bool get isNullOrEmpty => trim().isEmpty;
  
  /// 检查是否不为空
  bool get isNotNullOrEmpty => trim().isNotEmpty;
  
  /// 首字母大写
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  /// 截断文本
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength - suffix.length) + suffix;
  }
}

/// List 扩展
extension ListX<T> on List<T> {
  /// 安全获取最后一个元素
  T? get lastOrNull => isEmpty ? null : last;
  
  /// 安全获取第一个元素
  T? get firstOrNull => isEmpty ? null : first;
}
