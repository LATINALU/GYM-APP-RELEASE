import 'package:equatable/equatable.dart';

class FinancialSnapshot extends Equatable {
  final DateTime date;
  final double totalRevenue;
  final int activeSubscriptions;
  final double churnRate;

  const FinancialSnapshot({
    required this.date,
    required this.totalRevenue,
    required this.activeSubscriptions,
    required this.churnRate,
  });

  @override
  List<Object?> get props => [date, totalRevenue, activeSubscriptions, churnRate];
}
