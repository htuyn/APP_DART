# Project Brief: flutter_quiz_bilingual

## 1. Tổng quan
- **Tên dự án**: `flutter_quiz_bilingual`
- **Loại ứng dụng**: Ứng dụng trắc nghiệm đa nền tảng (Flutter) hỗ trợ song ngữ **Tiếng Việt (vi)** và **Tiếng Anh (en)**.
- **Mục tiêu**: Cung cấp công cụ luyện thi / ôn tập trắc nghiệm theo từng khối kiến thức (`block`), hỗ trợ chuyển đổi ngôn ngữ linh hoạt, xem giải thích chi tiết, theo dõi lịch sử làm bài và ôn tập lại các câu trả lời sai.

## 2. Yêu cầu cốt lõi
1. **Song ngữ (Bilingual VI/EN)**:
   - Hỗ trợ chuyển đổi ngôn ngữ toàn ứng dụng giữa Tiếng Việt và Tiếng Anh (`LanguageProvider`).
   - Dữ liệu câu hỏi, đáp án, tên khối kiến thức và giải thích đều hỗ trợ 2 ngôn ngữ (`LocalizedText`).
2. **Ngân hàng câu hỏi Offline**:
   - Đọc dữ liệu câu hỏi từ file JSON cục bộ (`assets/data/questions.json`).
   - Phân loại câu hỏi theo `block_id` / `block_name` và cấp độ (`level`, mặc định `'Nhớ'`).
3. **Lưu trữ cục bộ (Local Persistence)**:
   - Lưu danh sách ID các câu hỏi trả lời sai (`wrong_question_ids`) để người dùng ôn tập lại.
   - Lưu lịch sử kết quả các lần làm bài (`quiz_history`).
   - Lưu tùy chọn ngôn ngữ đã chọn (`selected_language`).
4. **Giao diện chuẩn Material 3**:
   - Hỗ trợ Light Mode và Dark Mode (`AppTheme`).
   - Đảm bảo khả năng tiếp cận (tap target tối thiểu 48dp cho nút bấm).

## 3. Phạm vi hiện tại
- Dự án đang trong giai đoạn xây dựng nền tảng (Core, Domain, Data layer và LanguageProvider đã có; UI screens, Quiz state management và file dữ liệu `questions.json` đang chờ triển khai).
