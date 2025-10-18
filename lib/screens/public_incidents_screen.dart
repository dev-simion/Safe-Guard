import 'package:flutter/material.dart';
import 'package:guardian_shield/models/public_incident.dart';
import 'package:guardian_shield/services/incident_service.dart';
import 'package:guardian_shield/services/location_service.dart';
import 'package:guardian_shield/services/storage_service.dart';
import 'package:guardian_shield/supabase/supabase_config.dart';
import 'package:file_picker/file_picker.dart';

class PublicIncidentsScreen extends StatefulWidget {
  const PublicIncidentsScreen({super.key});

  @override
  State<PublicIncidentsScreen> createState() => _PublicIncidentsScreenState();
}

class _PublicIncidentsScreenState extends State<PublicIncidentsScreen> {
  final _incidentService = IncidentService();
  final _storageService = StorageService();
  List<PublicIncident> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    final incidents = await _incidentService.getAllIncidents();
    setState(() {
      _incidents = incidents;
      _isLoading = false;
    });
  }

  Future<void> _showContributeDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    List<PlatformFile> selectedFiles = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Report Incident',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final file = await _storageService.pickImage();
                            if (file != null) {
                              setModalState(() => selectedFiles.add(file));
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final files = await _storageService.pickMultipleImages();
                            if (files.isNotEmpty) {
                              setModalState(() => selectedFiles.addAll(files));
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Multiple'),
                        ),
                      ),
                    ],
                  ),
                  if (selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('${selectedFiles.length} file(s) selected'),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty || descController.text.isEmpty) {
                          return;
                        }

                        Navigator.pop(context);
                        _submitIncident(
                          titleController.text,
                          descController.text,
                          selectedFiles,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitIncident(String title, String desc, List<PlatformFile> files) async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    final position = await LocationService.getCurrentLocation();
    if (position == null) return;

    final mediaUrls = await _storageService.uploadMultipleFiles(files, 'incidents');

    await _incidentService.createIncident(
      userId: userId,
      title: title,
      description: desc,
      latitude: position.latitude,
      longitude: position.longitude,
      mediaUrls: mediaUrls,
    );

    _loadIncidents();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Public Incidents',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : RefreshIndicator(
              onRefresh: _loadIncidents,
              child: _incidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.public, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No incidents reported yet',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _incidents.length,
                      itemBuilder: (context, index) => _IncidentCard(
                        incident: _incidents[index],
                        onVote: _loadIncidents,
                        incidentService: _incidentService,
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showContributeDialog,
        backgroundColor: theme.colorScheme.primary,
        icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        label: Text('Contribute', style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final PublicIncident incident;
  final VoidCallback onVote;
  final IncidentService incidentService;

  const _IncidentCard({
    required this.incident,
    required this.onVote,
    required this.incidentService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    incident.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              incident.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (incident.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.image, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${incident.mediaUrls.length} attachment(s)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    final userId = SupabaseConfig.auth.currentUser?.id;
                    if (userId != null) {
                      await incidentService.upvoteIncident(incident.id, userId);
                      onVote();
                    }
                  },
                  icon: const Icon(Icons.thumb_up),
                  color: theme.colorScheme.primary,
                ),
                Text('${incident.upvotes}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () async {
                    final userId = SupabaseConfig.auth.currentUser?.id;
                    if (userId != null) {
                      await incidentService.downvoteIncident(incident.id, userId);
                      onVote();
                    }
                  },
                  icon: const Icon(Icons.thumb_down),
                  color: theme.colorScheme.error,
                ),
                Text('${incident.downvotes}'),
                const Spacer(),
                Text(
                  _formatDate(incident.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}