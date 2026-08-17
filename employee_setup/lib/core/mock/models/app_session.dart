// ============================================================
// AppSession Model — represents an authenticated user session
// ============================================================

enum SessionStatus {
  active,
  expired,
  loggedOut,
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
  final LoginProvider provider;
  final DateTime loginAt;
  final DateTime expiresAt;
  final SessionStatus status;

  const AppSession({
    required this.sessionId,
    required this.employeeId,
    required this.email,
    required this.isAuthenticated,
    required this.provider,
    required this.loginAt,
    required this.expiresAt,
    required this.status,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == SessionStatus.active && !isExpired;

  AppSession copyWith({
    String? sessionId,
    String? employeeId,
    String? email,
    bool? isAuthenticated,
    LoginProvider? provider,
    DateTime? loginAt,
    DateTime? expiresAt,
    SessionStatus? status,
  }) {
    return AppSession(
      sessionId: sessionId ?? this.sessionId,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      provider: provider ?? this.provider,
      loginAt: loginAt ?? this.loginAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'employeeId': employeeId,
        'email': email,
        'isAuthenticated': isAuthenticated,
        'provider': provider.name,
        'loginAt': loginAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status.name,
      };

  factory AppSession.fromJson(Map<String, dynamic> json) => AppSession(
        sessionId: json['sessionId'] as String,
        employeeId: json['employeeId'] as String,
        email: json['email'] as String,
        isAuthenticated: json['isAuthenticated'] as bool,
        provider: LoginProvider.values.byName(json['provider'] as String),
        loginAt: DateTime.parse(json['loginAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        status: SessionStatus.values.byName(json['status'] as String),
      );

  /// Creates a fresh session valid for 12 hours from now.
  factory AppSession.create({
    required String employeeId,
    required String email,
    LoginProvider provider = LoginProvider.google,
  }) {
    final now = DateTime.now();
    return AppSession(
      sessionId: 'SESSION-${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      email: email,
      isAuthenticated: true,
      provider: provider,
      loginAt: now,
      expiresAt: now.add(const Duration(hours: 12)),
      status: SessionStatus.active,
    );
  }
}
