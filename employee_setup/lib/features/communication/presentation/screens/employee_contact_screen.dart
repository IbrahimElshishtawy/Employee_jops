import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/contacts_provider.dart';
import '../providers/communication_providers.dart';
import '../widgets/availability_indicator.dart';
import '../widgets/communication_error_state.dart';

class EmployeeContactScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeContactScreen({
    super.key,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final contactAsync = ref.watch(contactByIdProvider(employeeId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? 'الملف الوظيفي' : 'Employee Contact',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: contactAsync.when(
          data: (contact) {
            if (contact == null) {
              return Center(
                child: Text(isArabic ? 'الموظف غير موجود' : 'Contact not found'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Card
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    borderRadius: AppDimensions.radiusLarge,
                    child: Column(
                      children: [
                        // Large Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.primaryLight,
                              child: Text(
                                contact.fullName.isNotEmpty
                                    ? contact.fullName
                                        .split(' ')
                                        .take(2)
                                        .map((e) => e.isNotEmpty ? e[0] : '')
                                        .join()
                                        .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: isArabic ? null : 2,
                              left: isArabic ? 2 : null,
                              child: AvailabilityIndicator(
                                availability: contact.availability,
                                showText: false,
                                dotSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name & Title
                        Text(
                          contact.fullName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.localizedJobTitle(isArabic),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Department Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            contact.localizedDepartment(isArabic) ?? contact.departmentId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Availability Status
                        AvailabilityIndicator(
                          availability: contact.availability,
                          showText: true,
                          dotSize: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contact Details Card (if available)
                  if (contact.phone != null || contact.email != null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: AppDimensions.radiusLarge,
                      child: Column(
                        children: [
                          if (contact.phone != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  contact.phone!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (contact.phone != null && contact.email != null)
                            const Divider(height: 20),
                          if (contact.email != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  contact.email!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  AppButton(
                    text: isArabic ? 'بدء محادثة' : 'Start Chat',
                    icon: Icons.chat_rounded,
                    onPressed: contact.canChat
                        ? () async {
                            final getOrCreateConv =
                                ref.read(getOrCreateConversationUseCaseProvider);
                            final conv = await getOrCreateConv(
                              recipientId: contact.id,
                              departmentId: contact.departmentId,
                            );
                            if (context.mounted) {
                              context.push('/communication/chat/${conv.id}');
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: isArabic ? 'إنشاء طلب تشغيلي' : 'Create Request',
                    icon: Icons.assignment_add,
                    variant: AppButtonVariant.secondary,
                    onPressed: contact.canCreateRequest
                        ? () {
                            context.push(
                              '${AppRoutes.newDepartmentRequest}?deptId=${contact.departmentId}&recipientId=${contact.id}',
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => CommunicationErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(contactByIdProvider(employeeId)),
          ),
        ),
      ),
    );
  }
}
