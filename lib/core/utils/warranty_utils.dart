class WarrantyUtils {
  /// Parses YYYY-MM-DD string safely. Falls back to tryParse or current date.
  static DateTime _parseDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.isEmpty) return DateTime.now();
      final parts = clean.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  /// Formats a DateTime back to YYYY-MM-DD string.
  static String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parses and normalizes various date formats into standard YYYY-MM-DD format.
  /// Supported input formats: "19-Jul-2026", "19 July 2026", "19/07/2026", "19-07-2026",
  /// "2026-07-19", "19 Jul 26", "July 19 2026", etc.
  static String? parseAndNormalizeDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;
    
    final clean = rawDate.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Check if it already matches YYYY-MM-DD
    final yyyymmddReg = RegExp(r'^(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})$');
    final matchYmd = yyyymmddReg.firstMatch(clean);
    if (matchYmd != null) {
      final y = matchYmd.group(1)!;
      final m = matchYmd.group(2)!.padLeft(2, '0');
      final d = matchYmd.group(3)!.padLeft(2, '0');
      return '$y-$m-$d';
    }

    // Check if format is DD-MM-YYYY or DD/MM/YYYY
    final ddmmyyyyReg = RegExp(r'^(\d{1,2})[-\/](\d{1,2})[-\/](\d{4})$');
    final matchDmy = ddmmyyyyReg.firstMatch(clean);
    if (matchDmy != null) {
      final d = matchDmy.group(1)!.padLeft(2, '0');
      final m = matchDmy.group(2)!.padLeft(2, '0');
      final y = matchDmy.group(3)!;
      return '$y-$m-$d';
    }

    // Check if format is DD-MM-YY or DD/MM/YY
    final ddmmyyReg = RegExp(r'^(\d{1,2})[-\/](\d{1,2})[-\/](\d{2})$');
    final matchDmyy = ddmmyyReg.firstMatch(clean);
    if (matchDmyy != null) {
      final d = matchDmyy.group(1)!.padLeft(2, '0');
      final m = matchDmyy.group(2)!.padLeft(2, '0');
      final yy = matchDmyy.group(3)!;
      final y = '20$yy'; // Assume 21st century
      return '$y-$m-$d';
    }

    // Month text dictionary
    final monthsMap = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9, 'sept': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12
    };

    // Clean delimiters to spaces to make parsing easier
    final normalizedText = clean.toLowerCase().replaceAll('-', ' ').replaceAll('/', ' ').replaceAll(',', ' ');
    final parts = normalizedText.split(' ');

    int? parsedDay;
    int? parsedMonth;
    int? parsedYear;

    // Try finding month text
    String? foundMonthKey;
    for (final monthKey in monthsMap.keys) {
      if (parts.contains(monthKey)) {
        foundMonthKey = monthKey;
        parsedMonth = monthsMap[monthKey];
        break;
      }
    }

    if (parsedMonth != null && foundMonthKey != null) {
      final remainingParts = parts.where((p) => p != foundMonthKey).toList();
      final List<int> numbers = [];
      for (final p in remainingParts) {
        final parsed = int.tryParse(p.replaceAll(RegExp(r'\D'), ''));
        if (parsed != null) {
          numbers.add(parsed);
        }
      }

      if (numbers.length >= 2) {
        final num1 = numbers[0];
        final num2 = numbers[1];

        if (num1 > 31) {
          parsedYear = num1;
          parsedDay = num2;
        } else if (num2 > 31) {
          parsedYear = num2;
          parsedDay = num1;
        } else {
          // Check positions in text to guess day/year
          final idx1 = normalizedText.indexOf(num1.toString());
          final idx2 = normalizedText.indexOf(num2.toString());
          if (idx1 < idx2) {
            parsedDay = num1;
            parsedYear = num2;
          } else {
            parsedDay = num2;
            parsedYear = num1;
          }
        }
      }
    }

    if (parsedDay != null && parsedMonth != null && parsedYear != null) {
      if (parsedYear < 100) {
        parsedYear = 2000 + parsedYear; // Assume 20xx
      }
      final y = parsedYear.toString();
      final m = parsedMonth.toString().padLeft(2, '0');
      final d = parsedDay.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    // Direct DateTime tryParse fallback
    final parsedDt = DateTime.tryParse(clean);
    if (parsedDt != null) {
      final y = parsedDt.year.toString();
      final m = parsedDt.month.toString().padLeft(2, '0');
      final d = parsedDt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    return null;
  }

  /// Calculates expiry date automatically from purchaseDate, period, and unit.
  static String calculateExpiryDate(String purchaseDateStr, int period, String unit) {
    final purchaseDate = _parseDate(purchaseDateStr);
    final unitLower = unit.trim().toLowerCase();

    DateTime expiryDate;
    if (unitLower == 'days' || unitLower == 'day' || unitLower == 'd') {
      expiryDate = purchaseDate.add(Duration(days: period));
    } else if (unitLower == 'months' || unitLower == 'month' || unitLower == 'm') {
      int newYear = purchaseDate.year;
      int newMonth = purchaseDate.month + period;
      while (newMonth > 12) {
        newYear += 1;
        newMonth -= 12;
      }
      while (newMonth < 1) {
        newYear -= 1;
        newMonth += 12;
      }
      int newDay = purchaseDate.day;
      final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > lastDayOfTargetMonth) {
        newDay = lastDayOfTargetMonth;
      }
      expiryDate = DateTime(newYear, newMonth, newDay);
    } else if (unitLower == 'years' || unitLower == 'year' || unitLower == 'y') {
      int newYear = purchaseDate.year + period;
      int newMonth = purchaseDate.month;
      int newDay = purchaseDate.day;
      final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > lastDayOfTargetMonth) {
        newDay = lastDayOfTargetMonth;
      }
      expiryDate = DateTime(newYear, newMonth, newDay);
    } else {
      int newYear = purchaseDate.year;
      int newMonth = purchaseDate.month + period;
      while (newMonth > 12) {
        newYear += 1;
        newMonth -= 12;
      }
      int newDay = purchaseDate.day;
      final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > lastDayOfTargetMonth) {
        newDay = lastDayOfTargetMonth;
      }
      expiryDate = DateTime(newYear, newMonth, newDay);
    }

    return _formatDate(expiryDate);
  }

  /// Calculates remaining days between current date (today) and expiry date.
  static int calculateDaysRemaining(String expiryDateStr) {
    if (expiryDateStr.toLowerCase().contains('unknown') || expiryDateStr.trim().isEmpty) {
      return 9999; // Gracefully handle unknown expiry dates
    }
    final normalized = parseAndNormalizeDate(expiryDateStr);
    if (normalized == null) {
      return 9999;
    }
    final expiry = _parseDate(normalized);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryClean = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryClean.difference(today).inDays;
  }

  /// Resolves the warranty status based on expiryDate.
  static String calculateStatus(String expiryDateStr) {
    if (expiryDateStr.toLowerCase().contains('unknown') ||
        expiryDateStr.trim().isEmpty ||
        parseAndNormalizeDate(expiryDateStr) == null) {
      return 'ACTIVE';
    }
    final days = calculateDaysRemaining(expiryDateStr);
    if (days < 0) {
      return 'EXPIRED';
    } else if (days <= 30) {
      return 'EXPIRING SOON';
    } else {
      return 'ACTIVE';
    }
  }

  /// Calculates total warranty period in days based on period and unit.
  static int calculateTotalDays(int period, String unit) {
    final unitLower = unit.trim().toLowerCase();
    if (unitLower.startsWith('y')) {
      return period * 365;
    } else if (unitLower.startsWith('m')) {
      return period * 30;
    } else {
      return period;
    }
  }
}
