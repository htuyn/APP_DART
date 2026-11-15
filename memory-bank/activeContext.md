# Active Context

## 1. Trạng thái hiện tại
Dự án `flutter_quiz_bilingual` đã hoàn thiện phần khung kiến trúc dữ liệu (`core`, `domain`, `data`) và `LanguageProvider`, nhưng chưa kết nối vào UI thực tế.

## 2. Những gì đã có
- `lib/core/constants/app_colors.dart`: Bảng màu đầy đủ cho Light/Dark và trạng thái quiz.
- `lib/core/theme/app_theme.dart`: Cấu hình `lightTheme` và `darkTheme`.
- `lib/domain/repositories/quiz_repository.dart`: Interface `IQuizRepository`.
- `lib/data/models/question_model.dart`: `LocalizedText` và `QuestionModel` parse JSON linh hoạt (hỗ trợ cả `Map` song ngữ và `String`/`List` đơn ngữ).
- `lib/data/models/quiz_result_model.dart`: Model lưu kết quả và tính phần trăm điểm.
- `lib/data/datasources/quiz_local_datasource.dart`: Đọc `assets/data/questions.json`.
- `lib/data/datasources/quiz_storage_datasource.dart`: Lưu/xóa câu sai và lịch sử quiz bằng `SharedPreferences`.
- `lib/data/repositories/quiz_repository_impl.dart`: Triển khai `IQuizRepository`.
- `lib/presentation/providers/language_provider.dart`: Quản lý ngôn ngữ VI/EN.

## 3. Những việc cần làm tiếp theo (Next Steps)
1. **Tạo dữ liệu mẫu**: Tạo thư mục `assets/data/` và file `assets/data/questions.json` đúng schema của `QuestionModel`.
2. **Xây dựng `QuizProvider` (và `ThemeProvider` nếu cần)**: Quản lý danh sách câu hỏi, lọc theo `blockId` / câu sai, đếm thời gian, chấm điểm và lưu kết quả qua `IQuizRepository`.
3. **Xây dựng giao diện (`lib/presentation/screens/` & `widgets/`)**:
   - Màn hình chính (Home): Chọn khối kiến thức, chế độ làm bài (tất cả / ôn câu sai), chuyển ngôn ngữ, xem lịch sử.
   - Màn hình làm bài (Quiz): Hiển thị câu hỏi, đáp án, giải thích, tiến trình.
   - Màn hình kết quả (Result): Điểm số, thời gian, danh sách câu sai.
   - Màn hình lịch sử (History) & Ôn tập câu sai (Wrong Questions).
4. **Cập nhật `lib/main.dart`**: Khởi tạo `MultiProvider`, inject `QuizRepositoryImpl`, áp dụng `AppTheme.lightTheme` / `AppTheme.darkTheme` và trỏ `home` vào màn hình chính.
5. **Cập nhật Tests (`test/`)**: Viết unit test cho models/repository/providers và thay thế `test/widget_test.dart` mặc định.

## 4. Lưu ý kỹ thuật
- `lib/main.dart` hiện vẫn là ứng dụng counter mặc định của Flutter.
- Thư mục `assets/data/` chưa tồn tại trên đĩa dù đã khai báo trong `pubspec.yaml`.
- Trong `lib/core/theme/app_theme.dart`, `CardTheme` được dùng cho `cardTheme` — cần kiểm tra tương thích với phiên bản Flutter SDK hiện tại khi chạy `flutter analyze` (một số bản Flutter mới dùng `CardThemeData`).
