import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../attendance/data/services/real_biometric_service.dart';
import '../../../attendance/domain/services/biometric_service.dart';
import '../../domain/entities/chat_settings.dart';
import '../providers/chat_settings_provider.dart';
import '../widgets/chat_settings/chat_settings_section.dart';
import '../widgets/chat_settings/chat_settings_switch_tile.dart';
import '../widgets/chat_settings/chat_settings_tile.dart';
import '../widgets/chat_settings/chat_storage_tile.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  ConsumerState<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  final RealBiometricService _biometricService = RealBiometricService();
  bool _isBiometricSupported = true;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsSupport();
  }

  Future<void> _checkBiometricsSupport() async {
    final supported = await _biometricService.canCheckBiometrics();
    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
      });
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    final isArabic = context.isArabic;
    if (value) {
      final result = await _biometricService.authenticate(
        reason: isArabic
            ? 'يرجى تأكيد هويتك الحيوية لتفعيل قفل المحادثات'
            : 'Authenticate to enable biometric chat lock',
      );
      if (result == BiometricAuthResult.success) {
        await ref
            .read(chatSettingsProvider.notifier)
            .toggleBiometricChatLock(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تم تفعيل قفل المحادثات بالبصمة بنجاح'
                    : 'Biometric Chat Lock enabled successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'فشل التحقق من البصمة، لم يتم تفعيل القفل'
                    : 'Biometric authentication failed or cancelled',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } else {
      await ref
          .read(chatSettingsProvider.notifier)
          .toggleBiometricChatLock(false);
    }
  }

  Future<void> _showClearCacheDialog() async {
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
            const Icon(Icons.cleaning_services_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'مسح الملفات المؤقتة؟' : 'Clear cached files?',
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
              ? 'سيتم مسح الملفات المؤقتة لتوفير مساحة التخزين. يمكن تنزيل هذه الملفات لاحقاً عند الحاجة بدون التأثير على رسائلك أو حسابك.'
              : 'Cached files can be downloaded again when needed. This will not delete your messages or account.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              isArabic ? 'إلغاء' : 'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(isArabic ? 'مسح الذاكرة' : 'Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isClearingCache = true;
      });
      final repo = ref.read(chatSettingsRepositoryProvider);
      final success = await repo.clearCache();
      ref.invalidate(chatStorageUsageProvider);
      if (mounted) {
        setState(() {
          _isClearingCache = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isArabic
                      ? 'تم تفريغ الذاكرة المؤقتة بنجاح'
                      : 'Cached files cleared successfully')
                  : (isArabic
                      ? 'حدث خطأ أثناء تفريغ الذاكرة المؤقتة'
                      : 'Failed to clear cache'),
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _showMediaQualityPicker(ChatSettings settings) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'جودة إرسال وتنزيل الوسائط' : 'Media Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),
              ...ChatMediaQuality.values.map((quality) {
                final isSelected = settings.mediaQuality == quality;
                return RadioListTile<ChatMediaQuality>(
                  value: quality,
                  groupValue: settings.mediaQuality,
                  activeColor: AppColors.primary,
                  title: Text(
                    quality.localizedName(isArabic),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(chatSettingsProvider.notifier).setMediaQuality(val);
                      Navigator.pop(sheetCtx);
                    }
                  },
                );
              }),
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
    final settings = ref.watch(chatSettingsProvider);
    final notifier = ref.read(chatSettingsProvider.notifier);
    final storageAsync = ref.watch(chatStorageUsageProvider);

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
          isArabic ? 'إعدادات المحادثات' : 'Chat Settings',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. NOTIFICATIONS SECTION
              ChatSettingsSection(
                title: isArabic ? 'التنبيهات والإشعارات' : 'Notifications',
                icon: Icons.notifications_active_outlined,
                children: [
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'إشعارات الرسائل' : 'Message Notifications',
                    subtitle: isArabic
                        ? 'تلقي تنبيه عند وصول رسائل جديدة من الزملاء'
                        : 'Receive notifications when you receive a new message.',
                    icon: Icons.notifications_none_rounded,
                    iconColor: AppColors.primary,
                    value: settings.messageNotifications,
                    onChanged: notifier.toggleMessageNotifications,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'صوت التنبيه' : 'Message Sound',
                    subtitle: isArabic
                        ? 'تشغيل نغمة صوتية عند استقبال رسالة جديدة'
                        : 'Play a sound when a new message arrives.',
                    icon: Icons.volume_up_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    value: settings.messageSound,
                    enabled: settings.messageNotifications,
                    onChanged: notifier.toggleMessageSound,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'الاهتزاز' : 'Vibration',
                    subtitle: isArabic
                        ? 'اهتزاز الهاتف عند وصول رسالة جديدة'
                        : 'Vibrate the device when a new message arrives.',
                    icon: Icons.vibration_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    value: settings.vibration,
                    enabled: settings.messageNotifications,
                    onChanged: notifier.toggleVibration,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'معاينة محتوى الرسالة' : 'Message Preview',
                    subtitle: isArabic
                        ? 'إظهار نص واسم المرسل في شريط التنبيهات'
                        : 'Show message content in notifications.',
                    icon: Icons.preview_rounded,
                    iconColor: const Color(0xFF10B981),
                    value: settings.messagePreview,
                    enabled: settings.messageNotifications,
                    onChanged: notifier.toggleMessagePreview,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. PRIVACY SECTION
              ChatSettingsSection(
                title: isArabic ? 'الخصوصية والأمان' : 'Privacy',
                icon: Icons.security_rounded,
                children: [
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'إظهار حالة الاتصال' : 'Show Online Status',
                    subtitle: isArabic
                        ? 'السماح للزملاء برؤية أنك متاح ومتصل الآن'
                        : 'Allow other users to see that you are online.',
                    icon: Icons.circle_outlined,
                    iconColor: AppColors.success,
                    value: settings.showOnlineStatus,
                    onChanged: notifier.toggleShowOnlineStatus,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'إظهار آخر ظهور' : 'Show Last Seen',
                    subtitle: isArabic
                        ? 'عرض توقيت آخر نشاط لك في تطبيق العمل'
                        : 'Allow users to see your last active time.',
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    value: settings.showLastSeen,
                    onChanged: notifier.toggleShowLastSeen,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'مؤشر الكتابة' : 'Show Typing Indicator',
                    subtitle: isArabic
                        ? 'إظهار عبارة (جاري الكتابة...) للطرف الآخر'
                        : 'Control whether you participate in the typing indicator system.',
                    icon: Icons.keyboard_alt_outlined,
                    iconColor: const Color(0xFFEC4899),
                    value: settings.typingIndicator,
                    onChanged: notifier.toggleTypingIndicator,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'مؤشرات قراءة الرسائل' : 'Read Receipts',
                    subtitle: isArabic
                        ? 'مشاركة علامات تسليم وقراءة الرسائل (✓✓)'
                        : 'Control whether read status is shared.',
                    icon: Icons.done_all_rounded,
                    iconColor: AppColors.primary,
                    value: settings.readReceipts,
                    onChanged: notifier.toggleReadReceipts,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. MEDIA & DATA SECTION
              ChatSettingsSection(
                title: isArabic ? 'الوسائط واستهلاك البيانات' : 'Media & Data',
                icon: Icons.perm_media_outlined,
                children: [
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'تنزيل الصور تلقائياً' : 'Auto Download Images',
                    subtitle: isArabic
                        ? 'حفظ الصور الواردة مباشرة في ذاكرة المحادثة'
                        : 'Automatically download received photos.',
                    icon: Icons.image_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    value: settings.autoDownloadImages,
                    onChanged: notifier.toggleAutoDownloadImages,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'تنزيل الفيديوهات تلقائياً' : 'Auto Download Videos',
                    subtitle: isArabic
                        ? 'تنزيل مقاطع الفيديو التشغيلية تلقائياً'
                        : 'Automatically download received videos.',
                    icon: Icons.videocam_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    value: settings.autoDownloadVideos,
                    onChanged: notifier.toggleAutoDownloadVideos,
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'التنزيل عبر Wi-Fi فقط' : 'Download Media on Wi-Fi Only',
                    subtitle: isArabic
                        ? 'تنزيل الوسائط تلقائياً فقط عند الاتصال بشبكة Wi-Fi'
                        : 'Automatically download media only when connected to Wi-Fi.',
                    icon: Icons.wifi_rounded,
                    iconColor: const Color(0xFF10B981),
                    value: settings.wifiOnly,
                    onChanged: notifier.toggleWifiOnly,
                    showDivider: true,
                  ),
                  ChatSettingsTile(
                    title: isArabic ? 'جودة الوسائط' : 'Media Quality',
                    subtitle: isArabic
                        ? 'التحكم في دقة وحجم الصور والفيديوهات المرسلة'
                        : 'Manage compression and quality of uploaded media.',
                    leadingIcon: Icons.high_quality_rounded,
                    leadingColor: const Color(0xFFF59E0B),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.mediaQuality.localizedName(isArabic),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isArabic
                              ? Icons.arrow_back_ios_new_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ],
                    ),
                    onTap: () => _showMediaQualityPicker(settings),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. STORAGE USAGE SECTION
              ChatSettingsSection(
                title: isArabic ? 'التخزين والذاكرة' : 'Storage',
                icon: Icons.storage_rounded,
                children: [
                  storageAsync.when(
                    data: (breakdown) => ChatStorageTile(
                      breakdown: breakdown,
                      onClearCache: _showClearCacheDialog,
                      isClearing: _isClearingCache,
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, _) => ChatStorageTile(
                      breakdown: const ChatStorageBreakdown(),
                      onClearCache: _showClearCacheDialog,
                      isClearing: _isClearingCache,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. SECURITY SECTION
              ChatSettingsSection(
                title: isArabic ? 'الحماية والأمان البيومتري' : 'Security',
                icon: Icons.lock_outline_rounded,
                children: [
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'قفل المحادثات بالبصمة' : 'Lock Chat with Biometrics',
                    subtitle: _isBiometricSupported
                        ? (isArabic
                            ? 'طلب البصمة / Face ID عند فتح قسم المحادثات'
                            : 'Require fingerprint or Face ID to view chats.')
                        : (isArabic
                            ? 'المصادقة الحيوية غير مدعومة أو غير مفعلة على هذا الجهاز'
                            : 'Biometrics unavailable on this device.'),
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.primary,
                    value: settings.biometricChatLock,
                    enabled: _isBiometricSupported,
                    onChanged: (val) => _handleBiometricToggle(val),
                    showDivider: true,
                  ),
                  ChatSettingsSwitchTile(
                    title: isArabic ? 'إخفاء المعاينة الحساسة' : 'Hide Message Preview',
                    subtitle: isArabic
                        ? 'عدم كشف نصوص المحادثات الحساسة في قفل الشاشة'
                        : 'Notifications will not reveal sensitive message content.',
                    icon: Icons.visibility_off_outlined,
                    iconColor: const Color(0xFF64748B),
                    value: settings.hideMessagePreview,
                    onChanged: notifier.toggleHideMessagePreview,
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
}
