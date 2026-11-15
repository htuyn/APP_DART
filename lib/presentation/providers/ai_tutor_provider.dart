import 'package:flutter/foundation.dart';
import '../../data/datasources/ai_tutor_datasource.dart';
import '../../data/models/question_model.dart';

enum AiTutorState { idle, thinking, done, error }

class AiTutorProvider with ChangeNotifier {
  final AiTutorDataSource dataSource;

  AiTutorState _state = AiTutorState.idle;
  String _response = '';
  String _errorMessage = '';

  AiTutorState get state => _state;
  String get response => _response;
  String get errorMessage => _errorMessage;

  AiTutorProvider({AiTutorDataSource? dataSource})
      : dataSource = dataSource ?? const AiTutorDataSource(isDemoMode: true);

  Future<void> askTutor({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  }) async {
    _state = AiTutorState.thinking;
    _response = '';
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await dataSource.requestExplanation(
        question: question,
        userChoiceIndex: userChoiceIndex,
        langCode: langCode,
        action: action,
      );
      _response = result;
      _state = AiTutorState.done;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AiTutorState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = AiTutorState.idle;
    _response = '';
    _errorMessage = '';
    notifyListeners();
  }
}
