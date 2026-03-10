import 'package:intl/intl.dart';

/// Centralized utility for all formatting in the app.
/// Forces Western numerals and specific date orders (31 Jan 2026)
/// regardless of the current system locale.
class FormatHelper {
  // Use en_US locale internally to force LTR and Western numerals
  static const String _formatLocale = 'en_US';

  /// Formats a date to "31 Jan 2026" format
  static String date(DateTime date) {
    return '\u200E${DateFormat('dd MMM yyyy', _formatLocale).format(date)}\u200E';
  }

  /// Formats a date to "Jan 2026" (Month Year)
  static String monthYear(DateTime date) {
    return '\u200E${DateFormat('MMM yyyy', _formatLocale).format(date)}\u200E';
  }

  /// Formats a date to "31 Jan 2026 – 14:30" (Date Time)
  static String dateTime(DateTime date) {
    return '\u200E${DateFormat('dd MMM yyyy – HH:mm', _formatLocale).format(date)}\u200E';
  }

  /// Formats an amount to "#,##0.00" (e.g., 1,250.50)
  static String amount(double amount) {
    return '\u200E${NumberFormat('#,##0.00', _formatLocale).format(amount)}\u200E';
  }

  /// Formats a currency amount with AED prefix (e.g., AED 1,250.50)
  static String currency(double amount) {
    return '\u200E AED ${NumberFormat('#,##0.00', _formatLocale).format(amount)} \u200E';
  }

  /// Formats a percentage (e.g., 5.0%)
  static String percent(double value) {
    return '\u200E${NumberFormat('#,##0.0', _formatLocale).format(value)}%\u200E';
  }
}
