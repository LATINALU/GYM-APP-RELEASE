import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalGifImage(
  String path,
  BoxFit fit,
  Widget Function() fallback,
) {
  return Image.file(
    File(path),
    fit: fit,
    errorBuilder: (_, __, ___) => fallback(),
  );
}
