import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Project {
  final String name;
  final String description;
  final double progress;
  final String status;

  Project({
    required this.name,
    required this.description,
    required this.progress,
    required this.status,
  });

  factory Project.fromDatabase(Map<String, dynamic> data) {
    return Project(
      name: data['draw_request_id'] ?? 'Unknown Project',
      description: data['description'] ?? 'No description provided',
      progress: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Unknown',
    );
  }
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final List<Project> _projects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('draw_requests')
          .select()
          .order('created_at', ascending: false);

      if (response is List) {
        final projects = response
            .map((data) => Project.fromDatabase(data as Map<String, dynamic>))
            .toList();

        setState(() {
          _projects.addAll(projects);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _viewProjectDetails(Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: Colors.grey[300],
                    color: project.progress >= 75
                        ? Colors.green
                        : project.progress >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${project.progress.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Status: ${project.status}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: project.status == 'On Track'
                    ? Colors.green
                    : project.status == 'At Risk'
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Projects',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : _projects.isEmpty
              ? const Center(
                  child: Text(
                    'No projects found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: InkWell(
                          onTap: () => _viewProjectDetails(project),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  project.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: project.progress / 100,
                                        backgroundColor: Colors.grey[300],
                                        color: project.progress >= 75
                                            ? Colors.green
                                            : project.progress >= 50
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${project.progress.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Status: ${project.status}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: project.status == 'On Track'
                                        ? Colors.green
                                        : project.status == 'At Risk'
                                            ? Colors.orange
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
