import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/language_provider.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          lang.getText('terms_service'),
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
              lang.getText('tos_last_updated'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            _SectionTitle(lang.getText('tos_acceptance_title')),
            _SectionBody(lang.getText('tos_acceptance_body')),

            _SectionTitle(lang.getText('tos_eligibility_title')),
            _SectionBody(lang.getText('tos_eligibility_body')),

            _SectionTitle(lang.getText('tos_account_title')),
            _SectionBody(lang.getText('tos_account_body')),

            _SectionTitle(lang.getText('tos_services_title')),
            _SectionBody(lang.getText('tos_services_body')),

            _SectionTitle(lang.getText('tos_user_conduct_title')),
            _SectionBody(lang.getText('tos_user_conduct_body')),

            _SectionTitle(lang.getText('tos_disclaimer_title')),
            _SectionBody(lang.getText('tos_disclaimer_body')),

            _SectionTitle(lang.getText('tos_liability_title')),
            _SectionBody(lang.getText('tos_liability_body')),

            _SectionTitle(lang.getText('tos_termination_title')),
            _SectionBody(lang.getText('tos_termination_body')),

            _SectionTitle(lang.getText('tos_changes_title')),
            _SectionBody(lang.getText('tos_changes_body')),

            _SectionTitle(lang.getText('tos_contact_title')),
            _SectionBody(lang.getText('tos_contact_body')),

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
