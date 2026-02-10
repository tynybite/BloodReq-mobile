import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/config/language_config.dart';
import '../../../core/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isPushEnabled = _notificationService.isPushEnabled;
    setState(() {
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
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LanguageBottomSheet(),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => const _PremiumAboutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context);

    // Account info removed as requested

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildPremiumAppBar(isDark, lang),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(
                  title: lang.getText('preferences'),
                  isDark: isDark,
                ),
                _buildPreferencesSection(isDark, lang),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: lang.getText('support_section'),
                  isDark: isDark,
                ),
                _buildSupportSection(isDark, lang),
                const SizedBox(height: 48),
                _buildVersionInfo(isDark, lang),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAppBar(bool isDark, LanguageProvider lang) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : AppColors.primary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF2E2E4A),
                      const Color(0xFF16213E),
                    ]
                  : [
                      AppColors.primary,
                      const Color(0xFFE53935),
                      const Color(0xFFC62828),
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                        lang.getText('settings_title'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 4),
                  Text(
                    lang.getText('settings_subtitle'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(bool isDark, LanguageProvider lang) {
    final currentLangName = LanguageConfig.getOption(
      lang.currentLocale.languageCode,
    ).name;

    return Column(
      children: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return _PremiumSettingsTile(
              icon: Icons.dark_mode_rounded,
              title: lang.getText('dark_mode'),
              subtitle: lang.getText('dark_mode_desc'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeThumbColor: AppColors.primary,
              ),
              isDark: isDark,
              delay: 300,
            );
          },
        ),
        const SizedBox(height: 12),
        _PremiumSettingsTile(
          icon: Icons.language_rounded,
          title: lang.getText('language'),
          subtitle: currentLangName,
          onTap: _showLanguagePicker,
          isDark: isDark,
          delay: 400,
        ),
        const SizedBox(height: 12),
        _PremiumSettingsTile(
          icon: Icons.notifications_active_rounded,
          title: lang.getText('push_notifications'),
          subtitle: lang.getText('push_notifications_desc'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeThumbColor: AppColors.primary,
          ),
          isDark: isDark,
          delay: 500,
        ),
      ],
    );
  }

  Widget _buildSupportSection(bool isDark, LanguageProvider lang) {
    return Column(
      children: [
        _PremiumSettingsTile(
          icon: Icons.info_rounded,
          title: lang.getText('about_app'),
          onTap: _showAboutDialog,
          isDark: isDark,
          delay: 600,
        ),
        const SizedBox(height: 12),
        _PremiumSettingsTile(
          icon: Icons.description_rounded,
          title: lang.getText('terms_service'),
          onTap: () => context.push('/terms-of-service'),
          isDark: isDark,
          delay: 700,
        ),
        const SizedBox(height: 12),
        _PremiumSettingsTile(
          icon: Icons.privacy_tip_rounded,
          title: lang.getText('privacy_policy'),
          onTap: () => context.push('/privacy-policy'),
          isDark: isDark,
          delay: 800,
        ),
      ],
    );
  }

  Widget _buildVersionInfo(bool isDark, LanguageProvider lang) {
    return Center(
      child: Column(
        children: [
          Icon(
                Icons.bloodtype_rounded,
                size: 32,
                color: AppColors.primary.withValues(alpha: 0.5),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 8),
          Text(
            '${lang.getText('app_name')} v${AppConstants.appVersion}',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lang.getText('made_with_love'),
            style: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).animate(delay: 900.ms).fadeIn();
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.05, end: 0);
  }
}

class _PremiumSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;
  final int delay;

  const _PremiumSettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDark,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? Colors.white70 : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _LanguageBottomSheet extends StatelessWidget {
  const _LanguageBottomSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = context.watch<LanguageProvider>();
    final currentCode = languageProvider.currentLocale.languageCode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.getText('select_language'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...LanguageConfig.options.map((option) {
              return Column(
                children: [
                  _LanguageItem(
                    label: option.name,
                    flag: option.flag,
                    isSelected: currentCode == option.code,
                    onTap: () {
                      languageProvider.changeLanguage(Locale(option.code));
                      Navigator.pop(context);
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _LanguageItem({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? AppColors.primary : context.textPrimary,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _PremiumAboutDialog extends StatelessWidget {
  const _PremiumAboutDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bloodtype_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              lang.getText('app_name'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            Text(
              '${lang.getText('version')} ${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lang.getText('about_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.textPrimary.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  lang.getText('close'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
