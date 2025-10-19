import 'package:guardian_shield/services/supabase_service.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  static const String _bucketName = 'storage-server';

  Future<String?> uploadFile(PlatformFile file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$folder/$fileName';
      final bytes = file.bytes!;

      await SupabaseService.client.storage
          .from(_bucketName)
          .uploadBinary(path, bytes);

      final url = SupabaseService.client.storage
          .from(_bucketName)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> uploadMultipleFiles(List<PlatformFile> files, String folder) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadFile(file, folder);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<PlatformFile?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      return result?.files.first;
    } catch (e) {
      return null;
    }
  }

  Future<List<PlatformFile>> pickMultipleImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      return result?.files ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<PlatformFile?> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );
      return result?.files.first;
    } catch (e) {
      return null;
    }
  }
}
