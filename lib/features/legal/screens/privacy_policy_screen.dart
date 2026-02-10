import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/language_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          lang.getText('privacy_policy'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText('pp_last_updated'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            _SectionTitle(lang.getText('pp_intro_title')),
            _SectionBody(lang.getText('pp_intro_body')),

            _SectionTitle(lang.getText('pp_info_collect_title')),
            _SectionBody(lang.getText('pp_info_collect_body')),

            _SectionTitle(lang.getText('pp_info_use_title')),
            _SectionBody(lang.getText('pp_info_use_body')),

            _SectionTitle(lang.getText('pp_info_share_title')),
            _SectionBody(lang.getText('pp_info_share_body')),

            _SectionTitle(lang.getText('pp_data_security_title')),
            _SectionBody(lang.getText('pp_data_security_body')),

            _SectionTitle(lang.getText('pp_data_retention_title')),
            _SectionBody(lang.getText('pp_data_retention_body')),

            _SectionTitle(lang.getText('pp_your_rights_title')),
            _SectionBody(lang.getText('pp_your_rights_body')),

            _SectionTitle(lang.getText('pp_children_title')),
            _SectionBody(lang.getText('pp_children_body')),

            _SectionTitle(lang.getText('pp_changes_title')),
            _SectionBody(lang.getText('pp_changes_body')),

            _SectionTitle(lang.getText('pp_contact_title')),
            _SectionBody(lang.getText('pp_contact_body')),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary,
      ),
    );
  }
}
