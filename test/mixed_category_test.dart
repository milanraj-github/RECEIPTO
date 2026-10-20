import 'package:flutter_test/flutter_test.dart';
import 'package:receipto/features/receipts/presentation/widgets/receipt_card_item.dart';
import 'package:flutter/material.dart';

void main() {
  group('Conditional Category Highlighting for Mixed Receipts', () {
    test('Identifies mixed-category receipts with >= 2 distinct categories', () {
      final mixedReceipt = ReceiptInventoryItem(
        id: '1',
        merchant: 'Supermarket Purchase',
        date: '2026-10-20',
        amount: 3310.0,
        category: 'Others',
        matchScore: 100,
        icon: Icons.receipt_long,
        items: [
          ReceiptInventorySubItem(name: 'Headphones', price: 2000.0, category: 'Electronics'),
          ReceiptInventorySubItem(name: 'Milk', price: 60.0, category: 'Groceries'),
          ReceiptInventorySubItem(name: 'Rice', price: 200.0, category: 'Groceries'),
          ReceiptInventorySubItem(name: 'Pizza', price: 400.0, category: 'Food & Dining'),
          ReceiptInventorySubItem(name: 'Shampoo', price: 150.0, category: 'Beauty & Personal Care'),
          ReceiptInventorySubItem(name: 'Bread', price: 100.0, category: 'Groceries'),
          ReceiptInventorySubItem(name: 'Other Item', price: 400.0, category: 'Others'),
        ],
      );

      expect(mixedReceipt.isMixedCategory, isTrue);
    });

    test('Identifies normal single-category receipts as NOT mixed', () {
      final electronicsReceipt = ReceiptInventoryItem(
        id: '2',
        merchant: 'Electronics Store',
        date: '2026-10-20',
        amount: 62000.0,
        category: 'Electronics',
        matchScore: 100,
        icon: Icons.devices,
        items: [
          ReceiptInventorySubItem(name: 'Laptop', price: 60000.0, category: 'Computers'),
          ReceiptInventorySubItem(name: 'Mouse', price: 800.0, category: 'Computers'),
          ReceiptInventorySubItem(name: 'Keyboard', price: 1200.0, category: 'Computers'),
        ],
      );

      expect(electronicsReceipt.isMixedCategory, isFalse);

      final groceryReceipt = ReceiptInventoryItem(
        id: '3',
        merchant: 'Local Kirana',
        date: '2026-10-20',
        amount: 360.0,
        category: 'Groceries',
        matchScore: 100,
        icon: Icons.shopping_cart,
        items: [
          ReceiptInventorySubItem(name: 'Milk', price: 60.0, category: 'Groceries'),
          ReceiptInventorySubItem(name: 'Rice', price: 200.0, category: 'Groceries'),
          ReceiptInventorySubItem(name: 'Bread', price: 100.0, category: 'Groceries'),
        ],
      );

      expect(groceryReceipt.isMixedCategory, isFalse);
    });

    test('Preserves normal behavior when category information is missing or insufficient', () {
      final emptyReceipt = ReceiptInventoryItem(
        id: '4',
        merchant: 'Quick Stop',
        date: '2026-10-20',
        amount: 50.0,
        category: 'Shopping',
        matchScore: 100,
        icon: Icons.shopping_bag,
        items: [],
      );
      expect(emptyReceipt.isMixedCategory, isFalse);

      final singleItemReceipt = ReceiptInventoryItem(
        id: '5',
        merchant: 'Quick Stop',
        date: '2026-10-20',
        amount: 50.0,
        category: 'Shopping',
        matchScore: 100,
        icon: Icons.shopping_bag,
        items: [
          ReceiptInventorySubItem(name: 'Snack', price: 50.0, category: 'Groceries'),
        ],
      );
      expect(singleItemReceipt.isMixedCategory, isFalse);
    });

    test('isCategoryMatch correctly checks matching for highlighting and filtering', () {
      // Direct and canonical matching
      expect(ReceiptInventoryItem.isCategoryMatch('Electronics', 'Electronics'), isTrue);
      expect(ReceiptInventoryItem.isCategoryMatch('Computers', 'Electronics'), isTrue);
      expect(ReceiptInventoryItem.isCategoryMatch('Mobile & Gadgets', 'Electronics'), isTrue);
      expect(ReceiptInventoryItem.isCategoryMatch('Food & Dining', 'Food'), isTrue);
      expect(ReceiptInventoryItem.isCategoryMatch('Grocery', 'Groceries'), isTrue);
      expect(ReceiptInventoryItem.isCategoryMatch('Beauty & Personal Care', 'Beauty'), isTrue);
      expect(ReceiptInventoryItem.isCategoryMatch('Healthcare', 'Medical'), isTrue);

      // Non-matching
      expect(ReceiptInventoryItem.isCategoryMatch('Milk', 'Electronics'), isFalse);
      expect(ReceiptInventoryItem.isCategoryMatch('Groceries', 'Electronics'), isFalse);
      expect(ReceiptInventoryItem.isCategoryMatch('Groceries', 'Fuel'), isFalse);
    });

    test('Mixed receipt item highlighting discrimination across categories', () {
      final mixedItems = [
        ReceiptInventorySubItem(name: 'Headphones', price: 2000.0, category: 'Electronics'),
        ReceiptInventorySubItem(name: 'Milk', price: 60.0, category: 'Groceries'),
        ReceiptInventorySubItem(name: 'Rice', price: 200.0, category: 'Groceries'),
        ReceiptInventorySubItem(name: 'Pizza', price: 400.0, category: 'Food & Dining'),
        ReceiptInventorySubItem(name: 'Shampoo', price: 150.0, category: 'Beauty & Personal Care'),
        ReceiptInventorySubItem(name: 'Bread', price: 100.0, category: 'Groceries'),
        ReceiptInventorySubItem(name: 'Other Item', price: 400.0, category: 'Others'),
      ];

      // When Electronics is selected: ONLY Headphones highlighted
      final electronicsMatches = mixedItems
          .where((i) => ReceiptInventoryItem.isCategoryMatch(i.category, 'Electronics'))
          .map((i) => i.name)
          .toList();
      expect(electronicsMatches, equals(['Headphones']));

      // When Groceries is selected: Milk, Rice, Bread highlighted
      final groceryMatches = mixedItems
          .where((i) => ReceiptInventoryItem.isCategoryMatch(i.category, 'Groceries'))
          .map((i) => i.name)
          .toList();
      expect(groceryMatches, equals(['Milk', 'Rice', 'Bread']));

      // When Food is selected: Pizza highlighted
      final foodMatches = mixedItems
          .where((i) => ReceiptInventoryItem.isCategoryMatch(i.category, 'Food'))
          .map((i) => i.name)
          .toList();
      expect(foodMatches, equals(['Pizza']));

      // When Beauty is selected: Shampoo highlighted
      final beautyMatches = mixedItems
          .where((i) => ReceiptInventoryItem.isCategoryMatch(i.category, 'Beauty'))
          .map((i) => i.name)
          .toList();
      expect(beautyMatches, equals(['Shampoo']));

      // When Fuel is selected: None highlighted
      final fuelMatches = mixedItems
          .where((i) => ReceiptInventoryItem.isCategoryMatch(i.category, 'Fuel'))
          .map((i) => i.name)
          .toList();
      expect(fuelMatches, isEmpty);
    });
  });
}
