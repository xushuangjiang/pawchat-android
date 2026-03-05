import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/websocket/gateway_client.dart';
import '../../core/websocket/protocol.dart';
import '../chat/bloc/chat_bloc.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});
  
  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<SessionInfo> _sessions = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }
  
  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // TODO: 实现获取会话列表的 API
      // 目前使用模拟数据
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _sessions = [
          SessionInfo(
            sessionKey: 'default',
            title: '默认会话',
            lastActive: DateTime.now(),
            messageCount: 42,
          ),
          SessionInfo(
            sessionKey: 'work-001',
            title: '工作相关',
            lastActive: DateTime.now().subtract(const Duration(hours: 2)),
            messageCount: 15,
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '加载失败：$e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _sessions.isEmpty
                  ? _buildEmptyState()
                  : _buildSessionList(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewSession,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? '未知错误',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '暂无会话',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮创建新会话',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: const Icon(Icons.chat, color: Colors.white),
            ),
            title: Text(session.title ?? session.sessionKey),
            subtitle: Text(
              '${session.messageCount} 条消息 · ${session.lastActive.toRelativeTime()}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _renameSession(session),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteSession(session),
                  color: theme.colorScheme.error,
                ),
              ],
            ),
            onTap: () => _selectSession(session),
          ),
        );
      },
    );
  }
  
  void _createNewSession() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建会话'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '会话名称',
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: 创建新会话
              _loadSessions();
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
  
  void _renameSession(SessionInfo session) {
    final controller = TextEditingController(text: session.title);
    
    showDialog(
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: 重命名会话
              _loadSessions();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _deleteSession(SessionInfo session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定要删除"${session.title}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 删除会话
              _loadSessions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  void _selectSession(SessionInfo session) {
    // 切换到选中的会话
    final chatBloc = context.read<ChatBloc>();
    chatBloc.setSessionKey(session.sessionKey);
    
    Navigator.pop(context);
    
    // 重新加载历史消息
    chatBloc.add(ChatLoadHistory());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换到"${session.title}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
