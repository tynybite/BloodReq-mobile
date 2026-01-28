import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/verification_service.dart';

class VerificationScreen extends StatefulWidget {
  final String requestId;
  final bool
  isRequestor; // if true, show Generate Code. if false, show Enter Code.

  const VerificationScreen({
    super.key,
    required this.requestId,
    required this.isRequestor,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final VerificationService _service = VerificationService();
  String? _generatedCode;
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRequestor) {
      _generateCode();
    }
  }

  void _generateCode() {
    setState(() {
      _generatedCode = _service.generateCode(widget.requestId);
    });
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) throw Exception('User not found');

      final result = await _service.verifyCode(
        requestId: widget.requestId,
        donorId: user.id,
        code: code,
      );

      setState(() {
        _isSuccess = true;
        _resultMessage = result['message'] as String?;
        if (result['offline'] == true) {
          _resultMessage = "Saved Offline. Will sync when online.";
        }
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _resultMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(widget.isRequestor ? 'Verify Donor' : 'Verify Donation'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isRequestor)
                _buildRequestorView()
              else
                _buildDonorView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestorView() {
    return Column(
      children: [
        const Icon(Icons.qr_code_2, size: 100, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'Show this code to the Donor',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _generatedCode ?? '...',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppColors.textPrimary,
            ),
          ),
        ).animate().scale(delay: 200.ms),
        const SizedBox(height: 24),
        Text(
          'This confirms the donation was completed.',
          style: TextStyle(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDonorView() {
    if (_isSuccess) {
      return Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ).animate().scale(),
          const SizedBox(height: 24),
          Text(
            'Verified!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _resultMessage ?? 'Points awarded!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Enter Verification Code',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ask the Requestor for the 6-digit code',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        if (_resultMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _resultMessage!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitCode,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify Donation'),
          ),
        ),
      ],
    );
  }
}
