import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  bool _notificationsEnabled = false;

  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadNotifications();
    _setupStreamListener();
  }

  void _setupStreamListener() {
    _notificationSubscription = _notificationService.notificationStream.listen((
      _,
    ) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.get<dynamic>('/notifications');

    if (response.success && response.data != null) {
      List<dynamic> notifList;

      if (response.data is List) {
        notifList = response.data as List;
      } else if (response.data is Map) {
        final mapData = response.data as Map<String, dynamic>;
        notifList = (mapData['data'] ?? mapData['notifications'] ?? []) as List;
      } else {
        notifList = [];
      }

      setState(() {
        _notifications = notifList
            .map((e) => e as Map<String, dynamic>)
            .toList();
      });
    } else {
      // If API fails, show empty state (API might not exist yet)
      setState(() => _notifications = []);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermission();
    setState(() => _notificationsEnabled = granted);
  }

  Future<void> _markAllRead() async {
    setState(() => _isLoading = true);

    final response = await _api.put('/notifications', body: {});

    if (response.success) {
      // Optimistically update local state
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'is_read': true})
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read')),
        );
      }
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'blood_request':
        return Icons.water_drop;
      case 'donation_offer':
        return Icons.volunteer_activism;
      case 'donation_accepted':
        return Icons.check_circle;
      case 'fundraiser':
        return Icons.favorite;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'blood_request':
        return AppColors.primary;
      case 'donation_offer':
        return AppColors.success;
      case 'donation_accepted':
        return AppColors.info;
      case 'fundraiser':
        return AppColors.accent;
      case 'system':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Show permission request if not enabled
    if (!_notificationsEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enable Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Get notified about blood requests in your area and donation updates.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Enable Notifications'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll be notified about blood requests\nand donation updates here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        return _NotificationCard(
              title: notif['title'] ?? 'Notification',
              body: notif['body'] ?? notif['message'] ?? '',
              type: notif['type'],
              createdAt: notif['created_at'],
              isRead: notif['is_read'] ?? false,
              isActionable: notif['is_actionable'] ?? false,
              payload: notif['payload'],
              icon: _getNotificationIcon(notif['type']),
              color: _getNotificationColor(notif['type']),
              onTap: () {
                // Handle navigation based on notification data
              },
            )
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String? type;
  final String? createdAt;
  final bool isRead;
  final bool isActionable;
  final Map<String, dynamic>? payload;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
    this.type,
    this.createdAt,
    required this.isRead,
    this.isActionable = false,
    this.payload,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? context.cardBg : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: isRead
              ? null
              : Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: isActionable ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            if (isActionable) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Dismiss/Mark read
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('View Now'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
