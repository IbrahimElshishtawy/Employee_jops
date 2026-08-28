import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/employee_contact.dart';
import '../providers/chat_provider.dart';
import '../providers/conversations_provider.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/message_list.dart';
import '../widgets/message_input.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_error_state.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentEmp = ref.watch(employeeProvider);
    final currentUserId = currentEmp.id.isNotEmpty ? currentEmp.id : 'EMP-001';

    final chatState = ref.watch(chatProvider(widget.conversationId));
    final chatNotifier = ref.read(chatProvider(widget.conversationId).notifier);

    // Retrieve conversation info for recipient details
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

    ref.listen(chatProvider(widget.conversationId), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: ChatAppBar(
        contact: contact,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chatState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chatState.errorMessage != null
                      ? ChatErrorState(
                          errorMessage: chatState.errorMessage,
                          onRetry: () => chatNotifier.loadMessages(),
                        )
                      : chatState.messages.isEmpty
                          ? ChatEmptyState(contactName: contact.fullName)
                          : MessageList(
                              messages: chatState.messages,
                              currentUserId: currentUserId,
                              scrollController: _scrollController,
                            ),
            ),
            MessageInput(
              isSending: chatState.isSending,
              onSend: (text) {
                chatNotifier.sendMessage(
                  receiverId: contact.id,
                  content: text,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
