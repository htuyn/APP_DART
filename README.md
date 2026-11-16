# Flutter Bilingual Quiz (Ôn Tập Trắc Nghiệm Song Ngữ)

Dự án cuối kỳ học phần **INT1449 - Lập trình di động**.  
**Chủ đề 32:** Ôn tập trắc nghiệm song ngữ dựa trên ngân hàng 300 câu hỏi trắc nghiệm Flutter.

---

## 🌟 Tính Năng Nổi Bật

### 1. Tính Năng Tối Thiểu (Đạt chuẩn Rubric)
* **Nạp 300 câu từ JSON:** Dữ liệu chuẩn hóa 20 khối kiến thức Flutter, lưu tại `assets/data/questions.json`.
* **Chế độ Luyện Tập (Practice Mode):**
  * Luyện tự do theo từng khối kiến thức (hoặc tất cả các khối).
  * Hiển thị giải thích chi tiết ngay sau khi chọn đáp án.
* **Chế độ Thi Thử (Mock Exam):**
  * Trộn ngẫu nhiên câu hỏi từ ngân hàng đề.
  * Tự động chấm điểm, phân loại Đạt / Chưa đạt, hiển thị thời gian làm bài.
* **Làm Lại Câu Sai (Wrong Questions Book):**
  * Tự động lưu các câu người dùng trả lời sai vào bộ nhớ máy.
  * Cho phép luyện riêng các câu sai; khi làm đúng sẽ tự động gỡ khỏi danh sách câu sai.
* **Thống Kê Theo Khối (Knowledge Statistics):**
  * Biểu đồ tiến độ và tỉ lệ chính xác trên toàn bộ 20 khối kiến thức.
  * Bấm vào từng khối để luyện tập trực tiếp khối kiến thức còn yếu.
  * Lưu trữ lịch sử tất cả các lần thi thử.

### 2. Tính Năng Mở Rộng
* **Đa Ngôn Ngữ Song Ngữ (Bilingual VI / EN):**
  * Chuyển đổi ngôn ngữ toàn bộ giao diện chỉ với 1 chạm trên AppBar.
  * **Tính năng lật ngữ cảnh:** Cho phép đổi ngôn ngữ Tiếng Việt / Tiếng Anh ngay trên từng câu hỏi khi đang làm bài.
* **Đồng Hồ Đếm Ngược (Countdown Timer):**
  * Bộ đếm giờ đếm ngược thời gian làm bài trong phòng thi.
  * Tự động cảnh báo khi sắp hết giờ và tự động thu bài khi hết thời gian.

---

## 🏗️ Kiến Trúc Ứng Dụng (Architecture)

Ứng dụng tuân thủ mô hình **Clean Architecture & Repository Pattern**:

```
lib/
├── core/                  # Constants, Theme Material 3, Localization
├── data/
│   ├── datasources/       # QuizLocalDataSource (JSON), QuizStorageDataSource (Prefs)
│   ├── models/            # QuestionModel, QuizResultModel
│   └── repositories/      # QuizRepositoryImpl
├── domain/
│   └── repositories/      # IQuizRepository (Trừu tượng, dễ Mock khi test)
└── presentation/
    ├── providers/         # State Management (Provider: Quiz, Exam, Stats, Language)
    ├── screens/           # Home, Practice, Exam, ExamResult, WrongQuestions, Stats
    └── widgets/           # OptionTile (>= 48dp), CountdownTimer, StateViews (Loading, Error, Empty)
```

---

## 💾 Lưu Trữ Dữ Liệu (Data Storage)

* **Ngân hàng câu hỏi:** Lưu trữ ngoại tuyến tại `assets/data/questions.json` (đóng gói cùng ứng dụng, hoạt động 100% offline).
* **Tiến trình câu sai & Lịch sử thi:** Lưu tại `SharedPreferences` trên thiết bị người dùng.
* **Bảo mật:** Ứng dụng **không chứa bất kỳ API Key hay mật khẩu nào**. Không yêu cầu quyền hệ thống nguy hiểm.

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng (Dưới 15 Phút)

