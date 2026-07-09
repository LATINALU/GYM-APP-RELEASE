import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen> {
  int _activeSection = 0;
  bool _isSaving = false;
  bool _hasChanges = false;

  // ─── Identity State ───
  final _legalNameCtrl = TextEditingController();
  final _mainAddressCtrl = TextEditingController();
  Color _brandColor = GymColors.primary;
  String? _logoUrl;

  // ─── Access State ───
  String _accessMethod = 'QR Dinámico';
  final _turnstileIpCtrl = TextEditingController();
  bool _allowDebtAccess = true;
  final _maxCapacityCtrl = TextEditingController(text: '150');

  // ─── Billing State ───
  String _currency = 'MXN';
  final _taxRateCtrl = TextEditingController(text: '16');
  String _graceDays = '3 días';
  bool _cashEnabled = true;
  bool _stripeEnabled = false;
  bool _mercadoPagoEnabled = false;
  bool _paypalEnabled = false;
  final _monthlyPriceCtrl = TextEditingController();
  final _annualDiscountCtrl = TextEditingController();
  final _promoDiscountCtrl = TextEditingController();
  final _promoDescCtrl = TextEditingController();

  // ─── Notifications State ───
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _whatsappEnabled = false;
  bool _welcomeNotif = true;
  bool _paymentReminder = true;
  bool _abandonmentAlert = true;
  bool _birthdayNotif = false;

  // ─── Legal State ───
  bool _termsUploaded = true;
  bool _privacyUploaded = true;
  bool _contractUploaded = false;
  bool _waiverUploaded = true;

  // ─── Security & Codes State ───
  String _codeExpiry = '30 minutos';
  String _codeLength = '8 caracteres';
  bool _require2FA = false;
  bool _ownerCodeVerification = true;
  bool _memberOnboardingCodes = true;
  bool _employeeInvitationCodes = true;
  final _maxFailedLoginsCtrl = TextEditingController(text: '5');
  final _lockoutMinutesCtrl = TextEditingController(text: '15');
  String _sessionTimeout = '30 días';
  bool _forcePasswordReset = false;
  bool _auditLogEnabled = true;

  // ─── Schedules & Operations State ───
  final _openTimeCtrl = TextEditingController(text: '05:00');
  final _closeTimeCtrl = TextEditingController(text: '23:00');
  bool _openSundays = true;
  bool _openHolidays = false;
  final _autoCheckoutMinutesCtrl = TextEditingController(text: '180');
  bool _zoneCapacityEnabled = true;
  bool _classSchedulingEnabled = true;
  bool _maintenanceMode = false;

  // ─── Integrations State ───
  bool _webhooksEnabled = false;
  final _webhookUrlCtrl = TextEditingController();
  bool _apiAccessEnabled = false;
  bool _googleCalendarSync = false;
  bool _whatsappBusinessAPI = false;
  bool _zapierEnabled = false;
  bool _analyticsEnabled = true;

  // ─── Data & Backups State ───
  String _backupFrequency = 'Diario';
  bool _autoExportEnabled = false;
  String _retentionPeriod = '12 meses';
  bool _gdprMode = true;
  bool _anonymizeInactive = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _legalNameCtrl.dispose();
    _mainAddressCtrl.dispose();
    _turnstileIpCtrl.dispose();
    _maxCapacityCtrl.dispose();
    _taxRateCtrl.dispose();
    _maxFailedLoginsCtrl.dispose();
    _lockoutMinutesCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    _autoCheckoutMinutesCtrl.dispose();
    _webhookUrlCtrl.dispose();
    _monthlyPriceCtrl.dispose();
    _annualDiscountCtrl.dispose();
    _promoDiscountCtrl.dispose();
    _promoDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      if (gymId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('settings')
          .doc('global')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          // Identity
          _legalNameCtrl.text = data['legalName']?.toString() ?? '';
          _mainAddressCtrl.text = data['mainAddress']?.toString() ?? '';
          if (data['brandColor'] != null) {
            _brandColor = Color(data['brandColor']);
          }
          
          // Access
          _accessMethod = data['accessMethod'] ?? _accessMethod;
          _turnstileIpCtrl.text = data['turnstileIp']?.toString() ?? '';
          _allowDebtAccess = data['allowDebtAccess'] ?? _allowDebtAccess;
          _maxCapacityCtrl.text = (data['maxCapacity'] ?? 150).toString();

          // Billing
          _currency = data['currency'] ?? _currency;
          _taxRateCtrl.text = (data['taxRate'] ?? 16).toString();
          _graceDays = data['graceDays'] ?? _graceDays;
          _stripeEnabled = data['stripeEnabled'] ?? _stripeEnabled;
          _mercadoPagoEnabled = data['mercadoPagoEnabled'] ?? _mercadoPagoEnabled;
          _paypalEnabled = data['paypalEnabled'] ?? _paypalEnabled;
          _cashEnabled = data['cashEnabled'] ?? _cashEnabled;
          _monthlyPriceCtrl.text = data['monthlyPrice']?.toString() ?? '';
          _annualDiscountCtrl.text = data['annualDiscount']?.toString() ?? '';
          _promoDiscountCtrl.text = data['promoDiscount']?.toString() ?? '';
          _promoDescCtrl.text = data['promoDesc']?.toString() ?? '';

          // Notifications
          _pushEnabled = data['pushEnabled'] ?? _pushEnabled;
          _emailEnabled = data['emailEnabled'] ?? _emailEnabled;
          _whatsappEnabled = data['whatsappEnabled'] ?? _whatsappEnabled;
          _welcomeNotif = data['welcomeNotif'] ?? _welcomeNotif;
          _paymentReminder = data['paymentReminder'] ?? _paymentReminder;
          _abandonmentAlert = data['abandonmentAlert'] ?? _abandonmentAlert;
          _birthdayNotif = data['birthdayNotif'] ?? _birthdayNotif;

          // Security & Codes
          _codeExpiry = data['codeExpiry'] ?? _codeExpiry;
          _codeLength = data['codeLength'] ?? _codeLength;
          _require2FA = data['require2FA'] ?? _require2FA;
          _ownerCodeVerification = data['ownerCodeVerification'] ?? _ownerCodeVerification;
          _memberOnboardingCodes = data['memberOnboardingCodes'] ?? _memberOnboardingCodes;
          _employeeInvitationCodes = data['employeeInvitationCodes'] ?? _employeeInvitationCodes;
          _maxFailedLoginsCtrl.text = (data['maxFailedLogins'] ?? 5).toString();
          _lockoutMinutesCtrl.text = (data['lockoutMinutes'] ?? 15).toString();
          _sessionTimeout = data['sessionTimeout'] ?? _sessionTimeout;
          _forcePasswordReset = data['forcePasswordReset'] ?? _forcePasswordReset;
          _auditLogEnabled = data['auditLogEnabled'] ?? _auditLogEnabled;

          // Schedules & Operations
          _openTimeCtrl.text = data['openTime'] ?? _openTimeCtrl.text;
          _closeTimeCtrl.text = data['closeTime'] ?? _closeTimeCtrl.text;
          _openSundays = data['openSundays'] ?? _openSundays;
          _openHolidays = data['openHolidays'] ?? _openHolidays;
          _autoCheckoutMinutesCtrl.text = (data['autoCheckoutMinutes'] ?? 180).toString();
          _zoneCapacityEnabled = data['zoneCapacityEnabled'] ?? _zoneCapacityEnabled;
          _classSchedulingEnabled = data['classSchedulingEnabled'] ?? _classSchedulingEnabled;
          _maintenanceMode = data['maintenanceMode'] ?? _maintenanceMode;

          // Integrations
          _webhooksEnabled = data['webhooksEnabled'] ?? _webhooksEnabled;
          _webhookUrlCtrl.text = data['webhookUrl'] ?? _webhookUrlCtrl.text;
          _apiAccessEnabled = data['apiAccessEnabled'] ?? _apiAccessEnabled;
          _googleCalendarSync = data['googleCalendarSync'] ?? _googleCalendarSync;
          _whatsappBusinessAPI = data['whatsappBusinessAPI'] ?? _whatsappBusinessAPI;
          _zapierEnabled = data['zapierEnabled'] ?? _zapierEnabled;
          _analyticsEnabled = data['analyticsEnabled'] ?? _analyticsEnabled;

          // Data & Backups
          _backupFrequency = data['backupFrequency'] ?? _backupFrequency;
          _autoExportEnabled = data['autoExportEnabled'] ?? _autoExportEnabled;
          _retentionPeriod = data['retentionPeriod'] ?? _retentionPeriod;
          _gdprMode = data['gdprMode'] ?? _gdprMode;
          _anonymizeInactive = data['anonymizeInactive'] ?? _anonymizeInactive;
        });
      }
    } catch (_) {
      // Use defaults
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveSection(String sectionName, Map<String, dynamic> data) async {
    setState(() => _isSaving = true);
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value ?? 'default_gym';

      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('settings')
          .doc('global')
          .set(data, SetOptions(merge: true));

      // Audit log
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'gymId': gymId,
        'who': auth.profile?.displayName ?? 'Owner',
        'action': 'Actualizó configuración: $sectionName',
        'timestamp': FieldValue.serverTimestamp(),
        'module': 'CONFIGURACIÓN',
      });

      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $sectionName guardado exitosamente'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Sub-menú lateral de secciones
          Container(
            width: 250,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuración', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _sectionItem(0, 'Identidad', Icons.storefront_outlined),
                _sectionItem(1, 'Acceso CRÍTICO', Icons.security_outlined, isCritical: true),
                _sectionItem(2, 'Seguridad & Códigos', Icons.vpn_key_outlined, isCritical: true),
                _sectionItem(3, 'Facturación', Icons.receipt_long_outlined),
                _sectionItem(4, 'Notificaciones', Icons.notifications_none_outlined),
                _sectionItem(5, 'Horarios & Operaciones', Icons.schedule_outlined),
                _sectionItem(6, 'Integraciones', Icons.extension_outlined),
                _sectionItem(7, 'Datos & Backups', Icons.backup_outlined),
                _sectionItem(8, 'Legal', Icons.gavel_outlined),
                if (_hasChanges) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Cambios sin guardar', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Área de detalle
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _buildActiveSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionItem(int index, String label, IconData icon, {bool isCritical = false}) {
    bool isSelected = _activeSection == index;
    return InkWell(
      onTap: () => setState(() => _activeSection = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? GymColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? GymColors.primary : Colors.white24, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              )),
            ),
            if (isCritical) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeSection) {
      case 0: return _buildIdentitySection();
      case 1: return _buildAccessSection();
      case 2: return _buildSecuritySection();
      case 3: return _buildBillingSection();
      case 4: return _buildNotificationsSection();
      case 5: return _buildSchedulesSection();
      case 6: return _buildIntegrationsSection();
      case 7: return _buildDataSection();
      case 8: return _buildLegalSection();
      default: return const Center(child: Text('En construcción', style: TextStyle(color: Colors.white24)));
    }
  }

  // ─── SECCIÓN: IDENTIDAD ───
  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identidad del Negocio', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Personaliza la experiencia White Label de tu gimnasio.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),
        
        Row(
          children: [
            _buildImageUploadCard('Logo del Gym', 'Aparecerá en tickets y app.'),
            const SizedBox(width: 32),
            _buildColorPickerCard('Color de Marca', 'Personaliza el tema primario.'),
          ],
        ),
        
        const SizedBox(height: 48),
        _buildTextField('Nombre Legal', _legalNameCtrl),
        const SizedBox(height: 24),
        _buildTextField('Dirección Principal', _mainAddressCtrl),
        const SizedBox(height: 48),
        _buildSaveButton('Identidad', () {
          _saveSection('Identidad', {
            'legalName': _legalNameCtrl.text,
            'mainAddress': _mainAddressCtrl.text,
            'brandColor': _brandColor.toARGB32(),
            'logoUrl': _logoUrl,
          });
        }),
      ],
    );
  }

  // ─── SECCIÓN: ACCESO ───
  Widget _buildAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Control de Acceso', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('NIVEL CRÍTICO', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Configuración del hardware y reglas de entrada automática.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),
        
        _buildDropdownSetting('Método de Acceso', ['QR Dinámico', 'Reconocimiento Facial', 'RFID'], _accessMethod, (v) {
          setState(() { _accessMethod = v; _markChanged(); });
        }),
        const SizedBox(height: 24),
        _buildTextField('IP del Torno / Molinete', _turnstileIpCtrl),
        const SizedBox(height: 24),
        _buildToggleSetting('Reglas de Morosidad', '¿Permitir acceso si el usuario tiene deuda?', _allowDebtAccess, (v) {
          setState(() { _allowDebtAccess = v; _markChanged(); });
        }),
        const SizedBox(height: 24),
        _buildTextField('Aforo Máximo Legal', _maxCapacityCtrl),
        const SizedBox(height: 48),
        _buildSaveButton('Reglas de Acceso', () {
          _saveSection('Acceso CRÍTICO', {
            'accessMethod': _accessMethod,
            'turnstileIp': _turnstileIpCtrl.text,
            'allowDebtAccess': _allowDebtAccess,
            'maxCapacity': int.tryParse(_maxCapacityCtrl.text) ?? 150,
          });
        }),
      ],
    );
  }

  // ─── SECCIÓN: FACTURACIÓN ───
  Widget _buildBillingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Facturación y Pagos', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Configura tu moneda, impuestos y pasarelas de pago.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),
        
        Row(
          children: [
            Expanded(child: _buildDropdownSetting('Moneda Local', ['USD', 'MXN', 'EUR', 'COP'], _currency, (v) {
              setState(() { _currency = v; _markChanged(); });
            })),
            const SizedBox(width: 32),
            Expanded(child: _buildTextField('Tasa de Impuesto (IVA %)', _taxRateCtrl)),
          ],
        ),
        const SizedBox(height: 24),
        _buildDropdownSetting('Días de Gracia', ['0 días', '3 días', '5 días', '7 días'], _graceDays, (v) {
          setState(() { _graceDays = v; _markChanged(); });
        }),
        const SizedBox(height: 48),
        const Text('Precios de Membresía', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Precio Mensual (USD)', _monthlyPriceCtrl)),
            const SizedBox(width: 32),
            Expanded(child: _buildTextField('Descuento Anual (%)', _annualDiscountCtrl)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Promociones Especiales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Descuento Promo (%)', _promoDiscountCtrl)),
            const SizedBox(width: 32),
            Expanded(child: _buildTextField('Descripción Promo', _promoDescCtrl)),
          ],
        ),
        const SizedBox(height: 48),
        const Text('Pasarelas de Pago Activas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildCheckOption('Stripe (Global)', _stripeEnabled, (v) {
          setState(() { _stripeEnabled = v ?? false; _markChanged(); });
        }),
        _buildCheckOption('MercadoPago (LATAM)', _mercadoPagoEnabled, (v) {
          setState(() { _mercadoPagoEnabled = v ?? false; _markChanged(); });
        }),
        _buildCheckOption('PayPal', _paypalEnabled, (v) {
          setState(() { _paypalEnabled = v ?? false; _markChanged(); });
        }),
        _buildCheckOption('Efectivo (Caja)', _cashEnabled, (v) {
          setState(() { _cashEnabled = v ?? false; _markChanged(); });
        }),
        const SizedBox(height: 48),
        _buildSaveButton('Configuración Financiera', () {
          _saveSection('Facturación', {
            'currency': _currency,
            'taxRate': double.tryParse(_taxRateCtrl.text) ?? 16,
            'graceDays': _graceDays,
            'stripeEnabled': _stripeEnabled,
            'mercadoPagoEnabled': _mercadoPagoEnabled,
            'paypalEnabled': _paypalEnabled,
            'cashEnabled': _cashEnabled,
            'monthlyPrice': double.tryParse(_monthlyPriceCtrl.text) ?? 0,
            'annualDiscount': double.tryParse(_annualDiscountCtrl.text) ?? 0,
            'promoDiscount': double.tryParse(_promoDiscountCtrl.text) ?? 0,
            'promoDesc': _promoDescCtrl.text,
          });
        }),
      ],
    );
  }

  // ─── SECCIÓN: NOTIFICACIONES ───
  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notificaciones', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Configura los canales de comunicación automática con tus miembros.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),
        
        const Text('CANALES DE COMUNICACIÓN', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),
        _buildToggleSetting('Push Notifications', 'Enviar alertas push a la app móvil del miembro.', _pushEnabled, (v) {
          setState(() { _pushEnabled = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Correo Electrónico', 'Enviar resúmenes semanales y recordatorios por email.', _emailEnabled, (v) {
          setState(() { _emailEnabled = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('WhatsApp Business', 'Mensajes de recuperación y recordatorios de pago.', _whatsappEnabled, (v) {
          setState(() { _whatsappEnabled = v; _markChanged(); });
        }),
        
        const SizedBox(height: 48),
        const Text('EVENTOS AUTOMÁTICOS', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),
        _buildToggleSetting('Bienvenida', 'Mensaje automático cuando un miembro se registra.', _welcomeNotif, (v) {
          setState(() { _welcomeNotif = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Recordatorio de Pago', 'Avisar 3 días antes del vencimiento de suscripción.', _paymentReminder, (v) {
          setState(() { _paymentReminder = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Abandono Detectado', 'Alerta automática cuando un miembro lleva +7 días sin asistir.', _abandonmentAlert, (v) {
          setState(() { _abandonmentAlert = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Cumpleaños', 'Felicitación automática en el cumpleaños del miembro.', _birthdayNotif, (v) {
          setState(() { _birthdayNotif = v; _markChanged(); });
        }),
        
        const SizedBox(height: 48),
        _buildSaveButton('Preferencias de Notificación', () {
          _saveSection('Notificaciones', {
            'pushEnabled': _pushEnabled,
            'emailEnabled': _emailEnabled,
            'whatsappEnabled': _whatsappEnabled,
            'welcomeNotif': _welcomeNotif,
            'paymentReminder': _paymentReminder,
            'abandonmentAlert': _abandonmentAlert,
            'birthdayNotif': _birthdayNotif,
          });
        }),
      ],
    );
  }

  // ─── SECCIÓN: LEGAL ───
  Widget _buildLegalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Legal & Cumplimiento', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Documentos legales y regulatorios de tu gimnasio.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),
        
        _buildLegalDocCard(
          'Términos y Condiciones', 
          'Documento que acepta el miembro al registrarse.', 
          _termsUploaded,
          _termsUploaded ? 'Actualizado: 15 Nov 2025' : 'No configurado',
          onUpload: () => _handleDocUpload('Términos y Condiciones', () {
            setState(() => _termsUploaded = true);
          }),
        ),
        const SizedBox(height: 24),
        _buildLegalDocCard(
          'Política de Privacidad', 
          'Cumplimiento GDPR/LFPDPPP para datos personales.', 
          _privacyUploaded,
          _privacyUploaded ? 'Actualizado: 20 Dic 2025' : 'No configurado',
          onUpload: () => _handleDocUpload('Política de Privacidad', () {
            setState(() => _privacyUploaded = true);
          }),
        ),
        const SizedBox(height: 24),
        _buildLegalDocCard(
          'Contrato Digital de Membresía', 
          'Firma electrónica obligatoria al activar plan.', 
          _contractUploaded,
          _contractUploaded ? 'Configurado' : 'No configurado',
          onUpload: () => _handleDocUpload('Contrato Digital', () {
            setState(() => _contractUploaded = true);
          }),
        ),
        const SizedBox(height: 24),
        _buildLegalDocCard(
          'Deslinde de Responsabilidad', 
          'Documento legal por uso de instalaciones y equipo.', 
          _waiverUploaded,
          _waiverUploaded ? 'Actualizado: 01 Ene 2026' : 'No configurado',
          onUpload: () => _handleDocUpload('Deslinde de Responsabilidad', () {
            setState(() => _waiverUploaded = true);
          }),
        ),
        
        const SizedBox(height: 48),
        _buildSaveButton('Cambios Legales', () {
          _saveSection('Legal', {
            'termsUploaded': _termsUploaded,
            'privacyUploaded': _privacyUploaded,
            'contractUploaded': _contractUploaded,
            'waiverUploaded': _waiverUploaded,
          });
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECCIÓN: SEGURIDAD & CÓDIGOS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Seguridad & Códigos de Acceso', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('NIVEL CRÍTICO', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Configuración de códigos CSPRNG, autenticación y políticas de seguridad.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [GymColors.primary.withValues(alpha: 0.05), Colors.transparent]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GymColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_rounded, color: GymColors.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Los códigos se generan usando CSPRNG (Cryptographically Secure Pseudo-Random Number Generator) para máxima seguridad. Cada código incluye un prefijo de tipo para fácil identificación.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        const Text('GENERACIÓN DE CÓDIGOS', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: _buildDropdownSetting('Expiración por Defecto', ['15 minutos', '30 minutos', '1 hora', '2 horas', '24 horas', '7 días'], _codeExpiry, (v) {
              setState(() { _codeExpiry = v; _markChanged(); });
            })),
            const SizedBox(width: 32),
            Expanded(child: _buildDropdownSetting('Longitud de Código', ['6 caracteres', '8 caracteres', '10 caracteres', '12 caracteres'], _codeLength, (v) {
              setState(() { _codeLength = v; _markChanged(); });
            })),
          ],
        ),

        const SizedBox(height: 24),
        _buildToggleSetting('Códigos de Verificación Owner', 'Generar códigos de verificación para operaciones del dueño.', _ownerCodeVerification, (v) {
          setState(() { _ownerCodeVerification = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Códigos de Onboarding Miembros', 'Permitir que nuevos miembros se unan usando códigos de invitación.', _memberOnboardingCodes, (v) {
          setState(() { _memberOnboardingCodes = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Códigos de Invitación Empleados', 'Invitar staff mediante códigos seguros en vez de email directo.', _employeeInvitationCodes, (v) {
          setState(() { _employeeInvitationCodes = v; _markChanged(); });
        }),

        const SizedBox(height: 48),
        const Text('AUTENTICACIÓN', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        _buildToggleSetting('Autenticación de 2 Factores (2FA)', 'Requerir 2FA para todos los usuarios con rol de Staff o superior.', _require2FA, (v) {
          setState(() { _require2FA = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Forzar Reseteo de Contraseña', 'Requerir cambio de contraseña cada 90 días para staff.', _forcePasswordReset, (v) {
          setState(() { _forcePasswordReset = v; _markChanged(); });
        }),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildTextField('Intentos Fallidos Máximos', _maxFailedLoginsCtrl)),
            const SizedBox(width: 32),
            Expanded(child: _buildTextField('Minutos de Bloqueo', _lockoutMinutesCtrl)),
          ],
        ),
        const SizedBox(height: 24),
        _buildDropdownSetting('Tiempo de Sesión', ['1 hora', '8 horas', '24 horas', '7 días', '30 días'], _sessionTimeout, (v) {
          setState(() { _sessionTimeout = v; _markChanged(); });
        }),

        const SizedBox(height: 48),
        const Text('AUDITORÍA', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        _buildToggleSetting('Registro de Auditoría Inmutable', 'Todas las acciones de seguridad se registran y no pueden ser eliminadas.', _auditLogEnabled, (v) {
          setState(() { _auditLogEnabled = v; _markChanged(); });
        }),

        const SizedBox(height: 48),
        _buildSaveButton('Políticas de Seguridad', () {
          _saveSection('Seguridad & Códigos', {
            'codeExpiry': _codeExpiry,
            'codeLength': _codeLength,
            'require2FA': _require2FA,
            'ownerCodeVerification': _ownerCodeVerification,
            'memberOnboardingCodes': _memberOnboardingCodes,
            'employeeInvitationCodes': _employeeInvitationCodes,
            'maxFailedLogins': int.tryParse(_maxFailedLoginsCtrl.text) ?? 5,
            'lockoutMinutes': int.tryParse(_lockoutMinutesCtrl.text) ?? 15,
            'sessionTimeout': _sessionTimeout,
            'forcePasswordReset': _forcePasswordReset,
            'auditLogEnabled': _auditLogEnabled,
          });
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECCIÓN: HORARIOS & OPERACIONES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSchedulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horarios & Operaciones', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Define los horarios de apertura, zonas y reglas operativas del gimnasio.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),

        const Text('HORARIO DE OPERACIÓN', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: _buildTextField('Hora de Apertura', _openTimeCtrl)),
            const SizedBox(width: 32),
            Expanded(child: _buildTextField('Hora de Cierre', _closeTimeCtrl)),
          ],
        ),

        const SizedBox(height: 24),
        _buildToggleSetting('Abrir Domingos', 'Permitir acceso los días domingo.', _openSundays, (v) {
          setState(() { _openSundays = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Abrir en Días Festivos', 'Mantener el gimnasio abierto en días festivos (con horario reducido).', _openHolidays, (v) {
          setState(() { _openHolidays = v; _markChanged(); });
        }),

        const SizedBox(height: 48),
        const Text('REGLAS OPERATIVAS', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        _buildTextField('Auto-Checkout (minutos)', _autoCheckoutMinutesCtrl),
        const SizedBox(height: 8),
        const Text('Tiempo máximo de permanencia antes de marcar salida automática.', style: TextStyle(color: Colors.white24, fontSize: 11)),

        const SizedBox(height: 24),
        _buildToggleSetting('Control de Capacidad por Zonas', 'Activar monitoreo independiente de aforo por zona (pesas, cardio, clases).', _zoneCapacityEnabled, (v) {
          setState(() { _zoneCapacityEnabled = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Agenda de Clases Grupales', 'Habilitar reserva y gestión de clases grupales en horario.', _classSchedulingEnabled, (v) {
          setState(() { _classSchedulingEnabled = v; _markChanged(); });
        }),

        const SizedBox(height: 48),
        const Text('MANTENIMIENTO', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _maintenanceMode ? Colors.orange.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _maintenanceMode ? Colors.orange.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(
                _maintenanceMode ? Icons.engineering_rounded : Icons.check_circle_outline_rounded,
                color: _maintenanceMode ? Colors.orange : const Color(0xFF10B981),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _maintenanceMode ? 'MODO MANTENIMIENTO ACTIVO' : 'Sistema Operativo Normal',
                      style: TextStyle(color: _maintenanceMode ? Colors.orange : Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maintenanceMode
                          ? 'Los miembros verán un aviso de mantenimiento al intentar hacer check-in.'
                          : 'Todos los servicios están funcionando con normalidad.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _maintenanceMode,
                onChanged: (v) => setState(() { _maintenanceMode = v; _markChanged(); }),
                activeThumbColor: Colors.orange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        _buildSaveButton('Operaciones', () {
          _saveSection('Horarios & Operaciones', {
            'openTime': _openTimeCtrl.text,
            'closeTime': _closeTimeCtrl.text,
            'openSundays': _openSundays,
            'openHolidays': _openHolidays,
            'autoCheckoutMinutes': int.tryParse(_autoCheckoutMinutesCtrl.text) ?? 180,
            'zoneCapacityEnabled': _zoneCapacityEnabled,
            'classSchedulingEnabled': _classSchedulingEnabled,
            'maintenanceMode': _maintenanceMode,
          });
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECCIÓN: INTEGRACIONES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIntegrationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Integraciones', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Conecta servicios externos, APIs y webhooks para automatización.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),

        const Text('API & WEBHOOKS', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        _buildToggleSetting('Acceso a API REST', 'Habilitar endpoints REST para integraciones de terceros.', _apiAccessEnabled, (v) {
          setState(() { _apiAccessEnabled = v; _markChanged(); });
        }),

        if (_apiAccessEnabled) ...[
          const SizedBox(height: 16),
          _buildReadOnlyField('API Key', '••••••••-••••-••••-••••-••••••••••••', Icons.content_copy),
          const SizedBox(height: 8),
          Row(
            children: [
              GymButton(
                text: 'Regenerar API Key',
                style: GymButtonStyle.ghost,
                size: GymButtonSize.small,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⚠ Regenerar la API Key invalidará todas las integraciones existentes'),
                      backgroundColor: Colors.orangeAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        _buildToggleSetting('Webhooks', 'Enviar eventos (check-in, pago, registro) a una URL externa.', _webhooksEnabled, (v) {
          setState(() { _webhooksEnabled = v; _markChanged(); });
        }),

        if (_webhooksEnabled) ...[
          const SizedBox(height: 16),
          _buildTextField('Webhook URL', _webhookUrlCtrl),
          const SizedBox(height: 8),
          const Text('Eventos: member.created, payment.received, checkin.completed, membership.expired', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],

        const SizedBox(height: 48),
        const Text('SERVICIOS EXTERNOS', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        _buildIntegrationCard('Google Calendar', 'Sincronizar clases grupales y reservas.', Icons.calendar_month_rounded, const Color(0xFF4285F4), _googleCalendarSync, (v) {
          setState(() { _googleCalendarSync = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildIntegrationCard('WhatsApp Business API', 'Mensajes automáticos de bienvenida y recordatorios.', Icons.message_rounded, const Color(0xFF25D366), _whatsappBusinessAPI, (v) {
          setState(() { _whatsappBusinessAPI = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildIntegrationCard('Zapier', 'Conectar con +5,000 apps automáticamente.', Icons.electrical_services_rounded, const Color(0xFFFF4A00), _zapierEnabled, (v) {
          setState(() { _zapierEnabled = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildIntegrationCard('Google Analytics', 'Rastrear uso de la app y conversiones.', Icons.analytics_rounded, const Color(0xFFE37400), _analyticsEnabled, (v) {
          setState(() { _analyticsEnabled = v; _markChanged(); });
        }),

        const SizedBox(height: 48),
        _buildSaveButton('Integraciones', () {
          _saveSection('Integraciones', {
            'apiAccessEnabled': _apiAccessEnabled,
            'webhooksEnabled': _webhooksEnabled,
            'webhookUrl': _webhookUrlCtrl.text,
            'googleCalendarSync': _googleCalendarSync,
            'whatsappBusinessAPI': _whatsappBusinessAPI,
            'zapierEnabled': _zapierEnabled,
            'analyticsEnabled': _analyticsEnabled,
          });
        }),
      ],
    );
  }

  Widget _buildIntegrationCard(String title, String desc, IconData icon, Color color, bool enabled, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: enabled ? color.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Switch(value: enabled, onChanged: onChanged, activeThumbColor: color),
              Text(enabled ? 'ACTIVO' : 'INACTIVO', style: TextStyle(color: enabled ? color : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData trailingIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value, style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 13))),
              Icon(trailingIcon, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECCIÓN: DATOS & BACKUPS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Datos & Backups', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Respaldos automáticos, exportación de datos y cumplimiento GDPR/LFPDPPP.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),

        const Text('RESPALDOS AUTOMÁTICOS', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        _buildDropdownSetting('Frecuencia de Backup', ['Cada 6 horas', 'Diario', 'Semanal', 'Quincenal'], _backupFrequency, (v) {
          setState(() { _backupFrequency = v; _markChanged(); });
        }),

        const SizedBox(height: 24),
        _buildToggleSetting('Exportación Automática', 'Enviar un backup cifrado al email del owner periódicamente.', _autoExportEnabled, (v) {
          setState(() { _autoExportEnabled = v; _markChanged(); });
        }),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Último Backup Exitoso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Hoy a las 03:00 AM — Tamaño: 42.3 MB', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  ],
                ),
              ),
              GymButton(
                text: 'Backup Ahora',
                style: GymButtonStyle.ghost,
                size: GymButtonSize.small,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('☁ Iniciando backup manual...'),
                      backgroundColor: GymColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        const Text('EXPORTACIÓN DE DATOS', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        Row(
          children: [
            _buildExportButton('Miembros', Icons.people_outline_rounded, 'CSV'),
            const SizedBox(width: 16),
            _buildExportButton('Pagos', Icons.payments_outlined, 'CSV'),
            const SizedBox(width: 16),
            _buildExportButton('Asistencia', Icons.fact_check_outlined, 'CSV'),
            const SizedBox(width: 16),
            _buildExportButton('Reporte', Icons.summarize_outlined, 'PDF'),
          ],
        ),

        const SizedBox(height: 48),
        const Text('RETENCIÓN & PRIVACIDAD', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 24),

        _buildDropdownSetting('Período de Retención', ['6 meses', '12 meses', '24 meses', '36 meses', 'Indefinido'], _retentionPeriod, (v) {
          setState(() { _retentionPeriod = v; _markChanged(); });
        }),
        const SizedBox(height: 8),
        const Text('Tiempo que se conservan datos de miembros inactivos antes de eliminarlos.', style: TextStyle(color: Colors.white24, fontSize: 11)),

        const SizedBox(height: 24),
        _buildToggleSetting('Cumplimiento GDPR / LFPDPPP', 'Mostrar aviso de privacidad y consentimiento obligatorio al registrarse.', _gdprMode, (v) {
          setState(() { _gdprMode = v; _markChanged(); });
        }),
        const SizedBox(height: 16),
        _buildToggleSetting('Anonimizar Miembros Inactivos', 'Eliminar datos personales de miembros que superen el período de retención.', _anonymizeInactive, (v) {
          setState(() { _anonymizeInactive = v; _markChanged(); });
        }),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Zona de Peligro', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Acciones irreversibles sobre los datos del gimnasio.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  ],
                ),
              ),
              GymButton(
                text: 'Eliminar Datos',
                style: GymButtonStyle.ghost,
                size: GymButtonSize.small,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('⚠ Confirmar Eliminación Total', style: TextStyle(color: Colors.redAccent)),
                      content: const Text(
                        'Esta acción eliminará TODOS los datos del gimnasio de forma permanente. Esta acción NO se puede deshacer.\n\n¿Estás absolutamente seguro?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Operación bloqueada: requiere confirmación por email del owner'),
                                backgroundColor: Colors.orangeAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Entiendo, Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        _buildSaveButton('Políticas de Datos', () {
          _saveSection('Datos & Backups', {
            'backupFrequency': _backupFrequency,
            'autoExportEnabled': _autoExportEnabled,
            'retentionPeriod': _retentionPeriod,
            'gdprMode': _gdprMode,
            'anonymizeInactive': _anonymizeInactive,
          });
        }),
      ],
    );
  }

  Widget _buildExportButton(String label, IconData icon, String format) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⬇ Generando exportación de $label ($format)...'),
              backgroundColor: GymColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: GymColors.primary, size: 28),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GymColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(format, style: const TextStyle(color: GymColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDocUpload(String docName, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Subir: $docName', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded, color: GymColors.primary, size: 36),
                  SizedBox(height: 8),
                  Text('Arrastra tu archivo PDF aquí', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text('o haz clic para seleccionar', style: TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Formatos aceptados: PDF, DOCX\nTamaño máximo: 10MB',
              style: TextStyle(color: Colors.white24, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSuccess();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ $docName actualizado'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GymColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Subir Archivo'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDocCard(String title, String desc, bool isUploaded, String status, {required VoidCallback onUpload}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isUploaded ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUploaded ? Icons.description_outlined : Icons.upload_file_outlined,
              color: isUploaded ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                Text(status, style: TextStyle(color: isUploaded ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GymButton(
            text: isUploaded ? 'Reemplazar' : 'Subir Documento',
            style: GymButtonStyle.ghost,
            size: GymButtonSize.small,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSaveButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: _isSaving
          ? const Center(child: CircularProgressIndicator(color: GymColors.primary))
          : GymButton(
              text: 'Guardar $label',
              fullWidth: true,
              onPressed: onPressed,
            ),
    );
  }

  Widget _buildImageUploadCard(String title, String subtitle) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _logoUrl = 'uploaded';
            _markChanged();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('La selección de logo aún no está disponible en esta pantalla'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _logoUrl != null ? GymColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _logoUrl != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined, 
                color: _logoUrl != null ? const Color(0xFF10B981) : GymColors.primary, 
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                _logoUrl != null ? 'Logo cargado ✓' : subtitle, 
                style: TextStyle(color: _logoUrl != null ? const Color(0xFF10B981) : Colors.white24, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPickerCard(String title, String subtitle) {
    return Expanded(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                )),
                Container(width: 40, height: 40, decoration: BoxDecoration(color: _brandColor, borderRadius: BorderRadius.circular(8))),
              ],
            ),
            const SizedBox(height: 16),
            // Color presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GymColors.primary,
                const Color(0xFF10B981),
                const Color(0xFFEF4444),
                const Color(0xFFF59E0B),
                const Color(0xFF8B5CF6),
                const Color(0xFF06B6D4),
                const Color(0xFFEC4899),
                const Color(0xFFFF6B35),
              ].map((c) => InkWell(
                onTap: () => setState(() { _brandColor = c; _markChanged(); }),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _brandColor == c ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          onChanged: (_) => _markChanged(),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(String label, List<String> options, String currentValue, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              dropdownColor: const Color(0xFF16162A),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(String label, String desc, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(desc, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: GymColors.primary,
        ),
      ],
    );
  }

  Widget _buildCheckOption(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged, activeColor: GymColors.primary),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
