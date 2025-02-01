import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Inside your class:
final supabase = Supabase.instance.client;
// Project Data Model
class ProjectPhase {
  String name;
  String categoryId;  // Add this
  DateTime startDate;
  DateTime endDate;
  bool isCompleted;
  int progress;

  ProjectPhase({
    required this.name,
    required this.categoryId,  // Add this
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
    required this.progress,
  });
}
class ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
  });
}

// Define theme colors
class AppColors {
  static const primaryGradient = LinearGradient(
    colors: [
      Color(0xFFFF1970),
      Color(0xFFDB12AF),
      Color(0xFFA200FA),
      Color(0xFF2800D7),
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );
  
  static const primary = Color(0xFFDB12AF);
  static const secondary = Color(0xFF6500E9);
  static const accent = Color(0xFFFF1970);
  static const background = Color(0xFFF8F9FE);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF14142B);
  static const textSecondary = Color(0xFF6E7191);
}
class InspectionRecord {
  final DateTime date;
  final double percentage;
  final String notes;
  final String inspectorId;
  final List<String> photoUrls;

  InspectionRecord({
    required this.date,
    required this.percentage,
    required this.notes,
    required this.inspectorId,
    required this.photoUrls,
  });

  factory InspectionRecord.fromJson(Map<String, dynamic> json) {
    return InspectionRecord(
      date: DateTime.parse(json['inspection_date']),
      percentage: json['inspection_percentage'] * 100,
      notes: json['inspector_notes'] ?? '',
      inspectorId: json['inspector_id'],
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
    );
  }
}
Future<void> _debugInspectionSave({
  required String categoryId,
  required double percentage,
  required String notes,
}) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('DEBUG: No authenticated user found');
      return;
    }

    print('DEBUG: Attempting to save inspection with:');
    print('CategoryID: $categoryId');
    print('Percentage: $percentage');
    print('Notes: $notes');
    print('InspectorID: ${user.id}');

    final response = await supabase
        .from('line_item_inspections')
        .insert({
          'category_id': categoryId,
          'inspection_percentage': percentage / 100, // Convert to decimal
          'inspector_notes': notes,
          'inspector_id': user.id,
        })
        .select()
        .single();
    
    print('DEBUG: Success! Saved inspection: ${response.toString()}');
    
    // Verify the save by immediately fetching it back
    final verification = await supabase
        .from('line_item_inspections')
        .select()
        .eq('inspection_id', response['inspection_id'])
        .single();
    
    print('DEBUG: Verification fetch successful: ${verification.toString()}');

  } catch (e, stackTrace) {
    print('DEBUG: Error saving inspection:');
    print(e.toString());
    print('Stack trace:');
    print(stackTrace);
  }
}

class InspectorLoanScreen extends StatefulWidget {
  final Map<String, dynamic> projectData;

  const InspectorLoanScreen({Key? key, required this.projectData}) : super(key: key);

  @override
  _InspectorLoanScreenState createState() => _InspectorLoanScreenState();
}

