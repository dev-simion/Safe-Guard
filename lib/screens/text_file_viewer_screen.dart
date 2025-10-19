import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class TextFileViewerScreen extends StatelessWidget {
  final String? filePath;
  final String? assetPath;
  final String title;

  const TextFileViewerScreen({
    super.key,
    this.filePath,
    this.assetPath,
    required this.title,
  });

  Future<String> _loadFile(BuildContext context) async {
    try {
      if (assetPath != null) {
        return await rootBundle.loadString(assetPath!);
      } else if (filePath != null) {
        return await File(filePath!).readAsString();
      } else {
        return 'No file specified.';
      }
    } catch (e) {
      return 'Failed to load file: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: _loadFile(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Text(snapshot.data ?? '', style: const TextStyle(fontSize: 16)),
            ),
          );
        },
      ),
    );
  }
}
