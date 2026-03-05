import 'package:flutter/material.dart';
import 'dart:convert';

/// 工具调用显示组件
/// 用于展示 AI 执行工具时的状态和结果
class ToolCallDisplay extends StatelessWidget {
  final String toolName;
  final Map<String, dynamic>? input;
  final String? output;
  final ToolCallStatus status;
  
  const ToolCallDisplay({
    super.key,
    required this.toolName,
    this.input,
    this.output,
    this.status = ToolCallStatus.pending,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 工具名称和状态
            Row(
              children: [
                _buildStatusIcon(theme),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatToolName(toolName),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildStatusLabel(theme),
              ],
            ),
            // 输入参数 (折叠显示)
            if (input != null && input!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildExpandableSection(
                context,
                title: '输入参数',
                content: _formatJson(input!),
                theme: theme,
              ),
            ],
            // 输出结果
            if (output != null && status == ToolCallStatus.completed) ...[
              const SizedBox(height: 8),
              _buildExpandableSection(
                context,
                title: '执行结果',
                content: output!,
                theme: theme,
                isSuccess: true,
              ),
            ],
            // 错误信息
            if (status == ToolCallStatus.failed && output != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  output!,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusIcon(ThemeData theme) {
    IconData icon;
    Color color;
    
    switch (status) {
      case ToolCallStatus.pending:
        icon = Icons.schedule;
        color = theme.colorScheme.secondary;
        break;
      case ToolCallStatus.running:
        icon = Icons.sync;
        color = theme.colorScheme.primary;
        break;
      case ToolCallStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ToolCallStatus.failed:
        icon = Icons.error;
        color = theme.colorScheme.error;
        break;
    }
    
    return Icon(icon, size: 20, color: color);
  }
  
  Widget _buildStatusLabel(ThemeData theme) {
    String label;
    Color color;
    
    switch (status) {
      case ToolCallStatus.pending:
        label = '等待中';
        color = theme.colorScheme.secondary;
        break;
      case ToolCallStatus.running:
        label = '执行中';
        color = theme.colorScheme.primary;
        break;
      case ToolCallStatus.completed:
        label = '完成';
        color = Colors.green;
        break;
      case ToolCallStatus.failed:
        label = '失败';
        color = theme.colorScheme.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildExpandableSection(
    BuildContext context, {
    required String title,
    required String content,
    required ThemeData theme,
    bool isSuccess = false,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSuccess 
                ? theme.colorScheme.secondaryContainer.withOpacity(0.3)
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatToolName(String name) {
    // 将 snake_case 转换为可读格式
    return name.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
  
  String _formatJson(Map<String, dynamic> data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}

enum ToolCallStatus {
  pending,
  running,
  completed,
  failed,
}
