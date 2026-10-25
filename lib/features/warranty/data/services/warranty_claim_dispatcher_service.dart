import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/warranty/data/services/brand_support_directory.dart';
import 'package:receipto/features/warranty/data/services/warranty_claim_categories.dart';

final warrantyClaimDispatcherServiceProvider = Provider<WarrantyClaimDispatcherService>((ref) {
  return WarrantyClaimDispatcherService();
});

class WarrantyClaimDispatcherService {
  /// Generates an authoritative, formal warranty claim letter compliant with Consumer Protection standards
  String generateClaimLetter({
    required WarrantyModel warranty,
    required BrandSupportInfo supportInfo,
    required String issueDescription,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customModel,
    String? customSerial,
    ClaimCategoryConfig? categoryConfig,
  }) {
    final effectiveBrand = warranty.brand?.isNotEmpty == true ? warranty.brand! : supportInfo.brandName;
    final isCustomCategory = categoryConfig != null && categoryConfig.type != ClaimCategoryType.electronics;

    final firstSpecLabel = isCustomCategory ? categoryConfig.firstSpecLabel : 'Model Number';
    final secondSpecLabel = isCustomCategory ? categoryConfig.secondSpecLabel : 'Serial Number';

    final effectiveModel = (customModel != null && customModel.isNotEmpty)
        ? customModel
        : (warranty.model?.isNotEmpty == true ? warranty.model! : 'Specified on Tax Invoice');
    final effectiveSerial = (customSerial != null && customSerial.isNotEmpty)
        ? customSerial
        : (warranty.serialNumber?.isNotEmpty == true ? warranty.serialNumber! : 'Refer to Attached Purchase Document');

    final name = customerName?.isNotEmpty == true ? customerName! : '[Customer Name]';
    final phone = customerPhone?.isNotEmpty == true ? customerPhone! : '[Contact Phone]';
    final email = customerEmail?.isNotEmpty == true ? customerEmail! : '[Contact Email]';

    final reliefPoints = isCustomCategory
        ? categoryConfig.requestedRelief.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')
        : '''1. Inspection by an authorized $effectiveBrand service technician.
2. Free-of-cost repair or replacement of defective components under warranty terms.
3. Written confirmation and ticket number acknowledging this warranty claim.''';

    final legalText = isCustomCategory
        ? '''This formal grievance is submitted in accordance with statutory consumer protections, including the Consumer Protection Act, 2019 (Section 2(47) & Chapter VI - Product Liability & Defect Redressal) along with applicable merchantability and safety standards. 

${categoryConfig.legalSubtitle}

As a verified consumer holding valid proof of purchase within the active guarantee/warranty timeline, I am legally entitled to prompt grievance resolution without unreasonable delay.'''
        : '''This warranty service request is formally filed in accordance with the express warranty terms provided at the time of purchase and applicable statutory consumer safeguards, including the Consumer Protection Act, 2019 (Section 2(47) & Chapter VI - Product Liability & Defect Redressal). 

As a verified consumer holding proof of purchase within the active warranty timeline, I am legally entitled to prompt, unhindered repair or replacement of defective components using authentic manufacturer parts without unreasonable delay.''';

    return '''
To,
Customer Support & Warranty Redressal Department
$effectiveBrand Authorized Service Operations

Subject: FORMAL WARRANTY CLAIM & SERVICE REQUEST: ${warranty.productName} (Invoice Ref: ${warranty.invoiceNumber ?? 'Attached'})

Dear Customer Service Team,

I am writing to formally submit a warranty claim regarding my $effectiveBrand product, which was purchased under express warranty and has encountered a functional defect during the valid coverage window.

PRODUCT & PURCHASE CREDENTIALS:
-----------------------------------------------------------
• Product Name: ${warranty.productName}
• Brand / Manufacturer: $effectiveBrand
• $firstSpecLabel: $effectiveModel
• $secondSpecLabel: $effectiveSerial
• Place of Purchase / Merchant: ${warranty.merchantName}
• Invoice / Receipt Number: ${warranty.invoiceNumber ?? 'Verified on record'}
• Date of Purchase: ${warranty.purchaseDate}
• Warranty Coverage Period: ${warranty.warrantyPeriod} ${warranty.warrantyUnit}
• Warranty Expiration Date: ${warranty.expiryDate}
• Claim Submission Date: ${DateTime.now().toLocal().toString().split(' ')[0]}

NATURE OF DEFECT / ISSUE DESCRIPTION:
-----------------------------------------------------------
$issueDescription

STATUTORY RIGHTS & LEGAL CITATION:
-----------------------------------------------------------
$legalText

REQUESTED RELIEF:
-----------------------------------------------------------
$reliefPoints

Attached with this communication is the original tax invoice and proof of purchase record verified via the Receipto platform.

Kindly confirm receipt of this claim and provide the service reference number along with appointment scheduling details at the earliest.

Sincerely,
$name
Phone: $phone
Email: $email
Digital Proof: Verified via Receipto Mobile Vault
''';
  }

  /// Launches the user's native email client with pre-filled To, Subject, and Body
  Future<bool> launchEmailClient({
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipientEmail.trim(),
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        return await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(emailLaunchUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  /// Opens the native phone dialer with customer care number
  Future<bool> launchPhoneDialer(String rawPhone) async {
    final cleanNumber = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        return await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(phoneUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  /// Searches Google Maps for nearest authorized service centers
  Future<bool> launchServiceCenterMaps(String query) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    try {
      if (await canLaunchUrl(mapsUri)) {
        return await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      }
      // Fallback: attempt direct launch even if package visibility restricted query check
      return await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(mapsUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  /// Copies claim letter directly to clipboard
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Shares claim packet via native share sheet (WhatsApp, Telegram, Drive, etc.)
  Future<void> shareClaimPacket({
    required String claimText,
    String? subject,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final xFile = XFile(imagePath);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [xFile],
          text: claimText,
          subject: subject ?? 'Warranty Claim Submission Packet',
        );
        return;
      } catch (_) {
        // Fallback to text share if file sharing fails
      }
    }

    // ignore: deprecated_member_use
    await Share.share(
      claimText,
      subject: subject ?? 'Warranty Claim Submission Packet',
    );
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
