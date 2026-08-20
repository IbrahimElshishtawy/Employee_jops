/// Canonical User Roles within CyberWise IE HR Portal
enum AppRole {
  superAdmin('SUPER_ADMIN', 'Super Administrator'),
  hrAdmin('HR_ADMIN', 'HR Administrator'),
  hrManager('HR_MANAGER', 'HR Manager'),
  hrEmployee('HR_EMPLOYEE', 'HR Staff'),
  viewer('VIEWER', 'Audit / Read-Only Viewer');

  final String key;
  final String label;

  const AppRole(this.key, this.label);

  static AppRole fromKey(String? key) {
    if (key == null) return AppRole.viewer;
    return AppRole.values.firstWhere(
      (r) => r.key.toUpperCase() == key.toUpperCase(),
      orElse: () => AppRole.viewer,
    );
  }
}
