class ClaimSymptomPreset {
  final String title;
  final String detailedDescription;

  const ClaimSymptomPreset({
    required this.title,
    required this.detailedDescription,
  });
}

enum ClaimCategoryType {
  groceries,
  electronics,
  fashion,
  automotive,
  general,
}

class ClaimCategoryConfig {
  final ClaimCategoryType type;
  final String displayName;
  final String firstSpecLabel;
  final String firstSpecHint;
  final String secondSpecLabel;
  final String secondSpecHint;
  final String statutoryCitation;
  final String legalSubtitle;
  final List<String> requestedRelief;
  final List<ClaimSymptomPreset> symptoms;

  const ClaimCategoryConfig({
    required this.type,
    required this.displayName,
    required this.firstSpecLabel,
    required this.firstSpecHint,
    required this.secondSpecLabel,
    required this.secondSpecHint,
    required this.statutoryCitation,
    required this.legalSubtitle,
    required this.requestedRelief,
    required this.symptoms,
  });
}

class WarrantyClaimCategories {
  static const ClaimCategoryConfig groceries = ClaimCategoryConfig(
    type: ClaimCategoryType.groceries,
    displayName: 'Groceries & FMCG',
    firstSpecLabel: 'Batch / Lot Number',
    firstSpecHint: 'e.g. BATCH-2409A',
    secondSpecLabel: 'Mfg / Expiry Date',
    secondSpecHint: 'e.g. Best Before 25-Oct-2026',
    statutoryCitation: 'Consumer Protection Act, 2019 & Food Safety (FSSAI) Standards',
    legalSubtitle:
        'Claim invokes statutory protections under Section 2(47) & Food Safety and Standards Act, 2006 for adulterated, spoiled, or non-conforming consumable goods.',
    requestedRelief: [
      'Immediate product replacement or full refund of the purchase price.',
      'Batch quality audit and defect investigation by manufacturer Quality Assurance.',
      'Formal written grievance acknowledgement and service ticket reference.',
    ],
    symptoms: [
      ClaimSymptomPreset(
        title: 'Spoiled / Fermented / Sour',
        detailedDescription:
            'The food product was spoiled, fermented, sour, or curdled prior to or immediately upon opening within the declared shelf life, rendering it unfit for consumption.',
      ),
      ClaimSymptomPreset(
        title: 'Foreign Object / Contaminant',
        detailedDescription:
            'Discovered foreign matter, physical debris, or contamination inside the sealed packaging, posing a food hygiene and safety hazard.',
      ),
      ClaimSymptomPreset(
        title: 'Foul Odor / Mold / Discoloration',
        detailedDescription:
            'Product displays an abnormal putrid odor, unnatural discoloration, or visible mold growth despite valid storage.',
      ),
      ClaimSymptomPreset(
        title: 'Broken Seal / Packaging Leak',
        detailedDescription:
            'The packaging arrived with a damaged, punctured, or compromised hermetic seal, resulting in product leakage and spoilage.',
      ),
      ClaimSymptomPreset(
        title: 'Short Weight / Net Quantity Defect',
        detailedDescription:
            'The actual net product quantity/weight is materially lower than the declared weight on the label (Legal Metrology Act violation).',
      ),
      ClaimSymptomPreset(
        title: 'FSSAI Safety Non-Compliance',
        detailedDescription:
            'Product quality fails to comply with standard statutory food safety, labeling declarations, or consumable health standards.',
      ),
    ],
  );

