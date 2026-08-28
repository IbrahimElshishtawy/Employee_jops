import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../domain/entities/department_request.dart';
import '../../domain/entities/request_type.dart';
import 'communication_providers.dart';

final requestTypesProvider = FutureProvider.family<List<RequestType>, String?>((ref, deptId) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return await repo.getRequestTypes(departmentId: deptId);
});

final myDepartmentRequestsProvider = FutureProvider<List<DepartmentRequest>>((ref) async {
  final getMyRequests = ref.watch(getMyRequestsUseCaseProvider);
  return await getMyRequests();
});

final activeDepartmentRequestsCountProvider = Provider<int>((ref) {
  final requestsAsync = ref.watch(myDepartmentRequestsProvider);
  return requestsAsync.maybeWhen(
    data: (requests) => requests.where((r) => r.status.isActive).length,
    orElse: () => 0,
  );
});

final departmentRequestByIdProvider = FutureProvider.family<DepartmentRequest?, String>((ref, id) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return await repo.getRequestById(id);
});

class DepartmentRequestActionNotifier extends StateNotifier<AsyncValue<DepartmentRequest?>> {
  final Ref _ref;

  DepartmentRequestActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<DepartmentRequest?> createRequest({
    required String departmentId,
    required String requestTypeId,
    required RequestPriority priority,
    required String message,
    String? locationContext,
    String? recipientId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final createReq = _ref.read(createDepartmentRequestUseCaseProvider);
      final result = await createReq(
        departmentId: departmentId,
        requestTypeId: requestTypeId,
        priority: priority,
        message: message,
        locationContext: locationContext,
        recipientId: recipientId,
      );

      // In-App Notification integration
      final notifRepo = _ref.read(notificationsRepositoryProvider);
      await notifRepo.addNotification(
        AppNotification(
          id: 'notif-req-${DateTime.now().millisecondsSinceEpoch}',
          title: 'طلب تشغيلي جديد (${result.localizedDepartment(true)})',
          message: 'تم إرسال طلب ${result.localizedRequestType(true)} بنجاح، والحالة الحالية: قيد الانتظار.',
          category: NotificationCategory.requestUpdate,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );

      _ref.invalidate(myDepartmentRequestsProvider);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<DepartmentRequest?> acceptRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      final accept = _ref.read(acceptRequestUseCaseProvider);
      final result = await accept(requestId);

      final notifRepo = _ref.read(notificationsRepositoryProvider);
      await notifRepo.addNotification(
        AppNotification(
          id: 'notif-req-${DateTime.now().millisecondsSinceEpoch}',
          title: 'تم قبول الطلب التشغيلي',
          message: 'تم قبول طلب ${result.localizedRequestType(true)} بنجاح.',
          category: NotificationCategory.requestUpdate,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );

      _ref.invalidate(myDepartmentRequestsProvider);
      _ref.invalidate(departmentRequestByIdProvider(requestId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<DepartmentRequest?> rejectRequest(String requestId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      final reject = _ref.read(rejectRequestUseCaseProvider);
      final result = await reject(requestId, reason: reason);

      final notifRepo = _ref.read(notificationsRepositoryProvider);
      await notifRepo.addNotification(
        AppNotification(
          id: 'notif-req-${DateTime.now().millisecondsSinceEpoch}',
          title: 'تم رفض الطلب التشغيلي',
          message: 'تم رفض طلب ${result.localizedRequestType(true)}.',
          category: NotificationCategory.requestUpdate,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );

      _ref.invalidate(myDepartmentRequestsProvider);
      _ref.invalidate(departmentRequestByIdProvider(requestId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<DepartmentRequest?> startRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      final start = _ref.read(startRequestUseCaseProvider);
      final result = await start(requestId);

      final notifRepo = _ref.read(notificationsRepositoryProvider);
      await notifRepo.addNotification(
        AppNotification(
          id: 'notif-req-${DateTime.now().millisecondsSinceEpoch}',
          title: 'بدء تنفيذ الطلب',
          message: 'طلب ${result.localizedRequestType(true)} أصبح قيد التنفيذ حالياً.',
          category: NotificationCategory.requestUpdate,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );

      _ref.invalidate(myDepartmentRequestsProvider);
      _ref.invalidate(departmentRequestByIdProvider(requestId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<DepartmentRequest?> completeRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      final complete = _ref.read(completeRequestUseCaseProvider);
      final result = await complete(requestId);

      final notifRepo = _ref.read(notificationsRepositoryProvider);
      await notifRepo.addNotification(
        AppNotification(
          id: 'notif-req-${DateTime.now().millisecondsSinceEpoch}',
          title: 'اكتمل الطلب التشغيلي',
          message: 'تم إنجاز طلب ${result.localizedRequestType(true)} بنجاح.',
          category: NotificationCategory.requestUpdate,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );

      _ref.invalidate(myDepartmentRequestsProvider);
      _ref.invalidate(departmentRequestByIdProvider(requestId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final departmentRequestActionProvider =
    StateNotifierProvider<DepartmentRequestActionNotifier, AsyncValue<DepartmentRequest?>>((ref) {
  return DepartmentRequestActionNotifier(ref);
});
