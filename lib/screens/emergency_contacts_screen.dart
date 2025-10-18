import 'package:flutter/material.dart';
import '../services/user_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, String>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final userProfile = await UserService.getUserProfile();
    if (userProfile != null && userProfile['emergency_contacts'] != null) {
      setState(() {
        _contacts = List<Map<String, String>>.from(
          (userProfile['emergency_contacts'] as List).map(
            (contact) => Map<String, String>.from(contact),
          ),
        );
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContacts() async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Saving emergency contacts...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    final success = await UserService.updateEmergencyContacts(_contacts);
    
    // Clear the loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contacts updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update emergency contacts. Please check your internet connection and try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _addContact() {
    setState(() {
      _contacts.add({'name': '', 'phone': '', 'relationship': ''});
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          if (_contacts.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'clear_all') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Contacts'),
                      content: const Text('Are you sure you want to remove all emergency contacts?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    setState(() => _contacts.clear());
                    await _saveContacts();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
                ),
              ],
            ),
          TextButton(
            onPressed: _saveContacts,
            child: Text(
              'Save',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Add trusted contacts who will be notified during emergencies',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ..._contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return _ContactCard(
                    contact: contact,
                    onChanged: (updatedContact) {
                      setState(() {
                        _contacts[index] = updatedContact;
                      });
                    },
                    onRemove: () => _removeContact(index),
                  );
                }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Contact'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, String> contact;
  final Function(Map<String, String>) onChanged;
  final VoidCallback onRemove;

  const _ContactCard({
    required this.contact,
    required this.onChanged,
    required this.onRemove,
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
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Emergency Contact',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: contact['name'],
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (value) {
                final updated = Map<String, String>.from(contact);
                updated['name'] = value;
                onChanged(updated);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: contact['phone'],
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                final updated = Map<String, String>.from(contact);
                updated['phone'] = value;
                onChanged(updated);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: contact['relationship'],
              decoration: const InputDecoration(
                labelText: 'Relationship',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.family_restroom),
                hintText: 'e.g., Parent, Spouse, Friend',
              ),
              onChanged: (value) {
                final updated = Map<String, String>.from(contact);
                updated['relationship'] = value;
                onChanged(updated);
              },
            ),
          ],
        ),
      ),
    );
  }
}