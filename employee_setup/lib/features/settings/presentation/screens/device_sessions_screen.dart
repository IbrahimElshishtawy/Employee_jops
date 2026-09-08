import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/repositories/sessions_repository.dart';

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return SessionsRepository(client);
});

final activeSessionsProvider =
    FutureProvider.autoDispose<List<DeviceSessionItem>>((ref) async {
  final repo = ref.watch(sessionsRepositoryProvider);
  return repo.getMyDevices();
});

class DeviceSessionsScreen extends ConsumerWidget {
  const DeviceSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'الأجهزة والجلسات النشطة' : 'Active Device Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeSessionsProvider),
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                isRtl ? 'لا توجد أجهزة نشطة حالياً' : 'No active sessions found',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activeSessionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final session = sessions[index];
                return Card(
                  elevation: 0,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: session.isCurrent
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      width: session.isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: session.isCurrent
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      child: Icon(
                        session.deviceType == 'MOBILE'
                            ? Icons.phone_android_rounded
                            : Icons.laptop_mac_rounded,
                        color: session.isCurrent ? AppColors.primary : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.deviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (session.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isRtl ? 'هذا الجهاز' : 'Current',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${isRtl ? "آخر نشاط:" : "Last active:"} ${DateFormat('yyyy-MM-dd HH:mm').format(session.lastActive)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                        if (session.ipAddress != null)
                          Text(
                            'IP: ${session.ipAddress}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                    trailing: !session.isCurrent
                        ? IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: Text(isRtl ? 'تسجيل الخروج عن بعد' : 'Revoke Session'),
                                  content: Text(
                                    isRtl
                                        ? 'هل أنت متأكد من تسجيل الخروج من هذا الجهاز؟'
                                        : 'Are you sure you want to log out of this device?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx, false),
                                      child: Text(isRtl ? 'إلغاء' : 'Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx, true),
                                      child: Text(
                                        isRtl ? 'إنهاء الجلسة' : 'Revoke',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                final success = await ref
                                    .read(sessionsRepositoryProvider)
                                    .revokeSession(session.id);
                                if (success) {
                                  ref.invalidate(activeSessionsProvider);
                                }
                              }
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
