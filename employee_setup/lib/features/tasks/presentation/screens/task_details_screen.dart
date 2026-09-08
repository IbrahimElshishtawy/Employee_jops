import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/models/task_model.dart';
import '../controllers/tasks_provider.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final TaskItem? initialTask;
  final String? taskId;

  const TaskDetailsScreen({super.key, this.initialTask, this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  late TaskItem _task;
  final _commentController = TextEditingController();
  final _checklistController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _task = widget.initialTask ??
        TaskItem(
          id: widget.taskId ?? '',
          title: 'Task Details',
          description: '',
          priority: TaskPriority.medium,
          status: TaskStatus.todo,
          dueDate: DateTime.now(),
        );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _toggleChecklist(TaskChecklistItem item) async {
    final updatedCompleted = !item.isCompleted;
    final updatedList = _task.checklist.map((c) {
      if (c.id == item.id) {
        return c.copyWith(isCompleted: updatedCompleted);
      }
      return c;
    }).toList();

    final doneCount = updatedList.where((c) => c.isCompleted).length;
    final newProgress = updatedList.isNotEmpty ? (doneCount / updatedList.length) * 100.0 : 0.0;

    setState(() {
      _task = _task.copyWith(
        checklist: updatedList,
        progressPercent: newProgress,
      );
    });

    final repo = ref.read(tasksRepositoryProvider);
    await repo.toggleChecklistItem(_task.id, item.id, updatedCompleted);
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    final repo = ref.read(tasksRepositoryProvider);
    final newComment = await repo.addComment(_task.id, text);

    if (mounted) {
      setState(() {
        _isSubmittingComment = false;
        _commentController.clear();
        if (newComment != null) {
          _task = _task.copyWith(
            comments: [..._task.comments, newComment],
          );
        }
      });
    }
  }

  Future<void> _changeStatus(TaskStatus newStatus) async {
    setState(() {
      _task = _task.copyWith(status: newStatus);
    });
    final repo = ref.read(tasksRepositoryProvider);
    if (newStatus == TaskStatus.accepted) {
      await repo.acceptTask(_task.id);
    } else {
      await repo.updateTaskStatus(_task.id, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'تفاصيل المهمة' : 'Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Priority Bar
            Row(
              children: [
                _buildStatusChip(_task.status, isRtl),
                const SizedBox(width: 8),
                _buildPriorityChip(_task.priority, isRtl),
                const Spacer(),
                Text(
                  '${isRtl ? "موعد التسليم:" : "Due:"} ${DateFormat('MMM dd, yyyy').format(_task.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title & Description
            Text(
              _task.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _task.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Progress Meter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRtl ? 'نسبة الإنجاز الكلية' : 'Overall Progress',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${_task.progressPercent.toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _task.progressPercent / 100.0,
                      minHeight: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_task.status == TaskStatus.todo)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(isRtl ? 'قبول المهمة' : 'Accept Task'),
                    onPressed: () => _changeStatus(TaskStatus.accepted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_task.status == TaskStatus.accepted || _task.status == TaskStatus.blocked)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(isRtl ? 'بدء التنفيذ' : 'Start Task'),
                    onPressed: () => _changeStatus(TaskStatus.inProgress),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_task.status == TaskStatus.inProgress) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: Text(isRtl ? 'إيقاف / تعطل' : 'Mark Blocked'),
                    onPressed: () => _changeStatus(TaskStatus.blocked),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: Text(isRtl ? 'اكتمال المهمة' : 'Complete Task'),
                    onPressed: () => _changeStatus(TaskStatus.completed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Checklist Section
            Text(
              isRtl ? 'قائمة الفحص والمراجعة (Checklist)' : 'Task Checklist',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final item in _task.checklist)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: item.isCompleted,
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? Colors.grey : null,
                  ),
                ),
                onChanged: (_) => _toggleChecklist(item),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            const SizedBox(height: 20),

            // Comments Section
            Text(
              isRtl ? 'الملاحظات والنقاشات' : 'Comments & Discussion',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final comment in _task.comments)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          DateFormat('HH:mm').format(comment.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),

            // Add Comment Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: isRtl ? 'اكتب تعليقاً...' : 'Add a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _isSubmittingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  onPressed: _isSubmittingComment ? null : _addComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status, bool isRtl) {
    Color color;
    String label;
    switch (status) {
      case TaskStatus.todo:
        color = Colors.grey;
        label = isRtl ? 'جديد' : 'TODO';
        break;
      case TaskStatus.accepted:
        color = Colors.teal;
        label = isRtl ? 'تم القبول' : 'ACCEPTED';
        break;
      case TaskStatus.inProgress:
        color = AppColors.primary;
        label = isRtl ? 'قيد التنفيذ' : 'IN PROGRESS';
        break;
      case TaskStatus.blocked:
        color = Colors.amber.shade800;
        label = isRtl ? 'معطل' : 'BLOCKED';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        label = isRtl ? 'مكتمل' : 'COMPLETED';
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        label = isRtl ? 'ملغي' : 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority, bool isRtl) {
    Color color = Colors.grey;
    String label = priority.name.toUpperCase();
    if (priority == TaskPriority.high) color = Colors.orange;
    if (priority == TaskPriority.urgent) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
