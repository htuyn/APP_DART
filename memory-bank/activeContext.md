# Active Context

## 1. Trạng thái hiện tại
Dự án `flutter_quiz_bilingual` đã hoàn thành toàn bộ khung kiến trúc Clean Architecture, UI cơ bản với 4 chế độ (Luyện tập, Thi thử, Câu sai, Thống kê), hỗ trợ song ngữ VI/EN, CI GitHub Actions và 17 automated tests vượt qua 100%.
Hiện đang thực hiện nâng cấp:
1. **Giao diện người dùng (UI/UX)**: Đẹp mắt, hiện đại với bảng màu công nghệ, gradient, hiệu ứng sinh động, bố cục thẻ trực quan.
2. **Trợ lý AI Tutor**: Tích hợp hỗ trợ giải thích câu hỏi thông minh, chế độ Demo offline và sẵn sàng kết nối API giữ khóa ở backend (theo đúng Rubric điểm cộng +3).

## 2. Những gì đã hoàn thành
- Clean Architecture (Data, Domain, Presentation).
- State Management: `Provider` (`LanguageProvider`, `QuizProvider`, `ExamProvider`, `StatsProvider`).
- 17 Automated Tests (Unit + Widget + Accessibility `meetsGuideline` 48dp).
- `flutter analyze`: 0 issues found.
- `README.md` và `.github/workflows/ci.yml`.

## 3. Kế hoạch đang thực hiện
1. Tạo `AiTutorService` / `AiProvider`:
   - Phân tích câu hỏi và giải thích vì sao đáp án đúng là đúng, vì sao người dùng chọn sai.
   - Chế độ Demo Mode tích hợp sẵn (Offline 100% không cần key).
2. Nâng cấp giao diện `OptionTile`, `HomeScreen`, `PracticeScreen`, `ExamScreen`.
3. Tích hợp `AiTutorSheet` (Modal BottomSheet hiển thị gia sư AI với hiệu ứng gõ chữ, gợi ý code).
4. Viết Unit Test cho AI Service & chạy lại toàn bộ test suite.
