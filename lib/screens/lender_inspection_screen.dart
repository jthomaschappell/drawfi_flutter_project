
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Updated color scheme for light theme
const Color primaryColor = Color(0xFF4F46E5);  // Indigo
const Color successGreen = Color(0xFF059669);  // Emerald green
const Color warningRed = Color(0xFFDC2626);    // Red
const Color cardBackground = Color(0xFFFFFFFF); // White
const Color textPrimary = Color(0xFF1F2937);   // Dark gray
const Color textSecondary = Color(0xFF6B7280); // Medium gray
const Color backgroundColor = Color(0xFFF3F4F6); // Light gray background

class LenderInspectionScreen extends StatefulWidget {
  const LenderInspectionScreen({Key? key}) : super(key: key);

  @override
  State<LenderInspectionScreen> createState() => _LenderInspectionScreenState();
}

class _LenderInspectionScreenState extends State<LenderInspectionScreen> {
  final supabase = Supabase.instance.client;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  final TextEditingController _commentController = TextEditingController();
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> inspectionHistory = [];
  Map<String, dynamic>? _lineItemData;

  @override
  void initState() {
    super.initState();
    print('LenderInspectionScreen initialized');
    _loadInitialData();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _commentController.dispose();
    print('LenderInspectionScreen disposed');
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      print('Starting to load initial data');

      final lineItemResponse = await supabase
          .from('line_item_inspections')
          .select('''
            inspection_id,
            inspection_date,
            inspection_percentage,
            inspector_notes,
            completion_percentage,
            photo_urls,
            inspector_id
          ''')
          .limit(1)
          .single();
      
      print('Initial data loaded: $lineItemResponse');

      if (!mounted) return;
      
      setState(() {
        _lineItemData = lineItemResponse;
        isLoading = false;
      });

    } catch (e) {
      print('Error in _loadInitialData: $e');
      if (!mounted) return;
      
      setState(() {
        error = 'Error loading data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadInspectionHistory() async {
    try {
      if (_lineItemData == null || !mounted) return;
      
      final response = await supabase
          .from('line_item_inspections')
          .select()
          .eq('category_id', _lineItemData!['category_id']);

      print('Inspection history response: $response');

      if (!mounted) return;
      
      setState(() {
        inspectionHistory = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading inspection history: $e');
      if (mounted) {
        setState(() {
          error = 'Error loading inspection history: $e';
        });
      }
    }
  }

  Future<void> _submitDecision(bool isApproved) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      await supabase
          .from('line_item_inspections')
          .update({
            'status': isApproved ? 'approved' : 'declined',
            'lender_notes': _commentController.text,
            'lender_id': user.id,
            'decision_date': DateTime.now().toIso8601String(),
          })
          .eq('category_id', _lineItemData?['category_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? 'Inspection approved' : 'Inspection declined'),
            backgroundColor: isApproved ? successGreen : warningRed,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting decision: ${e.toString()}'),
            backgroundColor: warningRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            error!,
            style: TextStyle(color: textPrimary),
          ),
        ),
      );
    }

    if (_lineItemData == null) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            'No line item data available',
            style: TextStyle(color: textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        title: Text(
          _lineItemData?['name'] ?? 'Line Item Inspection',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLineItemHeader(),
            const SizedBox(height: 24),
            _buildInspectionGallery(),
            const SizedBox(height: 24),
            _buildInspectionDetails(),
            const SizedBox(height: 24),
            _buildDrawRequestDetails(),
            const SizedBox(height: 24),
            _buildApprovalSection(),
            const SizedBox(height: 24),
            _buildInspectionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  Text(
                    _lineItemData?['name'] ?? 'Line Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: \$${NumberFormat('#,##0.00').format(_lineItemData?['budget'] ?? 0)}',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timeline, color: primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_lineItemData?['progress'] ?? 0}% Complete',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_lineItemData?['progress'] ?? 0) / 100,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionGallery() {
    final List<String> photos = List<String>.from(_lineItemData?['photos'] ?? []);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inspection Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: photos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, 
                          color: textSecondary, 
                          size: 48
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No photos available',
                          style: TextStyle(
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(photos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index 
                      ? primaryColor 
                      : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInspectionHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inspection History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (inspectionHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No previous inspections',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inspectionHistory.length,
              itemBuilder: (context, index) {
                final item = inspectionHistory[index];
                final bool isApproved = item['status'] == 'approved';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(
                              DateTime.parse(item['inspection_date']),
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isApproved
                                  ? successGreen.withOpacity(0.1)
                                  : warningRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['status']?.toUpperCase() ?? 'PENDING',
                              style: TextStyle(
                                color: isApproved ? successGreen : warningRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['inspector']?['full_name'] ?? 'Unknown Inspector',
                            style: TextStyle(color: textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.timeline,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(item['inspection_percentage'] ?? 0) * 100}% Complete',
                            style: TextStyle(color: textSecondary),
                          ),
                        ],
                      ),
                      if (item['inspector_notes'] != null && 
                          item['inspector_notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item['inspector_notes'],
                          style: TextStyle(color: textPrimary),
                        ),
                      ],
                      if (item['photo_urls'] != null &&
                          (item['photo_urls'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (item['photo_urls'] as List).length,
                            itemBuilder: (context, photoIndex) {
                              return Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      item['photo_urls'][photoIndex],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildInspectionDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Inspection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Inspector',
            _lineItemData?['inspector_name'] ?? 'Not assigned',
            Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Inspection Date',
            DateFormat('MMM dd, yyyy').format(
              DateTime.parse(_lineItemData?['inspection_date'] ?? DateTime.now().toIso8601String()),
            ),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Completion',
            '${_lineItemData?['progress'] ?? 0}%',
            Icons.timeline,
          ),
          if (_lineItemData?['inspector_notes'] != null) ...[
            const SizedBox(height: 16),
            Text(
              'Inspector Notes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lineItemData?['inspector_notes'] ?? '',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawAmount(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawRequestDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Draw Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                'Draw #${_lineItemData?['draw_number'] ?? 1}',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDrawAmount(
                'Previous', 
                '\$${NumberFormat('#,##0.00').format(_lineItemData?['previous_draws'] ?? 0)}'
              ),
              _buildDrawAmount(
                'Current', 
                '\$${NumberFormat('#,##0.00').format(_lineItemData?['current_draw'] ?? 0)}'
              ),
              _buildDrawAmount(
                'Remaining', 
                '\$${NumberFormat('#,##0.00').format(_lineItemData?['remaining_budget'] ?? 0)}'
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildApprovalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Decision',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add comments about your decision...',
              hintStyle: TextStyle(color: textSecondary),
              filled: true,
              fillColor: backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _submitDecision(true),
                  child: const Text('Approve',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: warningRed),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _submitDecision(false),
                  child: Text('Decline',
                    style: TextStyle(
                      color: warningRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}