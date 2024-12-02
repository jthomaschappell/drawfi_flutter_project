import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class DrawLineItem {
  String categoryName;
  List<double?> draws;

  DrawLineItem({
    required this.categoryName,
    required this.draws,
  });
}

class DrawRequestScreen extends StatefulWidget {
  const DrawRequestScreen({super.key});

  @override
  State<DrawRequestScreen> createState() => _DrawRequestScreenState();
}

class _DrawRequestScreenState extends State<DrawRequestScreen> {
  final _currencyFormat = NumberFormat("#,##0.00", "en_US");
  final _noteController = TextEditingController();
  final _categoryController = TextEditingController();

  List<DrawLineItem> _lineItems = [];
  List<PlatformFile> _uploadedFiles = [];
  int _drawCount = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Draw Request Form',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Request Summary'),
            const SizedBox(height: 8),
            Expanded(child: _buildTable()),
            const SizedBox(height: 16),
            _buildSectionTitle('Notes'),
            const SizedBox(height: 8),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildSectionTitle('Attachments'),
            const SizedBox(height: 8),
            _buildFileUploadSection(),
            const Spacer(),
            _buildFooterButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ..._buildDataRows(),
          _buildAddLineItemButton(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(color: Colors.grey),
      child: Row(
        children: [
          _buildHeaderCell('Line Item', flex: 2),
          ...List.generate(
              _drawCount, (i) => _buildHeaderCell('Draw ${i + 1}')),
          _buildHeaderCell('INSP'),
          _buildHeaderCell('Remain'),
          _buildHeaderCell('Total'),
          _buildHeaderCell('Actions'),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<Widget> _buildDataRows() {
    return _lineItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return Container(
        color: index % 2 == 0 ? Colors.grey[100] : Colors.white,
        child: Row(
          children: [
            _buildLabelCell(item.categoryName, flex: 2),
            ...List.generate(_drawCount, (i) => _buildInputCell(index, i)),
            _buildInputCell(index, _drawCount), // INSP
            _buildReadOnlyCell(index, _drawCount + 1), // Remain
            _buildReadOnlyCell(index, _drawCount + 2), // Total
            _buildRemoveButton(index),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLabelCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildInputCell(int itemIndex, int drawIndex) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TextField(
          textAlign: TextAlign.right,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (value) => _updateValue(itemIndex, drawIndex, value),
        ),
      ),
    );
  }

  Widget _buildReadOnlyCell(int itemIndex, int index) {
    final value = _lineItems[itemIndex].draws[index] ?? 0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _currencyFormat.format(value),
          style: const TextStyle(color: Colors.black),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Widget _buildRemoveButton(int index) {
    return Expanded(
      child: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () {
          setState(() {
            _lineItems.removeAt(index);
          });
        },
      ),
    );
  }

  Widget _buildAddLineItemButton() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton.icon(
        onPressed: _addLineItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Line Item'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Add any additional notes...',
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.upload),
          label: const Text('Upload Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        if (_uploadedFiles.isNotEmpty)
          ..._uploadedFiles.map((file) => ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(file.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _uploadedFiles.remove(file);
                    });
                  },
                ),
              )),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _saveDraft,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
          ),
          child: const Text('Save Draft'),
        ),
        ElevatedButton(
          onPressed: _submitDrawRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void _addLineItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Line Item'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_categoryController.text.isNotEmpty) {
                setState(() {
                  _lineItems.add(DrawLineItem(
                    categoryName: _categoryController.text,
                    draws: List.filled(_drawCount + 3, 0),
                  ));
                });
                _categoryController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateValue(int itemIndex, int drawIndex, String value) {
    setState(() {
      _lineItems[itemIndex].draws[drawIndex] = double.tryParse(value) ?? 0;
    });
  }

  void _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _uploadedFiles = result.files;
      });
    }
  }

  void _saveDraft() {
    // Save draft logic
  }

  void _submitDrawRequest() {
    // Submit logicqflutter run
  }
}
