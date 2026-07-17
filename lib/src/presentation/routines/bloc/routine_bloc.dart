import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/data/dataset_exercise_catalog.dart';
import '../../../domain/data/exercise_catalog.dart';
import '../../../domain/ports/input/manage_routine_usecase_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../application/use_cases/maintain_routines_usecase.dart';

// === STATES ===

abstract class RoutineState extends Equatable {
  const RoutineState();
  @override
  List<Object?> get props => [];
}

class RoutineInitial extends RoutineState {}

class RoutineLoading extends RoutineState {}

class RoutinesLoaded extends RoutineState {
  final List<WorkoutRoutine> routines;
  final String? filterDifficulty;
  
  const RoutinesLoaded({
    required this.routines,
    this.filterDifficulty,
  });
  
  @override
  List<Object?> get props => [routines, filterDifficulty];
}

class RoutineDetailLoaded extends RoutineState {
  final WorkoutRoutine routine;
  
  const RoutineDetailLoaded(this.routine);
  
  @override
  List<Object?> get props => [routine];
}

class RoutineEditing extends RoutineState {
  final WorkoutRoutine? existingRoutine; // null si es nueva
  final String name;
  final String description;
  final DifficultyLevel difficulty;
  final List<RoutineExerciseInput> exercises;
  final int? selectedExerciseIndex;
  
  const RoutineEditing({
    this.existingRoutine,
    this.name = '',
    this.description = '',
    this.difficulty = DifficultyLevel.beginner,
    this.exercises = const [],
    this.selectedExerciseIndex,
  });
  
  RoutineEditing copyWith({
    String? name,
    String? description,
    DifficultyLevel? difficulty,
    List<RoutineExerciseInput>? exercises,
    int? selectedExerciseIndex,
  }) {
    return RoutineEditing(
      existingRoutine: existingRoutine,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      exercises: exercises ?? this.exercises,
      selectedExerciseIndex: selectedExerciseIndex,
    );
  }
  
  bool get isValid => 
      name.trim().length >= 3 && exercises.isNotEmpty;
  
  int get totalSets => 
      exercises.fold(0, (sum, e) => sum + e.sets);
  
  int get estimatedMinutes {
    int total = 0;
    for (final e in exercises) {
      total += (e.sets * 45 + e.sets * e.restSeconds) ~/ 60;
    }
    return total.clamp(10, 180);
  }
  
  @override
  List<Object?> get props => [
    existingRoutine, name, description, difficulty, 
    exercises, selectedExerciseIndex,
  ];
}

class ExerciseBrowsing extends RoutineState {
  final List<ExerciseTemplate> allExercises;
  final List<ExerciseTemplate> filteredExercises;
  final String searchQuery;
  final MuscleGroup? muscleFilter;
  final MovementPattern? patternFilter;
  final RoutineEditing previousState;
  
  const ExerciseBrowsing({
    required this.allExercises,
    required this.filteredExercises,
    this.searchQuery = '',
    this.muscleFilter,
    this.patternFilter,
    required this.previousState,
  });
  
  ExerciseBrowsing copyWith({
    List<ExerciseTemplate>? filteredExercises,
    String? searchQuery,
    MuscleGroup? muscleFilter,
    MovementPattern? patternFilter,
  }) {
    return ExerciseBrowsing(
      allExercises: allExercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      searchQuery: searchQuery ?? this.searchQuery,
      muscleFilter: muscleFilter,
      patternFilter: patternFilter,
      previousState: previousState,
    );
  }
  
  @override
  List<Object?> get props => [
    filteredExercises, searchQuery, muscleFilter, patternFilter,
  ];
}

class RoutineSuccess extends RoutineState {
  final String message;
  final WorkoutRoutine routine;
  
  const RoutineSuccess({required this.message, required this.routine});
  
  @override
  List<Object?> get props => [message, routine];
}

class RoutineError extends RoutineState {
  final String message;