  static const ClaimCategoryConfig electronics = ClaimCategoryConfig(
    type: ClaimCategoryType.electronics,
    displayName: 'Electronics & Appliances',
    firstSpecLabel: 'Model Number',
    firstSpecHint: 'e.g. WW80T504DAN',
    secondSpecLabel: 'Serial Number',
    secondSpecHint: 'e.g. S/N: 049830291',
    statutoryCitation: 'Consumer Protection Act, 2019 Citation Included',
    legalSubtitle:
        'Claim invokes statutory protections under Section 2(47) & Chapter VI for manufacturing defect redressal and authentic manufacturer part replacement.',
    requestedRelief: [
      'Inspection by an authorized service technician.',
      'Free-of-cost repair or replacement of defective components under warranty terms.',
      'Written confirmation and ticket number acknowledging this warranty claim.',
    ],
    symptoms: [
      ClaimSymptomPreset(
        title: 'Device Not Powering On',
        detailedDescription:
            'The device stopped powering on during normal indoor usage. There is no indicator light and it remains completely unresponsive.',
      ),
      ClaimSymptomPreset(
        title: 'Display / Screen Failure',
        detailedDescription:
            'The display screen has malfunctioned, showing horizontal/vertical lines, flickering, or dead pixels without physical impact.',
      ),
      ClaimSymptomPreset(
        title: 'Battery / Charging Issue',
        detailedDescription:
            'The product fails to retain battery charge, drains excessively fast, or refuses to charge with original accessories.',
      ),
      ClaimSymptomPreset(
        title: 'Excessive Overheating',
        detailedDescription:
            'The unit experiences abnormal thermal buildup during minimal usage, leading to automatic protective thermal shutdowns.',
      ),
      ClaimSymptomPreset(
        title: 'Audio / Sound Distortion',
        detailedDescription:
            'The integrated speakers or audio outputs suffer from severe cracking, static distortion, or zero audio output.',
      ),
      ClaimSymptomPreset(
        title: 'Motor / Mechanical Failure',
        detailedDescription:
            'The internal motor, compressor, or drive mechanism has seized or generates loud grinding friction noise during cycle operation.',
      ),
      ClaimSymptomPreset(
        title: 'Physical Hardware Defect',
        detailedDescription:
            'A structural hardware component, port, hinge, or fastener has detached or failed under standard manufacturer operating conditions.',
      ),
      ClaimSymptomPreset(
        title: 'Performance & Freezing',
        detailedDescription:
            'The firmware repeatedly freezes, hangs, or crashes during routine operation, rendering the unit unusable.',
      ),
    ],
  );

  static const ClaimCategoryConfig fashion = ClaimCategoryConfig(
    type: ClaimCategoryType.fashion,
    displayName: 'Fashion & Apparel',
    firstSpecLabel: 'Style / Article Code',
    firstSpecHint: 'e.g. ART-9021',
    secondSpecLabel: 'Size / Color Variant',
    secondSpecHint: 'e.g. UK 9 / Navy',
    statutoryCitation: 'Consumer Protection Act, 2019 - Merchantable Quality',
    legalSubtitle:
        'Claim invokes statutory consumer safeguards under Section 2(47) regarding premature material wear, color fastness, and manufacturing craftsmanship.',
    requestedRelief: [
      'Immediate product replacement or store credit / full refund.',
      'Prepaid reverse pickup arranged at customer address.',
      'Formal grievance reference ticket confirming resolution timeline.',
    ],
    symptoms: [
      ClaimSymptomPreset(
        title: 'Fabric Tear / Stitching Failure',
        detailedDescription:
            'Seams or stitching unraveled or split under standard gentle wear without excessive physical stress.',
      ),
      ClaimSymptomPreset(
        title: 'Color Bleed / Severe Fading',
        detailedDescription:
            'Severe dye loss, bleeding, or uneven patchiness occurred after following the manufacturer care label instructions.',
      ),
      ClaimSymptomPreset(
        title: 'Zipper / Button Hardware Broken',
        detailedDescription:
            'Zipper teeth, slider, buckle, or metallic fastener detached or jammed during ordinary operation.',
      ),
      ClaimSymptomPreset(
        title: 'Sole Detachment / Footwear Flaw',
        detailedDescription:
            'The outer sole or upper material has detached, peeled, or cracked from the footbed within the coverage window.',
      ),
      ClaimSymptomPreset(
        title: 'Severe Shrinkage / Distortion',
        detailedDescription:
            'Garment underwent severe dimensional shrinkage or deformation despite washing according to care instructions.',
      ),
      ClaimSymptomPreset(
        title: 'Material Flaw / Pilling Defect',
        detailedDescription:
            'Fabric developed abnormal fiber thinning, severe pilling, or material flaws inconsistent with genuine product quality.',
      ),
    ],
  );

