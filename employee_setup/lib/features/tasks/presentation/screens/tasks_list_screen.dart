import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/models/task_model.dart';
import '../controllers/tasks_provider.dart';
import 'task_details_screen.dart';

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen> {
  TaskStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final tasksAsync = ref.watch(tasksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'مهام العمل والتكليفات' : 'Tasks & Checklists'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip(label: isRtl ? 'الكل' : 'All', status: null),
                const SizedBox(width: 8),
                _buildFilterChip(label: isRtl ? 'قيد التنفيذ' : 'In Progress', status: TaskStatus.inProgress),
                const SizedBox(width: 8),
                _buildFilterChip(label: isRtl ? 'جديدة' : 'To Do', status: TaskStatus.todo),
                const SizedBox(width: 8),
                _buildFilterChip(label: isRtl ? 'مكتملة' : 'Completed', status: TaskStatus.completed),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = _filterStatus == null
                    ? tasks
                    : tasks.where((t) => t.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isRtl ? 'لا توجد مهام مطابقة' : 'No matching tasks found',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(tasksListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final task = filtered[index];
                      return _buildTaskCard(task, isDark, isRtl);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required TaskStatus? status}) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = status),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task, bool isDark, bool isRtl) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailsScreen(initialTask: task),
            ),
          ).then((_) => ref.invalidate(tasksListProvider));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(task.status, isRtl),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),

              // Checklist & Progress info
              Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 16,
                    color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.checklist.where((c) => c.isCompleted).length}/${task.checklist.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(task.dueDate),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progressPercent / 100.0,
                  minHeight: 5,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status, bool isRtl) {
    Color color;
    String label;
    switch (status) {
      case TaskStatus.inProgress:
        color = AppColors.primary;
        label = isRtl ? 'قيد التنفيذ' : 'IN PROGRESS';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        label = isRtl ? 'مكتمل' : 'COMPLETED';
        break;
      case TaskStatus.blocked:
        color = Colors.amber.shade800;
        label = isRtl ? 'معطل' : 'BLOCKED';
        break;
      case TaskStatus.accepted:
        color = Colors.teal;
        label = isRtl ? 'مقبول' : 'ACCEPTED';
        break;
      default:
        color = Colors.grey;
        label = isRtl ? 'جديد' : 'TODO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
