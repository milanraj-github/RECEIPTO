import 'package:receipto/core/utils/currency_formatter.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    return '$month $day, $year';
  }

  static String formatAmount(double amount, {String? currency}) {
    return CurrencyFormatter.format(amount, currency: currency);
  }
}
