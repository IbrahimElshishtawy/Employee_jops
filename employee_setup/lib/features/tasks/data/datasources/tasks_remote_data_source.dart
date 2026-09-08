import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/task_model.dart';

class TasksRemoteDataSource {
  final ApiClient apiClient;

  const TasksRemoteDataSource(this.apiClient);

  /// 1. GET /api/v1/tasks/my
  Future<List<TaskItem>> getMyTasks() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.myTasks,
        fromData: (data) {
          if (data is List) {
            return data
                .whereType<Map<String, dynamic>>()
                .map((e) => TaskItem.fromJson(e))
                .toList();
          }
          return <TaskItem>[];
        },
      );
      return response.data ?? _mockDefaultTasks();
    } on ApiException catch (e) {
      SecureLogger.error('TasksRemoteDataSource', 'Failed to get tasks', e);
      return _mockDefaultTasks();
    }
  }

  /// 2. GET /api/v1/tasks/:id
  Future<TaskItem?> getTaskById(String id) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.taskById(id),
        fromData: (data) {
          if (data is Map<String, dynamic>) {
            return TaskItem.fromJson(data);
          }
          return null;
        },
      );
      return response.data;
    } catch (e) {
      SecureLogger.error('TasksRemoteDataSource', 'Failed to get task $id', e);
      return null;
    }
  }

  /// 3. POST /api/v1/tasks/:id/accept
  Future<bool> acceptTask(String id) async {
    try {
      final response = await apiClient.post(ApiEndpoints.acceptTask(id));
      return response.success;
    } catch (e) {
      SecureLogger.error('TasksRemoteDataSource', 'Accept task error', e);
      return false;
    }
  }

  /// 4. POST /api/v1/tasks/:id/status
  Future<bool> updateTaskStatus(String id, TaskStatus status) async {
    try {
      String statusStr;
      switch (status) {
        case TaskStatus.inProgress:
          statusStr = 'IN_PROGRESS';
          break;
        case TaskStatus.blocked:
          statusStr = 'BLOCKED';
          break;
        case TaskStatus.completed:
          statusStr = 'COMPLETED';
          break;
        case TaskStatus.cancelled:
          statusStr = 'CANCELLED';
          break;
        default:
          statusStr = 'TODO';
      }

      final response = await apiClient.post(
        ApiEndpoints.updateTaskStatus(id),
        data: {'status': statusStr},
      );
      return response.success;
    } catch (e) {
      SecureLogger.error('TasksRemoteDataSource', 'Update status error', e);
      return false;
    }
  }

  /// 5. PATCH /api/v1/tasks/:id
  Future<bool> updateTaskProgress(String id, double progressPercent) async {
    try {
      final response = await apiClient.patch(
        ApiEndpoints.updateTask(id),
        data: {'progress': progressPercent},
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// 6. POST /api/v1/tasks/:id/checklist
  Future<TaskChecklistItem?> addChecklistItem(String taskId, String title) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.addTaskChecklist(taskId),
        data: {'title': title},
        fromData: (data) => TaskChecklistItem.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// 7. PATCH /api/v1/tasks/:taskId/checklist/:itemId
  Future<bool> toggleChecklistItem(String taskId, String itemId, bool isCompleted) async {
    try {
      final response = await apiClient.patch(
        ApiEndpoints.toggleChecklistItem(taskId, itemId),
        data: {'completed': isCompleted},
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// 8. DELETE /api/v1/tasks/:taskId/checklist/:itemId
  Future<bool> deleteChecklistItem(String taskId, String itemId) async {
    try {
      final response = await apiClient.delete(
        ApiEndpoints.deleteChecklistItem(taskId, itemId),
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// 9. GET /api/v1/tasks/:id/comments
  Future<List<TaskComment>> getComments(String taskId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.taskComments(taskId),
        fromData: (data) {
          if (data is List) {
            return data.map((e) => TaskComment.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <TaskComment>[];
        },
      );
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// 10. POST /api/v1/tasks/:id/comments
  Future<TaskComment?> addComment(String taskId, String content) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.taskComments(taskId),
        data: {'content': content},
        fromData: (data) => TaskComment.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// 11. GET /api/v1/tasks/:id/attachments
  Future<List<TaskAttachment>> getAttachments(String taskId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.taskAttachments(taskId),
        fromData: (data) {
          if (data is List) {
            return data.map((e) => TaskAttachment.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <TaskAttachment>[];
        },
      );
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  /// 12. POST /api/v1/tasks/:id/attachments
  Future<TaskAttachment?> addAttachment(String taskId, String url, String filename) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.taskAttachments(taskId),
        data: {'url': url, 'filename': filename},
        fromData: (data) => TaskAttachment.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// 13. GET /api/v1/tasks/:id/history
  Future<List<Map<String, dynamic>>> getTaskHistory(String taskId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.taskHistory(taskId),
        fromData: (data) {
          if (data is List) {
            return data.whereType<Map<String, dynamic>>().toList();
          }
          return <Map<String, dynamic>>[];
        },
      );
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  List<TaskItem> _mockDefaultTasks() {
    return [
      TaskItem(
        id: 'TSK-101',
        title: 'فحص وصيانة أجهزة التكييف في الجناح الملكي',
        description: 'إجراء الفحص الدوري الشامل لمرشحات التبريد وضغط الغاز قبل وصول الوفد.',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        progressPercent: 60.0,
        checklist: const [
          TaskChecklistItem(id: 'chk-1', title: 'تنظيف فلاتر الهواء', isCompleted: true),
          TaskChecklistItem(id: 'chk-2', title: 'قياس ضغط الفريون', isCompleted: true),
          TaskChecklistItem(id: 'chk-3', title: 'اختبار لوحة التحكم الذكية', isCompleted: false),
        ],
        comments: [
          TaskComment(
            id: 'cm-1',
            authorName: 'رئيس قسم الصيانة',
            content: 'يرجى إنهاء الفحص قبل الساعة 2 ظهراً.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      TaskItem(
        id: 'TSK-102',
        title: 'تجهيز صالة المؤتمرات لاجتماع مجلس الإدارة',
        description: 'إعداد الشاشات وأنظمة الصوت والترجمة الفورية وضبط إضاءة القاعة.',
        status: TaskStatus.todo,
        priority: TaskPriority.urgent,
        dueDate: DateTime.now().add(const Duration(hours: 5)),
        progressPercent: 0.0,
        checklist: const [
          TaskChecklistItem(id: 'chk-4', title: 'توصيل شاشة العرض الرئيسية', isCompleted: false),
          TaskChecklistItem(id: 'chk-5', title: 'اختبار مكبرات الصوت والمايكات', isCompleted: false),
        ],
      ),
    ];
  }
}
