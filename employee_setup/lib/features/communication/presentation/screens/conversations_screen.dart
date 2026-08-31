import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/conversations_provider.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/communication_empty_state.dart';
import '../widgets/communication_error_state.dart';
import '../widgets/communication_skeletons.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _onlyUnread = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final conversationsAsync = ref.watch(conversationsListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? 'المحادثات المباشرة' : 'Direct Messages',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary),
            tooltip: isArabic ? 'محادثة جديدة' : 'New Chat',
            onPressed: () {
              context.push(AppRoutes.departments);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Column(
                children: [
                  AppTextField(
                    controller: _searchController,
                    hintText: isArabic
                        ? 'ابحث في المحادثات (بالاسم، الرسالة...)'
                        : 'Search messages (by name, message...)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  Row(
                    children: [
                      FilterChip(
                        selected: !_onlyUnread,
                        label: Text(isArabic ? 'جميع المحادثات' : 'All Chats'),
                        onSelected: (_) {
                          setState(() {
                            _onlyUnread = false;
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: !_onlyUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: !_onlyUnread
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _onlyUnread,
                        label: Text(isArabic ? 'غير المقروءة' : 'Unread'),
                        onSelected: (_) {
                          setState(() {
                            _onlyUnread = true;
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _onlyUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _onlyUnread
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Conversations List
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  final filtered = conversations.where((c) {
                    if (_onlyUnread && c.unreadCount == 0) return false;
                    if (_searchQuery.isEmpty) return true;

                    final name = c.otherParticipant?.fullName.toLowerCase() ?? '';
                    final lastMsg = c.lastMessage?.toLowerCase() ?? '';
                    final jobAr = c.otherParticipant?.jobTitleAr.toLowerCase() ?? '';
                    final jobEn = c.otherParticipant?.jobTitleEn.toLowerCase() ?? '';

                    return name.contains(_searchQuery) ||
                        lastMsg.contains(_searchQuery) ||
                        jobAr.contains(_searchQuery) ||
                        jobEn.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: CommunicationEmptyState(
                        title: isArabic
                            ? 'لا توجد محادثات'
                            : 'No conversations found',
                        message: isArabic
                            ? (_onlyUnread
                                ? 'لا توجد رسائل غير مقروءة حالياً.'
                                : 'اختر موظفاً من دليل الأقسام لبدء محادثة فورية.')
                            : (_onlyUnread
                                ? 'No unread messages.'
                                : 'Select a colleague from departments to start chatting.'),
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(conversationsListProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        return ConversationTile(
                          conversation: conv,
                          onTap: () {
                            context.push('/communication/chat/${conv.id}');
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ConversationListSkeleton(itemCount: 6),
                ),
                error: (err, _) => Center(
                  child: CommunicationErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(conversationsListProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.departments);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(
          isArabic ? 'محادثة جديدة' : 'New Chat',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
