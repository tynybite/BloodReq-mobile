import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language_code');
    final isPushEnabled = _notificationService.isPushEnabled;

    setState(() {
      _selectedLanguage = savedLang == 'bn' ? 'Bangla' : 'English';
      _notificationsEnabled = isPushEnabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await _notificationService.enablePush();
    } else {
      await _notificationService.disablePush();
    }

    // Double check status after toggle
    // await Future.delayed(const Duration(milliseconds: 500));
    // final status = _notificationService.isPushEnabled;
    // if (mounted && status != _notificationsEnabled) {
    //   setState(() => _notificationsEnabled = status);
    // }
  }

  Future<void> _setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);

    setState(() {
      _selectedLanguage = langCode == 'bn' ? 'Bangla' : 'English';
    });

    // In a real app, you would also update the Locale here via a provider
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                _setLanguage('en');
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Bangla'),
              value: 'Bangla',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                _setLanguage('bn');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'BloodReq',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.bloodtype, color: Colors.red, size: 48),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'BloodReq is a platform connecting blood donors with patients in need. '
            'Together we save lives.',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Setting
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _SettingsTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeTrackColor: AppColors.primary,
                ),
              );
            },
          ),

          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _selectedLanguage,
            onTap: _showLanguagePicker,
          ),

          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeTrackColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'About',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About BloodReq',
            onTap: _showAboutDialog,
          ),

          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _openUrl('https://bloodreq.com/terms'),
          ),

          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _openUrl('https://bloodreq.com/privacy'),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'BloodReq v1.0.0',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
