class BrandSupportInfo {
  final String brandName;
  final String? supportEmail;
  final String? tollFreePhone;
  final String? website;
  final String serviceCenterQuery;
  final bool isVerified;

  const BrandSupportInfo({
    required this.brandName,
    this.supportEmail,
    this.tollFreePhone,
    this.website,
    required this.serviceCenterQuery,
    this.isVerified = true,
  });

  BrandSupportInfo copyWith({
    String? brandName,
    String? supportEmail,
    String? tollFreePhone,
    String? website,
    String? serviceCenterQuery,
    bool? isVerified,
  }) {
    return BrandSupportInfo(
      brandName: brandName ?? this.brandName,
      supportEmail: supportEmail ?? this.supportEmail,
      tollFreePhone: tollFreePhone ?? this.tollFreePhone,
      website: website ?? this.website,
      serviceCenterQuery: serviceCenterQuery ?? this.serviceCenterQuery,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class BrandSupportDirectory {
  static const Map<String, BrandSupportInfo> _directory = {
    'samsung': BrandSupportInfo(
      brandName: 'Samsung',
      supportEmail: 'support.india@samsung.com',
      tollFreePhone: '1800 40 7267864',
      website: 'https://www.samsung.com/in/support/',
      serviceCenterQuery: 'Samsung Authorized Service Center near me',
    ),
    'apple': BrandSupportInfo(
      brandName: 'Apple',
      supportEmail: 'service@apple.com',
      tollFreePhone: '000800 1009009',
      website: 'https://support.apple.com/in',
      serviceCenterQuery: 'Apple Authorized Service Provider near me',
    ),
    'lg': BrandSupportInfo(
      brandName: 'LG',
      supportEmail: 'serviceindia@lge.com',
      tollFreePhone: '1800 315 9999',
      website: 'https://www.lg.com/in/support',
      serviceCenterQuery: 'LG Authorized Service Center near me',
    ),
    'sony': BrandSupportInfo(
      brandName: 'Sony',
      supportEmail: 'sonyindia.care@sony.com',
      tollFreePhone: '1800 103 7799',
      website: 'https://www.sony.co.in/electronics/support',
      serviceCenterQuery: 'Sony Authorized Service Center near me',
    ),
    'dell': BrandSupportInfo(
      brandName: 'Dell',
      supportEmail: 'india_care@dell.com',
      tollFreePhone: '1800 425 0088',
      website: 'https://www.dell.com/support/home/en-in',
      serviceCenterQuery: 'Dell Authorized Service Center near me',
    ),
    'hp': BrandSupportInfo(
      brandName: 'HP',
      supportEmail: 'hp.care@hp.com',
      tollFreePhone: '1800 258 7170',
      website: 'https://support.hp.com/in-en',
      serviceCenterQuery: 'HP Authorized Service Center near me',
    ),
    'lenovo': BrandSupportInfo(
      brandName: 'Lenovo',
      supportEmail: 'customercare@lenovo.com',
      tollFreePhone: '1800 419 7555',
      website: 'https://pcsupport.lenovo.com/in/en',
      serviceCenterQuery: 'Lenovo Authorized Service Center near me',
    ),
    'asus': BrandSupportInfo(
      brandName: 'Asus',
      supportEmail: 'rc_india@asus.com',
      tollFreePhone: '1800 209 0365',
      website: 'https://www.asus.com/in/support/',
      serviceCenterQuery: 'Asus Authorized Service Center near me',
    ),
    'acer': BrandSupportInfo(
      brandName: 'Acer',
      supportEmail: 'ail.easycare@acer.com',
      tollFreePhone: '1800 11 6677',
      website: 'https://www.acer.com/in-en/support',
      serviceCenterQuery: 'Acer Authorized Service Center near me',
    ),
    'whirlpool': BrandSupportInfo(
      brandName: 'Whirlpool',
      supportEmail: 'helpdeskindia@whirlpool.com',
      tollFreePhone: '1800 208 1800',
      website: 'https://www.whirlpoolindia.com/services',
      serviceCenterQuery: 'Whirlpool Authorized Service Center near me',
    ),
    'bosch': BrandSupportInfo(
      brandName: 'Bosch',
      supportEmail: 'service.in@bosch-home.com',
      tollFreePhone: '1800 266 1880',
      website: 'https://www.bosch-home.in/service',
      serviceCenterQuery: 'Bosch Authorized Service Center near me',
    ),
    'philips': BrandSupportInfo(
      brandName: 'Philips',
      supportEmail: 'customercare.india@philips.com',
      tollFreePhone: '1800 102 2929',
      website: 'https://www.philips.co.in/c-w/support-home',
      serviceCenterQuery: 'Philips Authorized Service Center near me',
    ),
    'havells': BrandSupportInfo(
      brandName: 'Havells',
      supportEmail: 'customercare@havells.com',
      tollFreePhone: '1800 11 0303',
      website: 'https://www.havells.com/support',
      serviceCenterQuery: 'Havells Authorized Service Center near me',
    ),
    'voltas': BrandSupportInfo(
      brandName: 'Voltas',
      supportEmail: 'customercare@voltas.com',
      tollFreePhone: '1860 599 4555',
      website: 'https://www.voltas.com/customer-care',
      serviceCenterQuery: 'Voltas Authorized Service Center near me',
    ),
    'daikin': BrandSupportInfo(
      brandName: 'Daikin',
      supportEmail: 'communications@daikinindia.com',
      tollFreePhone: '1860 180 3900',
      website: 'https://www.daikinindia.com/service',
      serviceCenterQuery: 'Daikin Authorized Service Center near me',
    ),
    'godrej': BrandSupportInfo(
      brandName: 'Godrej',
      supportEmail: 'smartcare@godrej.com',
      tollFreePhone: '1800 209 5511',
      website: 'https://www.godrej.com/appliances/customer-care',
      serviceCenterQuery: 'Godrej Authorized Service Center near me',
    ),
    'panasonic': BrandSupportInfo(
      brandName: 'Panasonic',
      supportEmail: 'helpline@in.panasonic.com',
      tollFreePhone: '1800 103 1333',
      website: 'https://www.panasonic.com/in/support.html',
      serviceCenterQuery: 'Panasonic Authorized Service Center near me',
    ),
    'boat': BrandSupportInfo(
      brandName: 'boAt',
      supportEmail: 'info@imaginemarketingindia.com',
      tollFreePhone: '022 6918 1920',
      website: 'https://www.boat-lifestyle.com/pages/contact-us',
      serviceCenterQuery: 'boAt Service Center near me',
    ),
    'noise': BrandSupportInfo(
      brandName: 'Noise',
      supportEmail: 'help@gonoise.com',
      tollFreePhone: '022 6918 1900',
      website: 'https://support.gonoise.com/',
      serviceCenterQuery: 'Noise Service Center near me',
    ),
    'oneplus': BrandSupportInfo(
      brandName: 'OnePlus',
      supportEmail: 'onepluscare@oneplus.com',
      tollFreePhone: '1800 102 8411',
      website: 'https://www.oneplus.in/support',
      serviceCenterQuery: 'OnePlus Authorized Service Center near me',
    ),
    'xiaomi': BrandSupportInfo(
      brandName: 'Xiaomi',
      supportEmail: 'service.in@xiaomi.com',
      tollFreePhone: '1800 103 6286',
      website: 'https://www.mi.com/in/service/support/',
      serviceCenterQuery: 'Xiaomi Authorized Service Center near me',
    ),
    'mi': BrandSupportInfo(
      brandName: 'Xiaomi (Mi)',
      supportEmail: 'service.in@xiaomi.com',
      tollFreePhone: '1800 103 6286',
      website: 'https://www.mi.com/in/service/support/',
      serviceCenterQuery: 'Xiaomi Authorized Service Center near me',
    ),
    'realme': BrandSupportInfo(
      brandName: 'Realme',
      supportEmail: 'service.in@realme.com',
      tollFreePhone: '1800 102 2777',
      website: 'https://www.realme.com/in/support',
      serviceCenterQuery: 'Realme Authorized Service Center near me',
    ),
    'vivo': BrandSupportInfo(
      brandName: 'Vivo',
      supportEmail: 'vcare@vivo.com',
      tollFreePhone: '1800 102 3388',
      website: 'https://www.vivo.com/in/support',
      serviceCenterQuery: 'Vivo Authorized Service Center near me',
    ),
    'oppo': BrandSupportInfo(
      brandName: 'Oppo',
      supportEmail: 'support.in@oppo.com',
      tollFreePhone: '1800 103 2777',
      website: 'https://support.oppo.com/in/',
      serviceCenterQuery: 'Oppo Authorized Service Center near me',
    ),
    'jbl': BrandSupportInfo(
      brandName: 'JBL',
      supportEmail: 'indiahelpline@harman.com',
      tollFreePhone: '1800 102 0525',
      website: 'https://support.jbl.com/in/en/',
      serviceCenterQuery: 'JBL Authorized Service Center near me',
    ),
    'marshall': BrandSupportInfo(
      brandName: 'Marshall',
      supportEmail: 'support@marshallheadphones.com',
      tollFreePhone: '1800 102 0525',
      website: 'https://www.marshallheadphones.com/support',
      serviceCenterQuery: 'Marshall Audio Service Center near me',
    ),
    'dyson': BrandSupportInfo(
      brandName: 'Dyson',
      supportEmail: 'ask@dyson.in',
      tollFreePhone: '1800 258 6688',
      website: 'https://www.dyson.in/support',
      serviceCenterQuery: 'Dyson Authorized Service Center near me',
    ),
    'bajaj': BrandSupportInfo(
      brandName: 'Bajaj',
      supportEmail: 'customercare@bajajelectricals.com',
      tollFreePhone: '022 4128 0000',
      website: 'https://www.bajajelectricals.com/customer-care',
      serviceCenterQuery: 'Bajaj Electricals Service Center near me',
    ),
    'crompton': BrandSupportInfo(
      brandName: 'Crompton',
      supportEmail: 'crompton.care@crompton.co.in',
      tollFreePhone: '1800 419 0505',
      website: 'https://www.crompton.co.in/support/',
      serviceCenterQuery: 'Crompton Service Center near me',
    ),
    'usha': BrandSupportInfo(
      brandName: 'Usha',
      supportEmail: 'care@usha.com',
      tollFreePhone: '1800 1033 111',
      website: 'https://www.usha.com/contact-us',
      serviceCenterQuery: 'Usha Care Center near me',
    ),
    'prestige': BrandSupportInfo(
      brandName: 'Prestige',
      supportEmail: 'customercare@ttkprestige.com',
      tollFreePhone: '1800 123 334411',
      website: 'https://www.ttkprestige.com/customer-care',
      serviceCenterQuery: 'Prestige Service Center near me',
    ),
    'nikon': BrandSupportInfo(
      brandName: 'Nikon',
      supportEmail: 'service.in@nikon.com',
      tollFreePhone: '1800 102 7346',
      website: 'https://www.nikon.co.in/service-and-support',
      serviceCenterQuery: 'Nikon Service Center near me',
    ),
    'canon': BrandSupportInfo(
      brandName: 'Canon',
      supportEmail: 'cihelpline@canon.co.in',
      tollFreePhone: '1860 180 3366',
      website: 'https://in.canon/en/consumer/support',
      serviceCenterQuery: 'Canon Service Center near me',
    ),
    'sennheiser': BrandSupportInfo(
      brandName: 'Sennheiser',
      supportEmail: 'customercare@sennheiser.com',
      tollFreePhone: '1800 22 3632',
      website: 'https://www.sennheiser.com/service-support',
      serviceCenterQuery: 'Sennheiser Service Center near me',
    ),
  };

  /// Discovers official brand support details from brand name, product name, or merchant
  static BrandSupportInfo resolveBrandSupport({
    String? brand,
    required String productName,
    String? merchantName,
  }) {
    // 1. Check explicit brand field
    if (brand != null && brand.trim().isNotEmpty) {
      final key = brand.trim().toLowerCase();
      for (final entry in _directory.entries) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          return entry.value;
        }
      }
    }

    // 2. Check product name tokens
    final productLower = productName.toLowerCase();
    for (final entry in _directory.entries) {
      if (productLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3. Check merchant name tokens (e.g. "Apple Store", "Samsung Plaza")
    if (merchantName != null && merchantName.trim().isNotEmpty) {
      final merchantLower = merchantName.toLowerCase();
      for (final entry in _directory.entries) {
        if (merchantLower.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // 4. Fallback for unlisted brands
    final displayBrand = (brand != null && brand.trim().isNotEmpty)
        ? brand.trim()
        : _extractLikelyBrandFromProduct(productName);

    return BrandSupportInfo(
      brandName: displayBrand,
      supportEmail: null,
      tollFreePhone: null,
      website: null,
      serviceCenterQuery: '$displayBrand Authorized Service Center near me',
      isVerified: false,
    );
  }

  static String _extractLikelyBrandFromProduct(String productName) {
    final tokens = productName.trim().split(RegExp(r'\s+'));
    if (tokens.isNotEmpty && tokens[0].length >= 2) {
      // Capitalize first token as probable brand
      final first = tokens[0];
      return first[0].toUpperCase() + first.substring(1);
    }
    return 'Manufacturer';
  }
}
