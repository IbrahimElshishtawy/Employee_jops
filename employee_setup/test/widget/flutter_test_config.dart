import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  HttpOverrides.global = _TestHttpOverrides();
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
