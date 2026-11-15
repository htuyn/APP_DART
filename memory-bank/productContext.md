# Product Context: flutter_quiz_bilingual

## 1. Vấn đề cần giải quyết
Người học thường gặp khó khăn khi ôn tập kiến thức bằng cả tiếng Việt và tiếng Anh, hoặc cần một ứng dụng nhẹ, hoạt động offline để:
- Làm bài trắc nghiệm nhanh theo chuyên đề/khối kiến thức.
- Hiểu rõ lý do đúng/sai qua phần giải thích (`explanation`) song ngữ.
- Tập trung ôn lại những câu hay làm sai thay vì phải làm lại toàn bộ từ đầu.

## 2. Trải nghiệm người dùng (UX) mong muốn
- **Chuyển đổi ngôn ngữ tức thì**: Người dùng có thể đổi giữa `Tiếng Việt` và `English` và lựa chọn này được ghi nhớ cho các lần mở app sau.
- **Làm bài trực quan**: Hiển thị câu hỏi, các lựa chọn đáp án, phản hồi trạng thái đúng/sai rõ ràng bằng màu sắc (`AppColors.success`, `AppColors.error`, `AppColors.warning`).
- **Theo dõi tiến độ**: Lưu lại điểm số, tổng số câu, thời gian làm bài (`timeSpentSeconds`) và thời điểm hoàn thành (`timestamp`).
- **Ôn tập câu sai**: Tự động ghi nhận các câu làm sai vào danh sách riêng và cho phép xóa khỏi danh sách khi người dùng đã nắm vững.
- **Giao diện thân thiện**: Hỗ trợ chế độ Sáng/Tối (Light/Dark theme) với Material 3, bo góc mềm mại (10-12dp) và nút bấm dễ chạm (chiều cao tối thiểu 48dp).
