import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Full-screen WebView for bKash Tokenized Checkout.
///
/// Monitors URL changes — when the URL starts with `bloodreq://payment/`,
/// the screen closes and passes the result back to the caller.
class BkashWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String fundraiserId;

  const BkashWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.fundraiserId,
  });

  @override
  State<BkashWebViewScreen> createState() => _BkashWebViewScreenState();
}

class _BkashWebViewScreenState extends State<BkashWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            // Intercept bKash callback deep link
            if (url.startsWith('bloodreq://payment/')) {
              final uri = Uri.tryParse(url);
              final isSuccess =
                  uri?.host == 'payment' &&
                  (uri?.pathSegments.firstOrNull ?? '') == 'success';
              if (mounted) Navigator.of(context).pop(isSuccess);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Only dismiss on fatal errors (not sub-resource failures)
            if (error.isForMainFrame == true && mounted) {
              Navigator.of(context).pop(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // bKash brand color dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE2166E),
                shape: BoxShape.circle,
              ),
            ),
            const Text(
              'bKash Checkout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel payment',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE2166E)),
                  SizedBox(height: 12),
                  Text(
                    'Loading bKash...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