  const RoutineError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operación de mantenimiento (purga o seed) completada
class RoutineMaintenanceSuccess extends RoutineState {
  final String message;

  const RoutineMaintenanceSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// === EVENTS ===

abstract class RoutineEvent extends Equatable {
  const RoutineEvent();
  @override
  List<Object?> get props => [];
}

class LoadRoutines extends RoutineEvent {}

class FilterRoutinesByDifficulty extends RoutineEvent {
  final DifficultyLevel? difficulty;
  const FilterRoutinesByDifficulty(this.difficulty);
}

class LoadRoutineDetail extends RoutineEvent {
  final RoutineId routineId;
  const LoadRoutineDetail(this.routineId);
}

class StartCreatingRoutine extends RoutineEvent {}

class StartEditingRoutine extends RoutineEvent {
  final WorkoutRoutine routine;
  const StartEditingRoutine(this.routine);
}

class UpdateRoutineName extends RoutineEvent {
  final String name;
  const UpdateRoutineName(this.name);
}

class UpdateRoutineDescription extends RoutineEvent {
  final String description;
  const UpdateRoutineDescription(this.description);
}

class UpdateRoutineDifficulty extends RoutineEvent {
  final DifficultyLevel difficulty;
  const UpdateRoutineDifficulty(this.difficulty);
}

class OpenExerciseBrowser extends RoutineEvent {}

class SearchExercises extends RoutineEvent {
  final String query;
  const SearchExercises(this.query);
}

class FilterExercisesByMuscle extends RoutineEvent {
  final MuscleGroup? muscle;
  const FilterExercisesByMuscle(this.muscle);
}

class FilterExercisesByPattern extends RoutineEvent {
  final MovementPattern? pattern;
  const FilterExercisesByPattern(this.pattern);
}

class AddExerciseToRoutine extends RoutineEvent {
  final ExerciseTemplate exercise;
  final int sets;
  final int minReps;
  final int maxReps;
  final int restSeconds;
  
  const AddExerciseToRoutine({
    required this.exercise,
    this.sets = 3,
    this.minReps = 8,
    this.maxReps = 12,
    this.restSeconds = 90,
  });
}

class UpdateExerciseInRoutine extends RoutineEvent {
  final int index;
  final int? sets;
  final int? minReps;
  final int? maxReps;
  final int? restSeconds;
  
  const UpdateExerciseInRoutine({
    required this.index,
    this.sets,
    this.minReps,
    this.maxReps,
    this.restSeconds,
  });
}

class RemoveExerciseFromRoutine extends RoutineEvent {
  final int index;
  const RemoveExerciseFromRoutine(this.index);
}

class ReorderExercises extends RoutineEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderExercises(this.oldIndex, this.newIndex);
}

class CloseExerciseBrowser extends RoutineEvent {}

class SaveRoutine extends RoutineEvent {
  final UserId createdBy;
  const SaveRoutine(this.createdBy);
}

class DeleteRoutineRequested extends RoutineEvent {
  final RoutineId routineId;
  final UserId deletedBy;
  const DeleteRoutineRequested(this.routineId, this.deletedBy);
}

class DuplicateRoutineRequested extends RoutineEvent {
  final RoutineId originalId;
  final String newName;
  final UserId createdBy;
  const DuplicateRoutineRequested(this.originalId, this.newName, this.createdBy);
}

/// Crear las rutinas predefinidas del dataset
class SeedRoutinesRequested extends RoutineEvent {
  final UserId createdBy;
  const SeedRoutinesRequested(this.createdBy);
}

// === BLOC ===

class RoutineBloc extends Bloc<RoutineEvent, RoutineState> {
  final ManageRoutineUseCasePort _manageRoutineUseCase;
  final SeedRoutinesUseCase? _seedRoutinesUseCase;

