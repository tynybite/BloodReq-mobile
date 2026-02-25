import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

/// Returns the currency symbol based on the user's registered country.
/// BD → ৳ (BDT), all others → $ (USD).
String getCurrencySymbol(BuildContext context) {
  final user = Provider.of<AuthProvider>(context, listen: false).user;
  final country = (user?.country ?? 'BD').toUpperCase();
  return country == 'BD' ? '৳' : '\$';
}

/// Returns the currency code based on the user's registered country.
String getCurrencyCode(BuildContext context) {
  final user = Provider.of<AuthProvider>(context, listen: false).user;
  final country = (user?.country ?? 'BD').toUpperCase();
  return country == 'BD' ? 'BDT' : 'USD';
}