class _InspectorLoanScreenState extends State<InspectorLoanScreen> {
  final List<ProjectPhase> phases = [];
  final List<XFile> projectImages = [];
  final List<ChatMessage> chatMessages = [];
  final TextEditingController messageController = TextEditingController();
  DateTime lastInspection = DateTime.now();
  DateTime nextDue = DateTime.now().add(Duration(days: 14));
 @override
void initState() {
  super.initState();
  _loadInitialDates();
  fetchLineItems();
}

Future<void> fetchLineItems() async {
  try {
    print("Fetching line items for loan ID: ${widget.projectData['loan_id']}");

    final lineItemsResponse = await supabase
        .from('construction_loan_line_items')
        .select('''
          *,
          line_item_inspections (
            inspection_id,
            inspection_percentage,
            inspection_date,
            inspector_notes,
            photo_urls,
            last_inspection_date,
            next_due_date,
            completion_percentage
          )
        ''')
        .eq('loan_id', widget.projectData['loan_id']);

    print("Line items response: $lineItemsResponse"); // Debug log

    setState(() {
      phases.clear();
      double overallCompletion = 0;
      
      for (var item in lineItemsResponse) {
        final inspections = item['line_item_inspections'] as List?;
        double latestPercentage = 0.0;
        DateTime? lastInspDate;
        DateTime? nextDueDate;
        
        if (inspections != null && inspections.isNotEmpty) {
          inspections.sort((a, b) => 
            DateTime.parse(b['inspection_date']).compareTo(DateTime.parse(a['inspection_date']))
          );
          
          var latestInspection = inspections.first;
          latestPercentage = (latestInspection['inspection_percentage'] ?? 0.0).toDouble();
          
          // Update dates from the latest inspection
          if (latestInspection['last_inspection_date'] != null) {
            lastInspection = DateTime.parse(latestInspection['last_inspection_date']);
          }
          if (latestInspection['next_due_date'] != null) {
            nextDue = DateTime.parse(latestInspection['next_due_date']);
          }
        }
        
        phases.add(
          ProjectPhase(
            name: item['category_name'] ?? 'Unnamed Item',
            categoryId: item['category_id'],
            startDate: lastInspection,
            endDate: nextDue,
            isCompleted: latestPercentage >= 1.0,
            progress: (latestPercentage * 100).round(),
          ),
        );
        
        overallCompletion += latestPercentage;
      }

      // Update overall completion percentage
      if (phases.isNotEmpty) {
        widget.projectData['completion'] = ((overallCompletion / phases.length) * 100).round();
      }
    });

  } catch (e, stackTrace) {
    print('Error loading line items: $e');
    print('Stack trace: $stackTrace');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading line items: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
// Helper methods to calculate phase progress
bool _calculatePhaseCompletion(List<dynamic> items, String phaseName) {
  var phaseItems = items.where((item) => item['phase_name'] == phaseName);
  if (phaseItems.isEmpty) return false;
  return phaseItems.every((item) => (item['inspection_percentage'] ?? 0) >= 100);
}

int _calculatePhaseProgress(List<dynamic> items, String phaseName) {
  var phaseItems = items.where((item) => item['phase_name'] == phaseName);
  if (phaseItems.isEmpty) return 0;
  
  double totalProgress = phaseItems.fold(0.0, 
    (sum, item) => sum + (item['inspection_percentage'] ?? 0));
  return (totalProgress / phaseItems.length).round();
}
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        projectImages.add(image);
      });
    }
  }
Future<void> _loadInitialDates() async {
  try {
    // Get the most recent inspection record for this loan
    final response = await supabase
        .from('line_item_inspections')
        .select('last_inspection_date, next_due_date')
        .eq('category_id', widget.projectData['loan_id'])
        .order('inspection_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      setState(() {
        lastInspection = DateTime.parse(response['last_inspection_date']);
        nextDue = DateTime.parse(response['next_due_date']);
      });
    }
  } catch (e) {
    print('Error loading initial dates: $e');
  }
}

