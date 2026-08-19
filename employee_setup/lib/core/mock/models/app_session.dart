// ============================================================
// AppSession Model — represents an authenticated user session
// ============================================================

enum SessionStatus {
  active,
  loggedOut,
  expired,
  revoked,
}

enum LoginProvider {
  google,
  email,
  mock,
}

class AppSession {
  final String sessionId;
  final String employeeId;
  final String email;
  final bool isAuthenticated;
  final bool profileCompleted;
  final LoginProvider provider;
  final DateTime loginAt;
  final DateTime? logoutAt;
  final DateTime? lastActivityAt;
  final DateTime expiresAt;
  final String deviceInfo;
  final String platform;
  final SessionStatus status;
  final String dataSource;

  const AppSession({
    required this.sessionId,
    required this.employeeId,
    required this.email,
    required this.isAuthenticated,
    this.profileCompleted = false,
    required this.provider,
    required this.loginAt,
    this.logoutAt,
    this.lastActivityAt,
    required this.expiresAt,
    this.deviceInfo = 'Secure Mobile Device',
    this.platform = 'Mobile',
    required this.status,
    this.dataSource = 'DEVICE_TEST_DATA',
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == SessionStatus.active && !isExpired;

  AppSession copyWith({
    String? sessionId,
    String? employeeId,
    String? email,
    bool? isAuthenticated,
    bool? profileCompleted,
    LoginProvider? provider,
    DateTime? loginAt,
    DateTime? logoutAt,
    DateTime? lastActivityAt,
    DateTime? expiresAt,
    String? deviceInfo,
    String? platform,
    SessionStatus? status,
    String? dataSource,
  }) {
    return AppSession(
      sessionId: sessionId ?? this.sessionId,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      provider: provider ?? this.provider,
      loginAt: loginAt ?? this.loginAt,
      logoutAt: logoutAt ?? this.logoutAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'employeeId': employeeId,
        'email': email,
        'isAuthenticated': isAuthenticated,
        'profileCompleted': profileCompleted,
        'provider': provider.name,
        'loginAt': loginAt.toIso8601String(),
        'logoutAt': logoutAt?.toIso8601String(),
        'lastActivityAt': (lastActivityAt ?? loginAt).toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'deviceInfo': deviceInfo,
        'platform': platform,
        'status': status.name,
        'dataSource': dataSource,
      };

  factory AppSession.fromJson(Map<String, dynamic> json) => AppSession(
        sessionId: json['sessionId'] as String,
        employeeId: json['employeeId'] as String,
        email: json['email'] as String,
        isAuthenticated: json['isAuthenticated'] as bool? ?? true,
        profileCompleted: json['profileCompleted'] as bool? ?? false,
        provider: LoginProvider.values.byName(json['provider'] as String? ?? 'google'),
        loginAt: DateTime.parse(json['loginAt'] as String),
        logoutAt: json['logoutAt'] != null ? DateTime.parse(json['logoutAt'] as String) : null,
        lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt'] as String) : null,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        deviceInfo: json['deviceInfo'] as String? ?? 'Secure Mobile Device',
        platform: json['platform'] as String? ?? 'Mobile',
        status: SessionStatus.values.byName(json['status'] as String? ?? 'active'),
        dataSource: json['dataSource'] as String? ?? 'DEVICE_TEST_DATA',
      );

  /// Creates a fresh session valid for 12 hours from now.
  factory AppSession.create({
    required String employeeId,
    required String email,
    bool profileCompleted = false,
    LoginProvider provider = LoginProvider.google,
    String deviceInfo = 'Secure Mobile Device',
    String platform = 'Mobile',
  }) {
    final now = DateTime.now();
    return AppSession(
      sessionId: 'SESSION-${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      email: email,
      isAuthenticated: true,
      profileCompleted: profileCompleted,
      provider: provider,
      loginAt: now,
      lastActivityAt: now,
      expiresAt: now.add(const Duration(hours: 12)),
      deviceInfo: deviceInfo,
      platform: platform,
      status: SessionStatus.active,
      dataSource: 'DEVICE_TEST_DATA',
    );
  }
}
