import '../../domain/models/task_model.dart';
import '../datasources/tasks_remote_data_source.dart';

abstract class TasksRepository {
  Future<List<TaskItem>> getMyTasks();
  Future<TaskItem?> getTaskById(String id);
  Future<bool> acceptTask(String id);
  Future<bool> updateTaskStatus(String id, TaskStatus status);
  Future<bool> toggleChecklistItem(String taskId, String itemId, bool isCompleted);
  Future<TaskChecklistItem?> addChecklistItem(String taskId, String title);
  Future<bool> deleteChecklistItem(String taskId, String itemId);
  Future<List<TaskComment>> getComments(String taskId);
  Future<TaskComment?> addComment(String taskId, String content);
  Future<List<TaskAttachment>> getAttachments(String taskId);
  Future<TaskAttachment?> addAttachment(String taskId, String url, String filename);
}

class RealTasksRepository implements TasksRepository {
  final TasksRemoteDataSource remoteDataSource;

  const RealTasksRepository(this.remoteDataSource);

  @override
  Future<List<TaskItem>> getMyTasks() => remoteDataSource.getMyTasks();

  @override
  Future<TaskItem?> getTaskById(String id) => remoteDataSource.getTaskById(id);

  @override
  Future<bool> acceptTask(String id) => remoteDataSource.acceptTask(id);

  @override
  Future<bool> updateTaskStatus(String id, TaskStatus status) =>
      remoteDataSource.updateTaskStatus(id, status);

  @override
  Future<bool> toggleChecklistItem(String taskId, String itemId, bool isCompleted) =>
      remoteDataSource.toggleChecklistItem(taskId, itemId, isCompleted);

  @override
  Future<TaskChecklistItem?> addChecklistItem(String taskId, String title) =>
      remoteDataSource.addChecklistItem(taskId, title);

  @override
  Future<bool> deleteChecklistItem(String taskId, String itemId) =>
      remoteDataSource.deleteChecklistItem(taskId, itemId);

  @override
  Future<List<TaskComment>> getComments(String taskId) =>
      remoteDataSource.getComments(taskId);

  @override
  Future<TaskComment?> addComment(String taskId, String content) =>
      remoteDataSource.addComment(taskId, content);

  @override
  Future<List<TaskAttachment>> getAttachments(String taskId) =>
      remoteDataSource.getAttachments(taskId);

  @override
  Future<TaskAttachment?> addAttachment(String taskId, String url, String filename) =>
      remoteDataSource.addAttachment(taskId, url, filename);
}
