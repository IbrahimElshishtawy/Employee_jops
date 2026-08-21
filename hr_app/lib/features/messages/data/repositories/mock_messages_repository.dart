import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/message_entity.dart';

/// Mock repository with realistic employee message threads
class MockMessagesRepository implements MessagesRepository {
  final List<ConversationEntity> _mockConversations = [
    ConversationEntity(
      id: 'CONV-001',
      employeeId: 'EMP-1001',
      employeeName: 'Ahmed Hassan',
      employeeCode: 'EMP-1001',
      employeeDepartment: 'Engineering',
      employeeJobTitle: 'Senior Infrastructure Engineer',
      employeeWorkplace: 'CyberWise HQ Cairo',
      lastMessageContent: 'Thank you! The salary advance installment schedule looks very clear.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      lastMessageSenderType: MessageSenderType.employee,
      unreadCount: 1,
      status: ConversationStatus.open,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ConversationEntity(
      id: 'CONV-002',
      employeeId: 'EMP-1002',
      employeeName: 'Sara Mostafa',
      employeeCode: 'EMP-1002',
      employeeDepartment: 'Human Resources',
      employeeJobTitle: 'HR Operations Lead',
      employeeWorkplace: 'CyberWise HQ Cairo',
      lastMessageContent: 'Updated the shift rotation for the Alexandria support team.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      lastMessageSenderType: MessageSenderType.hr,
      unreadCount: 0,
      status: ConversationStatus.open,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ConversationEntity(
      id: 'CONV-003',
      employeeId: 'EMP-1003',
      employeeName: 'Youssef Ali',
      employeeCode: 'EMP-1003',
      employeeDepartment: 'Operations',
      employeeJobTitle: 'Cloud Operations Specialist',
      employeeWorkplace: 'Smart Village Data Center',
      lastMessageContent: 'Could you please check my check-in record for yesterday morning? The biometric scanner took 2 minutes to sync.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
      lastMessageSenderType: MessageSenderType.employee,
      unreadCount: 2,
      status: ConversationStatus.open,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ConversationEntity(
      id: 'CONV-004',
      employeeId: 'EMP-1004',
      employeeName: 'Omar Khaled',
      employeeCode: 'EMP-1004',
      employeeDepartment: 'Engineering',
      employeeJobTitle: 'Junior QA Engineer',
      employeeWorkplace: 'CyberWise HQ Cairo',
      lastMessageContent: 'Confirmed, the medical leave approval notification has been received.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      lastMessageSenderType: MessageSenderType.employee,
      unreadCount: 0,
      status: ConversationStatus.resolved,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ConversationEntity(
      id: 'CONV-005',
      employeeId: 'EMP-1005',
      employeeName: 'Mona Mahmoud',
      employeeCode: 'EMP-1005',
      employeeDepartment: 'Marketing',
      employeeJobTitle: 'Content Strategist',
      employeeWorkplace: 'CyberWise Alexandria Hub',
      lastMessageContent: 'Can I request 2 days work-from-home next week during the regional conference?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      lastMessageSenderType: MessageSenderType.employee,
      unreadCount: 1,
      status: ConversationStatus.open,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final Map<String, List<ChatMessageEntity>> _mockThreadMessages = {
    'CONV-001': [
      ChatMessageEntity(
        id: 'MSG-001-1',
        conversationId: 'CONV-001',
        senderId: 'EMP-1001',
        senderName: 'Ahmed Hassan',
        senderType: MessageSenderType.employee,
        content: 'Hi HR team, I submitted a salary advance request for 5,000 EGP yesterday. Has it been reviewed?',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
      ChatMessageEntity(
        id: 'MSG-001-2',
        conversationId: 'CONV-001',
        senderId: 'HR-USER',
        senderName: 'HR Department',
        senderType: MessageSenderType.hr,
        content: 'Hello Ahmed! Yes, your advance request was approved by the Finance Director. It will be disbursed across 2 monthly installments of 2,500 EGP starting next payroll cycle.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      ChatMessageEntity(
        id: 'MSG-001-3',
        conversationId: 'CONV-001',
        senderId: 'EMP-1001',
        senderName: 'Ahmed Hassan',
        senderType: MessageSenderType.employee,
        content: 'Thank you! The salary advance installment schedule looks very clear.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
    ],
    'CONV-003': [
      ChatMessageEntity(
        id: 'MSG-003-1',
        conversationId: 'CONV-003',
        senderId: 'EMP-1003',
        senderName: 'Youssef Ali',
        senderType: MessageSenderType.employee,
        content: 'Good morning HR team. I arrived at Smart Village DC at 08:58 AM but my mobile check-in recorded 09:02 AM due to WiFi reconnecting.',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      ChatMessageEntity(
        id: 'MSG-003-2',
        conversationId: 'CONV-003',
        senderId: 'EMP-1003',
        senderName: 'Youssef Ali',
        senderType: MessageSenderType.employee,
        content: 'Could you please check my check-in record for yesterday morning? The biometric scanner took 2 minutes to sync.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
      ),
    ],
  };

  @override
  Future<PaginatedList<ConversationEntity>> getConversations(ConversationFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var list = List<ConversationEntity>.from(_mockConversations);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      list = list.where((c) =>
          c.employeeName.toLowerCase().contains(q) ||
          c.employeeCode.toLowerCase().contains(q) ||
          c.employeeDepartment.toLowerCase().contains(q) ||
          c.lastMessageContent.toLowerCase().contains(q)).toList();
    }

    if (filter.onlyUnread == true) {
      list = list.where((c) => c.unreadCount > 0).toList();
    }

    if (filter.department != null && filter.department!.isNotEmpty) {
      list = list.where((c) => c.employeeDepartment == filter.department).toList();
    }

    if (filter.status != null) {
      list = list.where((c) => c.status == filter.status).toList();
    }

    final totalCount = list.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<ConversationEntity>(
      items: list.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<ConversationEntity> getConversationById(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockConversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => throw Exception('Conversation not found: $conversationId'),
    );
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId, {int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockThreadMessages[conversationId] ?? [
      ChatMessageEntity(
        id: 'MSG-$conversationId-1',
        conversationId: conversationId,
        senderId: 'SYSTEM',
        senderName: 'System Bot',
        senderType: MessageSenderType.system,
        content: 'Direct communication thread initiated with HR Department.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
    ];
  }

  @override
  Future<ChatMessageEntity> sendMessage(String conversationId, String content) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final msg = ChatMessageEntity(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'HR-OFFICER',
      senderName: 'HR Administration',
      senderType: MessageSenderType.hr,
      content: content.trim(),
      timestamp: DateTime.now(),
      isRead: true,
    );

    if (!_mockThreadMessages.containsKey(conversationId)) {
      _mockThreadMessages[conversationId] = [];
    }
    _mockThreadMessages[conversationId]!.add(msg);

    // Update conversation summary
    final idx = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _mockConversations[idx] = _mockConversations[idx].copyWith(
        lastMessageContent: content.trim(),
        lastMessageTime: DateTime.now(),
        lastMessageSenderType: MessageSenderType.hr,
        unreadCount: 0,
      );
    }

    return msg;
  }

  @override
  Future<ConversationEntity> startConversation(String employeeId, String initialMessage) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = 'CONV-${DateTime.now().millisecondsSinceEpoch}';

    final newConv = ConversationEntity(
      id: newId,
      employeeId: employeeId,
      employeeName: employeeId == 'EMP-1001' ? 'Ahmed Hassan' : 'Employee ($employeeId)',
      employeeCode: employeeId,
      employeeDepartment: 'Engineering',
      employeeJobTitle: 'Software Engineer',
      employeeWorkplace: 'CyberWise HQ Cairo',
      lastMessageContent: initialMessage.trim(),
      lastMessageTime: DateTime.now(),
      lastMessageSenderType: MessageSenderType.hr,
      unreadCount: 0,
      status: ConversationStatus.open,
      createdAt: DateTime.now(),
    );

    _mockConversations.insert(0, newConv);
    _mockThreadMessages[newId] = [
      ChatMessageEntity(
        id: 'MSG-$newId-1',
        conversationId: newId,
        senderId: 'HR-OFFICER',
        senderName: 'HR Administration',
        senderType: MessageSenderType.hr,
        content: initialMessage.trim(),
        timestamp: DateTime.now(),
        isRead: true,
      ),
    ];

    return newConv;
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _mockConversations[idx] = _mockConversations[idx].copyWith(unreadCount: 0);
    }
    final messages = _mockThreadMessages[conversationId];
    if (messages != null) {
      for (int i = 0; i < messages.length; i++) {
        messages[i] = messages[i].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<MessagesKpiSummary> getMessagesKpis() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final total = _mockConversations.length;
    final unreadConvs = _mockConversations.where((c) => c.unreadCount > 0).length;
    final totalUnreadMsgs = _mockConversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
    final resolved = _mockConversations.where((c) => c.status == ConversationStatus.resolved).length;

    return MessagesKpiSummary(
      totalConversations: total,
      activeUnreadConversations: unreadConvs,
      totalUnreadMessages: totalUnreadMsgs,
      resolvedConversations: resolved,
    );
  }
}
