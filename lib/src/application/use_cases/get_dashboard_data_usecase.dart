import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/output_ports.dart';
import '../../domain/value_objects/value_objects.dart';

/// Dashboard data for owner
class OwnerDashboardData {
  final int totalClients;
  final int totalEmployees;
  final int activeRoutines;
  final int todayCheckIns;
  final List<User> recentClients;
  final List<CheckIn> recentCheckIns;
  final Map<String, dynamic> globalStats;
  final List<Map<String, dynamic>> dailyMetrics;

  const OwnerDashboardData({
    required this.totalClients,
    required this.totalEmployees,
    required this.activeRoutines,
    required this.todayCheckIns,
    required this.recentClients,
    required this.recentCheckIns,
    required this.globalStats,
    required this.dailyMetrics,
  });
}

/// Dashboard data for employee
class EmployeeDashboardData {
  final int myClientsCount;
  final int myAssignmentsCount;
  final int todayCheckIns;
  final List<User> myClients;
  final List<RoutineAssignment> recentAssignments;

  const EmployeeDashboardData({
    required this.myClientsCount,
    required this.myAssignmentsCount,
    required this.todayCheckIns,
    required this.myClients,
    required this.recentAssignments,
  });
}

/// Dashboard data for client
class ClientDashboardData {
  final RoutineAssignment? activeAssignment;
  final WorkoutRoutine? currentRoutine;
  final int thisWeekCheckIns;
  final int thisMonthCheckIns;
  final List<CheckIn> recentCheckIns;

  const ClientDashboardData({
    this.activeAssignment,
    this.currentRoutine,
    required this.thisWeekCheckIns,
    required this.thisMonthCheckIns,
    required this.recentCheckIns,
  });
}

/// Get dashboard data use case
class GetDashboardDataUseCase {
  final UserRepositoryPort _userRepository;
  final RoutineRepositoryPort _routineRepository;
  final AssignmentRepositoryPort _assignmentRepository;
  final CheckInRepositoryPort _checkInRepository;
  final GymRepositoryPort _gymRepository;

  GetDashboardDataUseCase({
    required UserRepositoryPort userRepository,
    required RoutineRepositoryPort routineRepository,
    required AssignmentRepositoryPort assignmentRepository,
    required CheckInRepositoryPort checkInRepository,
    required GymRepositoryPort gymRepository,
  })  : _userRepository = userRepository,
        _routineRepository = routineRepository,
        _assignmentRepository = assignmentRepository,
        _checkInRepository = checkInRepository,
        _gymRepository = gymRepository;

  /// Get owner dashboard data
  FutureResult<OwnerDashboardData> getOwnerDashboard(GymId gymId) async {
    try {
      // Get counts
      final clientsResult = await _userRepository.findByRole(gymId: gymId, role: const GymRole.client());
      final employeesResult = await _userRepository.findByRole(gymId: gymId, role: const GymRole.employee());
      final routinesResult = await _routineRepository.findAllActive();
      final todayCheckInsResult = await _checkInRepository.findToday();

      final clients = clientsResult.getOrElse(() => <User>[]);
      final employees = employeesResult.getOrElse(() => <User>[]);
      final routines = routinesResult.getOrElse(() => <WorkoutRoutine>[]);
      final todayCheckIns = todayCheckInsResult.getOrElse(() => <CheckIn>[]);

      // Get Global Stats and Daily Metrics
      final statsResult = await _gymRepository.getStats(gymId);
      final metricsResult = await _gymRepository.getDailyMetrics(
        id: gymId, 
        start: DateTime.now().subtract(const Duration(days: 7)), 
        end: DateTime.now()
      );

      final stats = statsResult.getOrElse(() => <String, dynamic>{});
      final metrics = metricsResult.getOrElse(() => <Map<String, dynamic>>[]);

      return right(OwnerDashboardData(
        totalClients: clients.length,
        totalEmployees: employees.length,
        activeRoutines: routines.length,
        todayCheckIns: todayCheckIns.length,
        recentClients: clients.take(5).toList(),
        recentCheckIns: todayCheckIns.take(10).toList(),
        globalStats: stats,
        dailyMetrics: metrics,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error al cargar dashboard: $e'));
    }
  }

  /// Get employee dashboard data
  FutureResult<EmployeeDashboardData> getEmployeeDashboard(UserId employeeId, GymId gymId) async {
    try {
      final clientsResult = await _userRepository.findByRole(gymId: gymId, role: const GymRole.client());
      final assignmentsResult = await _assignmentRepository.findByAssigner(employeeId);
      final todayCheckInsResult = await _checkInRepository.findToday();

      final clients = clientsResult.getOrElse(() => <User>[]);
      final assignments = assignmentsResult.getOrElse(() => <RoutineAssignment>[]);
      final todayCheckIns = todayCheckInsResult.getOrElse(() => <CheckIn>[]);

      return right(EmployeeDashboardData(
        myClientsCount: clients.length,
        myAssignmentsCount: assignments.where((a) => a.isActive).length,
        todayCheckIns: todayCheckIns.length,
        myClients: clients.take(10).toList(),
        recentAssignments: assignments.take(5).toList(),
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error al cargar dashboard: $e'));
    }
  }

  /// Get client dashboard data
  FutureResult<ClientDashboardData> getClientDashboard(UserId clientId) async {
    try {
      // Get active assignment
      final assignmentsResult = await _assignmentRepository.findActiveByClient(clientId);
      final assignments = assignmentsResult.getOrElse(() => <RoutineAssignment>[]);
      final activeAssignment = assignments.isNotEmpty ? assignments.first : null;

      // Get current routine if assigned
      WorkoutRoutine? currentRoutine;
      if (activeAssignment != null) {
        final routineResult = await _routineRepository.findById(activeAssignment.routineId);
        currentRoutine = routineResult.fold((_) => null, (r) => r);
      }

      // Get check-in stats
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final weekCheckIns = await _checkInRepository.countByClientAndPeriod(
        clientId: clientId,
        startDate: startOfWeek,
        endDate: now,
      );

      final monthCheckIns = await _checkInRepository.countByClientAndPeriod(
        clientId: clientId,
        startDate: startOfMonth,
        endDate: now,
      );

      // Get recent check-ins
      final checkInsResult = await _checkInRepository.findByClient(clientId);
      final recentCheckIns = checkInsResult.getOrElse(() => <CheckIn>[]).take(5).toList();

      return right(ClientDashboardData(
        activeAssignment: activeAssignment,
        currentRoutine: currentRoutine,
        thisWeekCheckIns: weekCheckIns,
        thisMonthCheckIns: monthCheckIns,
        recentCheckIns: recentCheckIns,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error al cargar dashboard: $e'));
    }
  }
}
