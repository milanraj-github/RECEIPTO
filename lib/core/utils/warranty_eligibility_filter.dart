class WarrantyEligibilityFilter {
  // Categories that are explicitly warranty-eligible
  static const Set<String> _eligibleCategories = {
    'electronics',
    'mobile & gadgets',
    'computers',
    'home appliances',
    'accessories',
    'automotive',
    'utilities',
    'furniture',
    'sports',
  };

  // Categories that are explicitly NOT warranty-eligible
  static const Set<String> _ineligibleCategories = {
    'groceries',
    'grocery',
    'food & dining',
    'food',
    'medical',
    'healthcare',
    'pharmacy',
    'beauty & personal care',
    'books',
    'office supplies',
    'daily essentials',
    'kitchen consumables',
  };

  // Keywords that strongly indicate a warranty-eligible product
  static const List<String> _eligibleKeywords = [
    'laptop', 'desktop', 'computer', 'monitor', 'screen', 'tv', 'television',
    'mobile', 'phone', 'smartphone', 'tablet', 'ipad', 'watch', 'smartwatch',
    'headphone', 'headset', 'earbud', 'earphone', 'airpod', 'speaker', 'soundbar',
    'keyboard', 'mouse', 'printer', 'scanner', 'camera', 'webcam', 'router',
    'modem', 'powerbank', 'power bank', 'charger', 'adapter', 'harddisk', 'hard disk',
    'hdd', 'ssd', 'pendrive', 'flash drive', 'memory card', 'graphics card', 'gpu',
    'motherboard', 'cpu', 'processor', 'ram', 'psu', 'cabinet', 'gaming', 'console',
    'playstation', 'xbox', 'nintendo', 'joystick', 'controller',
    'ac', 'air conditioner', 'refrigerator', 'fridge', 'microwave', 'oven',
    'washing machine', 'dishwasher', 'dryer', 'mixer', 'blender', 'grinder',
    'air fryer', 'purifier', 'water purifier', 'geyser', 'water heater',
    'chimney', 'cooktop', 'induction', 'kettle', 'vacuum', 'iron',
    'trimmer', 'shaver', 'hair dryer', 'fan', 'ceiling fan', 'inverter',
    'battery', 'ups', 'stabilizer', 'projector', 'drone', 'smart home',
    'security camera', 'cctv', 'smart lock', 'treadmill', 'cycle', 'e-bike',
    'gadget', 'appliance', 'hardware', 'device', 'electronic', 'instrument'
  ];

  // Keywords that indicate non-warranty consumables/items
  static const List<String> _ineligibleKeywords = [
    'rice', 'wheat', 'flour', 'atta', 'dal', 'pulse', 'grain', 'sugar', 'salt',
    'oil', 'ghee', 'butter', 'milk', 'curd', 'cheese', 'paneer', 'yogurt',
    'bread', 'biscuit', 'cookie', 'snack', 'chip', 'chocolate', 'candy',
    'fruit', 'apple', 'banana', 'orange', 'grape', 'mango',
    'vegetable', 'potato', 'onion', 'tomato', 'garlic', 'ginger',
    'meat', 'chicken', 'fish', 'mutton', 'egg',
    'juice', 'water', 'soda', 'drink', 'beverage', 'tea', 'coffee',
    'soap', 'shampoo', 'conditioner', 'lotion', 'cream', 'wash', 'toothpaste',
    'brush', 'tissue', 'towel', 'wipe', 'detergent', 'cleaner', 'sanitizer',
    'medicine', 'capsule', 'syrup', 'ointment', 'bandage',
    'pen', 'pencil', 'eraser', 'notebook', 'paper', 'file', 'folder', 'stapler',
    'shirt', 't-shirt', 'pant', 'jeans', 'trouser', 'dress', 'top', 'socks',
    'shoe', 'slipper', 'sandal', 'boot'
  ];

  /// Evaluates whether an item is eligible for manual warranty entry.
  static bool isEligible(String productName, {String? category}) {
    final nameLower = productName.trim().toLowerCase();
    final catLower = category?.trim().toLowerCase() ?? '';

    // Check ineligible categories first
    if (_ineligibleCategories.contains(catLower)) {
      final hasElectronicsKeyword = _eligibleKeywords.any((kw) => nameLower.contains(kw));
      if (!hasElectronicsKeyword) {
        return false;
      }
    }

    // Check ineligible keywords
    final hasIneligibleKeyword = _ineligibleKeywords.any((kw) => nameLower.contains(kw));
    final hasEligibleKeyword = _eligibleKeywords.any((kw) => nameLower.contains(kw));

    if (hasIneligibleKeyword && !hasEligibleKeyword) {
      return false;
    }

    // Check eligible categories
    if (_eligibleCategories.contains(catLower)) {
      return true;
    }

    // Check eligible keywords in product name
    if (hasEligibleKeyword) {
      return true;
    }

    // Heuristic match for technical model numbers or electronics indicators
    final techReg = RegExp(r'\b(pro|max|ultra|wireless|bluetooth|usb|hdmi|type-c|led|oled|4k|5g|v|w|gb|tb|mah)\b', caseSensitive: false);
    if (techReg.hasMatch(nameLower)) {
      return true;
    }

    return false;
  }
}
