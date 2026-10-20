class EmailTemplates {
  static Map<String, String> _getBadgeDetails(int days) {
    if (days < 0) {
      return {
        'color': '#EF4444',
        'bg': '#FEF2F2',
        'text': 'Expired',
      };
    } else if (days == 0) {
      return {
        'color': '#DC2626',
        'bg': '#FEF2F2',
        'text': 'Expires Today',
      };
    } else if (days == 1) {
      return {
        'color': '#D97706',
        'bg': '#FFFBEB',
        'text': 'Expires Tomorrow',
      };
    } else if (days <= 7) {
      return {
        'color': '#D97706',
        'bg': '#FFFBEB',
        'text': '7 Days Remaining',
      };
    } else if (days <= 15) {
      return {
        'color': '#2563EB',
        'bg': '#EFF6FF',
        'text': '15 Days Remaining',
      };
    } else if (days <= 30) {
      return {
        'color': '#059669',
        'bg': '#ECFDF5',
        'text': '30 Days Remaining',
      };
    } else {
      return {
        'color': '#059669',
        'bg': '#ECFDF5',
        'text': '$days Days Remaining',
      };
    }
  }

  static String getWarrantyReminderHtml({
    required String userName,
    required String productName,
    required String merchantName,
    required String purchaseDate,
    required String expiryDate,
    required String daysRemaining,
    required String invoiceNumber,
  }) {
    final days = int.tryParse(daysRemaining) ?? -1;
    final badge = _getBadgeDetails(days);
    final badgeColor = badge['color']!;
    final badgeBg = badge['bg']!;
    final badgeText = badge['text']!;
    final invoiceDisplay = invoiceNumber.isNotEmpty ? invoiceNumber : 'N/A';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Warranty Expiration Reminder</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #F8FAFC;
      color: #0F172A;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #FFFFFF;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
      border: 1px solid #E2E8F0;
    }
    .header {
      background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%);
      color: #FFFFFF;
      padding: 36px 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    .header p {
      margin: 6px 0 0 0;
      font-size: 13px;
      opacity: 0.85;
      font-weight: 500;
    }
    .content {
      padding: 36px 32px;
      background-color: #FFFFFF;
    }
    .greeting {
      font-size: 20px;
      font-weight: 700;
      color: #0F172A;
      margin-top: 0;
      margin-bottom: 8px;
    }
    .intro {
      font-size: 15px;
      line-height: 1.6;
      color: #475569;
      margin-bottom: 28px;
    }
    .card {
      background-color: #FFFFFF;
      border: 1px solid #E2E8F0;
      border-radius: 12px;
      padding: 24px;
      margin-bottom: 28px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
    }
    .table {
      width: 100%;
      border-collapse: collapse;
    }
    .table td {
      padding: 10px 0;
      font-size: 14px;
      border-bottom: 1px solid #F1F5F9;
    }
    .table tr:last-child td {
      border-bottom: none;
      padding-bottom: 0;
    }
    .table td.label {
      color: #64748B;
      font-weight: 500;
      text-align: left;
    }
    .table td.value {
      color: #0F172A;
      font-weight: 600;
      text-align: right;
    }
    .btn-container {
      text-align: center;
      margin-top: 32px;
      margin-bottom: 8px;
    }
    .btn {
      display: inline-block;
      padding: 14px 32px;
      font-size: 14px;
      font-weight: 700;
      color: #FFFFFF !important;
      background-color: #2563EB;
      border-radius: 8px;
      text-decoration: none;
      box-shadow: 0 4px 6px -1px rgba(37, 99, 235, 0.2);
    }
    .footer {
      background-color: #F8FAFC;
      border-top: 1px solid #E2E8F0;
      padding: 28px;
      text-align: center;
      font-size: 12px;
      color: #64748B;
    }
    .footer p {
      margin: 4px 0;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🛡️ Receipto</h1>
      <p>Smart Receipt &amp; Warranty Manager</p>
    </div>
    <div class="content">
      <h2 class="greeting">Hello $userName,</h2>
      <p class="intro">This is an automatic warranty reminder from Receipto that your product warranty is nearing its expiration. Please keep your original receipt secure in case you need to file claims.</p>
      
      <div class="card">
        <table style="width: 100%; margin-bottom: 16px; border-collapse: collapse;">
          <tr>
            <td style="vertical-align: middle;">
              <h3 style="margin: 0; font-size: 18px; color: #0F172A; font-weight: 700;">$productName</h3>
            </td>
            <td style="text-align: right; vertical-align: middle;">
              <span style="display: inline-block; padding: 6px 12px; font-size: 11px; font-weight: 700; color: $badgeColor; background-color: $badgeBg; border-radius: 9999px; text-transform: uppercase; letter-spacing: 0.5px;">$badgeText</span>
            </td>
          </tr>
        </table>
        
        <table class="table">
          <tr>
            <td class="label">Merchant</td>
            <td class="value">$merchantName</td>
          </tr>
          <tr>
            <td class="label">Purchase Date</td>
            <td class="value">$purchaseDate</td>
          </tr>
          <tr>
            <td class="label">Expiry Date</td>
            <td class="value">$expiryDate</td>
          </tr>
          <tr>
            <td class="label">Invoice Number</td>
            <td class="value">$invoiceDisplay</td>
          </tr>
        </table>
      </div>
      
      <div class="btn-container">
        <a href="https://receipto.app" class="btn" style="color: #FFFFFF;">Open Receipto</a>
      </div>
    </div>
    <div class="footer">
      <p><strong>Receipto</strong> • Smart Receipt &amp; Warranty Manager</p>
      <p>Automatic Warranty Reminder</p>
      <p style="margin-top: 12px; font-size: 11px; color: #94A3B8;">This is a system-generated message. Please do not reply directly to this email.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  static String getTestEmailHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Receipto SMTP Connection Test</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #F8FAFC;
      color: #0F172A;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #FFFFFF;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
      border: 1px solid #E2E8F0;
    }
    .header {
      background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%);
      color: #FFFFFF;
      padding: 36px 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    .content {
      padding: 40px 32px;
      text-align: center;
    }
    .success-icon {
      font-size: 54px;
      margin-bottom: 20px;
    }
    .title {
      font-size: 22px;
      font-weight: 800;
      color: #059669;
      margin-bottom: 12px;
    }
    .message {
      font-size: 15px;
      line-height: 1.6;
      color: #475569;
      margin-bottom: 28px;
    }
    .footer {
      background-color: #F8FAFC;
      border-top: 1px solid #E2E8F0;
      padding: 24px;
      text-align: center;
      font-size: 12px;
      color: #64748B;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🛡️ Receipto</h1>
    </div>
    <div class="content">
      <div class="success-icon">✅</div>
      <div class="title">SMTP Connected Successfully!</div>
      <p class="message">
        Congratulations!<br>
        Your SMTP configuration is working successfully.<br><br>
        This email confirms Receipto can successfully send automated warranty reminder emails.
      </p>
    </div>
    <div class="footer">
      <p><strong>Receipto</strong> • Smart Receipt &amp; Warranty Manager</p>
      <p style="margin-top: 4px; font-size: 11px; color: #94A3B8;">This is a system-generated message. Please do not reply directly to this email.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  static String getGroupedWarrantyReminderHtml({
    required String userName,
    required List<Map<String, String>> products,
  }) {
    final String cardsHtml = products.map((p) {
      final days = int.tryParse(p['daysRemaining'] ?? '') ?? 0;
      final badge = _getBadgeDetails(days);
      final badgeColor = badge['color']!;
      final badgeBg = badge['bg']!;
      final badgeText = badge['text']!;
      final invoice = p['invoiceNumber'] ?? 'N/A';
      final invoiceDisplay = invoice.isNotEmpty ? invoice : 'N/A';

      return '''
      <div class="card" style="background-color: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 12px; padding: 24px; margin-bottom: 20px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);">
        <table style="width: 100%; margin-bottom: 16px; border-collapse: collapse;">
          <tr>
            <td style="vertical-align: middle;">
              <h3 style="margin: 0; font-size: 18px; color: #0F172A; font-weight: 700; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">${p['name']}</h3>
            </td>
            <td style="text-align: right; vertical-align: middle;">
              <span style="display: inline-block; padding: 6px 12px; font-size: 11px; font-weight: 700; color: $badgeColor; background-color: $badgeBg; border-radius: 9999px; text-transform: uppercase; letter-spacing: 0.5px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">$badgeText</span>
            </td>
          </tr>
        </table>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 10px 0; font-size: 14px; border-bottom: 1px solid #F1F5F9; color: #64748B; font-weight: 500; text-align: left;">Merchant</td>
            <td style="padding: 10px 0; font-size: 14px; border-bottom: 1px solid #F1F5F9; color: #0F172A; text-align: right; font-weight: 600;">${p['merchant']}</td>
          </tr>
          <tr>
            <td style="padding: 10px 0; font-size: 14px; border-bottom: 1px solid #F1F5F9; color: #64748B; font-weight: 500; text-align: left;">Purchase Date</td>
            <td style="padding: 10px 0; font-size: 14px; border-bottom: 1px solid #F1F5F9; color: #0F172A; text-align: right; font-weight: 600;">${p['purchaseDate']}</td>
          </tr>
          <tr>
            <td style="padding: 10px 0; font-size: 14px; border-bottom: 1px solid #F1F5F9; color: #64748B; font-weight: 500; text-align: left;">Expiry Date</td>
            <td style="padding: 10px 0; font-size: 14px; border-bottom: 1px solid #F1F5F9; color: #0F172A; text-align: right; font-weight: 600;">${p['expiryDate']}</td>
          </tr>
          <tr>
            <td style="padding: 10px 0; font-size: 14px; color: #64748B; font-weight: 500; text-align: left;">Invoice Number</td>
            <td style="padding: 10px 0; font-size: 14px; color: #0F172A; text-align: right; font-weight: 600;">$invoiceDisplay</td>
          </tr>
        </table>
      </div>
      ''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Warranty Expiration Reminder</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #F8FAFC;
      color: #0F172A;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #FFFFFF;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
      border: 1px solid #E2E8F0;
    }
    .header {
      background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%);
      color: #FFFFFF;
      padding: 36px 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    .header p {
      margin: 6px 0 0 0;
      font-size: 13px;
      opacity: 0.85;
      font-weight: 500;
    }
    .content {
      padding: 36px 32px;
      background-color: #FFFFFF;
    }
    .greeting {
      font-size: 20px;
      font-weight: 700;
      color: #0F172A;
      margin-top: 0;
      margin-bottom: 8px;
    }
    .intro {
      font-size: 15px;
      line-height: 1.6;
      color: #475569;
      margin-bottom: 28px;
    }
    .btn-container {
      text-align: center;
      margin-top: 32px;
      margin-bottom: 8px;
    }
    .btn {
      display: inline-block;
      padding: 14px 32px;
      font-size: 14px;
      font-weight: 700;
      color: #FFFFFF !important;
      background-color: #2563EB;
      border-radius: 8px;
      text-decoration: none;
      box-shadow: 0 4px 6px -1px rgba(37, 99, 235, 0.2);
    }
    .footer {
      background-color: #F8FAFC;
      border-top: 1px solid #E2E8F0;
      padding: 28px;
      text-align: center;
      font-size: 12px;
      color: #64748B;
    }
    .footer p {
      margin: 4px 0;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🛡️ Receipto</h1>
      <p>Smart Receipt &amp; Warranty Manager</p>
    </div>
    <div class="content">
      <h2 class="greeting">Hello $userName,</h2>
      <p class="intro">Here is a summary of your upcoming warranty reminders that need your attention. Please keep your original receipts secure for any replacement or support claims.</p>
      
      $cardsHtml
      
      <div class="btn-container">
        <a href="https://receipto.app" class="btn" style="color: #FFFFFF;">Open Receipto</a>
      </div>
    </div>
    <div class="footer">
      <p><strong>Receipto</strong> • Smart Receipt &amp; Warranty Manager</p>
      <p>Automatic Warranty Reminder</p>
      <p style="margin-top: 12px; font-size: 11px; color: #94A3B8;">This is a system-generated message. Please do not reply directly to this email.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Generates a clean plain-text version of the single warranty reminder email.
  static String getWarrantyReminderText({
    required String userName,
    required String productName,
    required String merchantName,
    required String purchaseDate,
    required String expiryDate,
    required String daysRemaining,
    required String invoiceNumber,
  }) {
    final invoiceStr = invoiceNumber.isNotEmpty ? invoiceNumber : 'N/A';
    return '''
Hello $userName,

This is a reminder regarding your warranty for $productName from $merchantName.

WARRANTY DETAILS:
- Product: $productName
- Merchant: $merchantName
- Purchase Date: $purchaseDate
- Expiry Date: $expiryDate
- Days Remaining: $daysRemaining
- Invoice/Receipt Number: $invoiceStr

Please keep your original receipt and documents safe for any warranty claims.

Best regards,
Receipto Team
https://receipto.app

This is an automated system notification. Please do not reply directly to this email.
''';
  }

  /// Generates a clean plain-text version of the grouped warranty reminder email.
  static String getGroupedWarrantyReminderText({
    required String userName,
    required List<Map<String, String>> products,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Hello $userName,');
    buffer.writeln();
    buffer.writeln('Here is a summary of your upcoming warranty expiration alerts:');
    buffer.writeln();

    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final name = p['name'] ?? 'Product';
      final merchant = p['merchant'] ?? 'Merchant';
      final purchase = p['purchaseDate'] ?? 'N/A';
      final expiry = p['expiryDate'] ?? 'N/A';
      final days = p['daysRemaining'] ?? '0';
      final invoice = (p['invoiceNumber'] != null && p['invoiceNumber']!.isNotEmpty) ? p['invoiceNumber']! : 'N/A';

      buffer.writeln('${i + 1}. $name ($merchant)');
      buffer.writeln('   - Expiry Date: $expiry ($days days remaining)');
      buffer.writeln('   - Purchase Date: $purchase');
      buffer.writeln('   - Invoice: $invoice');
      buffer.writeln();
    }

    buffer.writeln('Please keep your original receipts safe for any service or warranty claims.');
    buffer.writeln();
    buffer.writeln('Best regards,');
    buffer.writeln('Receipto Team');
    buffer.writeln('https://receipto.app');
    buffer.writeln();
    buffer.writeln('This is an automated system notification. Please do not reply directly to this email.');

    return buffer.toString();
  }

  /// Generates a clean plain-text version of the test email.
  static String getTestEmailText() {
    return '''
Receipto - SMTP Connection Test

Your Receipto email notification system is configured correctly and working.

If you received this message, warranty reminder emails will be delivered to this address.

Best regards,
Receipto Team
https://receipto.app
''';
  }
}
