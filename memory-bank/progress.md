# Progress Tracker

| Hạng mục | Trạng thái | Ghi chú |
| :--- | :--- | :--- |
| Khởi tạo dự án Flutter & `pubspec.yaml` | Hoàn thành | Đã thêm `provider`, `shared_preferences`, khai báo `assets/data/` |
| Core (`AppColors`, `AppTheme`) | Hoàn thành | Có Light/Dark theme, Material 3 |
| Domain (`IQuizRepository`) | Hoàn thành | Định nghĩa đủ 6 phương thức |
| Data Models (`QuestionModel`, `QuizResultModel`) | Hoàn thành | Hỗ trợ song ngữ `LocalizedText` |
| Data Sources (`Local` & `Storage`) | Hoàn thành | Đọc asset JSON & lưu `SharedPreferences` |
| Repository Implementation (`QuizRepositoryImpl`) | Hoàn thành | Kết nối Local & Storage DataSources |
| `LanguageProvider` | Hoàn thành | Hỗ trợ VI/EN, lưu vào `SharedPreferences` |
| Dữ liệu `assets/data/questions.json` | Chưa làm | Chưa có thư mục `assets/data/` |
| `QuizProvider` / State làm bài | Chưa làm | Cần tạo trong `lib/presentation/providers/` |
| Giao diện (Home, Quiz, Result, History) | Chưa làm | Chưa có thư mục `screens/` và `widgets/` |
| Tích hợp `lib/main.dart` | Chưa làm | Hiện vẫn là template counter mặc định |
| Unit & Widget Tests | Chưa làm | `test/widget_test.dart` vẫn là test mặc định |
