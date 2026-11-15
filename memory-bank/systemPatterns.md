# System Patterns & Architecture

## 1. Kiến trúc tổng thể
Dự án áp dụng kiến trúc phân tầng theo hướng **Clean Architecture** kết hợp **Provider** để quản lý state:

```text
lib/
├── core/               # Hằng số, màu sắc, theme dùng chung
│   ├── constants/
│   │   └── app_colors.dart
│   └── theme/
│       └── app_theme.dart
├── domain/             # Giao diện (abstraction) nghiệp vụ
│   └── repositories/
│       └── quiz_repository.dart
├── data/               # Models, DataSources, Repository implementation
│   ├── datasources/
│   │   ├── quiz_local_datasource.dart
│   │   └── quiz_storage_datasource.dart
│   ├── models/
│   │   ├── question_model.dart
│   │   └── quiz_result_model.dart
│   └── repositories/
│       └── quiz_repository_impl.dart
├── presentation/       # State management (Providers), Screens, Widgets
│   └── providers/
│       └── language_provider.dart
└── main.dart           # Entry point (hiện vẫn là template mặc định)
```

## 2. Design Patterns đang sử dụng
- **Repository Pattern**:
  - `IQuizRepository` (`lib/domain/repositories/quiz_repository.dart`) định nghĩa hợp đồng dữ liệu.
  - `QuizRepositoryImpl` (`lib/data/repositories/quiz_repository_impl.dart`) điều phối giữa `QuizLocalDataSource` và `QuizStorageDataSource`.
- **DataSource Pattern**:
  - `QuizLocalDataSource`: Đọc JSON từ `rootBundle` (`assets/data/questions.json`).
  - `QuizStorageDataSource`: Đọc/ghi dữ liệu người dùng qua `SharedPreferences`.
- **Provider (ChangeNotifier)**:
  - `LanguageProvider` quản lý `AppLanguage` (`vi` | `en`), cung cấp helper `translate(vi: ..., en: ...)` và tự động đồng bộ với `SharedPreferences`.

## 3. Data Models & Storage Keys

### `QuestionModel` (`lib/data/models/question_model.dart`)
- `id`: `String`
- `blockId`: `int` (JSON key: `block_id`)
- `blockName`: `LocalizedText` (JSON key: `block_name`)
- `level`: `String` (mặc định `'Nhớ'`)
- `question`: `LocalizedText`
- `optionsVi` / `optionsEn`: `List<String>` (JSON key: `options` dạng `{"vi": [...], "en": [...]}` hoặc `List`)
- `correctIndex`: `int` (JSON key: `correct_index`)
- `explanation`: `LocalizedText`

### `QuizResultModel` (`lib/data/models/quiz_result_model.dart`)
- `id`: `String`
- `timestamp`: `DateTime` (ISO 8601)
- `score`: `int`
- `totalQuestions`: `int` (JSON key: `total_questions`)
- `timeSpentSeconds`: `int` (JSON key: `time_spent_seconds`)
- `wrongQuestionIds`: `List<String>` (JSON key: `wrong_question_ids`)
- Computed getter: `percentage` (`(score / totalQuestions) * 100.0`)

### `SharedPreferences` Keys
- `selected_language`: `'vi'` hoặc `'en'` (`LanguageProvider`)
- `wrong_question_ids`: `List<String>` (`QuizStorageDataSource`)
- `quiz_history`: `List<String>` chứa JSON string của `QuizResultModel` (`QuizStorageDataSource`)
