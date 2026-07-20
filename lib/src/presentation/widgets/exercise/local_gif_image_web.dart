import 'package:flutter/material.dart';

// En web no hay archivos locales (ExerciseMediaPort devuelve siempre null),
// así que esta rama nunca se ejecuta; existe solo para que compile.
Widget buildLocalGifImage(
  String path,
  BoxFit fit,
  Widget Function() fallback,
) {
  return fallback();
}
