import 'package:flutter_test/flutter_test.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/warranty/data/services/brand_support_directory.dart';
import 'package:receipto/features/warranty/data/services/warranty_claim_dispatcher_service.dart';
import 'package:receipto/features/warranty/data/services/warranty_claim_categories.dart';

void main() {
  group('AI 1-Click Warranty Claim Dispatcher Tests', () {
    late WarrantyClaimDispatcherService dispatcherService;

    setUp(() {
      dispatcherService = WarrantyClaimDispatcherService();
    });

    test('1. Resolves official support details for recognized brands', () {
      final samsungInfo = BrandSupportDirectory.resolveBrandSupport(
        brand: 'Samsung',
        productName: 'EcoBubble 8kg Front Load Washing Machine',
      );

      expect(samsungInfo.brandName, 'Samsung');
      expect(samsungInfo.supportEmail, 'support.india@samsung.com');
      expect(samsungInfo.tollFreePhone, contains('1800 40 7267864'));
      expect(samsungInfo.serviceCenterQuery, contains('Samsung Authorized Service Center'));
      expect(samsungInfo.isVerified, true);

      final appleInfo = BrandSupportDirectory.resolveBrandSupport(
        productName: 'Apple MacBook Pro M3 Max 16-inch',
      );
      expect(appleInfo.brandName, 'Apple');
      expect(appleInfo.supportEmail, 'service@apple.com');
      expect(appleInfo.tollFreePhone, contains('000800 1009009'));
      expect(appleInfo.isVerified, true);

      final lgInfo = BrandSupportDirectory.resolveBrandSupport(
        brand: 'LG',
        productName: 'LG Smart Inverter 260L Refrigerator',
      );
      expect(lgInfo.brandName, 'LG');
      expect(lgInfo.supportEmail, 'serviceindia@lge.com');
      expect(lgInfo.tollFreePhone, '1800 315 9999');
      expect(lgInfo.isVerified, true);
    });

    test('2. Inferred brand detection from product and merchant name tokens', () {
      final inferredBoat = BrandSupportDirectory.resolveBrandSupport(
        productName: 'boAt Airdopes 141 Bluetooth Earbuds',
        merchantName: 'Croma Electronics',
      );
      expect(inferredBoat.brandName, 'boAt');
      expect(inferredBoat.supportEmail, 'info@imaginemarketingindia.com');
      expect(inferredBoat.isVerified, true);

      final inferredSony = BrandSupportDirectory.resolveBrandSupport(
        productName: 'Sony WH-1000XM5 Wireless Headphones',
        merchantName: 'Reliance Digital',
      );
      expect(inferredSony.brandName, 'Sony');
      expect(inferredSony.supportEmail, 'sonyindia.care@sony.com');
      expect(inferredSony.isVerified, true);
    });

    test('3. Gracefully handles unlisted / custom brands', () {
      final unlisted = BrandSupportDirectory.resolveBrandSupport(
        productName: 'AeroCraft Drone 4K Edition',
      );
      expect(unlisted.brandName, 'AeroCraft');
      expect(unlisted.supportEmail, isNull);
      expect(unlisted.tollFreePhone, isNull);
      expect(unlisted.isVerified, false);
      expect(unlisted.serviceCenterQuery, contains('AeroCraft Authorized Service Center near me'));
    });

    test('4. Generates a formal, legally backed Consumer Protection Act claim letter', () {
      final warranty = WarrantyModel(
        id: '101',
        userId: 'usr_test_1',
        productName: 'Samsung 8kg Washing Machine',
        merchantName: 'Reliance Digital Store #42',
        invoiceNumber: 'INV-2026-8899',
        purchaseDate: '2026-01-15',
        warrantyPeriod: 2,
        warrantyUnit: 'years',
        expiryDate: '2028-01-15',
        status: 'ACTIVE',
        brand: 'Samsung',
        model: 'WW80T504DAX',
        serialNumber: 'SN-SAMS-998811',
      );

      final supportInfo = BrandSupportDirectory.resolveBrandSupport(
        brand: warranty.brand,
        productName: warranty.productName,
      );

      final claimLetter = dispatcherService.generateClaimLetter(
        warranty: warranty,
        supportInfo: supportInfo,
        issueDescription: 'The washing machine motor is producing grinding noises and stops during spin cycle.',
        customerName: 'Milan Raj',
        customerPhone: '+91 98765 43210',
        customerEmail: 'milan@example.com',
      );

      // Verify essential credentials are present
      expect(claimLetter, contains('Samsung'));
      expect(claimLetter, contains('WW80T504DAX'));
      expect(claimLetter, contains('SN-SAMS-998811'));
      expect(claimLetter, contains('INV-2026-8899'));
      expect(claimLetter, contains('Reliance Digital Store #42'));
      expect(claimLetter, contains('2026-01-15'));
      expect(claimLetter, contains('2028-01-15'));
      expect(claimLetter, contains('Milan Raj'));
      expect(claimLetter, contains('+91 98765 43210'));
      expect(claimLetter, contains('milan@example.com'));

      // Verify the issue description
      expect(claimLetter, contains('The washing machine motor is producing grinding noises'));

      // Verify statutory consumer protection citation
      expect(claimLetter, contains('Consumer Protection Act, 2019'));
      expect(claimLetter, contains('Section 2(47) & Chapter VI'));

      // Verify formal relief request points
      expect(claimLetter, contains('1. Inspection by an authorized Samsung service technician.'));
      expect(claimLetter, contains('2. Free-of-cost repair or replacement of defective components'));
      expect(claimLetter, contains('3. Written confirmation and ticket number'));
      expect(claimLetter, contains('Receipto Mobile Vault'));
    });

    test('5. Detects grocery category for Nestle Curd and provides food-specific defect symptoms & claims', () {
      final curdCategory = WarrantyClaimCategories.detectCategory(
        productName: 'Nestle Curd (400 g)',
        brand: 'Nestle',
        merchantName: 'Blinkit Instant Commerce',
      );

      expect(curdCategory.type, ClaimCategoryType.groceries);
      expect(curdCategory.displayName, 'Groceries & FMCG');
      expect(curdCategory.firstSpecLabel, 'Batch / Lot Number');
      expect(curdCategory.secondSpecLabel, 'Mfg / Expiry Date');
      expect(curdCategory.symptoms.any((s) => s.title.contains('Spoiled')), true);
      expect(curdCategory.symptoms.any((s) => s.title.contains('Foreign Object')), true);
      expect(curdCategory.symptoms.any((s) => s.title.contains('FSSAI')), true);

      final warranty = WarrantyModel(
        id: '202',
        userId: 'usr_test_curd',
        productName: 'Nestle Curd (400 g)',
        merchantName: 'Blinkit Instant Commerce',
        invoiceNumber: 'BLK-9988-CURD',
        purchaseDate: '2026-10-20',
        warrantyPeriod: 7,
        warrantyUnit: 'days',
        expiryDate: '2026-10-27',
        status: 'ACTIVE',
        brand: 'Nestle',
      );

      final supportInfo = BrandSupportDirectory.resolveBrandSupport(
        brand: warranty.brand,
        productName: warranty.productName,
      );

      expect(supportInfo.supportEmail, 'wecare@in.nestle.com');
      expect(supportInfo.tollFreePhone, '1800 103 1947');

      final claimLetter = dispatcherService.generateClaimLetter(
        warranty: warranty,
        supportInfo: supportInfo,
        issueDescription: 'The curd was completely spoiled and fermented upon opening prior to the best before date.',
        customerName: 'Milan Raj',
        customerPhone: '+91 98765 43210',
        customerEmail: 'milan@example.com',
        customModel: 'BATCH-N26-OCT',
        customSerial: 'Best Before 27-Oct-2026',
        categoryConfig: curdCategory,
      );

      // Verify grocery fields
      expect(claimLetter, contains('Nestle'));
      expect(claimLetter, contains('Nestle Curd (400 g)'));
      expect(claimLetter, contains('Batch / Lot Number: BATCH-N26-OCT'));
      expect(claimLetter, contains('Mfg / Expiry Date: Best Before 27-Oct-2026'));
      expect(claimLetter, contains('The curd was completely spoiled and fermented'));
      expect(claimLetter, contains('Food Safety and Standards Act'));
      expect(claimLetter, contains('Immediate product replacement or full refund'));
      expect(claimLetter, contains('Batch quality audit and defect investigation'));
    });
  });
}
