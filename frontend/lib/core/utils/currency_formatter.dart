class CurrencyFormatter {
  /// Formats an amount with the provided currency symbol, defaulting to '₹' (INR) if null or empty.
  /// Includes thousand-separator commas for enhanced readability.
  static String format(double amount, {String? currency}) {
    final String symbol = (currency == null || currency.trim().isEmpty) ? '₹' : currency.trim();
    final parts = amount.abs().toStringAsFixed(2).split('.');
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = parts[0].replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$symbol$formattedInteger.${parts[1]}';
  }
  
  /// Formats an amount to a clean integer presentation if appropriate, or standard decimal with commas.
  static String formatCompact(double amount, {String? currency}) {
    final String symbol = (currency == null || currency.trim().isEmpty) ? '₹' : currency.trim();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    if (amount == amount.toInt()) {
      final formattedInteger = amount.abs().toInt().toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
      return '$symbol$formattedInteger';
    }
    return format(amount, currency: currency);
  }
}

