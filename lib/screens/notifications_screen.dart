import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onPublicIncidentsTap;
  final List newIncidents;

  const NotificationsScreen({
    super.key,
    required this.onPublicIncidentsTap,
    required this.newIncidents,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showIncidentNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          if (widget.newIncidents.isNotEmpty && _showIncidentNotification)
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text('New Public Incidents (${widget.newIncidents.length})'),
              subtitle: const Text('Tap to view latest updates'),
              onTap: () {
                setState(() {
                  _showIncidentNotification = false;
                });
                widget.onPublicIncidentsTap();
              },
              trailing: const Icon(Icons.chevron_right),
            ),
          if (widget.newIncidents.isEmpty || !_showIncidentNotification)
            const ListTile(
              title: Text('No new notifications'),
            ),
        ],
      ),
    );
  }
}