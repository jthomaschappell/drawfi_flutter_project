import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({Key? key}) : super(key: key);

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class LineItem {
  String description;
  double amount;
  bool addedViaCSV;

  LineItem({
    required this.description,
    required this.amount,
    this.addedViaCSV = false,
  });
}
// Add this after the LineItem class
double calculateTotalCSVAmount(List<LineItem> items) {
  return items
      .where((item) => item.addedViaCSV)
      .fold(0.0, (sum, item) => sum + item.amount);
}
double calculateTotalManualAmount(List<LineItem> items) {
  return items
      .where((item) => !item.addedViaCSV)
      .fold(0.0, (sum, item) => sum + item.amount);
}

double calculateTotalAmount(List<LineItem> items) {
  return items.fold(0.0, (sum, item) => sum + item.amount);
}
class _InvitationScreenState extends State<InvitationScreen> {
  // Controllers
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _gcEmailController = TextEditingController();
  final TextEditingController _inspectorEmailController =
      TextEditingController();
  final TextEditingController _loanNumberController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // State variables
  DateTime? _startDate;
  DateTime? _endDate;
  List<PlatformFile> _uploadedFiles = [];
  int _currentStep = 0;
  bool _inviteViaDrawfi = false;

  // Steps
  final List<String> _steps = [
    'Project Details',
    'General Contractor',
    'Inspector',
    'Review',
  ];

