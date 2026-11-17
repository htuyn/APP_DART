class LocalizedText {
  final String vi;
  final String en;

  const LocalizedText({required this.vi, required this.en});

  factory LocalizedText.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return LocalizedText(
        vi: json['vi'] as String? ?? '',
        en: json['en'] as String? ?? json['vi'] as String? ?? '',
      );
    } else if (json is String) {
      return LocalizedText(vi: json, en: json);
    }
    return const LocalizedText(vi: '', en: '');
  }

  Map<String, dynamic> toJson() => {'vi': vi, 'en': en};

  String getText(String langCode) => langCode == 'en' ? en : vi;
}

class QuestionModel {
  final String id;
  final int blockId;
  final LocalizedText blockName;
  final String level;
  final LocalizedText question;
  final List<String> optionsVi;
  final List<String> optionsEn;
  final int correctIndex;
  final LocalizedText explanation;

  const QuestionModel({
    required this.id,
    required this.blockId,
    required this.blockName,
    required this.level,
    required this.question,
    required this.optionsVi,
    required this.optionsEn,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final opts = json['options'];
    List<String> viOpts = [];
    List<String> enOpts = [];

    if (opts is Map<String, dynamic>) {
      viOpts = List<String>.from(opts['vi'] ?? []);
      enOpts = List<String>.from(opts['en'] ?? viOpts);
    } else if (opts is List) {
      viOpts = List<String>.from(opts);
      enOpts = List<String>.from(opts);
    }

    return QuestionModel(
      id: json['id'] as String? ?? '',
      blockId: json['block_id'] as int? ?? 1,
      blockName: LocalizedText.fromJson(json['block_name']),
      level: json['level'] as String? ?? 'Nhá»›',
      question: LocalizedText.fromJson(json['question']),
      optionsVi: viOpts,
      optionsEn: enOpts,
      correctIndex: json['correct_index'] as int? ?? 0,
      explanation: LocalizedText.fromJson(json['explanation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'block_id': blockId,
      'block_name': blockName.toJson(),
      'level': level,
      'question': question.toJson(),
      'options': {
        'vi': optionsVi,
        'en': optionsEn,
      },
      'correct_index': correctIndex,
      'explanation': explanation.toJson(),
    };
  }

  List<String> getOptions(String langCode) {
    return langCode == 'en' ? optionsEn : optionsVi;
  }
}
