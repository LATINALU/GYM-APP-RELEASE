/// Datos mock de la app demo. Todo es local: sin Firebase ni internet.
library;

class DemoUser {
  final String email;
  final String password;
  final String name;
  final String role; // 'owner' | 'staff' | 'client'
  final String roleLabel;

  const DemoUser({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.roleLabel,
  });
}

const demoUsers = <DemoUser>[
  DemoUser(
    email: 'dueno@demo.com',
    password: 'demo123',
    name: 'Ezequiel Alonso',
    role: 'owner',
    roleLabel: 'Dueño',
  ),
  DemoUser(
    email: 'empleado@demo.com',
    password: 'demo123',
    name: 'Carla Méndez',
    role: 'staff',
    roleLabel: 'Empleado',
  ),
  DemoUser(
    email: 'cliente@demo.com',
    password: 'demo123',
    name: 'Martín Ríos',
    role: 'client',
    roleLabel: 'Cliente',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// OWNER — KPIs y socios
// ═══════════════════════════════════════════════════════════════════════════

const ownerKpis = {
  'activeMembers': 128,
  'expiredMembers': 14,
  'monthlyIncome': 458900.0,
  'checkInsToday': 67,
  'newThisMonth': 11,
  'posToday': 12450.0,
};

/// Ingresos de los últimos 6 meses (para el gráfico de barras)
const monthlyIncomeHistory = <MapEntry<String, double>>[
  MapEntry('Feb', 391000),
  MapEntry('Mar', 402500),
  MapEntry('Abr', 415800),
  MapEntry('May', 430200),
  MapEntry('Jun', 447600),
  MapEntry('Jul', 458900),
];

const atRiskMembers = <Map<String, dynamic>>[
  {'name': 'Lucía Fernández', 'daysAbsent': 12, 'risk': 'CRÍTICO'},
  {'name': 'Jorge Paredes', 'daysAbsent': 9, 'risk': 'ALTO'},
  {'name': 'Ana Beltrán', 'daysAbsent': 8, 'risk': 'ALTO'},
  {'name': 'Diego Sosa', 'daysAbsent': 6, 'risk': 'MEDIO'},
];

// ═══════════════════════════════════════════════════════════════════════════
// STAFF — check-ins y miembros
// ═══════════════════════════════════════════════════════════════════════════

const todayCheckIns = <Map<String, String>>[
  {'name': 'Martín Ríos', 'time': '07:12', 'plan': 'Mensual'},
  {'name': 'Sofía Vega', 'time': '07:45', 'plan': 'Anual'},
  {'name': 'Pablo Duarte', 'time': '08:03', 'plan': 'Mensual'},
  {'name': 'Valentina Cruz', 'time': '08:30', 'plan': 'Trimestral'},
  {'name': 'Nicolás Herrera', 'time': '09:15', 'plan': 'Mensual'},
];

const gymMembers = <Map<String, String>>[
  {'name': 'Martín Ríos', 'status': 'Activo', 'until': '15/08/2026'},
  {'name': 'Sofía Vega', 'status': 'Activo', 'until': '02/01/2027'},
  {'name': 'Lucía Fernández', 'status': 'Vencido', 'until': '30/06/2026'},
  {'name': 'Pablo Duarte', 'status': 'Activo', 'until': '20/07/2026'},
  {'name': 'Jorge Paredes', 'status': 'Activo', 'until': '11/09/2026'},
  {'name': 'Valentina Cruz', 'status': 'Activo', 'until': '05/10/2026'},
];

// ═══════════════════════════════════════════════════════════════════════════
// CLIENT — plan, rutina y gamificación
// ═══════════════════════════════════════════════════════════════════════════

const clientStats = {
  'streakDays': 5,
  'workoutsThisWeek': 4,
  'caloriesToday': 580,
  'volumeTons': 12.8,
};

const assignedRoutine = {
  'name': 'Push Day — Pecho y Hombros',
  'difficulty': 'Intermedio',
  'duration': 65,
  'exercises': [
    {'name': 'Press de Banca', 'sets': 4, 'reps': '8-10', 'muscle': 'Pecho'},
    {'name': 'Press Militar', 'sets': 3, 'reps': '10-12', 'muscle': 'Hombros'},
    {
      'name': 'Press Inclinado Mancuernas',
      'sets': 3,
      'reps': '10-12',
      'muscle': 'Pecho'
    },
    {
      'name': 'Elevaciones Laterales',
      'sets': 3,
      'reps': '12-15',
      'muscle': 'Hombros'
    },
    {'name': 'Fondos en Paralelas', 'sets': 3, 'reps': '8-12', 'muscle': 'Tríceps'},
    {
      'name': 'Extensión de Tríceps en Polea',
      'sets': 3,
      'reps': '12-15',
      'muscle': 'Tríceps'
    },
  ],
};

const achievements = <Map<String, dynamic>>[
  {'title': 'Primera Sesión', 'icon': '🏁', 'unlocked': true},
  {'title': 'Racha de 5 días', 'icon': '🔥', 'unlocked': true},
  {'title': '10 Entrenamientos', 'icon': '💪', 'unlocked': true},
  {'title': 'Madrugador', 'icon': '🌅', 'unlocked': false},
  {'title': '1 Tonelada Levantada', 'icon': '🏋️', 'unlocked': true},
  {'title': 'Racha de 30 días', 'icon': '⚡', 'unlocked': false},
];
