# STRICT AI CODING RULES

## 1. READ BEFORE CODE
- Tự động đọc `AGENTS.md` trước khi thực hiện công việc.
- Luôn đọc `memory-bank/` để hiểu dự án, kiến trúc, tiến độ và các quyết định trước đó.
- Đọc các file code và tài liệu liên quan trực tiếp đến yêu cầu.
- Không code khi chưa hiểu cách hệ thống hiện tại hoạt động.
- Không tự suy đoán khi chưa kiểm chứng được thông tin.

## 2. MODIFY ONLY WHAT IS NECESSARY
- Chỉ sửa những file thực sự cần thiết để hoàn thành yêu cầu.
- Không tự ý sửa, tối ưu, refactor hoặc viết lại code ngoài phạm vi yêu cầu.
- Không thay đổi kiến trúc, cấu trúc thư mục, database hoặc công nghệ hiện tại nếu chưa được cho phép.
- Ưu tiên tận dụng code và chức năng đã có.
- Không tạo file, class, function hoặc dependency không cần thiết.
- Không xóa hoặc làm ảnh hưởng đến chức năng đang hoạt động.
- Giữ nguyên những phần không liên quan đến yêu cầu.

## 3. ACCURACY
- Hiểu đúng yêu cầu trước khi thực hiện.
- Tìm nguyên nhân gốc rễ trước khi sửa lỗi.
- Không bịa thông tin, không tự tạo API hoặc chức năng không tồn tại.
- Nếu chưa rõ hoặc có nhiều cách thực hiện ảnh hưởng đến kiến trúc, phải hỏi lại.
- Ưu tiên giải pháp đơn giản, chính xác và ít thay đổi nhất.

## 4. VERIFY AFTER CODING
- Kiểm tra toàn bộ phần code đã thay đổi.
- Chạy các lệnh test, build hoặc kiểm tra phù hợp với dự án.
- Kiểm tra lỗi phát sinh và ảnh hưởng đến chức năng hiện có.
- Kiểm tra Git diff để đảm bảo không sửa nhầm file.
- Không tuyên bố hoàn thành nếu chưa kiểm chứng.
- Không tự ý ghi đè hoặc xóa thay đổi có sẵn của người dùng.

## 5. MEMORY BANK — MANDATORY
- Trước khi làm: tự động đọc các tài liệu liên quan trong `memory-bank/`.
- Trong khi làm: tuân thủ các quyết định và kiến trúc đã được ghi nhận.
- Sau khi làm: tự động cập nhật Memory Bank theo kết quả thực tế.
- Cập nhật `progress.md` khi có thay đổi tiến độ.
- Chỉ cập nhật `architecture.md` khi kiến trúc thực sự thay đổi.
- Ghi nhận các quyết định kỹ thuật, thay đổi quan trọng và vấn đề còn tồn đọng.
- Không ghi thông tin chưa được xác minh.
- Không xóa lịch sử hoặc ghi đè nội dung cũ không liên quan.
- Nếu chưa có Memory Bank, kiểm tra cấu trúc dự án trước khi tạo.

## 6. ABSOLUTE RULES
1. Đọc trước khi sửa.
2. Hiểu trước khi code.
3. Chỉ sửa đúng phạm vi yêu cầu.
4. Không tự ý thay đổi những gì không được yêu cầu.
5. Kiểm tra sau khi sửa.
6. Tự động cập nhật Memory Bank sau khi hoàn thành.

**WORKFLOW BẮT BUỘC:**

`READ → UNDERSTAND → PLAN → MODIFY → VERIFY → UPDATE MEMORY BANK → REPORT`

Ưu tiên cao nhất: **Chính xác > An toàn > Giữ nguyên kiến trúc > Đúng phạm vi > Hoàn thành yêu cầu.**

Không được tự ý mở rộng phạm vi công việc chỉ vì cho rằng có thể cải thiện dự án.
