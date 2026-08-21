// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../controllers/messages_controller.dart';
import '../widgets/new_conversation_dialog.dart';

/// Comprehensive Master-Detail HR Messages & Internal Communication Screen
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageTextController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _openNewMessageDialog(BuildContext context) {
    final employeeRepo = context.read<EmployeeRepository>();
    final controller = context.read<MessagesController>();

    showDialog(
      context: context,
      builder: (ctx) => NewConversationDialog(
        employeeRepository: employeeRepo,
        onStartConversation: (empId, message) async {
          final conv = await controller.startNewConversation(empId, message);
          if (conv != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Direct conversation started successfully.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return conv;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MessagesController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canManage = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.messagesManage);
    final kpis = controller.kpis;
    final selectedConv = controller.selectedConversation;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HR Internal Communications & Direct Messages', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Direct two-way messaging with employees, inquiry resolution, and staff assistance',
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              if (canManage)
                HrButton(
                  label: 'New Direct Message',
                  icon: Icons.chat_bubble_outline,
                  variant: HrButtonVariant.primary,
                  onPressed: () => _openNewMessageDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Conversations',
                  value: kpis != null ? '${kpis.totalConversations}' : '—',
                  subtitle: 'Employee direct threads',
                  icon: Icons.forum_outlined,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Unread Inquiries',
                  value: kpis != null ? '${kpis.activeUnreadConversations}' : '—',
                  subtitle: 'Needs HR response',
                  icon: Icons.mark_chat_unread_outlined,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Unread Messages',
                  value: kpis != null ? '${kpis.totalUnreadMessages}' : '—',
                  subtitle: 'Pending staff messages',
                  icon: Icons.mail_outline,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Resolved Threads',
                  value: kpis != null ? '${kpis.resolvedConversations}' : '—',
                  subtitle: 'Inquiries closed',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Master-Detail Chat Layout Container
          Container(
            height: 640,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Master: Conversations Inbox Sidebar (Left)
                SizedBox(
                  width: 360,
                  child: Column(
                    children: [
                      // Subtabs Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppDimensions.space16, AppDimensions.space16, AppDimensions.space16, AppDimensions.space8),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: MessagesTab.values.map((tab) {
                                final isSelected = controller.activeTab == tab;
                                return ChoiceChip(
                                  label: Text(tab.label, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                                  onSelected: (selected) {
                                    if (selected) controller.setActiveTab(tab);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppDimensions.space12),
                            HrTextField(
                              hint: 'Search by name, code, message...',
                              prefixIcon: const Icon(Icons.search),
                              onChanged: controller.onSearch,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Conversations List
                      Expanded(
                        child: controller.isLoadingConversations && controller.conversations.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : controller.conversations.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppDimensions.space16),
                                      child: Text(
                                        'No conversations found.',
                                        style: AppTypography.captionOf(context),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: controller.conversations.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final conv = controller.conversations[index];
                                      final isSelected = selectedConv?.id == conv.id;

                                      return InkWell(
                                        onTap: () {
                                          controller.selectConversation(conv);
                                          _scrollToBottom();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(AppDimensions.space12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryLight.withValues(alpha: isDark ? 0.18 : 0.08)
                                                : Colors.transparent,
                                            border: isSelected
                                                ? const Border(left: BorderSide(color: AppColors.primaryLight, width: 4))
                                                : null,
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                                                child: Text(
                                                  conv.employeeName.isNotEmpty ? conv.employeeName[0].toUpperCase() : 'E',
                                                  style: const TextStyle(
                                                    color: AppColors.primaryLight,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: AppDimensions.space12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            conv.employeeName,
                                                            style: conv.unreadCount > 0
                                                                ? AppTypography.bodyBold
                                                                : AppTypography.bodyMedium,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Text(
                                                          DateFormatter.toDisplayDate(conv.lastMessageTime),
                                                          style: AppTypography.captionOf(context),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${conv.employeeCode} • ${conv.employeeDepartment}',
                                                      style: AppTypography.captionOf(context),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            conv.lastMessageContent,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: conv.unreadCount > 0
                                                                ? AppTypography.bodyBold.copyWith(fontSize: 13)
                                                                : AppTypography.captionOf(context),
                                                          ),
                                                        ),
                                                        if (conv.unreadCount > 0)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primaryLight,
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Text(
                                                              '${conv.unreadCount}',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),

                // 2. Detail: Conversation View & Message Stream (Right)
                Expanded(
                  child: selectedConv == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_outlined, size: 48, color: AppColors.textSecondary(context).withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text('Select a conversation to inspect thread', style: AppTypography.subtitleOf(context)),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Conversation Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20, vertical: AppDimensions.space12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: Border(bottom: BorderSide(color: AppColors.border(context))),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                                    child: Text(
                                      selectedConv.employeeName.isNotEmpty ? selectedConv.employeeName[0].toUpperCase() : 'E',
                                      style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(selectedConv.employeeName, style: AppTypography.bodyBold.copyWith(fontSize: 15)),
                                            const SizedBox(width: 8),
                                            StatusBadge(
                                              label: selectedConv.status.label,
                                              variant: selectedConv.status == ConversationStatus.open
                                                  ? BadgeVariant.success
                                                  : BadgeVariant.neutral,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${selectedConv.employeeCode} • ${selectedConv.employeeDepartment} • ${selectedConv.employeeJobTitle}${selectedConv.employeeWorkplace != null ? " • ${selectedConv.employeeWorkplace}" : ""}',
                                          style: AppTypography.captionOf(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Messages Thread List
                            Expanded(
                              child: controller.isLoadingMessages
                                  ? const Center(child: CircularProgressIndicator())
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(AppDimensions.space16),
                                      itemCount: controller.messages.length,
                                      itemBuilder: (context, index) {
                                        final msg = controller.messages[index];
                                        final isHr = msg.senderType == MessageSenderType.hr;
                                        final isSystem = msg.senderType == MessageSenderType.system;

                                        if (isSystem) {
                                          return Center(
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                msg.content,
                                                style: AppTypography.captionOf(context),
                                              ),
                                            ),
                                          );
                                        }

                                        return Align(
                                          alignment: isHr ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            constraints: const BoxConstraints(maxWidth: 480),
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            padding: const EdgeInsets.all(AppDimensions.space12),
                                            decoration: BoxDecoration(
                                              color: isHr
                                                  ? AppColors.primaryLight
                                                  : isDark
                                                      ? const Color(0xFF1E293B)
                                                      : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(AppDimensions.radiusMedium),
                                                topRight: const Radius.circular(AppDimensions.radiusMedium),
                                                bottomLeft: Radius.circular(isHr ? AppDimensions.radiusMedium : 2),
                                                bottomRight: Radius.circular(isHr ? 2 : AppDimensions.radiusMedium),
                                              ),
                                              border: isHr ? null : Border.all(color: AppColors.border(context)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isHr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  msg.content,
                                                  style: TextStyle(
                                                    color: isHr
                                                        ? Colors.white
                                                        : isDark
                                                            ? Colors.white
                                                            : AppColors.textPrimaryLight,
                                                    fontSize: 14,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      DateFormatter.toTimeOnly(msg.timestamp),
                                                      style: TextStyle(
                                                        color: isHr
                                                            ? Colors.white.withValues(alpha: 0.7)
                                                            : AppColors.textSecondary(context),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    if (isHr) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        msg.isRead ? Icons.done_all : Icons.done,
                                                        size: 14,
                                                        color: Colors.white.withValues(alpha: 0.8),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // Message Composer (Bottom Bar)
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.space12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                border: Border(top: BorderSide(color: AppColors.border(context))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageTextController,
                                      minLines: 1,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        hintText: 'Type your message to ${selectedConv.employeeName}... (Press Enter)',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                          borderSide: BorderSide(color: AppColors.border(context)),
                                        ),
                                      ),
                                      onSubmitted: (text) async {
                                        if (text.trim().isNotEmpty) {
                                          final ok = await controller.sendMessage(text);
                                          if (ok) {
                                            _messageTextController.clear();
                                            _scrollToBottom();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space8),
                                  IconButton.filled(
                                    icon: controller.isSendingMessage
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.send, size: 18),
                                    onPressed: controller.isSendingMessage
                                        ? null
                                        : () async {
                                            final text = _messageTextController.text.trim();
                                            if (text.isNotEmpty) {
                                              final ok = await controller.sendMessage(text);
                                              if (ok) {
                                                _messageTextController.clear();
                                                _scrollToBottom();
                                              }
                                            }
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
