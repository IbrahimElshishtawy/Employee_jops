import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/app_role.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

class AuthUserDto {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final List<String>? permissions;
  final String? avatarUrl;
  final String? department;

  const AuthUserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.permissions,
    this.avatarUrl,
    this.department,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'VIEWER',
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      avatarUrl: json['avatarUrl'] as String?,
      department: json['department'] as String?,
    );
  }

  AuthUser toDomain() {
    final customPerms = <AppPermission>{};
    if (permissions != null) {
      for (final p in permissions!) {
        final parsed = AppPermission.fromKey(p);
        if (parsed != null) customPerms.add(parsed);
      }
    }

    return AuthUser(
      id: id,
      email: email,
      fullName: fullName,
      role: AppRole.fromKey(role),
      customPermissions: customPerms,
      avatarUrl: avatarUrl,
      department: department,
    );
  }
}

class AuthSessionDto {
  final AuthUserDto user;
  final String accessToken;
  final String refreshToken;
  final String expiresAt;

  const AuthSessionDto({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    return AuthSessionDto(
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
    );
  }

  AuthSession toDomain() {
    return AuthSession(
      user: user.toDomain(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.tryParse(expiresAt) ?? DateTime.now().add(const Duration(hours: 8)),
    );
  }
}