void _updatePhaseProgress(int index) {
  final TextEditingController notesController = TextEditingController();
  double newProgress = phases[index].progress.toDouble();
  List<XFile> inspectionPhotos = [];
  List<InspectionRecord> inspectionHistory = [];
  bool isLoading = true;

  // Load inspection history first
  _fetchInspectionHistory(phases[index].categoryId).then((history) {
    if (mounted) {
      setState(() {
        inspectionHistory = history;
        isLoading = false;
      });
    }
  });

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Inspection Details - ${phases[index].name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // New Inspection Section
                Text(
                  'Add New Inspection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Text('Current Progress: ${phases[index].progress}%'),
                SizedBox(height: 12),
                Text('Set New Progress:'),
                Slider(
                  value: newProgress,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${newProgress.round()}%',
                  onChanged: (value) {
                    setDialogState(() => newProgress = value);
                  },
                ),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Inspection Notes',
                    hintText: 'Enter inspection details...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                
                // Photo Upload Section
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.camera_alt),
                      label: Text('Add Photos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          setDialogState(() {
                            inspectionPhotos.add(image);
                          });
                        }
                      },
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.photo_library),
                      label: Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setDialogState(() {
                            inspectionPhotos.add(image);
                          });
                        }
                      },
                    ),
                  ],
                ),

                // Selected Photos Preview
                if (inspectionPhotos.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('Selected Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: inspectionPhotos.length,
                      itemBuilder: (context, photoIndex) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Image.file(
                                File(inspectionPhotos[photoIndex].path),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setDialogState(() {
                                      inspectionPhotos.removeAt(photoIndex);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Inspection History Section
                SizedBox(height: 24),
                Text(
                  'Inspection History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                if (isLoading)
                  Center(child: CircularProgressIndicator())
                else if (inspectionHistory.isEmpty)
                  Text('No previous inspections found')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: inspectionHistory.length,
                    itemBuilder: (context, historyIndex) {
                      final inspection = inspectionHistory[historyIndex];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MM/dd/yyyy').format(inspection.date),
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${inspection.percentage.round()}%',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (inspection.notes.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(inspection.notes),
                              ],
                              if (inspection.photoUrls.isNotEmpty) ...[
                                SizedBox(height: 8),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: inspection.photoUrls.length,
                                    itemBuilder: (context, photoIndex) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Image.network(
                                          supabase.storage
                                              .from('inspection_photos')
                                              .getPublicUrl(inspection.photoUrls[photoIndex]),
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
       actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('Cancel'),
  ),
  TextButton(
    onPressed: () async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Not authenticated');

        // Save new inspection with dates and completion
        final response = await supabase
            .from('line_item_inspections')
            .insert({
              'category_id': phases[index].categoryId,
              'inspection_percentage': newProgress / 100,
              'completion_percentage': newProgress / 100,
              'inspector_notes': notesController.text,
              'inspector_id': user.id,
              'last_inspection_date': DateTime.now().toIso8601String(),
              'next_due_date': nextDue.toIso8601String(),
            })
            .select()
            .single();

        // Upload photos if any
        final photoUrls = <String>[];
        for (var photo in inspectionPhotos) {
          final bytes = await photo.readAsBytes();
          final fileName = '${response['inspection_id']}/${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
          
          await supabase.storage
            .from('inspection_photos')
            .uploadBinary(fileName, bytes);
          
          photoUrls.add(fileName);
        }

        // Update photo URLs in the inspection record
        if (photoUrls.isNotEmpty) {
          await supabase
              .from('line_item_inspections')
              .update({'photo_urls': photoUrls})
              .eq('inspection_id', response['inspection_id']);
        }

        // Set last inspection date to now and update state
        setState(() {
          lastInspection = DateTime.now();
          // Update the phase's progress
          phases[index].progress = newProgress.round();
        });

        // Refresh the data to update all UI elements
        await fetchLineItems();
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inspection saved successfully')),
        );
      } catch (e) {
        print('Error saving inspection: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving inspection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    child: Text('Save Inspection'),
  ),
],
      ),
    ),
  );
}

Future<List<InspectionRecord>> _fetchInspectionHistory(String categoryId) async {
  try {
    final response = await supabase
        .from('line_item_inspections')
        .select('*')
        .eq('category_id', categoryId)
        .order('inspection_date', ascending: false);

    return response.map<InspectionRecord>((record) => InspectionRecord.fromJson(record)).toList();
  } catch (e) {
    print('Error fetching inspection history: $e');
    return [];
  }
}

Future<void> fetchPhases() async {
  try {
    print("Starting phase data load for loan ID: ${widget.projectData['loan_id']}");
    
    // Fetch line items with their associated draws
    final lineItemsResponse = await supabase
        .from('construction_loan_line_items')
        .select('''
          *,
          construction_loan_draws (
            draw_number,
            amount,
            status
          )
        ''')
        .eq('loan_id', widget.projectData['loan_id']);

    // Group line items by phase and create ProjectPhase objects
    final Map<String, List<dynamic>> itemsByPhase = {};
    for (var item in lineItemsResponse) {
      String phaseName = item['phase_name'] ?? 'Unassigned';
      if (!itemsByPhase.containsKey(phaseName)) {
        itemsByPhase[phaseName] = [];
      }
      itemsByPhase[phaseName]!.add(item);
    }

    // Convert grouped items to ProjectPhase objects
    final List<ProjectPhase> newPhases = [];
    itemsByPhase.forEach((phaseName, items) {
      // Calculate phase progress based on inspection percentages
      double totalProgress = 0;
      for (var item in items) {
        totalProgress += item['inspection_percentage'] ?? 0;
      }
      double averageProgress = items.isEmpty ? 0 : totalProgress / items.length;

      newPhases.add(
  ProjectPhase(
    name: phaseName,
    categoryId: items.first['category_id'], // Add categoryId from the first item
    startDate: DateTime.now(),
    endDate: DateTime.now().add(Duration(days: 30)),
    isCompleted: averageProgress >= 100,
    progress: averageProgress.round(),
  )
);
    });

    setState(() {
      phases.clear();
      phases.addAll(newPhases);
    });

  } catch (e) {
    print('Error loading phase data: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading phase data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  Future<void> _updatePhaseDates(int index) async {
    DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
      initialDateRange: DateTimeRange(
        start: phases[index].startDate,
        end: phases[index].endDate,
      ),
    );

    if (dateRange != null) {
      setState(() {
        phases[index].startDate = dateRange.start;
        phases[index].endDate = dateRange.end;
      });
    }
  }
Future<void> _updateInspectionDates() async {
  try {
    // First, fetch a valid category_id for this loan
    final lineItemsResponse = await supabase
        .from('construction_loan_line_items')
        .select('category_id')
        .eq('loan_id', widget.projectData['loan_id'])
        .limit(1)
        .single();

    if (lineItemsResponse == null) {
      throw Exception('No line items found for this loan');
    }

    final categoryId = lineItemsResponse['category_id'];
    print('Using category_id: $categoryId');

    // Create temporary date variables to manage state in dialog
    DateTime tempLastInspection = lastInspection;
    DateTime tempNextDue = nextDue;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Inspection Dates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Last Inspection'),
                subtitle: Text(DateFormat('MM/dd/yyyy').format(tempLastInspection)),
                trailing: Icon(Icons.calendar_today, color: AppColors.primary),
                onTap: () async {
                  print('Opening last inspection date picker');
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: tempLastInspection,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null) {
                    print('Selected last inspection date: $picked');
                    setDialogState(() => tempLastInspection = picked);
                  }
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Next Due'),
                subtitle: Text(DateFormat('MM/dd/yyyy').format(tempNextDue)),
                trailing: Icon(Icons.calendar_today, color: AppColors.primary),
                onTap: () async {
                  print('Opening next due date picker');
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: tempNextDue,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null) {
                    print('Selected next due date: $picked');
                    setDialogState(() => tempNextDue = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final user = supabase.auth.currentUser;
                  if (user == null) throw Exception('Not authenticated');

                  print('Saving dates to database');
                  print('Category ID: $categoryId');
                  print('Last inspection: $tempLastInspection');
                  print('Next due: $tempNextDue');

                  // Create a new inspection record with the proper category_id
                  await supabase
                      .from('line_item_inspections')
                      .insert({
                        'category_id': categoryId,
                        'inspection_date': DateTime.now().toIso8601String(),
                        'last_inspection_date': tempLastInspection.toIso8601String(),
                        'next_due_date': tempNextDue.toIso8601String(),
                        'inspector_id': user.id,
                        'inspection_percentage': 0,
                        'inspector_notes': 'Date update only',
                      });

                  print('Dates saved successfully');

                  // Update state
                  setState(() {
                    lastInspection = tempLastInspection;
                    nextDue = tempNextDue;
                  });

                  Navigator.pop(context);
                  
                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Inspection dates updated successfully')),
                    );
                  }

                  // Refresh data
                  await fetchLineItems();

                } catch (e) {
                  print('Error updating dates: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating dates: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    print('Error in _updateInspectionDates: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: Unable to update inspection dates'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildInspectionStats(),
            _buildPhotoGallery(),
            _buildConstructionProgress(),
            _buildChatSection(),
            _buildSubmitSection(),
          ],
        ),
      ),
    );
  }

 AppBar _buildAppBar() {
  return AppBar(
    backgroundColor: AppColors.cardBackground,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      widget.projectData['name'] ?? 'Project Details',
      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
    ),
    actions: [
      // Debug print to verify the button is rendered
      Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.calendar_today, color: AppColors.primary),
          onPressed: () {
            print('Calendar button pressed'); // Debug print
            _updateInspectionDates(); // Call the date update function
          },
        ),
      ),
    ],
  );
}
  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Site Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          height: 140,
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: projectImages.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 140,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Center(
                      child: Icon(Icons.add_a_photo, color: AppColors.textSecondary, size: 32),
                    ),
                  ),
                );
              }
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(projectImages[index - 1].path)),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  

  Widget _buildPhaseTimelineItem(int index) {
    final phase = phases[index];
    return GestureDetector(
      onTap: () => _updatePhaseProgress(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: phase.isCompleted ? AppColors.primary : AppColors.background,
                border: Border.all(
                  color: phase.isCompleted ? AppColors.primary : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: phase.isCompleted
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        phase.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${phase.progress}%',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${DateFormat('MM/dd/yyyy').format(phase.startDate)} - ${DateFormat('MM/dd/yyyy').format(phase.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: phase.progress / 100,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat with Lender',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                return _buildChatMessage(message);
              },
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
  controller: messageController,
  decoration: InputDecoration(
    hintText: 'Type a message...',
    hintStyle: TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primary),
    ),
  ),
  style: TextStyle(color: AppColors.textPrimary),
),
              ),
              SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.send, color: AppColors.primary),
                onPressed: () {
                  if (messageController.text.isNotEmpty) {
                    setState(() {
                      chatMessages.add(ChatMessage(
                        sender: 'Inspector',
                        message: messageController.text,
                        timestamp: DateTime.now(),
                      ));
                      messageController.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatMessage(ChatMessage message) {
    final bool isInspector = message.sender == 'Inspector';
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isInspector ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isInspector) ...[
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text('L', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isInspector ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: isInspector ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isInspector ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isInspector) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Text('I', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Submit Report'),
                content: Text('Are you sure you want to submit the inspection report?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report submitted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Submit Inspection Report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.projectData['initials'] ?? 'PD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.projectData['name'] ?? 'Project Name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary
                      )
                    ),
                    Text(
                      widget.projectData['location'] ?? 'Location',
                      style: TextStyle(color: AppColors.textSecondary)
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00BA88), Color(0xFF00D1A0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.projectData['status'] ?? 'On Track',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13
            )
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary
            )
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionStats() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Last Inspection',
                  DateFormat('MM/dd/yyyy').format(lastInspection),
                  Icons.history
                )
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completion',
                  '${widget.projectData['completion'] ?? 0}%',
                  Icons.pie_chart
                )
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Next Due',
                  DateFormat('MM/dd/yyyy').format(nextDue),
                  Icons.calendar_today
                )
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildConstructionProgress() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Construction Phases', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary
            )
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: phases.length,
            itemBuilder: (context, index) => _buildPhaseTimelineItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final completion = double.tryParse(widget.projectData['completion']?.toString() ?? '0') ?? 0;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Progress',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 16
            )
          ),
          SizedBox(height: 12),
          Container(
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completion / 100,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}