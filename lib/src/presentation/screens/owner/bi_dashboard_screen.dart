import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/theme.dart';

class BiDashboardScreen extends StatefulWidget {
  const BiDashboardScreen({super.key});

  @override
  State<BiDashboardScreen> createState() => _BiDashboardScreenState();
}

class _BiDashboardScreenState extends State<BiDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: GymColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 48),
            _buildSummaryGrid(),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildRevenueChart()),
                const SizedBox(width: 32),
                Expanded(child: _buildChurnChart()),
              ],
            ),
            const SizedBox(height: 48),
            _buildRetentionTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Intelligence', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Analítica avanzada de ingresos, retención y crecimiento orgánico.', 
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
        _buildDateRangePicker(),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GymColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: Colors.white54, size: 20),
          SizedBox(width: 12),
          Text('Últimos 30 días', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          SizedBox(width: 12),
          Icon(Icons.keyboard_arrow_down, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildMetricCard('Ingresos Membresías', '\$8,450', '+18%', const Color(0xFF4ECDC4)),
            const SizedBox(width: 24),
            _buildMetricCard('Ventas Productos', '\$1,230', '+24%', const Color(0xFFFF6B6B)),
            const SizedBox(width: 24),
            _buildMetricCard('Total Ingresos', '\$9,680', '+19%', Colors.green),
            const SizedBox(width: 24),
            _buildMetricCard('ROI Marketing', '4.2x', '+0.5', Colors.purple),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildMetricCard('LTV Promedio', '\$480', '+12%', Colors.blue),
            const SizedBox(width: 24),
            _buildMetricCard('CAC', '\$15.20', '-5%', Colors.orange),
            const SizedBox(width: 24),
            _buildMetricCard('Churn Rate', '2.4%', '-0.8%', Colors.redAccent),
            const SizedBox(width: 24),
            _buildMetricCard('Margen Productos', '45%', '+3%', const Color(0xFF95E1D3)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String trend, Color color) {
    return Expanded(
      child: GymCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(trend, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return GymCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crecimiento de Ingresos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.05))),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 310), FlSpot(1, 420), FlSpot(2, 380), FlSpot(3, 500), FlSpot(4, 450), FlSpot(5, 520), FlSpot(6, 680)],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [GymColors.primary, Colors.purpleAccent]),
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [GymColors.primary.withValues(alpha: 0.2), Colors.transparent])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChurnChart() {
    return GymCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estado de Membresías', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sectionsSpace: 8,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(value: 85, color: GymColors.primary, title: '85%', radius: 20, showTitle: false),
                  PieChartSectionData(value: 10, color: Colors.orange, title: '10%', radius: 20, showTitle: false),
                  PieChartSectionData(value: 5, color: Colors.red, title: '5%', radius: 20, showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegendItem('Activas', GymColors.primary),
          _buildLegendItem('Por Vencer', Colors.orange),
          _buildLegendItem('Inactivas', Colors.red),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRetentionTable() {
    return GymCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Análisis por Cohortes (Retención)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Table(
            columnWidths: const {0: FlexColumnWidth(2)},
            children: [
              _buildTableRow(['Cohorte', 'Mes 1', 'Mes 2', 'Mes 3', 'Mes 4'], isHeader: true),
              _buildTableRow(['Oct 2025', '100%', '92%', '88%', '84%']),
              _buildTableRow(['Nov 2025', '100%', '94%', '91%', '-']),
              _buildTableRow(['Dic 2025', '100%', '89%', '-', '-']),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells.map((cell) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(cell, style: TextStyle(
          color: isHeader ? Colors.white : Colors.white54,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        )),
      )).toList(),
    );
  }
}
