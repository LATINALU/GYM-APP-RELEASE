import 'package:http/http.dart' as http;

import '../../../domain/ports/output/exercise_media_port.dart';
import 'web_exercise_media_service.dart';

ExerciseMediaPort createExerciseMediaService(http.Client client) =>
    WebExerciseMediaService();
