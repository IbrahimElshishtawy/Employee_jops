import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/app_localizations.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/update/presentation/providers/update_provider.dart';
import '../core/update/presentation/widgets/update_dialog.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackgroundServices();
    });
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      final notifService = ref.read(notificationServiceProvider);
      final granted = await notifService.requestPermission();
      if (granted) {
        // Send welcoming notification to confirm background capability
        await notifService.showNotification(
          id: 9901,
          title: 'تطبيق الموظف الذكي ',
          body: 'تم تفعيل الإشعارات وتأمين تتبع الدوام في الخلفية بنجاح.',
        );
      }
    } catch (_) {}

    // Initialize update service & check for updates
    try {
      final updateService = ref.read(updateServiceProvider);
      await updateService.initialize();
    } catch (_) {}
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
      // Refresh location, network status, and check for updates
      ref.read(attendanceFlowProvider.notifier).refreshLocation();
      ref.read(updateStateProvider.notifier).checkForUpdate(isManual: false);
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

    ref.listen<UpdateState>(updateStateProvider, (prev, next) {
      if (next.hasStoreUpdate && (prev == null || !prev.hasStoreUpdate)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = router.routerDelegate.navigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            UpdateDialog.show(ctx, checkResult: next.checkResult!);
          }
        });
      }
    });

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
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
