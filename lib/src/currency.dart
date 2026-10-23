import 'package:intl/intl.dart';

final NumberFormat _pkrNumberFormat = NumberFormat('#,##0');

/// Formats a monetary amount into a standardized Pakistani Rupee string.
/// In English / default: `PKR 1,200`
/// In Urdu (`isUrdu: true`): `روپے 1,200`
String formatPkr(num amount, {bool isUrdu = false}) {
  final isNegative = amount < 0;
  final formatted = _pkrNumberFormat.format(amount.abs());
  if (isUrdu) {
    return isNegative ? '-روپے $formatted' : 'روپے $formatted';
  }
  return isNegative ? '-PKR $formatted' : 'PKR $formatted';
}
