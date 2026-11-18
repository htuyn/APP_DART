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
- [x] Phân tích tĩnh sạch hoàn toàn (`flutter analyze`: No errors).
- [x] Nâng cấp **Trợ lý AI Chat trực tiếp** (Hướng 1: Gemini free key + backend proxy):
  - Màn hình chat AI (`AiChatScreen`) với streaming trả lời từng đoạn.
  - `ChatProvider`, `ChatMessageBubble`, `ChatInputBar`.
  - 2 nhánh: Remote (proxy Gemini qua Cloudflare Worker, giữ key ở server) + Demo offline fallback (questions.json).
  - Backend proxy: `backend/worker.js`, `wrangler.toml`, `README.md` hướng dẫn deploy.
  - Thêm nút "Trợ Lý AI Tutor" vào `HomeScreen`.
  - Dependencies mới: `http`, `convert`.
  - 21 tests passed, analyze 0 errors.

## Kế hoạch tiếp theo (Upcoming)
- [ ] Cấu hình `serverUrl` trong `ChatProvider` để bật AI thật (Gemini) thay vì demo offline.
- [ ] Lưu lịch sử chat vào `SharedPreferences` để mở lại sau.
- [ ] Chế độ Flashcard 3D lật mặt nếu người dùng yêu cầu.
- [ ] Trích xuất toàn bộ 300 câu hỏi vào `assets/data/questions.json`.
- [ ] Build file APK Release có ký khóa (+2 điểm).
