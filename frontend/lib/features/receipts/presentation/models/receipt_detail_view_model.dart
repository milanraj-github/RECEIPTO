class ReceiptDetailViewModel {
  final String id;
  final String? invoiceNumber;
  final String merchant;
  final String category;
  final double amount;
  final String purchaseDate;
  final String paymentMethod;
  final int? matchScore;
  final String receiptImageUrl;
  final String currency;
  final String? gstNumber;
  final double? subtotal;
  final double? tax;
  final double? discount;
  final List<ProductItemViewModel> items;

  ReceiptDetailViewModel({
    required this.id,
    this.invoiceNumber,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.purchaseDate,
    required this.paymentMethod,
    this.matchScore,
    required this.receiptImageUrl,
    required this.currency,
    this.gstNumber,
    this.subtotal,
    this.tax,
    this.discount,
    required this.items,
  });
}

class ProductItemViewModel {
  final String name;
  final double price;
  final int qty;
  final double unitPrice;
  final bool? warrantyAvailable;
  final int? warrantyPeriod;
  final String? warrantyUnit;
  final String? warrantyExpiry;

  ProductItemViewModel({
    required this.name,
    required this.price,
    required this.qty,
    required this.unitPrice,
    this.warrantyAvailable,
    this.warrantyPeriod,
    this.warrantyUnit,
    this.warrantyExpiry,
  });
}
