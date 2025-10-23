import 'package:flutter/material.dart';

Color colorPorCategoria(String? cat) {
  final c = (cat ?? '').toLowerCase();
  if (c.contains('caf')) return Colors.brown;
  if (c.contains('pan')) return Colors.orange;
  if (c.contains('rest')) return Colors.red;
  if (c.contains('tienda')) return Colors.green;
  return Colors.indigo;
}
