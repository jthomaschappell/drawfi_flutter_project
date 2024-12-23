import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class LineItem {
  String description;
  double amount;

  LineItem({
    required this.description,
    required this.amount,
  });
}

class CSVLineItemsWidget extends StatelessWidget {
  final List<LineItem> lineItems;
  final Function(List<LineItem>) onLineItemsChanged;

  const CSVLineItemsWidget({
    super.key,
    required this.lineItems,
    required this.onLineItemsChanged,
  });

  Future<void> _pickAndParseCSV() async {
    try {
      print('Starting file pick...'); // Debug print
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('File selected: ${file.name}'); // Debug print

        if (file.bytes != null) {
          final content = String.fromCharCodes(file.bytes!);
          final lines = content.split('\n');
          print('Number of lines found: ${lines.length}'); // Debug print
          print(
              'First line content: ${lines.first}'); // Debug print to see header

          final newItems = List<LineItem>.from(lineItems);

          // Skip header row and process each line
          for (var i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            final values = line.split(',');
            print('Line $i values: $values'); // Debug print

            if (values.length >= 2) {
              final description = values[0].trim();
              final amount =
                  double.tryParse(values[1].trim().replaceAll('\$', '')) ?? 0.0;
              print('Adding item: $description - $amount'); // Debug print

              newItems.add(LineItem(
                description: description,
                amount: amount,
              ));
            }
          }

          print(
              'Total items added: ${newItems.length - lineItems.length}'); // Debug print
          onLineItemsChanged(newItems);
        } else {
          print('File bytes are null'); // Debug print
        }
      } else {
        print('No file selected or result is null'); // Debug print
      }
    } catch (e) {
      print('Error parsing CSV: $e');
      print(
          'Error stack trace: ${StackTrace.current}'); // Debug print for stack trace
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Import from CSV',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _pickAndParseCSV,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload CSV'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'CSV should have columns: Description, Amount',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
