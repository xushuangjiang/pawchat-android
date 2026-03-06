import 'package:flutter/material.dart';
import '../../core/message_model.dart';
import '../../core/message_store.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Message> _allMessages = [];
  List<Message> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _focusNode.requestFocus();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    _allMessages = await MessageStore.loadMessages();
    setState(() => _isLoading = false);
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _results = _allMessages
          .where((msg) => msg.content.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索消息...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState('输入关键词搜索消息');
    }

    if (_results.isEmpty) {
      return _buildEmptyState('未找到包含 "${_searchController.text}" 的消息');
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final message = _results[index];
        return _buildMessageTile(message);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Message message) {
    final isUser = message.role == MessageRole.user;
    final query = _searchController.text.toLowerCase();
    final content = message.content;
    
    // 高亮匹配文本
    final spans = <TextSpan>[];
    final lowerContent = content.toLowerCase();
    int start = 0;
    
    while (true) {
      final index = lowerContent.indexOf(query, start);
      if (index == -1) {
        spans.add(TextSpan(text: content.substring(start)));
        break;
      }
      
      if (index > start) {
        spans.add(TextSpan(text: content.substring(start, index)));
      }
      
      spans.add(TextSpan(
        text: content.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isUser
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
        child: Icon(
          isUser ? Icons.person : Icons.smart_toy,
          color: isUser ? Colors.white : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        isUser ? '我' : 'AI',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
              children: spans,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () => _showMessageDetail(message),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);
    
    if (messageDay == today) {
      return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showMessageDetail(Message message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: message.role == MessageRole.user
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      child: Icon(
                        message.role == MessageRole.user
                            ? Icons.person
                            : Icons.smart_toy,
                        color: message.role == MessageRole.user
                            ? Colors.white
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      message.role == MessageRole.user ? '我' : 'AI',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(message.content),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 复制到剪贴板
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('复制'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 分享
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
