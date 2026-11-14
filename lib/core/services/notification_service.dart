import 'package:flutter/services.dart';

class NotificationService {
  static const _channel = MethodChannel('com.getnomor.wa_contact_collector/native');

  Future<bool> isAccessGranted() async {
    return await _channel.invokeMethod<bool>('isNotificationAccessGranted') ?? false;
  }

  Future<bool> isMonitoringEnabled() async {
    return await _channel.invokeMethod<bool>('isMonitoringEnabled') ?? false;
  }

  Future<void> setMonitoringEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setMonitoringEnabled', enabled);
  }

  Future<void> openAccessSettings() async {
    await _channel.invokeMethod<void>('openNotificationAccessSettings');
  }
}
