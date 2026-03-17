import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/gym_design_system.dart';
import '../../theme/gym_widgets.dart';

class GymClassesScreen extends StatefulWidget {
  const GymClassesScreen({super.key});

  @override
  State<GymClassesScreen> createState() => _GymClassesScreenState();
}

class _GymClassesScreenState extends State<GymClassesScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<String> _days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  String _intensityFilter = 'Todas';
  final List<Map<String, dynamic>> _classes = [];

  @override
  Widget build(BuildContext context) {
    final filteredClasses =
        _intensityFilter == 'Todas'
            ? _classes
            : _classes
                .where((gymClass) => gymClass['intensity'] == _intensityFilter)
                .toList();
    final bookedCount =
        _classes.where((gymClass) => gymClass['booked'] == true).length;

    return Scaffold(
      backgroundColor: GymColors.background,
      appBar: GymAppBar(
        title: 'Clases Grupales',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: GymColors.textSecondary),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarStrip(),
          Expanded(
            child: ListView(
              padding: GymSpacing.screenPadding,
              children: [
                const SectionHeader(
                  title: 'Disponibles Hoy',
                  actionText: 'Ver todas',
                ),
                const SizedBox(height: 16),
                if (filteredClasses.isEmpty)
                  GymCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_busy_outlined,
                          color: GymColors.textSecondary,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay clases publicadas para este filtro',
                          style: GymTypography.bodyLargeStyle.copyWith(
                            color: GymColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cuando existan clases reales del gimnasio, aparecerán aquí.',
                          style: GymTypography.labelStyle.copyWith(
                            color: GymColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredClasses.map((gymClass) => _buildClassCard(gymClass)),
                const SizedBox(height: 40),
                _buildMyBookingsInfo(bookedCount),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('📅 Solicitar clase personalizada — próximamente'),
              backgroundColor: GymColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        backgroundColor: GymColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: GymColors.surface,
        border: Border(
          bottom: BorderSide(color: GymColors.textSecondary.withValues(alpha: 0.1)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? GymColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(GymRadius.md),
                border: Border.all(
                  color: isSelected ? GymColors.primary : GymColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _days[date.weekday - 1],
                    style: TextStyle(
                      fontSize: GymTypography.bodySmall,
                      color: isSelected ? Colors.white : GymColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: GymTypography.bodyLarge,
                      color: isSelected ? Colors.white : GymColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> gymClass) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GymCard(
        onTap: () {},
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Color strip
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: gymClass['color'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(GymRadius.lg),
                    bottomLeft: Radius.circular(GymRadius.lg),
                  ),
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            gymClass['time'],
                            style: GymTypography.labelStyle.copyWith(
                              color: GymColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StatusBadge(
                            text: gymClass['intensity'],
                            type: StatusType.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gymClass['title'],
                        style: GymTypography.bodyLargeStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: GymColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: GymColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            gymClass['instructor'],
                            style: GymTypography.labelStyle.copyWith(color: GymColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.group, size: 14, color: GymColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            gymClass['capacity'],
                            style: GymTypography.labelStyle.copyWith(color: GymColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: gymClass['booked'] 
                  ? const Icon(Icons.check_circle, color: GymColors.success)
                  : GymButton(
                      text: 'Reservar',
                      size: GymButtonSize.small,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          gymClass['booked'] = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Reserva confirmada: ${gymClass['title']}'),
                            backgroundColor: GymColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyBookingsInfo(int bookedCount) {
    return GymCard(
      backgroundColor: GymColors.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: GymColors.primary, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookedCount > 0
                      ? 'Tienes $bookedCount reservas activas'
                      : 'No tienes reservas activas',
                  style: GymTypography.bodyMediumStyle.copyWith(
                    color: GymColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  bookedCount > 0
                      ? 'Recuerda llegar 5 min antes.'
                      : 'Tus próximas reservas aparecerán aquí.',
                  style: GymTypography.labelStyle.copyWith(color: GymColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: GymColors.textSecondary),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GymColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtrar por Intensidad',
                    style: GymTypography.headlineLargeStyle.copyWith(color: GymColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close, color: GymColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: ['Todas', 'Baja', 'Media', 'Alta', 'Extrema']
                    .map((intensity) => ChoiceChip(
                          label: Text(intensity),
                          selected: _intensityFilter == intensity,
                          selectedColor: GymColors.primary,
                          backgroundColor: GymColors.cardBackground,
                          labelStyle: TextStyle(
                            color: _intensityFilter == intensity ? Colors.white : GymColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setState(() => _intensityFilter = intensity);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