### Yêu Cầu Môi Trường
* Flutter SDK $\ge 3.13.0$
* Dart SDK $\ge 3.0.0$

### Các Bước Thực Hiện
1. Tải dependencies:
   ```bash
   flutter pub get
   ```
2. Kiểm tra chất lượng mã nguồn (phân tích tĩnh):
   ```bash
   flutter analyze
   ```
   *(Kết quả: `No issues found!`)*

3. Chạy kiểm thử tự động:
   ```bash
   flutter test
   ```
   *(Bao gồm 17 test kiểm tra logic, widget và trợ năng)*

4. Khởi chạy ứng dụng:
   ```bash
   flutter run
   ```

---

## 🧪 Kiểm Thử (Automated Tests)

Bộ kiểm thử gồm **17 test** đạt chuẩn Rubric xuất sắc:
* **Unit Tests:** Kiểm tra parse JSON, logic tính điểm, lọc câu hỏi theo khối, bộ đếm timer, lưu/xóa câu sai.
* **Widget Tests:** Kiểm tra hiển thị màn hình chính, chuyển đổi ngôn ngữ linh hoạt.
* **Accessibility Test:** Kiểm tra vùng chạm nút bấm đạt chuẩn tối thiểu `48x48dp` với `androidTapTargetGuideline`.

---

## 🤖 Mục "Dùng AI" (Tuân thủ Quy Định Học Phần)

* **Công cụ hỗ trợ:** Trợ lý AI (Google DeepMind Antigravity).
* **Phạm vi hỗ trợ:**
  * Tư vấn cấu trúc kiến trúc Clean Architecture và State Management cho Flutter.
  * Hỗ trợ sinh bộ khung kiểm thử Unit Test & Accessibility Test đạt chuẩn Rubric.
  * Tối ưu hóa giao diện Material 3 đáp ứng tiêu chuẩn Accessibility 48dp.
* Toàn bộ mã nguồn đã được nhóm rà soát, kiểm thử thủ công và tự động trên máy thật.

---

## 🧩 Phần Bổ Sung: State Management & Kiểm Thử

### Model và Kho Dữ Liệu

* Đồng bộ `KhoDuLieu` và `KhoBoNho` với các model hiện có: `QuestionModel`, `QuizResultModel` và `BlockStat`.
* Kho trong bộ nhớ hỗ trợ danh sách câu hỏi, sổ câu sai, lịch sử thi, điểm cao nhất, thống kê theo khối và ngôn ngữ.

### ViewModels Riverpod

* `BaiThiVm`: quản lý luyện tập, thi thử và làm lại câu sai; lọc/trộn câu hỏi, ghi đáp án, chấm điểm, cập nhật sổ câu sai và lưu kết quả thi thử.
* `DongHoVm`: quản lý đồng hồ thi thử, tạm dừng/tiếp tục và phát trạng thái hết giờ để tự nộp bài.
* `NgonNguVm`: tải, đổi và lưu lựa chọn tiếng Việt/tiếng Anh bằng SharedPreferences.
* `providers.dart`: cung cấp repository, ngân hàng câu hỏi, sổ câu sai, lịch sử, thống kê và mã ngôn ngữ.
* `logic_thi.dart` và `bai_thi_state.dart`: chứa các hàm nghiệp vụ thuần và trạng thái phiên làm bài.

### Test cho ViewModels

* Bổ sung test lọc/trộn/chấm câu, các chế độ làm bài, đồng hồ và lưu lựa chọn ngôn ngữ trong `test/viewmodels/`.
* Kết quả kiểm tra hiện tại: `flutter analyze` — `No issues found`; `flutter test` — **34 test passed**.

### Ghi Chú Tích Hợp

Các ViewModels Riverpod đã có thể được kiểm thử độc lập. `main.dart` hiện vẫn khởi tạo giao diện bằng package `provider`; để giao diện sử dụng các provider Riverpod mới, ứng dụng cần được tích hợp `ProviderScope` và chuyển phần giao diện tương ứng sang đọc Riverpod.
