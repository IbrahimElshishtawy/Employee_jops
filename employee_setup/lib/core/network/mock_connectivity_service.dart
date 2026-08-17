import 'dart:async';
import 'connectivity_service.dart';

class MockConnectivityService implements ConnectivityService {
  bool _isConnected = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  MockConnectivityService({bool initialConnected = true}) : _isConnected = initialConnected;

  @override
  Future<bool> get isConnected async => _isConnected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _controller.add(_isConnected);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
