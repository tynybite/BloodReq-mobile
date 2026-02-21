import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

import '../../../core/constants/app_theme.dart';

class DonationReceiptSheet extends StatefulWidget {
  final Map<String, dynamic> donation;

  const DonationReceiptSheet({super.key, required this.donation});

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> donation,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DonationReceiptSheet(donation: donation),
    );
  }

  @override
  State<DonationReceiptSheet> createState() => _DonationReceiptSheetState();
}

class _DonationReceiptSheetState extends State<DonationReceiptSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isGenerating = false;

  Map<String, dynamic> get d => widget.donation;

  String get _currency => (d['currency'] ?? 'BDT') as String;
  String get _sym => _currency == 'USD' ? '\$' : '৳';
  bool get _isBkash => (d['payment_method'] ?? '') == 'bkash';

  String _fmtAmount(dynamic amount) {
    final n = (amount ?? 0).toDouble();
    return '$_sym${n.toStringAsFixed(_currency == 'USD' ? 2 : 0)}';
  }

  String _fmtDate(String? s) {
    if (s == null) return '—';
    try {
      return DateFormat(
        'MMM d, yyyy · hh:mm a',
      ).format(DateTime.parse(s).toLocal());
    } catch (_) {
      return s;
    }
  }

  Color get _methodColor =>
      _isBkash ? const Color(0xFFE2166E) : const Color(0xFF635BFF);

  // ── PDF Generation ────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'DONATION RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'BloodReq',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.red700),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              // Amount
              pw.Center(
                child: pw.Text(
                  _fmtAmount(d['amount']),
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  (d['status'] ?? 'completed').toString().toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.green700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Details
              _pdfRow('Fundraiser', d['fundraiser_title'] ?? '—'),
              _pdfRow('Method', (_isBkash ? 'bKash' : 'Stripe Credit Card')),
              _pdfRow('Currency', _currency),
              _pdfRow('Date', _fmtDate(d['created_at']?.toString())),
              if (d['transaction_id'] != null)
                _pdfRow('Transaction ID', d['transaction_id'].toString()),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              pw.Center(
                child: pw.Text(
                  'Thank you for your generous donation!',
                  style: pw.TextStyle(
                    color: PdfColors.grey600,
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
          ),
          pw.Flexible(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _downloadPdf() async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'BloodReq_Receipt_${d['id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareCard() async {
    setState(() => _isGenerating = true);
    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        _ShareCard(donation: d),
        pixelRatio: 3.0,
      );
      final xFile = XFile.fromData(imageBytes, mimeType: 'image/png');
      await Share.shareXFiles(
        [xFile],
        text:
            'I just donated ${_fmtAmount(d['amount'])} to ${d['fundraiser_title'] ?? 'a fundraiser'} via BloodReq ❤️',
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Receipt Card
          Screenshot(
            controller: _screenshotController,
            child: _ReceiptCard(
              donation: d,
              sym: _sym,
              fmtAmount: _fmtAmount,
              fmtDate: _fmtDate,
              isBkash: _isBkash,
              methodColor: _methodColor,
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (_isGenerating)
            const CircularProgressIndicator()
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.download_rounded,
                    label: 'Download PDF',
                    onTap: _downloadPdf,
                    color: const Color(0xFF635BFF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share Card',
                    onTap: _shareCard,
                    color: _methodColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Receipt Card Widget ─────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final String sym;
  final String Function(dynamic) fmtAmount;
  final String Function(String?) fmtDate;
  final bool isBkash;
  final Color methodColor;

  const _ReceiptCard({
    required this.donation,
    required this.sym,
    required this.fmtAmount,
    required this.fmtDate,
    required this.isBkash,
    required this.methodColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [methodColor, methodColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isBkash ? Icons.phone_android : Icons.credit_card,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  fmtAmount(donation['amount']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✓  DONATION CONFIRMED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dashed separator
          _DashedDivider(color: methodColor.withValues(alpha: 0.3)),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Row('Fundraiser', donation['fundraiser_title'] ?? '—'),
                const SizedBox(height: 12),
                _Row(
                  'Payment Method',
                  isBkash ? 'bKash' : 'Stripe · Credit Card',
                ),
                const SizedBox(height: 12),
                _Row('Currency', donation['currency'] ?? 'BDT'),
                const SizedBox(height: 12),
                _Row('Date', fmtDate(donation['created_at']?.toString())),
                if (donation['transaction_id'] != null) ...[
                  const SizedBox(height: 12),
                  _Row(
                    'Transaction ID',
                    donation['transaction_id'].toString(),
                    mono: true,
                    truncate: true,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Thank you for your generous donation! ❤️',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, color: methodColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  'BloodReq  •  Powered by ${isBkash ? 'bKash' : 'Stripe'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: methodColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool truncate;

  const _Row(
    this.label,
    this.value, {
    this.mono = false,
    this.truncate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: truncate ? TextOverflow.ellipsis : null,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 20),
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Share Card (used for screenshot sharing) ─────────────────────────────────

class _ShareCard extends StatelessWidget {
  final Map<String, dynamic> donation;

  const _ShareCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    final isBkash = (donation['payment_method'] ?? '') == 'bkash';
    final currency = (donation['currency'] ?? 'BDT') as String;
    final sym = currency == 'USD' ? '\$' : '৳';
    final amount = (donation['amount'] ?? 0).toDouble();
    final amountStr =
        '$sym${amount.toStringAsFixed(currency == 'USD' ? 2 : 0)}';
    final methodColor = isBkash
        ? const Color(0xFFE2166E)
        : const Color(0xFF635BFF);
    final fundraiser =
        donation['fundraiser_title']?.toString() ?? 'a fundraiser';

    return Container(
      width: 360,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [methodColor, methodColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            'I just donated',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            amountStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'to $fundraiser',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                'BloodReq  •  Together we save lives',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
