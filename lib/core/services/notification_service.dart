import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Notification service for handling push notifications via OneSignal
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _api = ApiService();

  // OneSignal App ID - Replace with your actual OneSignal App ID
  // Get this from: https://app.onesignal.com > Settings > Keys & IDs
  static const String _oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';

  bool _initialized = false;
  String? _playerId;

  String? get playerId => _playerId;
  bool get isInitialized => _initialized;

  /// Initialize OneSignal
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set log level for debugging (remove in production)
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // Initialize with App ID
      OneSignal.initialize(_oneSignalAppId);

      // Request permission for notifications
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      // Get player ID (device token)
      _playerId = OneSignal.User.pushSubscription.id;

      debugPrint('🔔 OneSignal initialized. Player ID: $_playerId');
      _initialized = true;
    } catch (e) {
      debugPrint('❌ Failed to initialize OneSignal: $e');
    }
  }

  /// Set up notification handlers
  void _setupNotificationHandlers() {
    // Handle notification clicks
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('🔔 Notification clicked: ${event.notification.body}');
      _handleNotificationClick(event.notification);
    });

    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint(
        '🔔 Notification received in foreground: ${event.notification.body}',
      );
      // You can prevent the notification from displaying by calling:
      // event.preventDefault();
      // Or just let it display normally
      event.notification.display();
    });
  }

  /// Handle notification click actions
  void _handleNotificationClick(OSNotification notification) {
    final data = notification.additionalData;
    if (data == null) return;

    final type = data['type'] as String?;
    final id = data['id'] as String?;

    // Navigate based on notification type
    // This will be handled by the app's navigation
    switch (type) {
      case 'blood_request':
        if (id != null) {
          // Navigate to blood request detail
          debugPrint('Navigate to blood request: $id');
        }
        break;
      case 'donation_offer':
        if (id != null) {
          // Navigate to my donations
          debugPrint('Navigate to donations');
        }
        break;
      case 'fundraiser':
        if (id != null) {
          // Navigate to fundraiser detail
          debugPrint('Navigate to fundraiser: $id');
        }
        break;
    }
  }

  /// Set user's external ID (your app's user ID)
  Future<void> setExternalUserId(String userId) async {
    if (!_initialized) return;

    try {
      OneSignal.login(userId);
      debugPrint('🔔 External user ID set: $userId');
    } catch (e) {
      debugPrint('❌ Failed to set external user ID: $e');
    }
  }

  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    if (!_initialized) return;

    try {
      OneSignal.logout();
      debugPrint('🔔 External user ID removed');
    } catch (e) {
      debugPrint('❌ Failed to remove external user ID: $e');
    }
  }

  /// Register device token with backend
  Future<void> registerDeviceToken(String userId) async {
    if (_playerId == null) return;

    try {
      await _api.post(
        '/profile/device-token',
        body: {
          'player_id': _playerId,
          'platform': 'android', // or 'ios' based on platform
        },
      );
      debugPrint('🔔 Device token registered with backend');
    } catch (e) {
      debugPrint('❌ Failed to register device token: $e');
    }
  }

  /// Set notification tags for targeting
  Future<void> setTags(Map<String, dynamic> tags) async {
    if (!_initialized) return;

    try {
      OneSignal.User.addTags(tags.map((k, v) => MapEntry(k, v.toString())));
      debugPrint('🔔 Tags set: $tags');
    } catch (e) {
      debugPrint('❌ Failed to set tags: $e');
    }
  }

  /// Set blood group tag for targeted notifications
  Future<void> setBloodGroupTag(String bloodGroup) async {
    await setTags({'blood_group': bloodGroup});
  }

  /// Set location tag for targeted notifications
  Future<void> setLocationTag(String city, String country) async {
    await setTags({'city': city, 'country': country});
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return OneSignal.Notifications.permission;
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }
}
