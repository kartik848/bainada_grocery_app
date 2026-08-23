import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,##,###', 'en_IN');

  static String format(double amount) {
    return _inrFormatter.format(amount);
  }

  static String formatCompact(double amount) {
    return _inrCompact.format(amount);
  }

  static String formatWithoutSymbol(double amount) {
    return _inrFormatter.format(amount).replaceAll('₹', '').trim();
  }

  static String formatCount(int count) {
    return _numberFormat.format(count);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
}
