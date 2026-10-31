import 'package:flutter_test/flutter_test.dart';
import 'package:receipto/core/services/ai_categorizer_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/features/ai_assistant/data/services/ai_assistant_service.dart';
import 'package:receipto/features/ai_assistant/domain/models/ai_structured_response.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _dummyClient = SupabaseClient('https://mock.supabase.co', 'fakeAnonKey');

class FakeReceiptDb extends ReceiptDatabaseService {
  final List<Map<String, dynamic>> data;
  FakeReceiptDb(this.data) : super(_dummyClient, null);

  @override
  Future<List<Map<String, dynamic>>> fetchAllReceipts({required String userId}) async {
    return data.where((r) => r['user_id'] == null || r['user_id'] == userId).toList();
  }
}

class FakeWarrantyDb extends WarrantyDatabaseService {
  final List<WarrantyModel> data;
  FakeWarrantyDb(this.data) : super(_dummyClient, null);

  @override
  Future<List<WarrantyModel>> fetchAllWarranties(String userId) async {
    return data.where((w) => w.userId == userId).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AIAssistantService assistantService;
  late AICategorizerService categorizer;
  late List<Map<String, dynamic>> testReceipts;
  late List<WarrantyModel> testWarranties;

  setUp(() {
    categorizer = AICategorizerService();

    testReceipts = [
      {
        'id': '101',
        'user_id': 'user_A',
        'merchant_name': 'Croma Electronics',
        'date': '2026-10-05',
        'grand_total': '85000.00',
        'category': 'Electronics',
        'currency': '₹',
        'receipt_items': [
          {
            'name': 'Sony WH-1000XM5 Headphones',
            'quantity': 1,
            'unit_price': 24990.0,
            'total_price': 24990.0,
            'category': 'Electronics',
          },
          {
            'name': 'USB-C Fast Charging Cable',
            'quantity': 2,
            'unit_price': 450.0,
            'total_price': 900.0,
            'category': 'Electronics',
          },
        ],
      },
      {
        'id': '102',
        'user_id': 'user_A',
        'merchant_name': 'Nature Basket',
        'date': '2026-09-15',
        'grand_total': '3200.00',
        'category': 'Groceries',
        'currency': '₹',
        'receipt_items': [
          {
            'name': 'Organic Olive Oil 1L',
            'quantity': 1,
            'unit_price': 1450.0,
            'total_price': 1450.0,
            'category': 'Groceries',
          },
          {
            'name': 'Almond Milk Pack',
            'quantity': 2,
            'unit_price': 200.0,
            'total_price': 400.0,
            'category': 'Groceries',
          },
        ],
      },
      {
        'id': '103',
        'user_id': 'user_A',
        'merchant_name': 'Zara Fashion',
        'date': '2026-09-20',
        'grand_total': '7990.00',
        'category': 'Fashion',
        'currency': '₹',
        'receipt_items': [
          {
            'name': 'Slim Fit Denim Jacket',
            'quantity': 1,
            'unit_price': 4990.0,
            'total_price': 4990.0,
            'category': 'Fashion',
          },
          {
            'name': 'Cotton Crew T-Shirt',
            'quantity': 1,
            // Test missing price
            'unit_price': null,
            'total_price': null,
            'category': 'Fashion',
          },
        ],
      },
      {
        'id': '999',
        'user_id': 'user_B', // Different user's data
        'merchant_name': 'Apple Store Paris',
        'date': '2026-10-10',
        'grand_total': '140000.00',
        'category': 'Electronics',
        'currency': '₹',
        'receipt_items': [
          {
            'name': 'MacBook Pro M3',
            'quantity': 1,
            'unit_price': 140000.0,
            'total_price': 140000.0,
            'category': 'Electronics',
          },
        ],
      },
    ];

    testWarranties = [
      WarrantyModel(
        id: 'w_1',
        userId: 'user_A',
        receiptId: '101',
        productName: 'Sony WH-1000XM5 Headphones',
        merchantName: 'Croma Electronics',
        purchaseDate: '2026-10-05',
        warrantyPeriod: 24,
        warrantyUnit: 'months',
        expiryDate: '2028-10-05',
        status: 'ACTIVE',
      ),
      WarrantyModel(
        id: 'w_2',
        userId: 'user_B',
        receiptId: '999',
        productName: 'MacBook Pro M3',
        merchantName: 'Apple Store Paris',
        purchaseDate: '2026-10-10',
        warrantyPeriod: 12,
        warrantyUnit: 'months',
        expiryDate: '2027-10-10',
        status: 'ACTIVE',
      ),
    ];

    final fakeReceiptDb = FakeReceiptDb(testReceipts);
    final fakeWarrantyDb = FakeWarrantyDb(testWarranties);
    assistantService = AIAssistantService(fakeReceiptDb, fakeWarrantyDb, categorizer);
  });

  group('Receipto Upgraded AI Assistant Test Suite', () {
    test('1. Products above a minimum price return correct line items', () async {
      final res = await assistantService.askStructured(
        'Show products above ₹2,000',
        overrideUserId: 'user_A',
      );

      expect(res.type, AIStructuredResponseType.products);
      expect(res.hasProducts, isTrue);
      // Matching items: Sony Headphones (24,990) and Denim Jacket (4,990)
      for (final p in res.products) {
        expect(p.price, isNotNull);
        expect(p.price! >= 2000.0, isTrue);
      }
      expect(res.products.any((p) => p.name.contains('Sony')), isTrue);
      expect(res.products.any((p) => p.name.contains('Denim Jacket')), isTrue);
      expect(res.products.any((p) => p.name.contains('USB-C')), isFalse);
    });

    test('2. Products below a maximum price return correct line items', () async {
      final res = await assistantService.askStructured(
        'Show products below ₹500',
        overrideUserId: 'user_A',
      );

      expect(res.hasProducts, isTrue);
      for (final p in res.products) {
        expect(p.price! <= 500.0, isTrue);
      }
      expect(res.products.any((p) => p.name.contains('Almond Milk')), isTrue);
      expect(res.products.any((p) => p.name.contains('Sony')), isFalse);
    });

    test('3. Price-range queries apply both boundaries correctly', () async {
      final res = await assistantService.askStructured(
        'Find products between ₹1,000 and ₹5,000',
        overrideUserId: 'user_A',
      );

      expect(res.hasProducts, isTrue);
      for (final p in res.products) {
        expect(p.price! >= 1000.0, isTrue);
        expect(p.price! <= 5000.0, isTrue);
      }
      expect(res.products.any((p) => p.name.contains('Olive Oil')), isTrue); // 1,450
      expect(res.products.any((p) => p.name.contains('Denim Jacket')), isTrue); // 4,990
      expect(res.products.any((p) => p.name.contains('Sony')), isFalse); // 24,990
    });

    test('4. Product queries and receipt-total queries use different fields', () async {
      // Line item price query: USB cable total is ₹900, grand total of receipt is ₹85,000
      final prodRes = await assistantService.askStructured(
        'Show products below ₹1,000',
        overrideUserId: 'user_A',
      );
      expect(prodRes.products.any((p) => p.name.contains('USB-C')), isTrue);
      expect(prodRes.products.firstWhere((p) => p.name.contains('USB-C')).price, equals(900.0));

      // Receipt total query: Receipt 101 has grand_total of ₹85,000
      final receiptRes = await assistantService.askStructured(
        'Show receipts above ₹50,000',
        overrideUserId: 'user_A',
      );
      expect(receiptRes.type, AIStructuredResponseType.receipts);
      expect(receiptRes.receipts.length, equals(1));
      expect(receiptRes.receipts.first.receiptId, equals('101'));
      expect(receiptRes.receipts.first.total, equals(85000.0));
    });

    test('5. Category filters work with actual stored category values', () async {
      final res = await assistantService.askStructured(
        'Find electronics products',
        overrideUserId: 'user_A',
      );

      expect(res.hasProducts, isTrue);
      for (final p in res.products) {
        expect(p.category.toLowerCase(), equals('electronics'));
      }
      expect(res.products.any((p) => p.name.contains('Sony')), isTrue);
      expect(res.products.any((p) => p.name.contains('Olive Oil')), isFalse);
    });

    test('6. Date filters work at month boundaries', () async {
      final res = await assistantService.askStructured(
        'Find products purchased last month',
        overrideUserId: 'user_A',
      );

      // Last month relative to Oct 2026 is Sep 2026
      if (res.hasProducts) {
        for (final p in res.products) {
          expect(p.purchaseDate?.month, equals(9));
          expect(p.purchaseDate?.year, equals(2026));
        }
      }
    });

    test('7. Combined filters work correctly', () async {
      final res = await assistantService.askStructured(
        'Show electronics products above ₹2,000',
        overrideUserId: 'user_A',
      );

      expect(res.hasProducts, isTrue);
      for (final p in res.products) {
        expect(p.category.toLowerCase(), equals('electronics'));
        expect(p.price! >= 2000.0, isTrue);
      }
      expect(res.products.length, equals(1));
      expect(res.products.first.name, contains('Sony'));
    });

    test('8. Sorting works correctly (price descending and ascending)', () async {
      final descRes = await assistantService.askStructured(
        'Show my most expensive products',
        overrideUserId: 'user_A',
      );
      expect(descRes.products.first.name, contains('Sony'));
      expect(descRes.products.first.price, equals(24990.0));

      final ascRes = await assistantService.askStructured(
        'Show my cheapest products',
        overrideUserId: 'user_A',
      );
      expect(ascRes.products.first.name, contains('Almond Milk'));
      expect(ascRes.products.first.price, equals(400.0));
    });

    test('9. Missing prices are handled without substituting receipt totals', () async {
      // In receipt 103, 'Cotton Crew T-Shirt' has null price. Grand total is 7,990.
      final res = await assistantService.askStructured(
        'Find products from Zara Fashion',
        overrideUserId: 'user_A',
      );

      final tShirt = res.products.firstWhere((p) => p.name.contains('T-Shirt'));
      // Price must NOT be substituted with 7990!
      expect(tShirt.price, isNull);
      expect(tShirt.receiptTotal, equals(7990.0));
    });

    test('10. Products with missing warranty data are not incorrectly labelled expired', () async {
      final res = await assistantService.askStructured(
        'Find products from Nature Basket',
        overrideUserId: 'user_A',
      );

      final oil = res.products.firstWhere((p) => p.name.contains('Olive Oil'));
      // No warranty was registered for Olive oil -> status should be null / NO WARRANTY, NOT 'EXPIRED'
      expect(oil.warrantyStatus, isNot(equals('EXPIRED')));
      expect(oil.warrantyStatus, isNull);
    });

    test('11. Returned product cards contain the correct receipt identifiers', () async {
      final res = await assistantService.askStructured(
        'Show products above ₹20,000',
        overrideUserId: 'user_A',
      );

      expect(res.products.first.receiptId, equals('101'));
    });

    test('12. Associated receipt ID is accurate and tappable', () async {
      final res = await assistantService.askStructured(
        'What is my most expensive product?',
        overrideUserId: 'user_A',
      );

      expect(res.products.length, equals(1));
      expect(res.products.first.receiptId, equals('101'));
      expect(res.products.first.merchantName, equals('Croma Electronics'));
    });

    test('13. Conversation follow-ups preserve the intended filters', () async {
      // Turn 1
      await assistantService.askStructured(
        'Show products above ₹1,000',
        overrideUserId: 'user_A',
      );

      // Turn 2: Follow-up "Only electronics"
      final followUpRes = await assistantService.askStructured(
        'Only electronics',
        overrideUserId: 'user_A',
      );

      expect(followUpRes.hasProducts, isTrue);
      for (final p in followUpRes.products) {
        expect(p.category.toLowerCase(), equals('electronics'));
        expect(p.price! >= 1000.0, isTrue);
      }
      expect(followUpRes.products.every((p) => p.category.toLowerCase() == 'electronics'), isTrue);

      // Turn 3: "Sort them by price"
      final sortedRes = await assistantService.askStructured(
        'Sort them by price',
        overrideUserId: 'user_A',
      );
      expect(sortedRes.products.first.price, greaterThanOrEqualTo(sortedRes.products.last.price!));

      // Turn 4: "Which is the most expensive?"
      final topRes = await assistantService.askStructured(
        'Which is the most expensive?',
        overrideUserId: 'user_A',
      );
      expect(topRes.products.length, equals(1));
      expect(topRes.products.first.name, contains('Sony'));

      // Turn 5: "Open its receipt"
      final openRes = await assistantService.askStructured(
        'Open its receipt',
        overrideUserId: 'user_A',
      );
      expect(openRes.action?.actionType, equals('openReceipt'));
      expect(openRes.action?.targetReceiptId, equals('101'));
    });

    test('14. Financial totals are calculated deterministically without double-counting', () async {
      final summaryRes = await assistantService.askStructured(
        'How much did I spend this year?',
        overrideUserId: 'user_A',
      );

      expect(summaryRes.type, equals(AIStructuredResponseType.summary));
      expect(summaryRes.summary, isNotNull);
      // User A receipts: 85,000 + 3,200 + 7,990 = 96,190
      expect(summaryRes.summary!.totalSpending, equals(96190.0));
      expect(summaryRes.summary!.transactionCount, equals(3));
    });

    test('15. Multi-user isolation: User A cannot retrieve User B records', () async {
      final userARes = await assistantService.askStructured(
        'Show all products',
        overrideUserId: 'user_A',
      );

      // User A must NOT see 'MacBook Pro M3' from User B
      expect(userARes.products.any((p) => p.name.contains('MacBook Pro M3')), isFalse);
      expect(userARes.products.any((p) => p.merchantName.contains('Paris')), isFalse);

      final userBRes = await assistantService.askStructured(
        'Show all products',
        overrideUserId: 'user_B',
      );

      // User B must ONLY see their own MacBook
      expect(userBRes.products.length, equals(1));
      expect(userBRes.products.first.name, contains('MacBook Pro M3'));
      expect(userBRes.products.first.receiptId, equals('999'));
    });

    test('16. Legacy ask() method continues to return plain text response', () async {
      final text = await assistantService.ask(
        'Show products above ₹2,000',
        overrideUserId: 'user_A',
      );

      expect(text, isNotEmpty);
      expect(text, contains('product'));
    });

    test('17. Warranty search returns confirmed active warranties', () async {
      final res = await assistantService.askStructured(
        'Show products under warranty',
        overrideUserId: 'user_A',
      );

      expect(res.hasProducts, isTrue);
      expect(res.products.length, equals(1));
      expect(res.products.first.name, contains('Sony'));
      expect(res.products.first.warrantyStatus, equals('ACTIVE'));
    });

    test('18. Category breakdown aggregates spending accurately', () async {
      final res = await assistantService.askStructured(
        'Show category breakdown',
        overrideUserId: 'user_A',
      );

      expect(res.type, equals(AIStructuredResponseType.categories));
      expect(res.categories.isNotEmpty, isTrue);
      final electronicsCat = res.categories.firstWhere((c) => c.category == 'Electronics');
      expect(electronicsCat.amount, equals(85000.0));
    });

    test('19. What other items were purchased on same receipt is supported', () async {
      final res = await assistantService.askStructured(
        'Show products above ₹20,000',
        overrideUserId: 'user_A',
      );

      final sonyItem = res.products.first;
      // Other items on receipt 101 should include the USB-C cable
      expect(sonyItem.otherItemsInReceipt, contains('USB-C Fast Charging Cable'));
    });

    test('20. Empty results return courteous guidance without hallucinated items', () async {
      final res = await assistantService.askStructured(
        'Show products above ₹1,000,000',
        overrideUserId: 'user_A',
      );

      expect(res.type, equals(AIStructuredResponseType.empty));
      expect(res.products.isEmpty, isTrue);
      expect(res.text, contains('No products found'));
    });

    test('21. Natural greetings like "hy", "hi", "hello" return courteous greeting without querying products', () async {
      final resHy = await assistantService.askStructured('hy', overrideUserId: 'user_A');
      expect(resHy.type, equals(AIStructuredResponseType.textOnly));
      expect(resHy.hasProducts, isFalse);
      expect(resHy.hasReceipts, isFalse);
      expect(resHy.text, contains('Hello!'));

      final resHi = await assistantService.askStructured('hi', overrideUserId: 'user_A');
      expect(resHi.type, equals(AIStructuredResponseType.textOnly));
      expect(resHi.hasProducts, isFalse);
      expect(resHi.text, contains('Hello!'));

      final resHello = await assistantService.askStructured('hello', overrideUserId: 'user_A');
      expect(resHello.type, equals(AIStructuredResponseType.textOnly));
      expect(resHello.text, contains('Hello!'));
    });

    test('22. Identity inquiries like "who are you" return assistant identity and features', () async {
      final res = await assistantService.askStructured('who are you', overrideUserId: 'user_A');
      expect(res.type, equals(AIStructuredResponseType.textOnly));
      expect(res.hasProducts, isFalse);
      expect(res.text, contains('Receipto AI Agent'));
    });

    test('23. Greetings with financial intents correctly process receipt queries', () async {
      final res = await assistantService.askStructured('hi show my receipts', overrideUserId: 'user_A');
      expect(res.hasReceipts, isTrue);
      expect(res.receipts.isNotEmpty, isTrue);
    });
  });
}
