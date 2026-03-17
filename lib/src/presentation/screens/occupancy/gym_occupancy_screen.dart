/// Gym Occupancy Screen - Dashboard de ocupación en tiempo real
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../../domain/entities/gym_access.dart';

class GymOccupancyScreen extends StatefulWidget {
  const GymOccupancyScreen({super.key});

  @override
  State<GymOccupancyScreen> createState() => _GymOccupancyScreenState();
}

class _GymOccupancyScreenState extends State<GymOccupancyScreen> {
  late GymOccupancy _occupancy;
  late PeakHoursData _peakHours;

  @override
  void initState() {
    super.initState();
    _occupancy = GymOccupancy(
      timestamp: DateTime.now(),
      totalCurrentMembers: 0,
      maxCapacity: 1,
      zoneOccupancy: const {},
    );
    _peakHours = const PeakHoursData(hourlyOccupancy: {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Ocupación del Gym', style: QuantumTypography.h3.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: QuantumColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_2_outlined, color: Colors.white38, size: 48),
                SizedBox(height: 16),
                Text(
                  'Ocupación no disponible',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'La ocupación en tiempo real aún no está conectada a datos reales en esta pantalla.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainOccupancyCard() {
    final occupancyColor = Color(
        int.parse(_occupancy.occupancyColorHex.replaceFirst('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            occupancyColor.withValues(alpha: 0.2),
            QuantumColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: occupancyColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AHORA MISMO',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _occupancy.occupancyStatus,
                    style: TextStyle(
                      color: occupancyColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: occupancyColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getOccupancyIcon(),
                  color: occupancyColor,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Occupancy Gauge
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _occupancy.occupancyPercent / 100,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [QuantumColors.success, Colors.yellow, Colors.red],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOccupancyStat(
                '${_occupancy.totalCurrentMembers}',
                'Personas',
                Icons.people,
              ),
              _buildOccupancyStat(
                '${_occupancy.maxCapacity - _occupancy.totalCurrentMembers}',
                'Disponibles',
                Icons.check_circle_outline,
              ),
              _buildOccupancyStat(
                '${_occupancy.occupancyPercent.toStringAsFixed(0)}%',
                'Ocupación',
                Icons.pie_chart_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getOccupancyIcon() {
    if (_occupancy.occupancyPercent < 30) return Icons.sentiment_very_satisfied;
    if (_occupancy.occupancyPercent < 60) return Icons.sentiment_satisfied;
    if (_occupancy.occupancyPercent < 80) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  Widget _buildOccupancyStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: QuantumColors.quantumBlue, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildZoneBreakdown() {
    final zones = GymZone.values.where((z) => z != GymZone.reception);
    
    return Column(
      children: zones.map((zone) {
        final current = _occupancy.getZoneOccupancy(zone);
        final percent = _occupancy.getZonePercent(zone);
        final zoneColor = percent < 50
            ? QuantumColors.success
            : percent < 80
                ? Colors.orange
                : Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: QuantumColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(zone.icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          zone.displayName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$current/${zone.maxCapacity}',
                          style: TextStyle(color: zoneColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        color: zoneColor,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeakHoursChart() {
    final hours = List.generate(17, (i) => i + 6); // 6:00 to 22:00
    final currentHour = DateTime.now().hour;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: hours.map((hour) {
              final occupancy = _peakHours.hourlyOccupancy[hour] ?? 0;
              final isCurrentHour = hour == currentHour;
              final barColor = occupancy < 50
                  ? QuantumColors.success
                  : occupancy < 80
                      ? Colors.orange
                      : Colors.red;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: occupancy.clamp(5, 100).toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isCurrentHour
                            ? QuantumColors.quantumBlue
                            : barColor.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        border: isCurrentHour
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hour % 2 == 0)
                      Text(
                        '$hour',
                        style: TextStyle(
                          color: isCurrentHour ? Colors.white : Colors.white38,
                          fontSize: 9,
                          fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
                        ),
                      )
                    else
                      const SizedBox(height: 11),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(QuantumColors.success, 'Tranquilo'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange, 'Moderado'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.red, 'Ocupado'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildBestTimesCard() {
    final quietHours = _peakHours.quietHours;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuantumColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: QuantumColors.success, size: 24),
              SizedBox(width: 12),
              Text(
                'Mejores horarios para entrenar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quietHours.map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: QuantumColors.success.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$h:00 - ${h + 1}:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            '💡 Estos horarios tienen menos del 30% de ocupación',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    final activities = [
      _ActivityItem('Juan M.', 'Check-in', '2 min', Icons.login, Colors.green),
      _ActivityItem('María G.', 'Clase Spinning', '5 min', Icons.pedal_bike, Colors.orange),
      _ActivityItem('Carlos R.', 'Check-out', '8 min', Icons.logout, Colors.blue),
      _ActivityItem('Ana L.', 'Reservó clase', '12 min', Icons.event, Colors.purple),
    ];

    return Column(
      children: activities.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(a.icon, color: a.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    a.action,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              'Hace ${a.time}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _ActivityItem {
  final String name;
  final String action;
  final String time;
  final IconData icon;
  final Color color;

  _ActivityItem(this.name, this.action, this.time, this.icon, this.color);
}
