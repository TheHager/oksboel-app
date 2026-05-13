import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget buildPlatformAwareImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit? fit,
}) {
  return CachedNetworkImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    placeholder: (context, url) => SizedBox(
      width: width,
      height: height,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
    errorWidget: (context, url, error) => SizedBox(
      width: width,
      height: height,
      child: const Icon(Icons.error_outline, color: Colors.grey),
    ),
  );
}
