import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String doctorId;
  final String doctorName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('doctor_user_messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': userId,
        'body': text,
      });
      await Supabase.instance.client
          .from('doctor_user_conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', widget.conversationId);
      // Refresh conversations list so last_message_at updates
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final initial = widget.doctorName.trim().isNotEmpty
        ? widget.doctorName.trim()[0].toUpperCase()
        : 'D';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            child: Text(initial,
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.doctorName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const Text('Doctor',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.normal)),
            ],
          ),
        ]),
      ),
      body: Column(
        children: [
          // ── Messages ─────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                _scrollToBottom();
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primary
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppTheme.primary,
                              size: 30),
                        ),
                        const SizedBox(height: 16),
                        const Text('No messages yet',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Say hello! 👋',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == userId;
                    // Show date separator if day changes
                    final showDate = i == 0 ||
                        !_sameDay(messages[i - 1].createdAt,
                            msg.createdAt);

                    return Column(
                      children: [
                        if (showDate) _DateChip(msg.createdAt),
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context)
                                            .size
                                            .width *
                                        0.72),
                                margin: const EdgeInsets.only(
                                    bottom: 2, top: 4),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppTheme.primary
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.only(
                                    topLeft:
                                        const Radius.circular(18),
                                    topRight:
                                        const Radius.circular(18),
                                    bottomLeft:
                                        Radius.circular(isMe ? 18 : 4),
                                    bottomRight:
                                        Radius.circular(isMe ? 4 : 18),
                                  ),
                                  boxShadow: isMe
                                      ? null
                                      : AppTheme.cardShadow,
                                ),
                                child: Text(
                                  msg.body,
                                  style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontSize: 14,
                                      height: 1.4),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: 6,
                                    left: isMe ? 0 : 4,
                                    right: isMe ? 4 : 0),
                                child: Text(
                                  DateFormat('hh:mm a')
                                      .format(msg.createdAt),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border:
                  Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
            ),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                          color: AppTheme.textLight, fontSize: 14),
                      filled: true,
                      fillColor: AppTheme.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _sending
                        ? AppTheme.textLight
                        : AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: _sending
                        ? null
                        : AppTheme.coloredShadow(AppTheme.primary),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _sending ? null : _send,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip(this.date);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.border,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