  RoutineBloc({
    required ManageRoutineUseCasePort manageRoutineUseCase,
    SeedRoutinesUseCase? seedRoutinesUseCase,
  }) : _manageRoutineUseCase = manageRoutineUseCase,
       _seedRoutinesUseCase = seedRoutinesUseCase,
       super(RoutineInitial()) {
    on<LoadRoutines>(_onLoadRoutines);
    on<FilterRoutinesByDifficulty>(_onFilterByDifficulty);
    on<StartCreatingRoutine>(_onStartCreating);
    on<StartEditingRoutine>(_onStartEditing);
    on<UpdateRoutineName>(_onUpdateName);
    on<UpdateRoutineDescription>(_onUpdateDescription);
    on<UpdateRoutineDifficulty>(_onUpdateDifficulty);
    on<OpenExerciseBrowser>(_onOpenExerciseBrowser);
    on<SearchExercises>(_onSearchExercises);
    on<FilterExercisesByMuscle>(_onFilterByMuscle);
    on<FilterExercisesByPattern>(_onFilterByPattern);
    on<AddExerciseToRoutine>(_onAddExercise);
    on<UpdateExerciseInRoutine>(_onUpdateExercise);
    on<RemoveExerciseFromRoutine>(_onRemoveExercise);
    on<ReorderExercises>(_onReorderExercises);
    on<CloseExerciseBrowser>(_onCloseExerciseBrowser);
    on<SaveRoutine>(_onSaveRoutine);
    on<DeleteRoutineRequested>(_onDeleteRoutine);
    on<DuplicateRoutineRequested>(_onDuplicateRoutine);
    on<SeedRoutinesRequested>(_onSeedRoutines);
  }

  Future<void> _onSeedRoutines(
    SeedRoutinesRequested event, Emitter<RoutineState> emit,
  ) async {
    final useCase = _seedRoutinesUseCase;
    if (useCase == null) {
      emit(const RoutineError('Rutinas predefinidas no disponibles'));
      return;
    }
    emit(RoutineLoading());
    final result = await useCase.execute(event.createdBy);
    result.fold(
      (failure) => emit(RoutineError(failure.message)),
      (r) => emit(RoutineMaintenanceSuccess(r.message)),
    );
  }
  
  Future<void> _onLoadRoutines(
    LoadRoutines event, Emitter<RoutineState> emit,
  ) async {
    emit(RoutineLoading());
    final result = await _manageRoutineUseCase.getAllRoutines();
    result.fold(
      (failure) => emit(RoutineError(failure.message)),
      (routines) => emit(RoutinesLoaded(routines: routines)),
    );
  }
  
  Future<void> _onFilterByDifficulty(
    FilterRoutinesByDifficulty event, Emitter<RoutineState> emit,
  ) async {
    if (event.difficulty == null) {
      add(LoadRoutines());
      return;
    }
    emit(RoutineLoading());
    final result = await _manageRoutineUseCase.getRoutinesByDifficulty(event.difficulty!);
    result.fold(
      (failure) => emit(RoutineError(failure.message)),
      (routines) => emit(RoutinesLoaded(
        routines: routines,
        filterDifficulty: event.difficulty!.name,
      )),
    );
  }
  
  void _onStartCreating(
    StartCreatingRoutine event, Emitter<RoutineState> emit,
  ) {
    emit(const RoutineEditing());
  }
  
  void _onStartEditing(
    StartEditingRoutine event, Emitter<RoutineState> emit,
  ) {
    final routine = event.routine;
    final exercises = routine.exercises.asMap().entries.map((entry) {
      // El ejercicio persistido no guarda templateId; se resuelve por nombre
      final templateId =
          DatasetExerciseCatalog.templateIdForName(entry.value.name) ??
              entry.value.name;
      return RoutineExerciseInput(
        templateId: templateId,
        order: entry.key,
        sets: entry.value.sets,
        minReps: entry.value.reps,
        maxReps: entry.value.reps,
        restSeconds: entry.value.restSeconds ?? 90,
      );
    }).toList();
    
    emit(RoutineEditing(
      existingRoutine: routine,
      name: routine.name,
      description: routine.description ?? '',
      difficulty: routine.difficulty,
      exercises: exercises,
    ));
  }
  
