import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/features/communication/domain/entities/department.dart';
import 'package:employee_setup/features/communication/domain/entities/department_request.dart';
import 'package:employee_setup/features/communication/domain/entities/employee_contact.dart';
import 'package:employee_setup/features/communication/domain/entities/message.dart';
import 'package:employee_setup/features/communication/presentation/screens/communication_screen.dart';
import 'package:employee_setup/features/communication/presentation/screens/create_request_screen.dart';
import 'package:employee_setup/features/communication/presentation/widgets/department_card.dart';
import 'package:employee_setup/features/communication/presentation/widgets/employee_contact_card.dart';
import 'package:employee_setup/features/communication/presentation/widgets/message_bubble.dart';
import 'package:employee_setup/features/communication/presentation/widgets/request_card.dart';

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DepartmentCard Widget Tests', () {
    testWidgets('Renders Arabic department name and availability badge', (tester) async {
      const dept = Department(
        id: 'SECURITY',
        nameAr: 'الأمن والحراسة',
        nameEn: 'Security & Safety',
        iconName: 'security',
        availableEmployeesCount: 4,
        totalEmployeesCount: 6,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const DepartmentCard(department: dept),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الأمن والحراسة'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6 موظف'), findsOneWidget);
    });

    testWidgets('Renders English department name in dark mode', (tester) async {
      const dept = Department(
        id: 'HOUSEKEEPING',
        nameAr: 'خدمة الغرف',
        nameEn: 'Housekeeping',
        iconName: 'cleaning_services',
        availableEmployeesCount: 5,
        totalEmployeesCount: 10,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const DepartmentCard(department: dept),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Housekeeping'), findsOneWidget);
      expect(find.text('10 members'), findsOneWidget);
    });
  });

  group('EmployeeContactCard Widget Tests', () {
    testWidgets('Renders employee contact card details and availability correctly', (tester) async {
      const contact = EmployeeContact(
        id: 'EMP-01',
        fullName: 'Mohamed Ali',
        jobTitleAr: 'مشرف أمن',
        jobTitleEn: 'Security Supervisor',
        departmentId: 'SECURITY',
        isOnline: true,
        availability: EmployeeAvailability.available,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const EmployeeContactCard(contact: contact),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mohamed Ali'), findsOneWidget);
      expect(find.text('مشرف أمن'), findsOneWidget);
      expect(find.text('متاح الآن'), findsOneWidget);
    });
  });

  group('MessageBubble Widget Tests', () {
    testWidgets('Renders incoming and outgoing message bubbles correctly', (tester) async {
      final msgMe = Message(
        id: 'MSG-01',
        conversationId: 'CONV-01',
        senderId: 'EMP-001',
        senderName: 'Ibrahim',
        receiverId: 'EMP-002',
        content: 'Hello, need urgent assistance',
        createdAt: DateTime.now(),
        status: MessageStatus.delivered,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: MessageBubble(message: msgMe, isMe: true),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello, need urgent assistance'), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    });
  });

  group('RequestCard Widget Tests', () {
    testWidgets('Renders request card details and status badge', (tester) async {
      final req = DepartmentRequest(
        id: 'REQ-101',
        departmentId: 'SECURITY',
        departmentNameAr: 'الأمن والحراسة',
        departmentNameEn: 'Security',
        requesterId: 'EMP-001',
        requesterName: 'Ibrahim',
        requestTypeId: 'SECURITY_ASSISTANCE',
        requestTypeNameAr: 'مساعدة أمنية',
        requestTypeNameEn: 'Security Assistance',
        priority: RequestPriority.high,
        message: 'Security assistance required at reception',
        createdAt: DateTime.now(),
        status: DepartmentRequestStatus.inProgress,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: RequestCard(request: req, onTap: () {}),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#REQ-101'), findsOneWidget);
      expect(find.text('مساعدة أمنية'), findsOneWidget);
      expect(find.text('الأمن والحراسة'), findsOneWidget);
      expect(find.text('جاري التنفيذ'), findsOneWidget);
    });
  });

  group('CreateRequestScreen Widget Tests', () {
    testWidgets('Renders CreateRequestScreen with form fields and submit button', (tester) async {
      final storage = SharedPrefsStorage();
      await storage.init();

      await tester.pumpWidget(
        _buildTestApp(
          child: const CreateRequestScreen(initialDepartmentId: 'SECURITY'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إنشاء طلب تشغيلي'), findsOneWidget);
      expect(find.text('القسم المستهدف'), findsOneWidget);
      expect(find.text('مستوى الأولوية'), findsOneWidget);
      expect(find.text('إرسال الطلب التشغيلي'), findsOneWidget);
    });
  });

  group('CommunicationScreen Widget Tests', () {
    testWidgets('Renders CommunicationScreen with sections', (tester) async {
      final storage = SharedPrefsStorage();
      await storage.init();

      await tester.pumpWidget(
        _buildTestApp(
          child: const CommunicationScreen(),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('التواصل والعمليات'), findsOneWidget);
      expect(find.text('أقسام الفندق'), findsOneWidget);
      expect(find.text('محادثاتي الأخيرة'), findsOneWidget);
    });
  });
}