  static const ClaimCategoryConfig automotive = ClaimCategoryConfig(
    type: ClaimCategoryType.automotive,
    displayName: 'Automotive & Parts',
    firstSpecLabel: 'Part / Item Number',
    firstSpecHint: 'e.g. PART-8823B',
    secondSpecLabel: 'Vehicle Reg / VIN',
    secondSpecHint: 'e.g. MH02AB1234',
    statutoryCitation: 'Consumer Protection Act, 2019 - Product Liability',
    legalSubtitle:
        'Claim invokes statutory protections under Chapter VI (Product Liability) for component failure and express automotive manufacturer warranty compliance.',
    requestedRelief: [
      'Pro-rata or 100% free warranty replacement in accordance with warranty terms.',
      'Technical diagnostic test report by authorized service technician.',
      'Formal docket reference number acknowledging this claim.',
    ],
    symptoms: [
      ClaimSymptomPreset(
        title: 'Battery Dead / No Voltage',
        detailedDescription:
            'Automotive battery failed open circuit voltage test and fails to crank the vehicle within the active warranty window.',
      ),
      ClaimSymptomPreset(
        title: 'Tire Bulge / Tread Separation',
        detailedDescription:
            'Tire developed structural sidewall bulge, ply separation, or uneven cracking under normal highway operating pressure.',
      ),
      ClaimSymptomPreset(
        title: 'Mechanical Component Failure',
        detailedDescription:
            'Mechanical automotive component sheared, cracked, or jammed during ordinary vehicle operation.',
      ),
      ClaimSymptomPreset(
        title: 'Electrical / Sensor Malfunction',
        detailedDescription:
            'Sensor or electronic control module generates persistent fault diagnostic codes and fails standard inspection.',
      ),
    ],
  );

  static const ClaimCategoryConfig general = ClaimCategoryConfig(
    type: ClaimCategoryType.general,
    displayName: 'General Merchandise',
    firstSpecLabel: 'Item Code / SKU',
    firstSpecHint: 'e.g. SKU-10492',
    secondSpecLabel: 'Serial / Lot Number',
    secondSpecHint: 'e.g. LOT-4481',
    statutoryCitation: 'Consumer Protection Act, 2019 Citation Included',
    legalSubtitle:
        'Claim invokes statutory protections under Section 2(47) & Chapter VI for manufacturing defect redressal and merchantable quality.',
    requestedRelief: [
      'Inspection and assessment by authorized product redressal team.',
      'Free-of-cost repair, replacement, or full refund as appropriate under warranty.',
      'Written confirmation and grievance reference number.',
    ],
    symptoms: [
      ClaimSymptomPreset(
        title: 'Manufacturing / Material Defect',
        detailedDescription:
            'The product has developed a material defect during ordinary intended use, falling short of merchantable quality.',
      ),
      ClaimSymptomPreset(
        title: 'Broken / Damaged on Arrival',
        detailedDescription:
            'The item suffered internal component failure or arrived with undisclosed physical flaws.',
      ),
      ClaimSymptomPreset(
        title: 'Missing Components / Incomplete',
        detailedDescription:
            'Essential accessories or core parts were omitted from the packaging, impairing standard utility.',
      ),
      ClaimSymptomPreset(
        title: 'Premature Wear / Structural Failure',
        detailedDescription:
            'Structural frame, joint, or functional mechanism collapsed or degraded prematurely under normal usage.',
      ),
      ClaimSymptomPreset(
        title: 'Mismatch from Description',
        detailedDescription:
            'Delivered product differs materially in specifications and performance from the merchant warranty.',
      ),
    ],
  );

  static const List<ClaimCategoryConfig> allConfigs = [
    groceries,
    electronics,
    fashion,
    automotive,
    general,
  ];

