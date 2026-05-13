import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

Widget buildPlatformAwareImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit? fit,
}) {
  // Generer en unik view id for hver instans
  final String viewId = 'html-image-\${imageUrl.hashCode}-\${width}-\${height}-\${DateTime.now().microsecondsSinceEpoch}';

  // Registrer view factory. Ignorerer advarsler, da vi bruger ui_web
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    return html.ImageElement()
      ..src = imageUrl
      ..style.width = width != null ? '\${width}px' : '100%'
      ..style.height = height != null ? '\${height}px' : '100%'
      ..style.objectFit = _boxFitToHtml(fit)
      ..style.border = 'none'
      ..style.pointerEvents = 'none'; // Forhindrer at billedet stjæler klik
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewId),
  );
}

String _boxFitToHtml(BoxFit? fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.cover:
      return 'cover';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitHeight:
      return 'contain';
    case BoxFit.fitWidth:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
    default:
      return 'contain';
  }
}