  final String appLogo =
      '''<svg width="1531" height="1531" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="1531" height="1531" rx="200" fill="url(#paint0_linear_82_170)"/>
<ellipse cx="528" cy="429.5" rx="136.5" ry="136" transform="rotate(-90 528 429.5)" fill="white"/>
<circle cx="528" cy="1103" r="136" transform="rotate(-90 528 1103)" fill="white"/>
<circle cx="1001" cy="773" r="136" fill="white"/>
<ellipse cx="528" cy="774" rx="29" ry="28" fill="white"/>
<ellipse cx="808" cy="494" rx="29" ry="28" fill="white"/>
<ellipse cx="808" cy="1038.5" rx="29" ry="29.5" fill="white"/>
<defs>
<linearGradient id="paint0_linear_82_170" x1="1485.07" y1="0.00010633" x2="30.6199" y2="1485.07" gradientUnits="userSpaceOnUse">
<stop stop-color="#FF1970"/>
<stop offset="0.145" stop-color="#E81766"/>
<stop offset="0.307358" stop-color="#DB12AF"/>
<stop offset="0.43385" stop-color="#BF09D5"/>
<stop offset="0.556871" stop-color="#A200FA"/>
<stop offset="0.698313" stop-color="#6500E9"/>
<stop offset="0.855" stop-color="#3C17DB"/>
<stop offset="1" stop-color="#2800D7"/>
</linearGradient>
</defs>
</svg>''';
  List<LineItem> _lineItems = [];

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'csv'],
        withData: true, // Add this
      );

      if (result != null) {
        setState(() {
          _uploadedFiles = result.files;
        });
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  Future<void> _pickAndParseCSV() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing CSV file...'),
          duration: Duration(seconds: 1),
        ),
      );

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('File picked: ${file.name}');

        if (file.bytes != null) {
          final content = String.fromCharCodes(file.bytes!);
          final lines = content.split('\n');
          print('Number of lines: ${lines.length}');

          // Find Description and Amount columns in header
          final headers =
              lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
          final descriptionIndex =
              headers.indexWhere((h) => h.contains('description'));
          final amountIndex = headers.indexWhere((h) => h.contains('amount'));

          if (descriptionIndex == -1 || amountIndex == -1) {
            throw Exception('CSV must contain Description and Amount columns');
          }

          setState(() {
            _lineItems = []; // Clear existing items
          });

          // Process each line (skip header)
          for (var i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            final values = line.split(',');
            if (values.length > math.max(descriptionIndex, amountIndex)) {
              final description = values[descriptionIndex].trim();
              final amount = double.tryParse(values[amountIndex].trim()) ?? 0.0;

              setState(() {
  _lineItems.add(LineItem(
    description: description,
    amount: amount,
    addedViaCSV: true,  // Add this line
  ));
});
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV imported successfully'),
              backgroundColor: Color(0xFF4F46E5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error parsing CSV: $e');
      print('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing CSV: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF4F46E5) : Colors.white,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLineItemsTable() {
    return Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[200]!),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Line Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        if (_lineItems.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Total: \$${calculateTotalAmount(_lineItems).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ],
    ),
    ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _lineItems.add(LineItem(
            description: '',
            amount: 0,
            addedViaCSV: false,
          ));
        });
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Item'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  ],
),
          Container(
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
                      onPressed: _pickAndParseCSV, // Just this one line changes
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
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (_lineItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No line items added yet',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ..._lineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: item.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter description',
                          hintStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            item.description = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: item.amount.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          setState(() {
                            item.amount = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.close, size: 20, color: Colors.grey[400]),
                      onPressed: () {
                        setState(() {
                          _lineItems.removeAt(index);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isMultiline = false,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: isMultiline ? 4 : 1,
            style: const TextStyle(
              color: Color(0xFF111827), // Text color when typing
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF6B7280), // Darker placeholder text
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: const Color(0xFF6B7280))
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUpload() {
    return Column(
      children: [
        DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          color: const Color(0xFF4F46E5),
          strokeWidth: 2,
          dashPattern: const [8, 4],
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Drag and drop files here',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                TextButton(
                  onPressed: _pickFiles,
                  child: const Text('or browse files'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._uploadedFiles
            .map((file) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file,
                          color: Color(0xFF6B7280)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          file.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _uploadedFiles.remove(file);
                          });
                        },
                        color: const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF6B7280), size: 20),
                const SizedBox(width: 12),
                Text(
                  date?.toString().split(' ')[0] ?? 'Select date',
                  style: TextStyle(
                    color: date != null
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientText(String text) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFFA200FA)],
      ).createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradientText('Create Your Project'),
            const SizedBox(height: 8),
            Text(
              'Start by entering the basic project information.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            _buildFormField(
              controller: _projectNameController,
              label: 'Project Name',
              hint: 'Enter project name',
              prefixIcon: Icons.business,
            ),
            const SizedBox(height: 24),
            _buildFormField(
              controller: _locationController,
              label: 'Location',
              hint: 'Enter project location',
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: 24),
            _buildFormField(
              controller: _loanAmountController,
              label: 'Loan Amount',
              hint: '\$0.00',
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: 24),
            _buildLineItemsTable(),
            _buildFormField(
              controller: _loanNumberController,
              label: 'Loan Number',
              hint: 'Enter a loan number',
              prefixIcon: Icons.numbers_outlined,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Start Date',
                    _startDate,
                    () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'End Date',
                    _endDate,
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradientText('Invite General Contractor'),
            const SizedBox(height: 8),
            Text(
              'Add your general contractor to the project.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: SvgPicture.string(appLogo),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Invite through DrawFi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _inviteViaDrawfi,
                        onChanged: (value) {
                          setState(() {
                            _inviteViaDrawfi = value;
                          });
                        },
                        activeColor: const Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                  if (_inviteViaDrawfi) ...[
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _gcEmailController,
                      label: 'DrawFi Username',
                      hint: '@username',
                      prefixIcon: Icons.alternate_email,
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _gcEmailController,
                      label: 'Email Address',
                      hint: 'Enter email address',
                      prefixIcon: Icons.email,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Required Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload any relevant project documents for your contractor.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildFileUpload(),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradientText('Invite Inspector'),
            const SizedBox(height: 8),
            Text(
              'Add your inspector to the project.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: SvgPicture.string(appLogo),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Invite through DrawFi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _inviteViaDrawfi,
                        onChanged: (value) {
                          setState(() {
                            _inviteViaDrawfi = value;
                          });
                        },
                        activeColor: const Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                  if (_inviteViaDrawfi) ...[
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _inspectorEmailController,
                      label: 'DrawFi Username',
                      hint: '@username',
                      prefixIcon: Icons.alternate_email,
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _inspectorEmailController,
                      label: 'Email Address',
                      hint: 'Enter email address',
                      prefixIcon: Icons.email,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              controller: _noteController,
              label: 'Additional Notes',
              hint: 'Add any notes for the inspector...',
              isMultiline: true,
            ),
          ],
        );

      case 3:
        return _buildReviewStep();

      default:
        return Container();
    }
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGradientText('Review Details'),
        const SizedBox(height: 8),
        Text(
          'Review your project information before creating.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        _buildReviewSection('Project Information', [
          {'Project Name': _projectNameController.text},
          {'Location': _locationController.text},
          {'Loan Amount': '\$${_loanAmountController.text}'},
          {'Start Date': _startDate?.toString().split(' ')[0] ?? 'Not set'},
          {'End Date': _endDate?.toString().split(' ')[0] ?? 'Not set'},
        ]),
        const SizedBox(height: 24),
        _buildReviewSection('Team Members', [
          {'General Contractor': _gcEmailController.text},
          {'Inspector': _inspectorEmailController.text},
        ]),
        if (_uploadedFiles.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildReviewSection('Documents',
              _uploadedFiles.map((file) => {'File': file.name}).toList()),
        ],
      ],
    );
  }

  Widget _buildReviewSection(String title, List<Map<String, String>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const Divider(height: 1),
          ...items
              .map((item) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.keys.first,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          item.values.first,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: SvgPicture.string(appLogo),
            ),
            const SizedBox(width: 12),
            const Text(
              'New Project',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep < _steps.length - 1) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      // Handle project creation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Project created successfully'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentStep < _steps.length - 1
                        ? 'Continue'
                        : 'Create Project',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _locationController.dispose();
    _loanAmountController.dispose();
    _gcEmailController.dispose();
    _inspectorEmailController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

// Mock classes for FilePicker

