import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_shimmer.dart';

/// Full screen skeleton for the main Community & Communication Hub.
class CommunicationMainScreenSkeleton extends StatelessWidget {
  const CommunicationMainScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Skeleton
            Row(
              children: [
                const ShimmerCircle(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 140, height: 16),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 12),
                    ],
                  ),
                ),
                const ShimmerBox(width: 40, height: 40, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Action Hub 3 Cards Skeleton
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == 2 ? 0 : 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: 32, height: 32, borderRadius: 8),
                          SizedBox(height: 10),
                          ShimmerBox(width: 65, height: 12),
                          SizedBox(height: 6),
                          ShimmerBox(width: 45, height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Departments Section Header Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 110, height: 16),
                ShimmerBox(width: 80, height: 14),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Departments Grid Skeleton (4 items)
            const DepartmentGridSkeleton(itemCount: 4),

            const SizedBox(height: 24),

            // 5. Recent Conversations Section Header Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 130, height: 16),
                ShimmerBox(width: 60, height: 14),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Recent Conversations Skeleton List
            const ConversationListSkeleton(itemCount: 3),

            const SizedBox(height: 24),

            // 7. Recent Requests Section Header Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 140, height: 16),
                ShimmerBox(width: 60, height: 14),
              ],
            ),
            const SizedBox(height: 12),

            // 8. Recent Requests Skeleton List
            const RequestListSkeleton(itemCount: 2),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for hotel department cards in grid.
class DepartmentGridSkeleton extends StatelessWidget {
  final int itemCount;

  const DepartmentGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.3,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const ShimmerCard(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                ShimmerBox(width: 36, height: 36, borderRadius: 10),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(width: double.infinity, height: 12),
                      SizedBox(height: 6),
                      ShimmerBox(width: 50, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton for conversations list.
class ConversationListSkeleton extends StatelessWidget {
  final int itemCount;

  const ConversationListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return const ShimmerCard(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                ShimmerCircle(size: 48),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 110, height: 13),
                          ShimmerBox(width: 45, height: 10),
                        ],
                      ),
                      SizedBox(height: 8),
                      ShimmerBox(width: 180, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton for operational requests list.
class RequestListSkeleton extends StatelessWidget {
  final int itemCount;

  const RequestListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return const ShimmerCard(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: ID badge & Status pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 75, height: 20, borderRadius: 6),
                    ShimmerBox(width: 85, height: 20, borderRadius: 12),
                  ],
                ),
                SizedBox(height: 12),
                // Request Type Title
                ShimmerBox(width: 170, height: 14),
                SizedBox(height: 8),
                // Department & Requester info
                Row(
                  children: [
                    ShimmerBox(width: 90, height: 12),
                    SizedBox(width: 12),
                    ShimmerBox(width: 70, height: 12),
                  ],
                ),
                SizedBox(height: 12),
                // Bottom Date & Priority
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 100, height: 11),
                    ShimmerBox(width: 60, height: 18, borderRadius: 6),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton for employee contact cards in department contacts list.
class EmployeeListSkeleton extends StatelessWidget {
  final int itemCount;

  const EmployeeListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return const ShimmerCard(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ShimmerCircle(size: 46),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 130, height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 11),
                      SizedBox(height: 8),
                      ShimmerBox(width: 65, height: 16, borderRadius: 6),
                    ],
                  ),
                ),
                ShimmerCircle(size: 36),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Full screen skeleton for Request Details Screen.
class RequestDetailsSkeleton extends StatelessWidget {
  const RequestDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            ShimmerCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 90, height: 22, borderRadius: 6),
                      ShimmerBox(width: 90, height: 22, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const ShimmerBox(width: 200, height: 18),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 140, height: 13),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline / Status Card Skeleton
            ShimmerCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 110, height: 15),
                  const SizedBox(height: 16),
                  ...List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: const [
                          ShimmerCircle(size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBox(width: 120, height: 13),
                                SizedBox(height: 4),
                                ShimmerBox(width: 80, height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details card Skeleton
            ShimmerCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 100, height: 15),
                  SizedBox(height: 14),
                  ShimmerBox(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  ShimmerBox(width: 220, height: 12),
                  SizedBox(height: 8),
                  ShimmerBox(width: 160, height: 12),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button Skeleton
            const ShimmerBox(
              width: double.infinity,
              height: 48,
              borderRadius: AppDimensions.radiusMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen skeleton for Employee Contact & Profile Screen.
class EmployeeProfileSkeleton extends StatelessWidget {
  const EmployeeProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            ShimmerCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: const [
                  ShimmerCircle(size: 92),
                  SizedBox(height: 16),
                  ShimmerBox(width: 160, height: 18),
                  SizedBox(height: 8),
                  ShimmerBox(width: 110, height: 13),
                  SizedBox(height: 12),
                  ShimmerBox(width: 80, height: 22, borderRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info items skeleton
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: const [
                      ShimmerBox(width: 36, height: 36, borderRadius: 8),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 70, height: 11),
                            SizedBox(height: 6),
                            ShimmerBox(width: 140, height: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Button
            const ShimmerBox(
              width: double.infinity,
              height: 48,
              borderRadius: AppDimensions.radiusMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for Chat Conversation Messages.
class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final isMe = index % 2 == 1;
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  const ShimmerCircle(size: 28),
                  const SizedBox(width: 8),
                ],
                ShimmerBox(
                  width: index.isEven ? 180 : 130,
                  height: index == 2 ? 60 : 38,
                  borderRadius: 16,
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  const ShimmerCircle(size: 28),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
