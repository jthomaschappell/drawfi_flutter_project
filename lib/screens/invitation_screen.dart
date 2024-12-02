import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final TextEditingController _contractorEmailController =
      TextEditingController();
  final TextEditingController _inspectorEmailController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<PlatformFile> _uploadedFiles = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _uploadedFiles = result.files;
      });
    }
  }

  void _sendInvitation() {
    final contractorEmail = _contractorEmailController.text;
    final inspectorEmail = _inspectorEmailController.text;

    if (contractorEmail.isEmpty || inspectorEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields.'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Invitation sent to $contractorEmail and $inspectorEmail'),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6500E9), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Invite to Project',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _contractorEmailController,
              label: 'Contractor Email',
              hint: 'Enter contractor email',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _inspectorEmailController,
              label: 'Inspector Email',
              hint: 'Enter inspector email',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _noteController,
              label: 'Notes',
              hint: 'Write a note for the invitation...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Files',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Files',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Icon(Icons.cloud_upload_outlined, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            if (_uploadedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: _uploadedFiles
                      .map((file) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file_outlined,
                                    color: Colors.grey[600], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close,
                                      color: Colors.grey[600], size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _uploadedFiles.remove(file);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sendInvitation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6500E9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send Invitation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contractorEmailController.dispose();
    _inspectorEmailController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class FileType {
  static var any;
}

class FilePicker {
  static var platform;
}

class PlatformFile {
  late String name;
}
