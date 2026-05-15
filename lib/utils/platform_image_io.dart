import 'package:flutter/material.dart';

Widget buildPlatformAwareImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit? fit,
}) {
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => SizedBox(
      width: width,
      height: height,
      child: const Icon(Icons.error_outline, color: Colors.grey),
    ),
  );
}
