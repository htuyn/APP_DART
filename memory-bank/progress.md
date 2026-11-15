# Tiến độ Dự án (Progress)

## Đã hoàn thành (Done)
- [x] Khởi tạo dự án Flutter với Clean Architecture.
- [x] Khai báo cấu hình `pubspec.yaml` (`provider`, `shared_preferences`, assets data).
- [x] Tạo `QuestionModel` và `QuizResultModel` song ngữ VI/EN.
- [x] Tạo `QuizRepository` và triển khai Datasource (JSON Local + SharedPreferences Storage).
- [x] Triển khai các Providers: `LanguageProvider`, `QuizProvider`, `ExamProvider`, `StatsProvider`, `AiTutorProvider`.
- [x] Nâng cấp giao diện (UI/UX) hiện đại, bắt mắt:
  - Hero Header với dải màu Gradient công nghệ và chỉ số độ chính xác (Accuracy rate).
  - Thẻ chế độ học tập (ModernMenuCard) với icon gradient đổ bóng 3D.
  - OptionTile tương tác sinh động (hiệu ứng bóng mờ khi đúng/sai, vùng chạm $\ge 52\text{dp}$).
  - Đồng hồ đếm ngược với vòng tròn tiến trình trực quan.
- [x] Tích hợp **Trợ lý AI Flutter Tutor** (Modal BottomSheet, phân tích chi tiết, giải thích vì sao chọn sai, code mẫu, mẹo ghi nhớ, chế độ Demo offline chuẩn Rubric +3 điểm).
- [x] Nâng cấp màn hình Luyện tập (`PracticeScreen`) và Sổ tay câu sai (`WrongQuestionsScreen`) với nút bấm mở AI Tutor.
- [x] Viết thêm unit tests cho `AiTutorProvider`, nâng tổng số test lên **21 tests tự động**.
- [x] Toàn bộ test đạt 100% (`flutter test`: 21 passed).
- [x] Phân tích tĩnh sạch hoàn toàn (`flutter analyze`: No issues found).

## Kế hoạch tiếp theo (Upcoming)
- [ ] Chế độ Flashcard 3D lật mặt nếu người dùng yêu cầu.
- [ ] Trích xuất toàn bộ 300 câu hỏi vào `assets/data/questions.json`.
- [ ] Build file APK Release có ký khóa (+2 điểm).