  void _onUpdateName(
    UpdateRoutineName event, Emitter<RoutineState> emit,
  ) {
    if (state is RoutineEditing) {
      emit((state as RoutineEditing).copyWith(name: event.name));
    }
  }
  
  void _onUpdateDescription(
    UpdateRoutineDescription event, Emitter<RoutineState> emit,
  ) {
    if (state is RoutineEditing) {
      emit((state as RoutineEditing).copyWith(description: event.description));
    }
  }
  
  void _onUpdateDifficulty(
    UpdateRoutineDifficulty event, Emitter<RoutineState> emit,
  ) {
    if (state is RoutineEditing) {
      emit((state as RoutineEditing).copyWith(difficulty: event.difficulty));
    }
  }
  
  void _onOpenExerciseBrowser(
    OpenExerciseBrowser event, Emitter<RoutineState> emit,
  ) {
    if (state is RoutineEditing) {
      final exercises = ExerciseCatalog.all;
      emit(ExerciseBrowsing(
        allExercises: exercises,
        filteredExercises: exercises,
        previousState: state as RoutineEditing,
      ));
    }
  }
  
  void _onSearchExercises(
    SearchExercises event, Emitter<RoutineState> emit,
  ) {
    if (state is ExerciseBrowsing) {
      final current = state as ExerciseBrowsing;
      final filtered = ExerciseCatalog.search(event.query);
      emit(current.copyWith(
        filteredExercises: filtered,
        searchQuery: event.query,
      ));
    }
  }
  
  void _onFilterByMuscle(
    FilterExercisesByMuscle event, Emitter<RoutineState> emit,
  ) {
    if (state is ExerciseBrowsing) {
      final current = state as ExerciseBrowsing;
      final filtered = event.muscle != null
          ? ExerciseCatalog.byMuscle(event.muscle!)
          : current.allExercises;
      emit(current.copyWith(
        filteredExercises: filtered,
        muscleFilter: event.muscle,
      ));
    }
  }
  
  void _onFilterByPattern(
    FilterExercisesByPattern event, Emitter<RoutineState> emit,
  ) {
    if (state is ExerciseBrowsing) {
      final current = state as ExerciseBrowsing;
      final filtered = event.pattern != null
          ? ExerciseCatalog.byPattern(event.pattern!)
          : current.allExercises;
      emit(current.copyWith(
        filteredExercises: filtered,
        patternFilter: event.pattern,
      ));
    }
  }
  
  void _onAddExercise(
    AddExerciseToRoutine event, Emitter<RoutineState> emit,
  ) {
    if (state is ExerciseBrowsing) {
      final current = state as ExerciseBrowsing;
      final prev = current.previousState;
      final newExercise = RoutineExerciseInput(
        templateId: event.exercise.id,
        order: prev.exercises.length,
        sets: event.sets,
        minReps: event.minReps,
        maxReps: event.maxReps,
        restSeconds: event.restSeconds,
      );
      
      emit(prev.copyWith(
        exercises: [...prev.exercises, newExercise],
      ));
    }
  }
  
  void _onUpdateExercise(
    UpdateExerciseInRoutine event, Emitter<RoutineState> emit,
  ) {
    if (state is RoutineEditing) {
      final current = state as RoutineEditing;
      if (event.index < current.exercises.length) {
        final updated = List<RoutineExerciseInput>.from(current.exercises);
        final old = updated[event.index];
        updated[event.index] = RoutineExerciseInput(
          templateId: old.templateId,
          order: old.order,
          sets: event.sets ?? old.sets,
          minReps: event.minReps ?? old.minReps,
          maxReps: event.maxReps ?? old.maxReps,
          restSeconds: event.restSeconds ?? old.restSeconds,
        );
        emit(current.copyWith(exercises: updated));
      }
    }
  }
  
