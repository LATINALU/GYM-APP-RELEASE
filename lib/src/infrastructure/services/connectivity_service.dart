import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that monitors network connectivity status.
/// Provides a stream of online/offline state changes.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  late final StreamController<bool> _controller;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> init() async {
    _controller = StreamController<bool>.broadcast();
    final result = await _connectivity.checkConnectivity();
    _isOnline = result.any((c) => c != ConnectivityResult.none);
    _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((c) => c != ConnectivityResult.none);
      if (wasOnline != _isOnline) {
        _controller.add(_isOnline);
      }
    });
  }

  void dispose() {
    _controller.close();
  }
}
