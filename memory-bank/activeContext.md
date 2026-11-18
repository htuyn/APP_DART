# Active Context

## 1. Trạng thái hiện tại
Dự án `flutter_quiz_bilingual` đã hoàn thành toàn bộ khung kiến trúc Clean Architecture, UI cơ bản với 4 chế độ (Luyện tập, Thi thử, Câu sai, Thống kê), hỗ trợ song ngữ VI/EN, CI GitHub Actions và 21 automated tests vượt qua 100%.

## 2. Tính năng vừa hoàn thành — Trợ lý AI Chat trực tiếp
- **Màn hình chat AI** (`lib/presentation/screens/ai_chat_screen.dart`): người dùng gõ câu hỏi tự do, AI trả lời ngay (streaming).
- **ChatProvider** (`lib/presentation/providers/chat_provider.dart`): quản lý danh sách tin nhắn, trạng thái streaming/done/error, xóa lịch sử.
- **Giao diện chat** (`chat_message_bubble.dart`, `chat_input_bar.dart`): bubbles user/AI, ô nhập tin nhắn, typing indicator, auto-scroll.
- **Nút vào chat** trên `HomeScreen` (tab "Trợ Lý AI Tutor", badge AI).
- **2 nhánh dữ liệu**:
  - **Remote (AI thật qua Gemini)**: gọi backend proxy (Cloudflare Worker) giữ `GEMINI_API_KEY`, trả SSE stream.
  - **Demo offline**: fallback từ `questions.json`, không cần key, không cần mạng (giữ rubric +3).
- **Backend proxy** (`backend/worker.js` + `wrangler.toml`): SSE stream từ Gemini `streamGenerateContent`, CORS, health check.
- **Dependencies mới**: `http`, `convert`.

## 3. Những gì đã hoàn thành
- Clean Architecture (Data, Domain, Presentation).
- State Management: `Provider` (`LanguageProvider`, `QuizProvider`, `ExamProvider`, `StatsProvider`, `AiTutorProvider`, `ChatProvider`).
- 21 Automated Tests (Unit + Widget + Accessibility `meetsGuideline` 48dp) — **all passed**.
- `flutter analyze`: 0 errors (3 info style-only).

## 4. Tùy chọn tiếp theo
- Cấu hình `serverUrl` trong `ChatProvider` để bật AI thật (Gemini) thay vì demo offline.
- Lưu lịch sử chat vào `SharedPreferences` để mở lại sau.
- Thêm flashcard 3D, trích xuất 300 câu hỏi, build APK release.
