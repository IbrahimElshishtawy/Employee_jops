import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/employee_contact.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_settings_provider.dart';
import '../providers/conversations_provider.dart';
import '../widgets/availability_indicator.dart';
import '../widgets/chat_settings/chat_settings_section.dart';
import '../widgets/chat_settings/chat_settings_switch_tile.dart';
import '../widgets/chat_settings/chat_settings_tile.dart';

class ConversationInfoScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationInfoScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ConversationInfoScreen> createState() =>
      _ConversationInfoScreenState();
}

class _ConversationInfoScreenState extends ConsumerState<ConversationInfoScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showClearChatDialog() async {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'مسح سجل المحادثة؟' : 'Clear Chat History?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من رغبتك في مسح جميع الرسائل من هذه المحادثة على جهازك؟'
              : 'Are you sure you want to clear all messages from this conversation on your device?',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(isArabic ? 'مسح الرسائل' : 'Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(chatProvider(widget.conversationId).notifier).loadMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم مسح سجل المحادثة بنجاح'
                  : 'Chat messages cleared successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConversationDialog() async {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'حذف المحادثة نهائياً؟' : 'Delete Conversation?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'سيتم حذف المحادثة وسجل الرسائل بالكامل من قائمة المحادثات النشطة.'
              : 'This will delete the entire conversation and chat history from your active chats.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(isArabic ? 'حذف نهائي' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(chatSettingsRepositoryProvider);
      await repo.deleteConversation(widget.conversationId);
      ref.invalidate(conversationsListProvider);
      if (mounted) {
        context.go(AppRoutes.conversations);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم حذف المحادثة بنجاح'
                  : 'Conversation deleted successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showMediaAttachmentsSheet() {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'الوسائط والملفات والروابط' : 'Media, Files & Links',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 48,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'لا توجد ملفات أو وسائط متبادلة في هذه المحادثة حتى الآن'
                            : 'No media or shared documents in this conversation yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final conversationsAsync = ref.watch(conversationsListProvider);
    final convList = conversationsAsync.asData?.value ?? [];
    final conv = convList.where((c) => c.id == widget.conversationId).firstOrNull ??
        (convList.isNotEmpty ? convList.first : null);

    final contact = conv?.otherParticipant ??
        const EmployeeContact(
          id: 'EMP-OTHER',
          fullName: 'Colleague',
          jobTitleAr: 'موظف',
          jobTitleEn: 'Employee',
          departmentId: 'SECURITY',
        );

    final customSettings =
        ref.watch(conversationSettingsProvider(widget.conversationId));
    final customNotifier =
        ref.read(conversationSettingsProvider(widget.conversationId).notifier);

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
          isArabic ? 'معلومات المحادثة' : 'Conversation Info',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: AppColors.primary),
            tooltip: isArabic ? 'إعدادات المحادثات العامة' : 'Chat Settings',
            onPressed: () => context.push(AppRoutes.chatSettings),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              // 1. Participant Profile Card
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                borderRadius: AppDimensions.radiusMedium,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
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
                              fontSize: 24,
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
                            dotSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      contact.fullName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.localizedJobTitle(isArabic),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuickAction(
                          icon: Icons.person_search_rounded,
                          label: isArabic ? 'الملف الشخصي' : 'Profile',
                          color: AppColors.primary,
                          onTap: () {
                            context.push('/communication/employee/${contact.id}');
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        _buildQuickAction(
                          icon: Icons.add_task_rounded,
                          label: isArabic ? 'طلب تشغيلي' : 'New Request',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            context.push(
                              '${AppRoutes.newDepartmentRequest}?deptId=${contact.departmentId}&recipientId=${contact.id}',
                            );
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        _buildQuickAction(
                          icon: Icons.folder_shared_outlined,
                          label: isArabic ? 'الوسائط' : 'Media',
                          color: const Color(0xFFF59E0B),
                          onTap: _showMediaAttachmentsSheet,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search in Conversation Box (if active)
              if (_isSearching) ...[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? 'ابحث في رسائل المحادثة...'
                                : 'Search messages in this chat...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      isArabic
                          ? 'جاري البحث عن "$_searchQuery" في الرسائل...'
                          : 'Searching for "$_searchQuery" in chat messages...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // 2. CONVERSATION SETTINGS SECTION
              ChatSettingsSection(
                title: isArabic ? 'إعدادات المحادثة' : 'Conversation Settings',
                icon: Icons.tune_rounded,
                children: [
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'كتم التنبيهات' : 'Mute Notifications',
                    subtitle: isArabic
                        ? 'عدم تلقي إشعارات جديدة من هذه المحادثة'
                        : 'Mute alerts for this specific conversation.',
                    icon: Icons.notifications_off_outlined,
                    iconColor: const Color(0xFF64748B),
                    value: customSettings.isMuted,
                    onChanged: customNotifier.toggleMute,
                    showDivider: true,
                  ),
                  ChatSettingsTile(
                    title: isArabic ? 'البحث في المحادثة' : 'Search in Conversation',
                    subtitle: isArabic
                        ? 'البحث عن كلمات ونصوص في سجل الرسائل'
                        : 'Search text and past messages.',
                    leadingIcon: Icons.search_rounded,
                    leadingColor: const Color(0xFF3B82F6),
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                    showDivider: true,
                  ),
                  ChatSettingsTile(
                    title: isArabic ? 'الوسائط والمستندات والروابط' : 'Media / Files / Links',
                    subtitle: isArabic
                        ? 'عرض جميع الصور والمرفقات المشتركة'
                        : 'Browse shared media and attachments.',
                    leadingIcon: Icons.perm_media_outlined,
                    leadingColor: const Color(0xFF8B5CF6),
                    onTap: _showMediaAttachmentsSheet,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'تثبيت المحادثة' : 'Pin Conversation',
                    subtitle: isArabic
                        ? 'إبقاء هذه المحادثة في أعلى قائمة المحادثات'
                        : 'Keep this chat at the top of your list.',
                    icon: Icons.push_pin_outlined,
                    iconColor: AppColors.primary,
                    value: customSettings.isPinned,
                    onChanged: customNotifier.togglePin,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'أرشفة المحادثة' : 'Archive Conversation',
                    subtitle: isArabic
                        ? 'نقل المحادثة إلى قسم الأرشيف'
                        : 'Move this conversation to archive.',
                    icon: Icons.archive_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    value: customSettings.isArchived,
                    onChanged: customNotifier.toggleArchive,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. DANGER / DESTRUCTIVE ACTIONS SECTION
              ChatSettingsSection(
                title: isArabic ? 'إدارة سجل المحادثة' : 'Manage Chat History',
                icon: Icons.delete_outline_rounded,
                children: [
                  ChatSettingsTile(
                    title: isArabic ? 'مسح سجل الرسائل' : 'Clear Chat',
                    subtitle: isArabic
                        ? 'حذف جميع الرسائل من هذه المحادثة'
                        : 'Delete all messages inside this conversation.',
                    leadingIcon: Icons.delete_sweep_rounded,
                    leadingColor: AppColors.error,
                    onTap: _showClearChatDialog,
                    showDivider: true,
                  ),
                  ChatSettingsTile(
                    title: isArabic ? 'حذف المحادثة' : 'Delete Conversation',
                    subtitle: isArabic
                        ? 'حذف المحادثة بالكامل من قائمتك'
                        : 'Permanently remove this conversation.',
                    leadingIcon: Icons.delete_forever_rounded,
                    leadingColor: AppColors.error,
                    onTap: _showDeleteConversationDialog,
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
