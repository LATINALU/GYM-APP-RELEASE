import 'dart:typed_data' show Uint8List;

import 'package:file_picker/file_picker.dart';

/// Utility for exporting data as CSV files.
class CsvExporter {
  /// Exports a list of rows (each row is a list of cell values) as a CSV file.
  /// [headers] is the first row. [rows] are the data rows.
  /// [filename] is the suggested file name (without extension).
  static Future<bool> export({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String filename,
  }) async {
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(headers.map(_escapeCsvCell).join(','));

    // Data rows
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }

    final csvContent = buffer.toString();

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar exportación CSV',
        fileName: '$filename.csv',
        bytes: Uint8List.fromList(csvContent.codeUnits),
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      return result != null;
    } catch (_) {
      return false;
    }
  }

  static String _escapeCsvCell(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
}
