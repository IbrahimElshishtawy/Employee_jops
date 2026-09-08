import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../utils/secure_logger.dart';

class UploadedFileResult {
  final String url;
  final String filename;
  final int sizeBytes;

  const UploadedFileResult({
    required this.url,
    required this.filename,
    required this.sizeBytes,
  });

  factory UploadedFileResult.fromJson(Map<String, dynamic> json) => UploadedFileResult(
        url: json['url'] as String? ?? json['path'] as String? ?? '',
        filename: json['filename'] as String? ?? json['name'] as String? ?? 'file',
        sizeBytes: json['sizeBytes'] as int? ?? json['size'] as int? ?? 0,
      );
}

class FileUploadService {
  final ApiClient apiClient;
  final ImagePicker _picker = ImagePicker();

  FileUploadService(this.apiClient);

  /// Prompts user to pick an image from Camera or Gallery.
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        return File(picked.path);
      }
    } catch (e) {
      SecureLogger.error('FileUploadService', 'Error picking image', e);
    }
    return null;
  }

  /// Uploads a file via POST /api/v1/storage/upload using Base64 payload or Multipart.
  Future<UploadedFileResult?> uploadFile(
    File file, {
    String folder = 'attachments',
    void Function(int count, int total)? onProgress,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final filename = file.path.split(Platform.pathSeparator).last;

      final response = await apiClient.post(
        ApiEndpoints.storageUpload,
        data: {
          'filename': filename,
          'folder': folder,
          'base64Data': base64String,
          'size': bytes.length,
        },
        fromData: (data) => UploadedFileResult.fromJson(data as Map<String, dynamic>),
      );

      return response.data;
    } on ApiException catch (e) {
      SecureLogger.error('FileUploadService', 'File upload API failed', e);
      return null;
    } catch (e) {
      SecureLogger.error('FileUploadService', 'File upload failed', e);
      return null;
    }
  }
}
