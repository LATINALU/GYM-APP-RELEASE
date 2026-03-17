import 'package:cloud_firestore/cloud_firestore.dart';

enum ChurnRisk { low, medium, high }

class ChurnAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// FUNCIÓN 1: Algoritmo de Predicción de Abandono (Predictive Logic)
  Future<Map<String, dynamic>> calculateChurnRisk(String userId) async {
    final now = DateTime.now();
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    
    final lastVisit = (userData['lastCheckIn'] as Timestamp?)?.toDate();
    if (lastVisit == null) return {'level': 'CRITICAL', 'score': 1.0};

    final daysSinceLastVisit = now.difference(lastVisit).inDays;
    
    // Simulación de tendencia (Promedio mensual vs asistencias este mes)
    final avgVisitsLastMonth = userData['avgVisitsLastMonth'] ?? 12.0;
    final visitsThisMonth = userData['visitsThisMonth'] ?? 4.0;
    final attendanceTrend = avgVisitsLastMonth - visitsThisMonth;

    String riskLevel = 'LOW';
    if (daysSinceLastVisit > 15) {
      riskLevel = 'CRITICAL'; // ROJO
    } else if (daysSinceLastVisit > 7 || attendanceTrend > 5) {
      riskLevel = 'HIGH'; // AMARILLO
    }

    // Actualizar base de datos para mostrar en Dashboard
    await _firestore.collection('users').doc(userId).update({'churn_risk': riskLevel});
    
    return {'level': riskLevel, 'daysAbsent': daysSinceLastVisit};
  }

  /// FUNCIÓN 2: Generador de Mensaje de Recuperación
  String generateRecoveryMessage(String riskLevel, String userName) {
    if (riskLevel == 'CRITICAL') {
      return 'Hola $userName, te extrañamos en GymOS. Vuelve hoy y tu batido post-entreno es gratis. 🥤💪';
    }
    if (riskLevel == 'HIGH') {
      return 'Hola $userName, ¡a darle duro esta semana! Te esperamos en el gimnasio para seguir con tus metas. 🔥';
    }
    return 'Hola $userName, ¡gran trabajo! Sigue así con tu entrenamiento.';
  }

  /// Obtiene una lista de usuarios con alto riesgo de abandono
  Future<List<Map<String, dynamic>>> getHighRiskUsers() async {
    final usersSnap = await _firestore.collection('users')
        .where('churn_risk', whereIn: ['CRITICAL', 'HIGH'])
        .limit(20)
        .get();
    
    return usersSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'userId': doc.id,
        'name': data['name'] ?? 'Usuario',
        'phone': data['phone'] ?? '',
        'riskLevel': data['churn_risk'] ?? 'HIGH',
        'lastCheckIn': (data['lastCheckIn'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }
}
