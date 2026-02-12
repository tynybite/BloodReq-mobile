import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/utils/avatar_utils.dart';
import '../../../shared/widgets/donor_avatar_ring.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildPremiumAppBar(context, user, isDark, lang),
          _buildQuickStats(context, user, isDark, lang),
          _buildMenuSection(context, isDark, authProvider, lang),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildPremiumAppBar(
    BuildContext context,
    dynamic user,
    bool isDark,
    LanguageProvider lang,
  ) {
    return SliverAppBar(
      expandedHeight: 280, // Taller to fit avatar + info
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : AppColors.primary,
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
                      const Color(0xFFD32F2F),
                      const Color(0xFFC62828),
                      const Color(0xFFB71C1C),
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Avatar
                DonorAvatarRing(
                  isDonor: user?.isAvailableToDonate ?? false,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: AvatarUtils.getImageProvider(
                      user?.avatarUrl,
                    ),
                    child: !AvatarUtils.hasAvatar(user?.avatarUrl)
                        ? Text(
                            user?.initials ?? '?',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ).animate().scale(curve: Curves.elasticOut),
                const SizedBox(height: 16),
                // Name
                Text(
                  user?.fullName ?? lang.getText('guest_user'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 4),
                // Email
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate(delay: 200.ms).fadeIn(),
                if (user?.isAvailableToDonate ?? false) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang.getText('active_donor'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).fadeIn().scale(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    dynamic user,
    bool isDark,
    LanguageProvider lang,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.bloodtype_rounded,
                label: lang.getText('blood_type'),
                value: user?.bloodGroup ?? 'O+',
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.volunteer_activism_rounded,
                label: lang.getText('donations'),
                value: '${user?.totalDonations ?? 0}',
                color: AppColors.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                label: lang.getText('points'),
                value: '${user?.points ?? 0}',
                color: const Color(0xFFFFB300),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
    LanguageProvider lang,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SectionHeader(title: lang.getText('account'), isDark: isDark),
          _PremiumMenuItem(
            icon: Icons.person_outline_rounded,
            title: lang.getText('edit_profile'),
            subtitle: lang.getText('edit_profile_desc'),
            onTap: () => context.push('/edit-profile'),
            isDark: isDark,
            delay: 450,
          ),
          const SizedBox(height: 12),
          _PremiumMenuItem(
            icon: Icons.settings_outlined,
            title: lang.getText('settings_title'),
            subtitle: lang.getText('app_settings_desc'),
            onTap: () => context.push('/settings'),
            isDark: isDark,
            delay: 500,
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: lang.getText('activity'), isDark: isDark),
          _PremiumMenuItem(
            icon: Icons.water_drop_outlined,
            title: lang.getText('my_requests'),
            subtitle: lang.getText('my_requests_desc'),
            onTap: () => context.push('/my-requests'),
            isDark: isDark,
            delay: 550,
          ),
          const SizedBox(height: 12),
          _PremiumMenuItem(
            icon: Icons.volunteer_activism_outlined,
            title: lang.getText('my_donations'),
            subtitle: lang.getText('my_donations_desc'),
            onTap: () => context.push('/my-donations'),
            isDark: isDark,
            delay: 600,
          ),
          const SizedBox(height: 12),
          _PremiumMenuItem(
            icon: Icons.leaderboard_outlined,
            title: lang.getText('leaderboard'),
            subtitle: lang.getText('leaderboard_desc'),
            onTap: () => context.push('/leaderboard'),
            isDark: isDark,
            delay: 650,
          ),
          const SizedBox(height: 12),
          _PremiumMenuItem(
            icon: Icons.notifications_outlined,
            title: lang.getText('notifications'),
            subtitle: lang.getText('notifications_desc'),
            onTap: () => context.push('/notifications'),
            isDark: isDark,
            delay: 700,
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: lang.getText('support'), isDark: isDark),
          _PremiumMenuItem(
            icon: Icons.help_outline_rounded,
            title: lang.getText('help_center'),
            onTap: () => context.push('/support'),
            isDark: isDark,
            delay: 750,
          ),
          const SizedBox(height: 24),
          _LogoutButton(
            title: lang.getText('sign_out'),
            onTap: () async {
              await authProvider.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: 32),
          const SizedBox(height: 60, child: Center(child: BannerAdWidget())),
          const SizedBox(height: 20),
          _buildFooter(isDark, lang),
        ]),
      ),
    );
  }

  Widget _buildFooter(bool isDark, LanguageProvider lang) {
    return Center(
      child: Column(
        children: [
          Text(
            '${lang.getText('app_name')} v${AppConstants.appVersion}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ).animate(delay: 800.ms).fadeIn();
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _PremiumMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final int delay;

  const _PremiumMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
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
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    size: 20,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 18,
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

class _LogoutButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LogoutButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 750.ms).fadeIn().scale();
  }
}
