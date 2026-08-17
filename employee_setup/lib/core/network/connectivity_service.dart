import 'dart:async';

abstract class ConnectivityService {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
  void dispose();
}
