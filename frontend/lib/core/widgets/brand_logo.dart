import 'package:flutter/material.dart';

class BrandLogoIcon extends StatelessWidget {
  final double size;

  const BrandLogoIcon({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logos/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
