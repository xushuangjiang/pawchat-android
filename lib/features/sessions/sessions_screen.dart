import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import '../../core/session_model.dart';

class SessionsScreen extends StatefulWidget {
  final SessionManager sessionManager;
  
  const SessionsScreen({super.key, required this.sessionManager});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessionManager.sessions;
    final currentKey = widget.sessionManager.currentSessionKey;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewSession,
            tooltip: '新建会话',
          ),
        ],
      ),
      body: sessions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isCurrent = session.key == currentKey;
                
                return Dismissible(
                  key: Key(session.key),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteSession(session),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      child: Icon(
                        Icons.chat_bubble,
                        color: isCurrent ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      session.displayTitle,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${session.messageCount} 条消息 · ${session.formattedTime}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => _switchSession(session),
                    onLongPress: () => _showSessionOptions(session),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有会话',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createNewSession,
            icon: const Icon(Icons.add),
            label: const Text('新建会话'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewSession() async {
    final titleController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建会话'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '会话名称（可选）',
            hintText: '输入会话名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      await widget.sessionManager.createSession(
        title: result.isEmpty ? null : result,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _switchSession(Session session) async {
    await widget.sessionManager.switchSession(session.key);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteSession(Session session) async {
    await widget.sessionManager.deleteSession(session.key);
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 ${session.displayTitle}'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () {
              // 撤销删除
            },
          ),
        ),
      );
    }
  }

  void _showSessionOptions(Session session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(context);
                _renameSession(session);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade400),
              title: Text('删除', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameSession(Session session) async {
    final controller = TextEditingController(text: session.title);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '会话名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      await widget.sessionManager.updateSession(
        session.copyWith(title: result.isEmpty ? null : result),
      );
      setState(() {});
    }
  }

  Future<void> _confirmDelete(Session session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定要删除 "${session.displayTitle}" 吗？'),
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
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _deleteSession(session);
    }
  }
}
