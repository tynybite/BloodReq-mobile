import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/config/language_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      setState(() => _emailSent = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to send reset email'),
          backgroundColor: AppColors.error,
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => context.go('/login'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: PopupMenuButton<Locale>(
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tooltip: 'Select Language',
                initialValue: lang.currentLocale,
                onSelected: (locale) => lang.changeLanguage(locale),
                itemBuilder: (context) => LanguageConfig.options.map((option) {
                  return PopupMenuItem(
                    value: Locale(option.code),
                    child: Row(
                      children: [
                        Text(option.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(option.name),
                      ],
                    ),
                  );
                }).toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${LanguageConfig.getOption(lang.currentLocale.languageCode).flag} ${lang.currentLocale.languageCode.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Organic Blob Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.40,
            child: CustomPaint(painter: _BlobPainter(color: AppColors.primary)),
          ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),

                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        lang.getText('forgot_password'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn().slideX(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _emailSent
                            ? 'Check your inbox'
                            : lang.getText('reset_your_password'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ),
                  ),

                  SizedBox(height: size.height * 0.15),

                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: context.isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _emailSent
                        ? _buildSuccessView(lang)
                        : _buildFormView(lang),
                  ).animate().slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(LanguageProvider lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Email Sent',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset link to\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: const Text('Didn\'t receive the email? Try again'),
        ),
      ],
    );
  }

  Widget _buildFormView(LanguageProvider lang) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            lang.getText('enter_email'),
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: InputDecoration(
              labelText: lang.getText('email'),
              prefixIcon: const Icon(Icons.email_outlined),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return lang.getText('enter_email');
              }
              if (!value.contains('@')) {
                return lang.getText('valid_email');
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      lang.getText('send_reset_link'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;

  _BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    // Start top-left
    path.lineTo(0, size.height * 0.75);

    // Smooth bezier curve for organic blob feel
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.6,
      size.height * 0.85,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.75,
      size.width,
      size.height * 0.9,
    );

    // End top-right
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