  /// Intelligently infers the most appropriate claim category for a product
  static ClaimCategoryConfig detectCategory({
    required String productName,
    String? merchantName,
    String? brand,
  }) {
    final lowerProduct = productName.toLowerCase();
    final lowerMerchant = (merchantName ?? '').toLowerCase();
    final lowerBrand = (brand ?? '').toLowerCase();
    final combined = '$lowerProduct $lowerMerchant $lowerBrand';

    // 1. Groceries, Dairy, Food & FMCG
    const groceryKeywords = [
      'curd', 'dahi', 'yogurt', 'milk', 'paneer', 'butter', 'cheese', 'ghee',
      'atta', 'flour', 'rice', 'dal', 'oil', 'sugar', 'salt', 'spice', 'masala',
      'biscuit', 'cookie', 'chip', 'chips', 'snack', 'chocolate', 'juice', 'drink',
      'bread', 'sauce', 'ketchup', 'cereal', 'maggi', 'noodle', 'noodles', 'pasta',
      'pickle', 'jam', 'honey', 'egg', 'eggs', 'meat', 'chicken', 'fish',
      'vegetable', 'fruit', 'ice cream', 'curry', 'tea', 'coffee',
      'nestle', 'amul', 'britannia', 'parle', 'haldiram', 'cadbury', 'dabur',
      'mother dairy', 'patanjali', 'aashirvaad', 'lays', 'doritos', 'pepsi',
      'coca cola', 'coke', 'thums up', 'frooti', 'kissan', 'marico', 'saffola',
      'fortune', 'blinkit', 'zepto', 'instamart', 'bigbasket', 'dmart',
      'reliance fresh', 'grocery', 'supermarket',
    ];
    for (final kw in groceryKeywords) {
      if (combined.contains(kw)) {
        return groceries;
      }
    }

    // 2. Fashion & Apparel
    const fashionKeywords = [
      'shoe', 'shoes', 'sneaker', 'sneakers', 'sandal', 'sandals', 'slipper', 'slippers',
      'shirt', 't-shirt', 'tshirt', 'jeans', 'pant', 'pants', 'trouser', 'trousers',
      'jacket', 'hoodie', 'sweater', 'kurta', 'saree', 'dress', 'socks',
      'belt', 'wallet', 'bag', 'backpack', 'handbag', 'suitcase', 'trolley',
      'nike', 'adidas', 'puma', 'reebok', 'zara', 'h&m', 'levis', "levi's",
      'woodland', 'bata', 'wildcraft', 'american tourister', 'skybags', 'safari',
    ];
    for (final kw in fashionKeywords) {
      if (combined.contains(kw)) {
        return fashion;
      }
    }

    // 3. Automotive
    const autoKeywords = [
      'tire', 'tyre', 'tires', 'tyres', 'mrf', 'ceat', 'apollo', 'bridgestone',
      'battery', 'amaron', 'exide', 'helmet', 'engine oil', 'castrol', 'motul',
      'brake pad', 'wiper', 'spark plug', 'motorcycle', 'scooter',
    ];
    for (final kw in autoKeywords) {
      if (combined.contains(kw)) {
        return automotive;
      }
    }

    // 4. Electronics & Appliances
    const electronicsKeywords = [
      'phone', 'mobile', 'laptop', 'macbook', 'tv', 'television', 'monitor',
      'computer', 'pc', 'washing machine', 'refrigerator', 'fridge', 'ac',
      'air conditioner', 'cooler', 'geyser', 'inverter', 'earphone', 'headphone',
      'speaker', 'soundbar', 'charger', 'adapter', 'cable', 'iron', 'vacuum',
      'camera', 'drone', 'tablet', 'ipad', 'smartwatch', 'watch', 'printer',
      'microwave', 'oven', 'mixer', 'grinder', 'blender', 'kettle', 'purifier',
      'samsung', 'apple', 'lg', 'sony', 'dell', 'hp', 'lenovo', 'asus', 'acer',
      'whirlpool', 'bosch', 'philips', 'voltas', 'godrej', 'panasonic', 'boat',
      'noise', 'oneplus', 'xiaomi', 'redmi', 'realme', 'vivo', 'oppo', 'jbl',
      'marshall', 'dyson', 'bajaj', 'crompton', 'prestige', 'nikon', 'canon',
      'sennheiser',
    ];
    for (final kw in electronicsKeywords) {
      if (combined.contains(kw)) {
        return electronics;
      }
    }

    // Fallback to General
    return general;
  }
}
