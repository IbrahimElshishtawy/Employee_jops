import 'package:flutter_test/flutter_test.dart';
import 'package:employee_setup/features/communication/data/datasources/communication_mock_data_source.dart';
import 'package:employee_setup/features/communication/data/repositories/communication_repository_impl.dart';
import 'package:employee_setup/features/communication/domain/entities/department_request.dart';
import 'package:employee_setup/features/communication/domain/entities/employee_contact.dart';
import 'package:employee_setup/features/communication/domain/usecases/get_departments.dart';
import 'package:employee_setup/features/communication/domain/usecases/get_allowed_contacts.dart';
import 'package:employee_setup/features/communication/domain/usecases/get_conversations.dart';
import 'package:employee_setup/features/communication/domain/usecases/send_message.dart';
import 'package:employee_setup/features/communication/domain/usecases/create_department_request.dart';
import 'package:employee_setup/features/communication/domain/usecases/accept_request.dart';
import 'package:employee_setup/features/communication/domain/usecases/reject_request.dart';
import 'package:employee_setup/features/communication/domain/usecases/start_request.dart';
import 'package:employee_setup/features/communication/domain/usecases/complete_request.dart';

void main() {
  late CommunicationMockDataSource mockDataSource;
  late CommunicationRepositoryImpl repository;

  setUp(() {
    mockDataSource = CommunicationMockDataSource(
      currentUserId: 'EMP-001',
      currentUserName: 'Ibrahim Elshishtawy',
    );
    repository = CommunicationRepositoryImpl(
      remoteDataSource: mockDataSource,
      currentUserId: 'EMP-001',
      currentUserName: 'Ibrahim Elshishtawy',
    );
  });

  group('Departments & HR', () {
    test('GetDepartments returns non-empty list with stable IDs including HR and Security', () async {
      final getDepartments = GetDepartments(repository);
      final departments = await getDepartments();

      expect(departments.isNotEmpty, isTrue);
      expect(departments.any((d) => d.id == 'SECURITY'), isTrue);
      expect(departments.any((d) => d.id == 'HUMAN_RESOURCES'), isTrue);
      expect(departments.any((d) => d.id == 'HOUSEKEEPING'), isTrue);
      expect(departments.any((d) => d.id == 'ENGINEERING'), isTrue);

      final secDept = departments.firstWhere((d) => d.id == 'SECURITY');
      expect(secDept.nameAr, 'الأمن والحراسة');
      expect(secDept.nameEn, 'Security & Safety');
      expect(secDept.localizedName(true), 'الأمن والحراسة');
      expect(secDept.localizedName(false), 'Security & Safety');
    });

    test('HR Department uses the same communication infrastructure', () async {
      final getContacts = GetAllowedContacts(repository);
      final hrContacts = await getContacts(departmentId: 'HUMAN_RESOURCES');

      expect(hrContacts.isNotEmpty, isTrue);
      final hrMember = hrContacts.first;
      expect(hrMember.departmentId, 'HUMAN_RESOURCES');
      expect(hrMember.canChat, isTrue);
    });
  });

  group('Allowed Contacts & Employees', () {
    test('Filters contacts by department and respects availability', () async {
      final getContacts = GetAllowedContacts(repository);
      final secContacts = await getContacts(departmentId: 'SECURITY');

      expect(secContacts.length, 3);
      expect(secContacts.any((c) => c.fullName == 'Mohamed Ali'), isTrue);
      expect(secContacts.any((c) => c.fullName == 'Ahmed Hassan'), isTrue);
      expect(secContacts.any((c) => c.fullName == 'Mahmoud Samir'), isTrue);

      final mohamed = secContacts.firstWhere((c) => c.fullName == 'Mohamed Ali');
      expect(mohamed.availability, EmployeeAvailability.available);
      expect(mohamed.isOnline, isTrue);

      final mahmoud = secContacts.firstWhere((c) => c.fullName == 'Mahmoud Samir');
      expect(mahmoud.availability, EmployeeAvailability.offline);
      expect(mahmoud.isOnline, isFalse);
    });
  });

  group('Conversations & Messages', () {
    test('GetConversations returns active chats with latest messages', () async {
      final getConversations = GetConversations(repository);
      final conversations = await getConversations();

      expect(conversations.isNotEmpty, isTrue);
      expect(conversations.any((c) => c.departmentId == 'SECURITY'), isTrue);
      expect(conversations.any((c) => c.departmentId == 'HUMAN_RESOURCES'), isTrue);
    });

    test('SendMessage sends a new message and updates conversation', () async {
      final sendMessage = SendMessage(repository);
      final msg = await sendMessage(
        conversationId: 'CONV-001',
        receiverId: 'EMP-SEC-01',
        content: 'Testing direct message dispatch',
      );

      expect(msg.id.isNotEmpty, isTrue);
      expect(msg.content, 'Testing direct message dispatch');
      expect(msg.senderId, 'EMP-001');

      final messages = await repository.getMessages('CONV-001');
      expect(messages.any((m) => m.id == msg.id), isTrue);
    });

    test('GetOrCreateConversation returns existing or creates a new conversation', () async {
      final conv = await repository.getOrCreateConversation(
        recipientId: 'EMP-ENG-01',
        departmentId: 'ENGINEERING',
      );

      expect(conv.id.isNotEmpty, isTrue);
      expect(conv.participantIds.contains('EMP-ENG-01'), isTrue);
      expect(conv.departmentId, 'ENGINEERING');
    });
  });

  group('Department Requests & Status Lifecycle', () {
    test('CreateDepartmentRequest creates pending request with priority and notification details', () async {
      final createReq = CreateDepartmentRequest(repository);
      final req = await createReq(
        departmentId: 'SECURITY',
        requestTypeId: 'SECURITY_ASSISTANCE',
        priority: RequestPriority.high,
        message: 'Need urgent security presence at main gate',
        locationContext: 'Gate 1',
      );

      expect(req.id.isNotEmpty, isTrue);
      expect(req.status, DepartmentRequestStatus.pending);
      expect(req.priority, RequestPriority.high);
      expect(req.message, 'Need urgent security presence at main gate');
      expect(req.locationContext, 'Gate 1');
    });

    test('Request Lifecycle Transition: PENDING -> ACCEPTED -> IN_PROGRESS -> COMPLETED', () async {
      final createReq = CreateDepartmentRequest(repository);
      final acceptReq = AcceptRequest(repository);
      final startReq = StartRequest(repository);
      final completeReq = CompleteRequest(repository);

      // 1. Create (PENDING)
      final created = await createReq(
        departmentId: 'ENGINEERING',
        requestTypeId: 'MAINTENANCE',
        priority: RequestPriority.normal,
        message: 'AC repair in meeting room',
      );
      expect(created.status, DepartmentRequestStatus.pending);

      // 2. Accept (ACCEPTED)
      final accepted = await acceptReq(created.id);
      expect(accepted.status, DepartmentRequestStatus.accepted);

      // 3. Start (IN_PROGRESS)
      final started = await startReq(created.id);
      expect(started.status, DepartmentRequestStatus.inProgress);

      // 4. Complete (COMPLETED)
      final completed = await completeReq(created.id);
      expect(completed.status, DepartmentRequestStatus.completed);
      expect(completed.status.isTerminal, isTrue);
    });

    test('Request Lifecycle Rejection: PENDING -> REJECTED with reason', () async {
      final createReq = CreateDepartmentRequest(repository);
      final rejectReq = RejectRequest(repository);

      final created = await createReq(
        departmentId: 'HOUSEKEEPING',
        requestTypeId: 'HOUSEKEEPING_ASSISTANCE',
        priority: RequestPriority.low,
        message: 'Extra towels',
      );
      expect(created.status, DepartmentRequestStatus.pending);

      final rejected = await rejectReq(created.id, reason: 'Department out of stock');
      expect(rejected.status, DepartmentRequestStatus.rejected);
      expect(rejected.rejectionReason, 'Department out of stock');
      expect(rejected.status.isTerminal, isTrue);
    });

    test('Invalid transitions throw Exception', () async {
      final createReq = CreateDepartmentRequest(repository);
      final completeReq = CompleteRequest(repository);

      final created = await createReq(
        departmentId: 'IT',
        requestTypeId: 'TECHNICAL_SUPPORT',
        priority: RequestPriority.normal,
        message: 'Printer issue',
      );

      // Attempting to complete a PENDING request directly should throw
      expect(() => completeReq(created.id), throwsA(isA<Exception>()));
    });
  });
}
