import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

class MessageInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final bool isSending;

  const MessageInput({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + context.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: TextStyle(
                  fontSize: 14.5,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'اكتب رسالتك هنا...'
                      : 'Type your message...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textSecondaryLight,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _hasText && !widget.isSending
                ? AppColors.primary
                : (isDark
                    ? AppColors.surfaceVariantDark
                    : const Color(0xFFE2E8F0)),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _hasText && !widget.isSending ? _handleSend : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: widget.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Transform.rotate(
                        angle: isArabic ? 3.14159 : 0,
                        child: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: _hasText && !widget.isSending
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
