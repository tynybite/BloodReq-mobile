import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/support_provider.dart';
import '../../../core/providers/language_provider.dart';

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({super.key});

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadTickets();
    });
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.error_outline_rounded;
      case 'in_progress':
        return Icons.schedule_rounded;
      case 'resolved':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final lang = context.read<LanguageProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          lang.getText('support_title'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(lang.getText('support_new_ticket')),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.tickets.isEmpty) {
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
                    onPressed: () => provider.loadTickets(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.headset_mic_rounded,
                    size: 64,
                    color: context.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.getText('support_empty_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.getText('support_empty_subtitle'),
                    style: TextStyle(color: context.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadTickets(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ticket = provider.tickets[index];
                final statusColor = _statusColor(ticket.status);

                return GestureDetector(
                  onTap: () => context.push('/support/chat/${ticket.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: context.borderColor),
                      boxShadow: context.cardShadow,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Icon(
                                _statusIcon(ticket.status),
                                size: 18,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ticket.subject,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: context.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimeAgo(ticket.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _Chip(
                              label: _statusLabel(ticket.status),
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            _Chip(
                              label: ticket.category,
                              color: context.textSecondary,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.message_rounded,
                              size: 14,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${ticket.messageCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (ticket.lastMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${ticket.lastMessage!.isAdmin ? "Admin: " : ""}${ticket.lastMessage!.text}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
              },
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
