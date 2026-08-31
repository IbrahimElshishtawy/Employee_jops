import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/app_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import 'app_providers.dart';

class EmployeeApp extends ConsumerStatefulWidget {
  const EmployeeApp({super.key});

  @override
  ConsumerState<EmployeeApp> createState() => _EmployeeAppState();
}

class _EmployeeAppState extends ConsumerState<EmployeeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Propagate lifecycle state to background location tracking engine
    ref.read(locationTrackingProvider.notifier).handleAppLifecycle(state);

    if (state == AppLifecycleState.resumed) {
      // Refresh location and network status upon returning to foreground
      ref.read(attendanceFlowProvider.notifier).refreshLocation();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Invalidate transient pending states if app is backgrounded
      final flowState = ref.read(attendanceFlowProvider);
      if (flowState.isLoading) {
        ref.read(attendanceFlowProvider.notifier).resetState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'CyberWise IE',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: settings.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
