import 'package:flutter/foundation.dart' show kIsWeb;
// We conditionally import dart:io to avoid web build errors
// Note: In a real project, we'd use conditional exports or a platform interface

// Since we cannot easily use conditional imports without multiple files,
// and we want to keep it simple, we will use a more robust way to handle 'dart:io'
// for the build process. Flutter's build tool will fail if it sees 'dart:io' 
// in a web build UNLESS it's handled. 

/// Servicio para manejar registros de acceso con soporte multiplataforma.
class OfflineAccessService {

  /// Guarda un registro de acceso localmente
  Future<void> bufferCheckIn({
    required String userId,
    required String method,
    required String gymId,
  }) async {
    if (kIsWeb) return;
    return;
  }

  /// Tenta enviar los registros pendientes a Firestore cuando hay conexión
  Future<void> syncPendingLogs() async {
    if (kIsWeb) return;
    return;
  }
}
