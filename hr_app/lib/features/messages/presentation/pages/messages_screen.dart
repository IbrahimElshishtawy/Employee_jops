import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';

/// HR Broadcast & Direct Messages Screen
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('HR Internal Communications', style: AppTypography.heading2),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Send direct messages or company-wide announcements to employee mobile apps.',
            style: AppTypography.subtitleOf(context),
          ),
          const SizedBox(height: AppDimensions.space24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Compose Announcement / Message', style: AppTypography.heading3),
                  const SizedBox(height: AppDimensions.space16),
                  const HrTextField(
                    label: 'Target Audience',
                    hint: 'All Employees / Specific Department',
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  const HrTextField(
                    label: 'Message Subject',
                    hint: 'e.g. Upcoming Public Holiday Working Schedule',
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  const HrTextField(
                    label: 'Message Content',
                    hint: 'Enter your message body...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      HrButton(
                        label: 'Send Broadcast',
                        icon: Icons.send_outlined,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Broadcast message queued for delivery.')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
