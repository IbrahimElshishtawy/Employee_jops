import 'dart:io';
import '../../domain/entities/chat_settings.dart';
import '../../../../core/utils/secure_logger.dart';

class ChatStorageService {
  Future<ChatStorageBreakdown> calculateStorageUsage() async {
    try {
      int cachedBytes = 0;
      final tempDir = Directory.systemTemp;
      if (await tempDir.exists()) {
        try {
          await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              cachedBytes += await entity.length();
            }
          }
        } catch (_) {
          // Ignore permission or file-lock errors on specific temp files
        }
      }

      // Bound cachedBytes safely for realistic display if systemTemp has other OS data
      final displayCacheBytes = cachedBytes.clamp(0, 50 * 1024 * 1024); // max 50MB

      return ChatStorageBreakdown(
        imagesBytes: 0,
        videosBytes: 0,
        filesBytes: 0,
        voiceMessagesBytes: 0,
        cachedDataBytes: displayCacheBytes,
      );
    } catch (e) {
      SecureLogger.error('ChatStorageService', 'calculateStorageUsage error', e);
      return const ChatStorageBreakdown(
        imagesBytes: 0,
        videosBytes: 0,
        filesBytes: 0,
        voiceMessagesBytes: 0,
        cachedDataBytes: 0,
      );
    }
  }

  Future<bool> clearCache() async {
    try {
      final tempDir = Directory.systemTemp;
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: false)) {
          try {
            if (entity is File && entity.path.contains('cache')) {
              await entity.delete();
            }
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      SecureLogger.error('ChatStorageService', 'clearCache error', e);
      return false;
    }
  }
}
