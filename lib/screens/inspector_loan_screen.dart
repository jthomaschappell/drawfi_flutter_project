import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Project Data Model
class ProjectPhase {
  String name;
  DateTime startDate;
  DateTime endDate;
  bool isCompleted;
  int progress;

  ProjectPhase({
    required this.name,
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
    phases.addAll([
      ProjectPhase(
        name: 'Foundation',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 15),
        isCompleted: true,
        progress: 100,
      ),
      ProjectPhase(
        name: 'Structural',
        startDate: DateTime(2024, 2, 16),
        endDate: DateTime(2024, 4, 30),
        isCompleted: false,
        progress: 75,
      ),
      ProjectPhase(
        name: 'Electrical',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 6, 15),
        isCompleted: false,
        progress: 30,
      ),
      ProjectPhase(
        name: 'Plumbing',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 6, 30),
        isCompleted: false,
        progress: 45,
      ),
      ProjectPhase(
        name: 'Finishing',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 8, 30),
        isCompleted: false,
        progress: 0,
      ),
    ]);
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

  void _updatePhaseProgress(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Progress'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${phases[index].name} Progress: ${phases[index].progress}%'),
              Slider(
                value: phases[index].progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${phases[index].progress}%',
                onChanged: (value) {
                  setDialogState(() {
                    phases[index].progress = value.round();
                  });
                },
              ),
              TextButton(
                onPressed: () => _updatePhaseDates(index),
                child: Text('Update Dates'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                phases[index].isCompleted = phases[index].progress == 100;
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                phases.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('Remove Phase'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Inspection Dates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Last Inspection'),
              subtitle: Text(DateFormat('MM/dd/yyyy').format(lastInspection)),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: lastInspection,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2025),
                );
                if (picked != null) {
                  setState(() => lastInspection = picked);
                }
              },
            ),
            ListTile(
              title: Text('Next Due'),
              subtitle: Text(DateFormat('MM/dd/yyyy').format(nextDue)),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: nextDue,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2025),
                );
                if (picked != null) {
                  setState(() => nextDue = picked);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
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
        IconButton(
          icon: Icon(Icons.calendar_today, color: AppColors.primary),
          onPressed: _updateInspectionDates,
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