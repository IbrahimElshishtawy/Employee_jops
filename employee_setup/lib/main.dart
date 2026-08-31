import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.dart';
import 'app/app_providers.dart';
import 'core/services/notification_service.dart';
import 'core/storage/secure_session_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow Google Fonts runtime fetching with local asset fallback
  GoogleFonts.config.allowRuntimeFetching = true;


  // Set preferred orientations & system overlay
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize secure local storage
  final secureStorage = SecureSessionStorage();
  await secureStorage.init();

  // Initialize local notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(secureStorage),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const EmployeeApp(),
    ),
  );
}

