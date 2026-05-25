import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _api = ApiClient();
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final convs = await _api.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = convs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (now.difference(dt).inDays == 0) {
        return DateFormat('HH:mm').format(dt);
      }
      if (now.difference(dt).inDays < 7) {
        return DateFormat('EEE').format(dt);
      }
      return DateFormat('dd.MM').format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> _showNewChatDialog() async {
    List<dynamic> contacts = [];
    bool loading = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (loading) {
            _api.getChatContacts().then((c) {
              setDialogState(() {
                contacts = c;
                loading = false;
              });
            }).catchError((_) {
              setDialogState(() => loading = false);
            });
          }
          return AlertDialog(
            title: const Text('Yangi suhbat'),
            content: SizedBox(
              width: double.maxFinite,
              child: loading
                  ? const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : contacts.isEmpty
                      ? const Text(
                          "Hozircha suhbat boshlash mumkin bo'lgan kontakt yo'q.\n\nOta-ona uchun: avval bolani guruhga biriktiring.\nPedagog uchun: guruh yarating va bolalar biriktirilishini kuting.",
                          style: TextStyle(color: Colors.grey),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = contacts[i];
                            final name = c['full_name'] as String;
                            final role = c['role'] as String;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primaryColor.withValues(alpha: 0.2),
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(name),
                              subtitle: Text(
                                role == 'teacher' ? 'Pedagog' : 'Ota-ona',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatRoomScreen(
                                      otherUserId: c['id'] as String,
                                      otherUserName: name,
                                    ),
                                  ),
                                ).then((_) => _loadConversations());
                              },
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Suhbatlar')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: AppTheme.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          "Hali suhbatlar yo'q",
                          style: TextStyle(
                              fontSize: 18, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = _conversations[i];
                      final unread = c['unread_count'] ?? 0;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.2),
                          child: Text(
                            (c['full_name'] as String).isNotEmpty
                                ? (c['full_name'] as String)[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        title: Text(
                          c['full_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          c['last_message'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatTime(c['last_message_at'] ?? ''),
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            if (unread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              otherUserId: c['user_id'],
                              otherUserName: c['full_name'],
                            ),
                          ),
                        ).then((_) => _loadConversations()),
                      );
                    },
                  ),
      ),
    );
  }
}
