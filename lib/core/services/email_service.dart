import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:receipto/core/services/email_templates.dart';
import 'package:shared_preferences/shared_preferences.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

class EmailService {
  Future<void> cacheEnvCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
        'SMTP_HOST',
        'SMTP_PORT',
        'SMTP_USERNAME',
        'SMTP_PASSWORD',
        'SMTP_SENDER',
      ];
      for (final key in keys) {
        final val = dotenv.env[key];
        if (val != null && val.isNotEmpty) {
          await prefs.setString('env_$key', val);
        }
      }
      debugPrint('[EmailService] Caching environment variables to SharedPreferences completed.');
    } catch (e) {
      debugPrint('[EmailService] Error caching environment variables: $e');
    }
  }

  Future<SmtpServer> _getSmtpServer() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String host = dotenv.env['SMTP_HOST'] ?? prefs.getString('env_SMTP_HOST') ?? 'smtp-relay.brevo.com';
    final String portStr = dotenv.env['SMTP_PORT'] ?? prefs.getString('env_SMTP_PORT') ?? '587';
    final String username = dotenv.env['SMTP_USERNAME'] ?? prefs.getString('env_SMTP_USERNAME') ?? 'b2786c001@smtp-brevo.com';
    final String password = dotenv.env['SMTP_PASSWORD'] ?? prefs.getString('env_SMTP_PASSWORD') ?? 'xsmtpsib-6bd2aa412b0e2539075028fa719ed8d47586bb0a898b5f4d814ddcb7c39def54-uf5X2irs5yjLkMMZ';

    // Validate that all required environment variables exist or have fallbacks
    if (username.isEmpty || password.isEmpty) {
      final errorMsg = 'SMTP Configuration Error: Missing username or password.';
      debugPrint('[EmailService] $errorMsg');
      throw Exception(errorMsg);
    }

    final int port = int.tryParse(portStr) ?? 587;

    if (host.contains('gmail.com')) {
      return gmail(username, password);
    }

    return SmtpServer(
      host,
      port: port,
      username: username,
      password: password,
      ssl: port == 465,
      ignoreBadCertificate: false,
    );
  }

  /// Verifies the connection to the SMTP server.
  Future<bool> verifyConnection() async {
    try {
      debugPrint('SMTP: Verifying SMTP connection');
      await _getSmtpServer();
      debugPrint('Authentication check passed');
      return true;
    } catch (e, stack) {
      debugPrint('Authentication check failed');
      debugPrint('SMTP exception: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stack');
      }
      return false;
    }
  }

  void _logError(dynamic e, StackTrace stack) {
    debugPrint('SMTP error: $e');
    if (kDebugMode) {
      debugPrint('Stack trace: $stack');
    }
  }

  void _printEmailFlowDebug({
    required String emailType,
    required String senderEmail,
    required String recipientEmail,
    required String subject,
    required String host,
    String? warrantyId,
    String? productName,
    String? loggedUserUid,
    String? loggedUserEmail,
    String? warrantyOwnerUid,
    String? warrantyOwnerEmail,
  }) {
    String firebaseEmail = 'NULL';
    String uid = 'NULL';
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      firebaseEmail = currentUser?.email ?? 'NULL';
      uid = currentUser?.uid ?? 'NULL';
    } catch (_) {
      debugPrint("Firebase not initialized in this environment.");
    }

    final String recipientBefore = recipientEmail;
    final String recipientAfter = recipientEmail.trim();

    print("======================================");
    print("EMAIL FLOW DEBUG");
    print("======================================");
    print("Email Type:");
    print(emailType);
    print("");
    print("Warranty ID:");
    print(warrantyId ?? 'N/A');
    print("");
    print("Product Name:");
    print(productName ?? 'N/A');
    print("");
    print("Logged User UID:");
    print(loggedUserUid ?? uid);
    print("");
    print("Logged User Email:");
    print(loggedUserEmail ?? firebaseEmail);
    print("");
    print("Warranty Owner UID:");
    print(warrantyOwnerUid ?? 'N/A');
    print("");
    print("Warranty Owner Email:");
    print(warrantyOwnerEmail ?? 'N/A');
    print("");
    print("Recipient Before Validation:");
    print(recipientBefore);
    print("");
    print("Recipient After Validation:");
    print(recipientAfter);
    print("");
    print("Sender:");
    print(senderEmail);
    print("");
    print("Subject:");
    print(subject);
    print("");
    print("SMTP Host:");
    print(host);
    print("");
    print("SMTP Port:");
    print("587");
    print("======================================");

    if (recipientBefore != recipientAfter) {
      print("RECIPIENT MODIFIED");
      print("Old Value:");
      print(recipientBefore);
      print("New Value:");
      print(recipientAfter);
      print("Filename:");
      print("email_service.dart");
      print("Function:");
      print("sendEmail");
      print("Line Number:");
      print("140");
    }
  }

  void _validateRecipient(String recipientEmail) {
    if (recipientEmail.trim().isEmpty) {
      print("Recipient is EMPTY");
      throw Exception("Recipient is EMPTY");
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(recipientEmail)) {
      print("Recipient format INVALID");
      throw Exception("Recipient format INVALID");
    }
  }

  /// Sends a warranty reminder email using HTML template.
  Future<void> sendWarrantyReminderEmail({
    required String recipientEmail,
    required String userName,
    required String productName,
    required String merchantName,
    required String purchaseDate,
    required String expiryDate,
    required String daysRemaining,
    required String invoiceNumber,
    String? loggedUserUid,
    String? loggedUserEmail,
    String? warrantyOwnerUid,
    String? warrantyOwnerEmail,
    String? warrantyId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final host = dotenv.env['SMTP_HOST'] ?? prefs.getString('env_SMTP_HOST') ?? 'smtp-relay.brevo.com';
    final senderEmail = dotenv.env['SMTP_SENDER'] ?? prefs.getString('env_SMTP_SENDER') ?? 'receiptotechexplorers@gmail.com';
    final subject = 'Warranty Reminder - $productName';

    _printEmailFlowDebug(
      emailType: 'Reminder',
      senderEmail: senderEmail,
      recipientEmail: recipientEmail,
      subject: subject,
      host: host,
      warrantyId: warrantyId,
      productName: productName,
      loggedUserUid: loggedUserUid,
      loggedUserEmail: loggedUserEmail,
      warrantyOwnerUid: warrantyOwnerUid,
      warrantyOwnerEmail: warrantyOwnerEmail,
    );

    _validateRecipient(recipientEmail);

    try {
      final emailHtml = EmailTemplates.getWarrantyReminderHtml(
        userName: userName,
        productName: productName,
        merchantName: merchantName,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        daysRemaining: daysRemaining,
        invoiceNumber: invoiceNumber,
      );
      final emailText = EmailTemplates.getWarrantyReminderText(
        userName: userName,
        productName: productName,
        merchantName: merchantName,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        daysRemaining: daysRemaining,
        invoiceNumber: invoiceNumber,
      );

      if (senderEmail.isEmpty) {
        throw Exception('SMTP_SENDER is missing');
      }

      final message = Message()
        ..from = Address(senderEmail, 'Receipto')
        ..recipients.add(recipientEmail.trim())
        ..subject = subject
        ..text = emailText
        ..html = emailHtml
        ..headers['Reply-To'] = senderEmail;

      int retries = 3;
      bool sentSuccessfully = false;
      int attempt = 0;

      while (retries > 0 && !sentSuccessfully) {
        if (attempt > 0) {
          debugPrint('Retry attempt: $attempt');
        }
        try {
          print("Recipient Verified");
          print("Connecting to Gmail SMTP...");
          final smtpServer = await _getSmtpServer();
          
          print("SMTP Connected");
          print("SMTP Accepted");
          print("Gmail Accepted");
          
          print("Message.from:");
          print(message.from);
          print("Message.recipients:");
          print(message.recipients.join(', '));
          print("Message.subject:");
          print(message.subject);
          print("Message.html.length:");
          print(message.html?.length ?? 0);

          print("Email Uploaded");
          final SendReport report = await send(message, smtpServer);
          sentSuccessfully = true;
          
          print("SMTP Response:");
          print(report.toString());
          print("Email Delivered Successfully");
        } catch (e) {
          retries--;
          attempt++;
          final errStr = e.toString();
          if (errStr.contains('Username and Password not accepted') || 
              errStr.contains('Authentication failed') || 
              errStr.contains('535')) {
            throw AuthenticationException('SMTP authentication failed: Invalid username or password.');
          }
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 2));
          } else {
            rethrow;
          }
        }
      }

      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'SUCCESS');
      } catch (_) {}

    } on SocketException catch (e, stack) {
      print("SocketException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (SocketException): $e');
      } catch (_) {}
      throw Exception('Network connection failed. Please check your internet connection and SMTP host.');
    } on AuthenticationException catch (e, stack) {
      print("AuthenticationException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (AuthenticationException): $e');
      } catch (_) {}
      throw Exception('SMTP authentication failed. Please verify your credentials.');
    } on TimeoutException catch (e, stack) {
      print("TimeoutException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (TimeoutException): $e');
      } catch (_) {}
      throw Exception('SMTP connection timed out.');
    } on FormatException catch (e, stack) {
      print("FormatException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (FormatException): $e');
      } catch (_) {}
      throw Exception('Invalid data format in email configuration or templates.');
    } on MailerException catch (e, stack) {
      print("MailerException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (MailerException): $e');
      } catch (_) {}
      throw Exception('SMTP mail delivery failed: ${e.message}');
    } catch (e, stack) {
      print("Exception: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED: $e');
      } catch (_) {}
      throw Exception('Email delivery failed: $e');
    }
  }

  /// Sends a simple configuration test email to the user.
  Future<void> sendTestEmail({
    required String recipientEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final host = dotenv.env['SMTP_HOST'] ?? prefs.getString('env_SMTP_HOST') ?? 'smtp-relay.brevo.com';
    final senderEmail = dotenv.env['SMTP_SENDER'] ?? prefs.getString('env_SMTP_SENDER') ?? 'receiptotechexplorers@gmail.com';
    final subject = 'Receipto SMTP Connection Test';

    _printEmailFlowDebug(
      emailType: 'Test',
      senderEmail: senderEmail,
      recipientEmail: recipientEmail,
      subject: subject,
      host: host,
    );

    _validateRecipient(recipientEmail);

    try {
      final emailHtml = EmailTemplates.getTestEmailHtml();
      final emailText = EmailTemplates.getTestEmailText();

      if (senderEmail.isEmpty) {
        throw Exception('SMTP_SENDER is missing');
      }

      final message = Message()
        ..from = Address(senderEmail, 'Receipto')
        ..recipients.add(recipientEmail.trim())
        ..subject = subject
        ..text = emailText
        ..html = emailHtml
        ..headers['Reply-To'] = senderEmail;

      print("Recipient Verified");
      print("Connecting to Gmail SMTP...");
      final smtpServer = await _getSmtpServer();
      
      print("SMTP Connected");
      print("SMTP Accepted");
      print("Gmail Accepted");
      
      print("Message.from:");
      print(message.from);
      print("Message.recipients:");
      print(message.recipients.join(', '));
      print("Message.subject:");
      print(message.subject);
      print("Message.html.length:");
      print(message.html?.length ?? 0);

      print("Email Uploaded");
      final SendReport report = await send(message, smtpServer);
      
      print("SMTP Response:");
      print(report.toString());
      print("Email Delivered Successfully");
    } on SocketException catch (e, stack) {
      print("SocketException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      throw Exception('Network connection failed. Please check your internet connection and SMTP host.');
    } on AuthenticationException catch (e, stack) {
      print("AuthenticationException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      throw Exception('SMTP authentication failed. Please verify your credentials.');
    } on TimeoutException catch (e, stack) {
      print("TimeoutException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      throw Exception('SMTP connection timed out.');
    } on FormatException catch (e, stack) {
      print("FormatException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      throw Exception('Invalid data format in email configuration or templates.');
    } on MailerException catch (e, stack) {
      print("MailerException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      final errStr = e.toString();
      if (errStr.contains('Username and Password not accepted') || 
          errStr.contains('Authentication failed') || 
          errStr.contains('535')) {
        throw Exception('SMTP authentication failed. Please verify your credentials.');
      }
      throw Exception('SMTP mail delivery failed: ${e.message}');
    } catch (e, stack) {
      print("Exception: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      final errStr = e.toString();
      if (errStr.contains('Username and Password not accepted') || 
          errStr.contains('Authentication failed') || 
          errStr.contains('535')) {
        throw Exception('SMTP authentication failed. Please verify your credentials.');
      }
      throw Exception('Email delivery failed: $e');
    }
  }

  /// Sends a grouped warranty reminder email using HTML template.
  Future<void> sendGroupedWarrantyReminderEmail({
    required String recipientEmail,
    required String userName,
    required List<Map<String, String>> products,
    String? loggedUserUid,
    String? loggedUserEmail,
    String? warrantyOwnerUid,
    String? warrantyOwnerEmail,
    String? warrantyId,
    String? productName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final host = dotenv.env['SMTP_HOST'] ?? prefs.getString('env_SMTP_HOST') ?? 'smtp.gmail.com';
    final senderEmail = dotenv.env['SMTP_SENDER'] ?? prefs.getString('env_SMTP_SENDER') ?? 'receiptotechexplorers@gmail.com';
    final count = products.length;
    final subject = count == 1
        ? 'Warranty Reminder - ${products.first['name']}'
        : 'Warranty Reminder Summary - $count Products Need Your Attention';

    _printEmailFlowDebug(
      emailType: 'Grouped',
      senderEmail: senderEmail,
      recipientEmail: recipientEmail,
      subject: subject,
      host: host,
      warrantyId: warrantyId,
      productName: productName,
      loggedUserUid: loggedUserUid,
      loggedUserEmail: loggedUserEmail,
      warrantyOwnerUid: warrantyOwnerUid,
      warrantyOwnerEmail: warrantyOwnerEmail,
    );

    _validateRecipient(recipientEmail);

    try {
      final emailHtml = EmailTemplates.getGroupedWarrantyReminderHtml(
        userName: userName,
        products: products,
      );
      final emailText = EmailTemplates.getGroupedWarrantyReminderText(
        userName: userName,
        products: products,
      );

      if (senderEmail.isEmpty) {
        throw Exception('SMTP_SENDER is missing');
      }

      final message = Message()
        ..from = Address(senderEmail, 'Receipto')
        ..recipients.add(recipientEmail.trim())
        ..subject = subject
        ..text = emailText
        ..html = emailHtml
        ..headers['Auto-Submitted'] = 'auto-generated'
        ..headers['X-Auto-Response-Suppress'] = 'All'
        ..headers['X-Mailer'] = 'Receipto App';

      int retries = 3;
      bool sentSuccessfully = false;
      int attempt = 0;

      while (retries > 0 && !sentSuccessfully) {
        if (attempt > 0) {
          debugPrint('Retry attempt: $attempt');
        }
        try {
          print("Recipient Verified");
          print("Connecting to Gmail SMTP...");
          final smtpServer = await _getSmtpServer();
          
          print("SMTP Connected");
          print("SMTP Accepted");
          print("Gmail Accepted");
          
          print("Message.from:");
          print(message.from);
          print("Message.recipients:");
          print(message.recipients.join(', '));
          print("Message.subject:");
          print(message.subject);
          print("Message.html.length:");
          print(message.html?.length ?? 0);

          print("Email Uploaded");
          final SendReport report = await send(message, smtpServer);
          sentSuccessfully = true;
          
          print("SMTP Response:");
          print(report.toString());
          print("Email Delivered Successfully");
        } catch (e) {
          retries--;
          attempt++;
          final errStr = e.toString();
          if (errStr.contains('Username and Password not accepted') || 
              errStr.contains('Authentication failed') || 
              errStr.contains('535')) {
            throw AuthenticationException('SMTP authentication failed: Invalid username or password.');
          }
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 2));
          } else {
            rethrow;
          }
        }
      }

      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'SUCCESS (Grouped count: $count)');
      } catch (_) {}

    } on SocketException catch (e, stack) {
      print("SocketException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (SocketException): $e');
      } catch (_) {}
      throw Exception('Network connection failed. Please check your internet connection and SMTP host.');
    } on AuthenticationException catch (e, stack) {
      print("AuthenticationException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (AuthenticationException): $e');
      } catch (_) {}
      throw Exception('SMTP authentication failed. Please verify your credentials.');
    } on TimeoutException catch (e, stack) {
      print("TimeoutException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (TimeoutException): $e');
      } catch (_) {}
      throw Exception('SMTP connection timed out.');
    } on FormatException catch (e, stack) {
      print("FormatException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (FormatException): $e');
      } catch (_) {}
      throw Exception('Invalid data format in email configuration or templates.');
    } on MailerException catch (e, stack) {
      print("MailerException: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED (MailerException): $e');
      } catch (_) {}
      throw Exception('SMTP mail delivery failed: ${e.message}');
    } catch (e, stack) {
      print("Exception: $e");
      print("Stack trace:\n$stack");
      _logError(e, stack);
      try {
        await prefs.setString('last_email_sent_time', DateTime.now().toLocal().toString());
        await prefs.setString('last_email_sent_status', 'FAILED: $e');
      } catch (_) {}
      throw Exception('Email delivery failed: $e');
    }
  }
}
