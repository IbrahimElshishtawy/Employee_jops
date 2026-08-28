import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Supported device platform types
enum DeviceType {
  android,
  ios,
  web,
  desktop,
  other;

  String get typeName => name.toUpperCase();
}

/// Device information payload model
class DeviceInfo {
  final String deviceId;
  final DeviceType deviceType;
  final String platform;
  final String operatingSystem;
  final String osVersion;
  final String appVersion;
  final String deviceModel;
  final String manufacturer;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceType,
    required this.platform,
    required this.operatingSystem,
    required this.osVersion,
    required this.appVersion,
    required this.deviceModel,
    required this.manufacturer,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceType': deviceType.typeName,
        'platform': platform,
        'operatingSystem': operatingSystem,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'deviceModel': deviceModel,
        'manufacturer': manufacturer,
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        deviceId: json['deviceId'] as String? ?? 'UNKNOWN_DEVICE_ID',
        deviceType: DeviceType.values.firstWhere(
          (d) => d.typeName == (json['deviceType'] as String? ?? 'OTHER'),
          orElse: () => DeviceType.other,
        ),
        platform: json['platform'] as String? ?? 'Unknown',
        operatingSystem: json['operatingSystem'] as String? ?? 'Unknown',
        osVersion: json['osVersion'] as String? ?? '1.0.0',
        appVersion: json['appVersion'] as String? ?? '1.0.0',
        deviceModel: json['deviceModel'] as String? ?? 'Mobile Device',
        manufacturer: json['manufacturer'] as String? ?? 'Standard',
      );

  static DeviceInfo defaultMock({DeviceType type = DeviceType.android}) => DeviceInfo(
        deviceId: 'DEV-MOCK-${type == DeviceType.android ? "ANDROID" : "IOS"}-001',
        deviceType: type,
        platform: type == DeviceType.android ? 'Android' : 'iOS',
        operatingSystem: type == DeviceType.android ? 'Android OS' : 'iOS',
        osVersion: type == DeviceType.android ? '14.0' : '17.4',
        appVersion: '1.0.0+1',
        deviceModel: type == DeviceType.android ? 'Pixel 8 Pro / Galaxy S24' : 'iPhone 15 Pro',
        manufacturer: type == DeviceType.android ? 'Google / Samsung' : 'Apple',
      );
}

/// Interface for obtaining platform device information
abstract class DeviceInfoService {
  Future<DeviceInfo> getDeviceInfo();
  DeviceType get currentDeviceType;
}

/// Concrete implementation of DeviceInfoService using platform properties
class PlatformDeviceInfoService implements DeviceInfoService {
  final DeviceInfo? overrideInfo;

  PlatformDeviceInfoService({this.overrideInfo});

  @override
  DeviceType get currentDeviceType {
    if (overrideInfo != null) return overrideInfo!.deviceType;
    if (kIsWeb) return DeviceType.web;
    try {
      if (Platform.isAndroid) return DeviceType.android;
      if (Platform.isIOS) return DeviceType.ios;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return DeviceType.desktop;
      }
    } catch (_) {}
    return DeviceType.other;
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    if (overrideInfo != null) return overrideInfo!;

    final type = currentDeviceType;
    String osName = 'Unknown';
    String osVersion = '1.0.0';

    if (!kIsWeb) {
      try {
        osName = Platform.operatingSystem;
        osVersion = Platform.operatingSystemVersion;
      } catch (_) {}
    } else {
      osName = 'Web Browser';
      osVersion = 'Web Standard';
    }

    return DeviceInfo(
      deviceId: 'DEVICE-${type.name.toUpperCase()}-CW-01',
      deviceType: type,
      platform: osName,
      operatingSystem: osName,
      osVersion: osVersion,
      appVersion: '1.0.0+1',
      deviceModel: type == DeviceType.android
          ? 'Android Client Device'
          : (type == DeviceType.ios ? 'Apple iOS Client Device' : 'Web/Desktop Client'),
      manufacturer: type == DeviceType.ios ? 'Apple' : 'Android Manufacturer',
    );
  }
}