  void _onRemoveExercise(
    RemoveExerciseFromRoutine event, Emitter<RoutineState> emit,
  ) {
    if (state is RoutineEditing) {
      final current = state as RoutineEditing;
      final updated = List<RoutineExerciseInput>.from(current.exercises);
      updated.removeAt(event.index);
      // Reorder
      for (int i = 0; i < updated.length; i++) {
        updated[i] = RoutineExerciseInput(
          templateId: updated[i].templateId,
          order: i,
          sets: updated[i].sets,
          minReps: updated[i].minReps,
          maxReps: updated[i].maxReps,
          restSeconds: updated[i].restSeconds,
        );
      }
      emit(current.copyWith(exercises: updated));
    }
  }
  
  void _onReorderExercises(
    ReorderExercises event, Emitter<RoutineState> emit,
  ) {
    if (state is RoutineEditing) {
      final current = state as RoutineEditing;
      final updated = List<RoutineExerciseInput>.from(current.exercises);
      final item = updated.removeAt(event.oldIndex);
      updated.insert(event.newIndex, item);
      // Update order
      for (int i = 0; i < updated.length; i++) {
        updated[i] = RoutineExerciseInput(
          templateId: updated[i].templateId,
          order: i,
          sets: updated[i].sets,
          minReps: updated[i].minReps,
          maxReps: updated[i].maxReps,
          restSeconds: updated[i].restSeconds,
        );
      }
      emit(current.copyWith(exercises: updated));
    }
  }
  
  void _onCloseExerciseBrowser(
    CloseExerciseBrowser event, Emitter<RoutineState> emit,
  ) {
    if (state is ExerciseBrowsing) {
      emit((state as ExerciseBrowsing).previousState);
    }
  }
  
  Future<void> _onSaveRoutine(
    SaveRoutine event, Emitter<RoutineState> emit,
  ) async {
    if (state is! RoutineEditing) return;
    final current = state as RoutineEditing;
    
    if (!current.isValid) {
      emit(const RoutineError('Complete todos los campos requeridos'));
      emit(current);
      return;
    }
    
    emit(RoutineLoading());
    
    if (current.existingRoutine != null) {
      // Update
      final result = await _manageRoutineUseCase.updateRoutine(
        UpdateRoutineCommand(
          routineId: current.existingRoutine!.id,
          name: current.name,
          description: current.description,
          difficulty: current.difficulty,
          exercises: current.exercises,
          updatedBy: event.createdBy,
        ),
      );
      
      result.fold(
        (failure) {
          emit(RoutineError(failure.message));
          emit(current);
        },
        (res) => emit(RoutineSuccess(message: res.message, routine: res.routine)),
      );
    } else {
      // Create
      final result = await _manageRoutineUseCase.createRoutine(
        CreateRoutineCommand(
          name: current.name,
          description: current.description.isEmpty ? null : current.description,
          difficulty: current.difficulty,
          exercises: current.exercises,
          createdBy: event.createdBy,
        ),
      );
      
      result.fold(
        (failure) {
          emit(RoutineError(failure.message));
          emit(current);
        },
        (res) => emit(RoutineSuccess(message: res.message, routine: res.routine)),
      );
    }
  }
  
  Future<void> _onDeleteRoutine(
    DeleteRoutineRequested event, Emitter<RoutineState> emit,
  ) async {
    emit(RoutineLoading());
    final result = await _manageRoutineUseCase.deleteRoutine(
      event.routineId, event.deletedBy,
    );
    result.fold(
      (failure) => emit(RoutineError(failure.message)),
      (_) {
        add(LoadRoutines());
      },
    );
  }
  
  Future<void> _onDuplicateRoutine(
    DuplicateRoutineRequested event, Emitter<RoutineState> emit,
  ) async {
    emit(RoutineLoading());
    final result = await _manageRoutineUseCase.duplicateRoutine(
      originalId: event.originalId,
      newName: event.newName,
      createdBy: event.createdBy,
    );
    result.fold(
      (failure) => emit(RoutineError(failure.message)),
      (res) => emit(RoutineSuccess(message: res.message, routine: res.routine)),
    );
  }
}
