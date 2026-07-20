/// Lógica pura de renovación de membresías (sin Firestore, testeable).
///
/// El vencimiento de los miembros se guarda como string `dd/MM/yyyy` en
/// `gyms/{id}/members.expiry` — este helper centraliza parseo, formato y
/// el cálculo del nuevo vencimiento al registrar un cobro.
class MembershipRenewal {
  MembershipRenewal._();

  /// Parsea `dd/MM/yyyy`; null si el formato no es válido (p. ej. '--').
  static DateTime? parseExpiry(String? raw) {
    if (raw == null) return null;
    final parts = raw.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final parsed = DateTime(year, month, day);
    // Rechazar fechas inválidas tipo 31/02 (DateTime las normaliza a marzo)
    if (parsed.day != day || parsed.month != month) return null;
    return parsed;
  }

  static String formatExpiry(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Nuevo vencimiento al cobrar [days] días de membresía.
  ///
  /// Si el miembro todavía está vigente, los días se SUMAN a su vencimiento
  /// actual (no pierde lo ya pagado); si está vencido o sin fecha válida,
  /// se cuenta desde hoy.
  static DateTime computeNewExpiry({
    String? currentExpiry,
    required int days,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final current = parseExpiry(currentExpiry);
    final base = (current != null && current.isAfter(today)) ? current : today;
    return base.add(Duration(days: days));
  }
}
