import 'dart:async';
import '../../domain/entities/employee_contact.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/department_request.dart';
import '../../domain/entities/message.dart';
import '../models/department_model.dart';
import '../models/employee_contact_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/department_request_model.dart';
import '../models/request_type_model.dart';
import 'communication_remote_data_source.dart';

class CommunicationMockDataSource implements CommunicationRemoteDataSource {
  final String currentUserId;
  final String currentUserName;

  CommunicationMockDataSource({
    this.currentUserId = 'EMP-001',
    this.currentUserName = 'Ibrahim Elshishtawy',
  }) {
    _initializeSeedData();
  }

  final List<DepartmentModel> _departments = [];
  final List<EmployeeContactModel> _contacts = [];
  final List<ConversationModel> _conversations = [];
  final List<MessageModel> _messages = [];
  final List<RequestTypeModel> _requestTypes = [];
  final List<DepartmentRequestModel> _requests = [];

  void _initializeSeedData() {
    // 1. Departments
    _departments.addAll([
      const DepartmentModel(
        id: 'SECURITY',
        nameAr: 'الأمن والحراسة',
        nameEn: 'Security & Safety',
        iconName: 'security',
        descriptionAr: 'حماية المنشأة، تأمين النزلاء، وإجراءات السلامة والطوارئ',
        descriptionEn: 'Facility protection, guest safety, and emergency response',
        availableEmployeesCount: 4,
        totalEmployeesCount: 6,
      ),
      const DepartmentModel(
        id: 'HOUSEKEEPING',
        nameAr: 'خدمة الغرف والنظافة',
        nameEn: 'Housekeeping',
        iconName: 'cleaning_services',
        descriptionAr: 'نظافة الغرف، المرافق العامة، وغسيل المفروشات',
        descriptionEn: 'Room cleaning, public area maintenance, and laundry',
        availableEmployeesCount: 8,
        totalEmployeesCount: 12,
      ),
      const DepartmentModel(
        id: 'ENGINEERING',
        nameAr: 'الهندسة والصيانة',
        nameEn: 'Engineering & Maintenance',
        iconName: 'engineering',
        descriptionAr: 'الصيانة الفنية، السباكة، التكييف، والكهرباء',
        descriptionEn: 'Technical maintenance, plumbing, HVAC, and electrical',
        availableEmployeesCount: 3,
        totalEmployeesCount: 5,
      ),
      const DepartmentModel(
        id: 'FRONT_OFFICE',
        nameAr: 'المكاتب الأمامية والاستقبال',
        nameEn: 'Front Office & Reception',
        iconName: 'room_service',
        descriptionAr: 'تسجيل الوصول، خدمة النزلاء، والكونسيرج',
        descriptionEn: 'Check-in, guest relations, and concierge services',
        availableEmployeesCount: 5,
        totalEmployeesCount: 7,
      ),
      const DepartmentModel(
        id: 'HUMAN_RESOURCES',
        nameAr: 'الموارد البشرية (HR)',
        nameEn: 'Human Resources (HR)',
        iconName: 'badge',
        descriptionAr: 'خدمات الموظفين، الإجازات، الرواتب، والتدريب',
        descriptionEn: 'Employee services, leaves, payroll, and training',
        availableEmployeesCount: 3,
        totalEmployeesCount: 4,
      ),
      const DepartmentModel(
        id: 'FOOD_BEVERAGE',
        nameAr: 'الأغذية والمشروبات',
        nameEn: 'Food & Beverage',
        iconName: 'restaurant',
        descriptionAr: 'المطاعم، الكافيهات، وخدمات الضيافة',
        descriptionEn: 'Restaurants, cafes, and hospitality services',
        availableEmployeesCount: 6,
        totalEmployeesCount: 9,
      ),
      const DepartmentModel(
        id: 'KITCHEN',
        nameAr: 'المطبخ والطهي',
        nameEn: 'Kitchen & Culinary',
        iconName: 'soup_kitchen',
        descriptionAr: 'إعداد الوجبات، سلامة الغذاء، ومراقبة الجودة',
        descriptionEn: 'Meal preparation, food safety, and quality control',
        availableEmployeesCount: 4,
        totalEmployeesCount: 6,
      ),
      const DepartmentModel(
        id: 'IT',
        nameAr: 'تكنولوجيا المعلومات (IT)',
        nameEn: 'Information Technology (IT)',
        iconName: 'computer',
        descriptionAr: 'الشبكات، أنظمة الفندق، والدعم الفني للأجهزة',
        descriptionEn: 'Networks, hotel management systems, and device support',
        availableEmployeesCount: 2,
        totalEmployeesCount: 3,
      ),
      const DepartmentModel(
        id: 'FINANCE',
        nameAr: 'المالية والحسابات',
        nameEn: 'Finance & Accounting',
        iconName: 'account_balance_wallet',
        descriptionAr: 'المحاسبة، التدقيق، والمصروفات التشغيلية',
        descriptionEn: 'Accounting, auditing, and operational expenses',
        availableEmployeesCount: 2,
        totalEmployeesCount: 3,
      ),
      const DepartmentModel(
        id: 'SALES_MARKETING',
        nameAr: 'المبيعات والتسويق',
        nameEn: 'Sales & Marketing',
        iconName: 'campaign',
        descriptionAr: 'عروض الشركات، الحجوزات الجماعية، والتسويق',
        descriptionEn: 'Corporate deals, group bookings, and marketing',
        availableEmployeesCount: 3,
        totalEmployeesCount: 4,
      ),
      const DepartmentModel(
        id: 'RESERVATIONS',
        nameAr: 'إدارة الحجوزات',
        nameEn: 'Reservations',
        iconName: 'event_available',
        descriptionAr: 'حجوزات الغرف، الإلغاءات، واستفسارات الأسعار',
        descriptionEn: 'Room bookings, cancellations, and rate queries',
        availableEmployeesCount: 2,
        totalEmployeesCount: 3,
      ),
      const DepartmentModel(
        id: 'PURCHASING',
        nameAr: 'المشتريات والتموين',
        nameEn: 'Purchasing & Supply',
        iconName: 'shopping_cart',
        descriptionAr: 'طلبات الشراء، الموردين، وإمدادات الفندق',
        descriptionEn: 'Purchase orders, vendors, and hotel supplies',
        availableEmployeesCount: 1,
        totalEmployeesCount: 2,
      ),
      const DepartmentModel(
        id: 'STORES',
        nameAr: 'المخازن والمستودعات',
        nameEn: 'Stores & Inventory',
        iconName: 'inventory_2',
        descriptionAr: 'إدارة المخزون، العهد، وصرف المواد',
        descriptionEn: 'Inventory management, custody, and material dispatch',
        availableEmployeesCount: 2,
        totalEmployeesCount: 2,
      ),
      const DepartmentModel(
        id: 'BANQUETS_EVENTS',
        nameAr: 'الحفلات والفعاليات',
        nameEn: 'Banquets & Events',
        iconName: 'celebration',
        descriptionAr: 'تنظيم المؤتمرات، قاعات الأفراح، وتجهيز الفعاليات',
        descriptionEn: 'Conferences, wedding halls, and event setups',
        availableEmployeesCount: 3,
        totalEmployeesCount: 4,
      ),
      const DepartmentModel(
        id: 'RECREATION',
        nameAr: 'الأنشطة الترفيهية والسبا',
        nameEn: 'Recreation & Spa',
        iconName: 'pool',
        descriptionAr: 'حمام السباحة، الجيم، النادي الصحي، والأنشطة',
        descriptionEn: 'Swimming pool, gym, health club, and activities',
        availableEmployeesCount: 2,
        totalEmployeesCount: 3,
      ),
    ]);

    // 2. Contacts (Allowed employees per department)
    _contacts.addAll([
      // Security
      const EmployeeContactModel(
        id: 'EMP-SEC-01',
        fullName: 'Mohamed Ali',
        jobTitleAr: 'مشرف الأمن والسلامة',
        jobTitleEn: 'Security Supervisor',
        departmentId: 'SECURITY',
        departmentNameAr: 'الأمن والحراسة',
        departmentNameEn: 'Security & Safety',
        isOnline: true,
        availability: EmployeeAvailability.available,
        phone: '+201001234567',
        email: 'mohamed.ali@cyberwise.com',
      ),
      const EmployeeContactModel(
        id: 'EMP-SEC-02',
        fullName: 'Ahmed Hassan',
        jobTitleAr: 'فرد أمن مناوب',
        jobTitleEn: 'Duty Security Guard',
        departmentId: 'SECURITY',
        departmentNameAr: 'الأمن والحراسة',
        departmentNameEn: 'Security & Safety',
        isOnline: true,
        availability: EmployeeAvailability.available,
        phone: '+201007654321',
        email: 'ahmed.hassan@cyberwise.com',
      ),
      EmployeeContactModel(
        id: 'EMP-SEC-03',
        fullName: 'Mahmoud Samir',
        jobTitleAr: 'حارس أمن',
        jobTitleEn: 'Security Guard',
        departmentId: 'SECURITY',
        departmentNameAr: 'الأمن والحراسة',
        departmentNameEn: 'Security & Safety',
        isOnline: false,
        availability: EmployeeAvailability.offline,
        lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
        phone: '+201009876543',
      ),

      // Housekeeping
      const EmployeeContactModel(
        id: 'EMP-HK-01',
        fullName: 'Fatma Al-Zahraa',
        jobTitleAr: 'مشرفة خدمة الغرف',
        jobTitleEn: 'Housekeeping Supervisor',
        departmentId: 'HOUSEKEEPING',
        departmentNameAr: 'خدمة الغرف والنظافة',
        departmentNameEn: 'Housekeeping',
        isOnline: true,
        availability: EmployeeAvailability.available,
        phone: '+201012348765',
      ),
      const EmployeeContactModel(
        id: 'EMP-HK-02',
        fullName: 'Omar Khaled',
        jobTitleAr: 'فني نظافة وتجهيز',
        jobTitleEn: 'Room Attendant',
        departmentId: 'HOUSEKEEPING',
        departmentNameAr: 'خدمة الغرف والنظافة',
        departmentNameEn: 'Housekeeping',
        isOnline: true,
        availability: EmployeeAvailability.busy,
      ),

      // Engineering
      const EmployeeContactModel(
        id: 'EMP-ENG-01',
        fullName: 'Eng. Tarek Mansour',
        jobTitleAr: 'مهندس صيانة المناوبة',
        jobTitleEn: 'Duty Maintenance Engineer',
        departmentId: 'ENGINEERING',
        departmentNameAr: 'الهندسة والصيانة',
        departmentNameEn: 'Engineering & Maintenance',
        isOnline: true,
        availability: EmployeeAvailability.available,
        phone: '+201056789012',
      ),
      EmployeeContactModel(
        id: 'EMP-ENG-02',
        fullName: 'Hassan Mahmoud',
        jobTitleAr: 'فني كهرباء وتكييف',
        jobTitleEn: 'HVAC & Electrical Technician',
        departmentId: 'ENGINEERING',
        departmentNameAr: 'الهندسة والصيانة',
        departmentNameEn: 'Engineering & Maintenance',
        isOnline: false,
        availability: EmployeeAvailability.away,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 25)),
      ),

      // Front Office
      const EmployeeContactModel(
        id: 'EMP-FO-01',
        fullName: 'Nour El-Din Mostafa',
        jobTitleAr: 'مدير الاستقبال المناوب',
        jobTitleEn: 'Duty Reception Manager',
        departmentId: 'FRONT_OFFICE',
        departmentNameAr: 'المكاتب الأمامية والاستقبال',
        departmentNameEn: 'Front Office & Reception',
        isOnline: true,
        availability: EmployeeAvailability.available,
      ),

      // HR
      const EmployeeContactModel(
        id: 'EMP-HR-01',
        fullName: 'Sara Ibrahim',
        jobTitleAr: 'أخصائي علاقات الموظفين',
        jobTitleEn: 'Employee Relations Specialist',
        departmentId: 'HUMAN_RESOURCES',
        departmentNameAr: 'الموارد البشرية (HR)',
        departmentNameEn: 'Human Resources (HR)',
        isOnline: true,
        availability: EmployeeAvailability.available,
        phone: '+201099887766',
        email: 'sara.ibrahim@cyberwise.com',
      ),
      const EmployeeContactModel(
        id: 'EMP-HR-02',
        fullName: 'Karim Adel',
        jobTitleAr: 'مسؤول شؤون الموظفين والرواتب',
        jobTitleEn: 'Personnel & Payroll Officer',
        departmentId: 'HUMAN_RESOURCES',
        departmentNameAr: 'الموارد البشرية (HR)',
        departmentNameEn: 'Human Resources (HR)',
        isOnline: true,
        availability: EmployeeAvailability.available,
      ),

      // IT
      const EmployeeContactModel(
        id: 'EMP-IT-01',
        fullName: 'Khaled Mostafa',
        jobTitleAr: 'مسؤول الدعم الفني والشبكات',
        jobTitleEn: 'IT Support & Network Admin',
        departmentId: 'IT',
        departmentNameAr: 'تكنولوجيا المعلومات (IT)',
        departmentNameEn: 'Information Technology (IT)',
        isOnline: true,
        availability: EmployeeAvailability.available,
      ),
    ]);

    // 3. Request Types
    _requestTypes.addAll([
      const RequestTypeModel(
        id: 'SECURITY_ASSISTANCE',
        nameAr: 'مساعدة أمنية فورية',
        nameEn: 'Security Assistance',
        departmentId: 'SECURITY',
        descriptionAr: 'طلب تواجد فرد أمن، التعامل مع واقعة، أو مرافقة زائر',
        descriptionEn: 'Immediate security presence, incident support, or escort',
      ),
      const RequestTypeModel(
        id: 'MAINTENANCE',
        nameAr: 'صيانة وإصلاح أعطال',
        nameEn: 'Maintenance & Repair',
        departmentId: 'ENGINEERING',
        descriptionAr: 'إصلاح تكييف، سباكة، كهرباء، أو أثاث',
        descriptionEn: 'AC, plumbing, electricity, or furniture repair',
      ),
      const RequestTypeModel(
        id: 'HOUSEKEEPING_ASSISTANCE',
        nameAr: 'خدمة نظافة وتجهيز',
        nameEn: 'Housekeeping Assistance',
        departmentId: 'HOUSEKEEPING',
        descriptionAr: 'تنظيف طارئ، توريد مفروشات، أو مستلزمات غرف',
        descriptionEn: 'Emergency cleaning, linen replenishment, or supplies',
      ),
      const RequestTypeModel(
        id: 'TECHNICAL_SUPPORT',
        nameAr: 'دعم فني وتقني (IT)',
        nameEn: 'Technical Support (IT)',
        departmentId: 'IT',
        descriptionAr: 'مشكلة بالشبكة، نظام الكروت، الطابعات، أو الحواسيب',
        descriptionEn: 'Network issues, keycard system, printers, or PC support',
      ),
      const RequestTypeModel(
        id: 'GUEST_ASSISTANCE',
        nameAr: 'مساعدة خاصة بنزيل',
        nameEn: 'Guest Assistance',
        descriptionAr: 'طلب يخص متطلبات خاصة أو استفسار نزيل',
        descriptionEn: 'Special requests or assistance concerning a hotel guest',
      ),
      const RequestTypeModel(
        id: 'GENERAL_ASSISTANCE',
        nameAr: 'مساعدة تشغيلية عامة',
        nameEn: 'General Operations Assistance',
        descriptionAr: 'أي طلب تنسيق أو مساعدة بين الأقسام',
        descriptionEn: 'General coordination or operational support request',
      ),
    ]);

    // 4. Initial Conversations
    _conversations.addAll([
      ConversationModel(
        id: 'CONV-001',
        participantIds: [currentUserId, 'EMP-SEC-01'],
        departmentId: 'SECURITY',
        lastMessage: 'تمام يا فندم، فرد الأمن متواجد حالياً عند مدخل الاستقبال.',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
        unreadCount: 1,
        status: ConversationStatus.active,
        otherParticipant: _contacts.firstWhere((c) => c.id == 'EMP-SEC-01'),
      ),
      ConversationModel(
        id: 'CONV-002',
        participantIds: [currentUserId, 'EMP-HR-01'],
        departmentId: 'HUMAN_RESOURCES',
        lastMessage: 'مرحباً، تم استلام استفسارك بخصوص رصيد الإجازات السنوية.',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        status: ConversationStatus.active,
        otherParticipant: _contacts.firstWhere((c) => c.id == 'EMP-HR-01'),
      ),
      ConversationModel(
        id: 'CONV-003',
        participantIds: [currentUserId, 'EMP-HK-01'],
        departmentId: 'HOUSEKEEPING',
        lastMessage: 'جاري تجهيز الغرفة 304 للنزيل الجديد.',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        status: ConversationStatus.active,
        otherParticipant: _contacts.firstWhere((c) => c.id == 'EMP-HK-01'),
      ),
    ]);

    // 5. Initial Messages
    _messages.addAll([
      MessageModel(
        id: 'MSG-001',
        conversationId: 'CONV-001',
        senderId: currentUserId,
        senderName: currentUserName,
        receiverId: 'EMP-SEC-01',
        content: 'السلام عليكم، محتاجين فرد أمن للتواجد عند كاونتر الاستقبال للتعامل مع زحام النزلاء.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: MessageStatus.read,
      ),
      MessageModel(
        id: 'MSG-002',
        conversationId: 'CONV-001',
        senderId: 'EMP-SEC-01',
        senderName: 'Mohamed Ali',
        receiverId: currentUserId,
        content: 'تمام يا فندم، فرد الأمن متواجد حالياً عند مدخل الاستقبال.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        status: MessageStatus.delivered,
      ),
      MessageModel(
        id: 'MSG-003',
        conversationId: 'CONV-002',
        senderId: currentUserId,
        senderName: currentUserName,
        receiverId: 'EMP-HR-01',
        content: 'صباح الخير أستاذة سارة، حابب أتأكد من رصيد الإجازات المتبقي لهذا الشهر.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: MessageStatus.read,
      ),
      MessageModel(
        id: 'MSG-004',
        conversationId: 'CONV-002',
        senderId: 'EMP-HR-01',
        senderName: 'Sara Ibrahim',
        receiverId: currentUserId,
        content: 'مرحباً، تم استلام استفسارك بخصوص رصيد الإجازات السنوية.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
    ]);

    // 6. Initial Operational Requests
    _requests.addAll([
      DepartmentRequestModel(
        id: 'REQ-DPT-101',
        departmentId: 'SECURITY',
        departmentNameAr: 'الأمن والحراسة',
        departmentNameEn: 'Security & Safety',
        requesterId: currentUserId,
        requesterName: currentUserName,
        recipientId: 'EMP-SEC-01',
        recipientName: 'Mohamed Ali',
        requestTypeId: 'SECURITY_ASSISTANCE',
        requestTypeNameAr: 'مساعدة أمنية فورية',
        requestTypeNameEn: 'Security Assistance',
        priority: RequestPriority.high,
        message: 'محتاج فرد أمن عند بهو الاستقبال لمرافقة نزيل VIP والتأكد من انسيابية الدخول.',
        locationContext: 'بهو الاستقبال الرئيسي - بوابة 1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: DepartmentRequestStatus.inProgress,
      ),
      DepartmentRequestModel(
        id: 'REQ-DPT-102',
        departmentId: 'ENGINEERING',
        departmentNameAr: 'الهندسة والصيانة',
        departmentNameEn: 'Engineering & Maintenance',
        requesterId: currentUserId,
        requesterName: currentUserName,
        recipientId: 'EMP-ENG-01',
        recipientName: 'Eng. Tarek Mansour',
        requestTypeId: 'MAINTENANCE',
        requestTypeNameAr: 'صيانة وإصلاح أعطال',
        requestTypeNameEn: 'Maintenance & Repair',
        priority: RequestPriority.normal,
        message: 'عطل في مكيف صالة الاجتماعات B، درجة الحرارة مرتفعة.',
        locationContext: 'صالة الاجتماعات B - الدور الأول',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: DepartmentRequestStatus.accepted,
      ),
      DepartmentRequestModel(
        id: 'REQ-DPT-103',
        departmentId: 'HOUSEKEEPING',
        departmentNameAr: 'خدمة الغرف والنظافة',
        departmentNameEn: 'Housekeeping',
        requesterId: currentUserId,
        requesterName: currentUserName,
        recipientId: 'EMP-HK-01',
        recipientName: 'Fatma Al-Zahraa',
        requestTypeId: 'HOUSEKEEPING_ASSISTANCE',
        requestTypeNameAr: 'خدمة نظافة وتجهيز',
        requestTypeNameEn: 'Housekeeping Assistance',
        priority: RequestPriority.low,
        message: 'إعادة تعقيم وتجهيز دورات مياه الموظفين بالدور الأرضي.',
        locationContext: 'الممر الإداري - الدور الأرضي',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: DepartmentRequestStatus.completed,
      ),
      DepartmentRequestModel(
        id: 'REQ-DPT-104',
        departmentId: 'IT',
        departmentNameAr: 'تكنولوجيا المعلومات (IT)',
        departmentNameEn: 'Information Technology (IT)',
        requesterId: currentUserId,
        requesterName: currentUserName,
        recipientId: 'EMP-IT-01',
        recipientName: 'Khaled Mostafa',
        requestTypeId: 'TECHNICAL_SUPPORT',
        requestTypeNameAr: 'دعم فني وتقني (IT)',
        requestTypeNameEn: 'Technical Support (IT)',
        priority: RequestPriority.normal,
        message: 'طابعة الاستقبال متوقفة عن طباعة إيصالات تسجيل الدخول.',
        locationContext: 'كاونتر الاستقبال 2',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: DepartmentRequestStatus.pending,
      ),
    ]);
  }

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_departments);
  }

  @override
  Future<DepartmentModel?> getDepartmentById(String departmentId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _departments.firstWhere((d) => d.id == departmentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<EmployeeContactModel>> getAllowedContacts({required String departmentId}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _contacts.where((c) => c.departmentId == departmentId).toList();
  }

  @override
  Future<EmployeeContactModel?> getContactById(String contactId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _contacts.firstWhere((c) => c.id == contactId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _conversations.toList()
      ..sort((a, b) => (b.lastMessageAt ?? DateTime(2000))
          .compareTo(a.lastMessageAt ?? DateTime(2000)));
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String recipientId,
    required String departmentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final existingIndex = _conversations.indexWhere(
      (c) => c.participantIds.contains(recipientId) && c.participantIds.contains(currentUserId),
    );

    if (existingIndex != -1) {
      return _conversations[existingIndex];
    }

    final contact = _contacts.firstWhere(
      (c) => c.id == recipientId,
      orElse: () => EmployeeContactModel(
        id: recipientId,
        fullName: 'Colleague',
        jobTitleAr: 'موظف',
        jobTitleEn: 'Employee',
        departmentId: departmentId,
      ),
    );

    final newConv = ConversationModel(
      id: 'CONV-${DateTime.now().millisecondsSinceEpoch}',
      participantIds: [currentUserId, recipientId],
      departmentId: departmentId,
      unreadCount: 0,
      status: ConversationStatus.active,
      otherParticipant: contact,
    );

    _conversations.insert(0, newConv);
    return newConv;
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _messages.where((m) => m.conversationId == conversationId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final message = MessageModel(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: currentUserName,
      receiverId: receiverId,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    _messages.add(message);

    // Update conversation last message
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      _conversations[convIndex] = ConversationModel.fromEntity(
        _conversations[convIndex].copyWith(
          lastMessage: content,
          lastMessageAt: message.createdAt,
        ),
      );
    }

    return message;
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      _conversations[convIndex] = ConversationModel.fromEntity(
        _conversations[convIndex].copyWith(
          unreadCount: 0,
        ),
      );
    }
  }

  @override
  Future<List<RequestTypeModel>> getRequestTypes({String? departmentId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (departmentId == null) {
      return List.unmodifiable(_requestTypes);
    }
    return _requestTypes
        .where((r) => r.departmentId == null || r.departmentId == departmentId)
        .toList();
  }

  @override
  Future<List<DepartmentRequestModel>> getMyRequests() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.where((r) => r.requesterId == currentUserId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<DepartmentRequestModel>> getDepartmentRequests(String departmentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.where((r) => r.departmentId == departmentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<DepartmentRequestModel?> getRequestById(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _requests.firstWhere((r) => r.id == requestId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DepartmentRequestModel> createDepartmentRequest(DepartmentRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final dept = _departments.firstWhere(
      (d) => d.id == request.departmentId,
      orElse: () => DepartmentModel(
        id: request.departmentId,
        nameAr: request.departmentId,
        nameEn: request.departmentId,
        iconName: 'business',
      ),
    );

    final type = _requestTypes.firstWhere(
      (t) => t.id == request.requestTypeId,
      orElse: () => RequestTypeModel(
        id: request.requestTypeId,
        nameAr: request.requestTypeId,
        nameEn: request.requestTypeId,
      ),
    );

    final created = DepartmentRequestModel.fromEntity(
      request.copyWith(
        id: 'REQ-DPT-${DateTime.now().millisecondsSinceEpoch % 100000}',
        departmentNameAr: dept.nameAr,
        departmentNameEn: dept.nameEn,
        requestTypeNameAr: type.nameAr,
        requestTypeNameEn: type.nameEn,
        createdAt: DateTime.now(),
        status: DepartmentRequestStatus.pending,
      ),
    );

    _requests.insert(0, created);
    return created;
  }

  @override
  Future<DepartmentRequestModel> updateRequestStatus({
    required String requestId,
    required String status,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw Exception('Request not found');
    }

    final current = _requests[index];
    DepartmentRequestStatus newStatus;
    switch (status.toLowerCase()) {
      case 'accepted':
        if (current.status != DepartmentRequestStatus.pending) {
          throw Exception('Cannot accept request in status ${current.status}');
        }
        newStatus = DepartmentRequestStatus.accepted;
        break;
      case 'in_progress':
      case 'inprogress':
        if (current.status != DepartmentRequestStatus.accepted &&
            current.status != DepartmentRequestStatus.pending) {
          throw Exception('Cannot start request in status ${current.status}');
        }
        newStatus = DepartmentRequestStatus.inProgress;
        break;
      case 'completed':
        if (current.status != DepartmentRequestStatus.inProgress &&
            current.status != DepartmentRequestStatus.accepted) {
          throw Exception('Cannot complete request in status ${current.status}');
        }
        newStatus = DepartmentRequestStatus.completed;
        break;
      case 'rejected':
        if (current.status != DepartmentRequestStatus.pending) {
          throw Exception('Cannot reject request in status ${current.status}');
        }
        newStatus = DepartmentRequestStatus.rejected;
        break;
      case 'cancelled':
        if (current.status.isTerminal) {
          throw Exception('Cannot cancel request in status ${current.status}');
        }
        newStatus = DepartmentRequestStatus.cancelled;
        break;
      default:
        throw Exception('Invalid status: $status');
    }

    final updated = DepartmentRequestModel.fromEntity(
      current.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        rejectionReason: reason ?? current.rejectionReason,
      ),
    );

    _requests[index] = updated;
    return updated;
  }
}
