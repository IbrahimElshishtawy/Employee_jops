import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../data/datasources/remote_update_data_source.dart';
import '../../data/datasources/shorebird_data_source.dart';
import '../../data/services/app_update_service_impl.dart';
import '../../domain/entities/app_version.dart';
import '../../domain/entities/update_info.dart';
import '../../domain/services/update_service.dart';

final remoteUpdateDataSourceProvider = Provider<RemoteUpdateDataSource>((ref) {
  final storage = ref.watch(localStorageProvider);
  return RemoteUpdateDataSourceImpl(localStorage: storage);
});

final shorebirdDataSourceProvider = Provider<ShorebirdDataSource>((ref) {
  return ShorebirdDataSourceImpl();
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  final remoteDs = ref.watch(remoteUpdateDataSourceProvider);
  final shorebirdDs = ref.watch(shorebirdDataSourceProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return AppUpdateServiceImpl(
    remoteDataSource: remoteDs,
    shorebirdDataSource: shorebirdDs,
    notificationService: notificationService,
  );
});

enum UpdateStatus {
  initial,
  checking,
  noUpdate,
  storeUpdateAvailable,
  shorebirdPatchReady,
  error,
}

class UpdateState {
  final UpdateStatus status;
  final UpdateCheckResult? checkResult;
  final bool isDismissed;
  final String? errorMessage;

  const UpdateState({
    this.status = UpdateStatus.initial,
    this.checkResult,
    this.isDismissed = false,
    this.errorMessage,
  });

  bool get isChecking => status == UpdateStatus.checking;
  bool get hasStoreUpdate =>
      status == UpdateStatus.storeUpdateAvailable &&
      checkResult != null &&
      !isDismissed;
  bool get isForceUpdate => checkResult?.isForceUpdate ?? false;
  bool get hasShorebirdPatch => status == UpdateStatus.shorebirdPatchReady;

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateCheckResult? checkResult,
    bool? isDismissed,
    String? errorMessage,
  }) {
    return UpdateState(
      status: status ?? this.status,
      checkResult: checkResult ?? this.checkResult,
      isDismissed: isDismissed ?? this.isDismissed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _service;

  UpdateNotifier(this._service) : super(const UpdateState()) {
    // Perform initial background check on startup
    _initialCheck();
  }

  Future<void> _initialCheck() async {
    await _service.initialize();
    await checkForUpdate(isManual: false);
  }

  Future<UpdateCheckResult> checkForUpdate({bool isManual = false}) async {
    state = state.copyWith(status: UpdateStatus.checking, errorMessage: null);

    try {
      final result = await _service.checkForUpdate(isManualCheck: isManual);
      if (result.hasUpdate) {
        if (result.updateType.isNormalRelease) {
          state = state.copyWith(
            status: UpdateStatus.storeUpdateAvailable,
            checkResult: result,
            isDismissed: false,
          );
        } else if (result.updateType.isShorebirdPatch) {
          state = state.copyWith(
            status: UpdateStatus.shorebirdPatchReady,
            checkResult: result,
            isDismissed: false,
          );
        }
      } else {
        state = state.copyWith(
          status: UpdateStatus.noUpdate,
          checkResult: result,
        );
      }
      return result;
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );
      return UpdateCheckResult.noUpdate(
        currentVersion: _service.currentInstalledVersion,
        config: const UpdateConfig(
          latestVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12),
          minimumSupportedVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
        ),
      );
    }
  }

  void dismissOptionalUpdate() {
    if (!state.isForceUpdate) {
      state = state.copyWith(isDismissed: true);
    }
  }

  Future<bool> launchUpdateUrl(String? url) async {
    return await _service.openStoreOrReleaseUrl(url);
  }
}

final updateStateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final service = ref.watch(updateServiceProvider);
  return UpdateNotifier(service);
});
