import 'package:flutter/foundation.dart';

import '../../data/datasources/ai_tutor_datasource.dart';
import '../../data/models/question_model.dart';

enum AiTutorState { idle, thinking, done, error }

class AiTutorProvider with ChangeNotifier {
  final AiTutorDataSource dataSource;

  AiTutorState _state = AiTutorState.idle;
  String _response = '';
  String _errorMessage = '';
  int _requestId = 0;
  bool _disposed = false;

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
    final requestId = ++_requestId;

    _state = AiTutorState.thinking;
    _response = '';
    _errorMessage = '';
    _notify();

    try {
      final result = await dataSource.requestExplanation(
        question: question,
        userChoiceIndex: userChoiceIndex,
        langCode: langCode,
        action: action,
      );
      if (requestId != _requestId) return;
      _response = result;
      _state = AiTutorState.done;
    } catch (e) {
      if (requestId != _requestId) return;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = AiTutorState.error;
    }
    _notify();
  }

  void reset() {
    _requestId++;
    _state = AiTutorState.idle;
    _response = '';
    _errorMessage = '';
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}
