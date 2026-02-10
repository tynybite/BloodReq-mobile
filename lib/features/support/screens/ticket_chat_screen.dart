import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/support_provider.dart';
import '../../../core/providers/language_provider.dart';

class TicketChatScreen extends StatefulWidget {
  final String ticketId;

  const TicketChatScreen({super.key, required this.ticketId});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadTicketDetail(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<SupportProvider>().clearCurrentTicket();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    final success = await context.read<SupportProvider>().sendReply(
      widget.ticketId,
      text,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (success) _scrollToBottom();
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Today';
    if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final lang = context.read<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Consumer<SupportProvider>(
          builder: (context, provider, _) {
            final ticket = provider.currentTicket;
            if (ticket == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _statusLabel(ticket.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusColor(ticket.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<SupportProvider>(
            builder: (context, provider, _) {
              if (provider.currentTicket == null)
                return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.refresh_rounded, color: context.textSecondary),
                onPressed: () =>
                    provider.loadTicketDetail(widget.ticketId).then((_) {
                      _scrollToBottom();
                    }),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.borderColor),
        ),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentTicket == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.currentTicket == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: context.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    style: TextStyle(color: context.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => provider.loadTicketDetail(widget.ticketId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final ticket = provider.currentTicket;
          if (ticket == null) return const SizedBox.shrink();

          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );

          return Column(
            children: [
              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: ticket.messages.length,
                  itemBuilder: (context, index) {
                    final msg = ticket.messages[index];
                    final isMe = !msg.isAdmin;

                    // Date header
                    Widget? dateHeader;
                    if (index == 0 ||
                        _formatDateHeader(msg.createdAt) !=
                            _formatDateHeader(
                              ticket.messages[index - 1].createdAt,
                            )) {
                      dateHeader = Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              _formatDateHeader(msg.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (dateHeader != null) dateHeader,
                        Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primary
                                      : isDark
                                      ? AppColors.surfaceVariantDark
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.support_agent_rounded,
                                              size: 12,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Support Team',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Text(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isMe
                                            ? Colors.white
                                            : context.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(msg.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                            : context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .slideX(
                              begin: isMe ? 0.1 : -0.1,
                              end: 0,
                              duration: 200.ms,
                            ),
                      ],
                    );
                  },
                ),
              ),

              // Input Bar
              if (ticket.status != 'resolved')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    border: Border(top: BorderSide(color: context.borderColor)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendReply(),
                            decoration: InputDecoration(
                              hintText: lang.getText('support_type_message'),
                              hintStyle: TextStyle(
                                color: context.textSecondary,
                              ),
                              filled: true,
                              fillColor: context.surfaceVariantBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _sending
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                            onPressed: _sendReply,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Resolved Banner
              if (ticket.status == 'resolved')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.getText('support_ticket_resolved'),
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }
}
