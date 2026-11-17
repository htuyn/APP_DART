# Flutter Bilingual Quiz (Ôn Tập Trắc Nghiệm Song Ngữ)

Dự án cuối kỳ học phần **INT1449 - Lập trình di động**.  
**Chủ đề 32:** Ôn tập trắc nghiệm song ngữ dựa trên ngân hàng 300 câu hỏi trắc nghiệm Flutter.

---

## 🌟 Tính Năng

* **Ngân hàng câu hỏi Flutter:** Nạp câu hỏi song ngữ từ `assets/data/questions.json`, phân nhóm theo khối kiến thức để luyện tập.
* **Luyện tập:** Luyện theo khối hoặc làm lại sổ câu sai; hiển thị đáp án và giải thích, cập nhật danh sách câu sai theo kết quả.
* **Thi thử:** Chọn đề, trả lời câu hỏi có giới hạn thời gian, tự động nộp khi hết giờ và xem điểm, thời gian, đáp án cùng phần giải thích.
* **Thống kê:** Xem tiến độ theo khối, độ chính xác và lịch sử kết quả thi.
* **Tiếng Việt và English:** Chuyển đổi ngôn ngữ giao diện và nội dung câu hỏi.
* **Chuỗi ngày học (Streak):** Ghi nhận ngày có hoạt động học, số ngày liên tiếp và kỷ lục chuỗi học dài nhất.
* **Hệ thống huy hiệu:** Tự mở khóa huy hiệu theo số câu trả lời, ngày học liên tiếp, số bài thi và bài thi đạt điểm tuyệt đối. Trang Thành tích hiển thị tiến độ và ngày nhận huy hiệu; khi thi mở khóa huy hiệu mới, ứng dụng hiện hộp thoại chúc mừng.
* **Gia sư AI:** Cung cấp hỗ trợ giải thích trong quá trình học thông qua luồng gia sư AI.
* **Giao diện và trợ năng:** Hỗ trợ giao diện sáng/tối, bố cục co giãn và vùng chạm tối thiểu 48dp cho các thành phần tương tác.

---

## 🏗️ Kiến Trúc và Cấu Trúc `lib/`

Ứng dụng tổ chức theo các lớp `core`, `data`, `domain` và `presentation`, kết hợp Repository Pattern với package `provider` cho các luồng giao diện hiện tại. `lib/viewmodels/` chứa các ViewModel và logic bài thi riêng của dự án.

```text
lib/
├── core/
│   ├── constants/app_colors.dart
│   ├── l10n/app_strings.dart
│   ├── navigation/app_page_route.dart
│   ├── theme/app_theme.dart
│   └── utils/
│       ├── clock.dart
│       └── date_key.dart
├── data/
│   ├── datasources/
│   │   ├── ai_tutor_datasource.dart
│   │   ├── gamification_storage_datasource.dart
│   │   ├── quiz_local_datasource.dart
│   │   └── quiz_storage_datasource.dart
│   ├── models/
│   │   ├── gamification_model.dart
│   │   ├── question_model.dart
│   │   ├── quiz_result_model.dart
│   │   └── thong_ke.dart
│   ├── repositories/
│   │   ├── gamification_repository_impl.dart
│   │   └── quiz_repository_impl.dart
│   ├── kho_bo_nho.dart
│   └── kho_du_lieu.dart
├── domain/
│   ├── gamification/
│   │   ├── badge_catalog.dart
│   │   └── gamification_engine.dart
│   └── repositories/
│       ├── ai_repository.dart
│       ├── i_gamification_repository.dart
│       └── quiz_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── ai_tutor_provider.dart
│   │   ├── exam_provider.dart
│   │   ├── gamification_provider.dart
│   │   ├── language_provider.dart
│   │   ├── quiz_provider.dart
│   │   ├── stats_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── achievements_screen.dart
│   │   ├── exam_result_screen.dart
│   │   ├── exam_screen.dart
│   │   ├── home_screen.dart
│   │   ├── practice_screen.dart
│   │   ├── stats_screen.dart
│   │   └── wrong_questions_screen.dart
│   └── widgets/
│       ├── ai_tutor_sheet.dart
│       ├── badge_tile.dart
│       ├── badge_unlocked_dialog.dart
│       ├── countdown_timer_widget.dart
│       ├── explanation_card.dart
│       ├── language_button.dart
│       ├── option_tile.dart
│       ├── responsive_body.dart
│       ├── state_views.dart
│       └── streak_card.dart
├── screens/
│   ├── chon_de_screen.dart
│   ├── chon_khoi_screen.dart
│   ├── cua_toi_screen.dart
│   └── trang_chu_screen.dart
├── viewmodels/
│   ├── bai_thi_state.dart
│   ├── bai_thi_vm.dart
│   ├── dong_ho_vm.dart
│   ├── logic_thi.dart
│   ├── ngon_ngu.dart
│   ├── ngon_ngu_vm.dart
│   ├── providers.dart
│   └── thong_ke_vm.dart
└── main.dart
```

Màn hình khởi chạy hiện tại là `screens/trang_chu_screen.dart` (`TrangChuScreen`).

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
   *(Chạy toàn bộ unit test, widget test và kiểm thử trợ năng trong thư mục `test/`.)*

4. Khởi chạy ứng dụng:
   ```bash
   flutter run
   ```

---

## 🧪 Kiểm Thử

Chạy bộ kiểm thử bằng `flutter test`. Các nhóm test hiện có bao gồm:

* **Unit tests:** Parse dữ liệu, nghiệp vụ bài thi, ViewModels, đồng hồ, lưu trữ, streak và điều kiện mở khóa huy hiệu.
* **Widget tests:** Màn hình chính, Thành tích, chuyển đổi ngôn ngữ và các thành phần giao diện.
* **Accessibility tests:** Kiểm tra vùng chạm tối thiểu `48x48dp`.

---

## 🤖 Mục "Dùng AI" (Tuân thủ Quy Định Học Phần)

* **Công cụ hỗ trợ:** Trợ lý AI (Google DeepMind Antigravity).
* **Phạm vi hỗ trợ:**
  * Tư vấn cấu trúc kiến trúc Clean Architecture và State Management cho Flutter.
  * Hỗ trợ sinh bộ khung kiểm thử Unit Test & Accessibility Test đạt chuẩn Rubric.
  * Tối ưu hóa giao diện Material 3 đáp ứng tiêu chuẩn Accessibility 48dp.
* Toàn bộ mã nguồn đã được nhóm rà soát, kiểm thử thủ công và tự động trên máy thật.

---

## 🧠 State Management và Gamification

* Giao diện hiện khởi tạo các `ChangeNotifier` bằng package `provider` trong `main.dart`, gồm quiz, thi thử, thống kê, ngôn ngữ, giao diện, gia sư AI và gamification.
* `lib/viewmodels/` chứa các ViewModel/logic bài thi, đồng hồ, ngôn ngữ và thống kê; `bai_thi_state.dart` cùng `logic_thi.dart` biểu diễn trạng thái và nghiệp vụ bài thi.
* `GamificationEngine` xử lý ngày học liên tiếp và điều kiện mở huy hiệu; `GamificationProvider` giữ tiến độ, phối hợp với luồng quiz/thi và cung cấp huy hiệu mới mở khóa cho giao diện.
* Tiến độ gamification được lưu cục bộ dưới khóa `gamification_v1`; `Clock` cho phép kiểm thử logic đổi ngày.
* `BadgeCatalog` định nghĩa các huy hiệu; `AchievementsScreen`, `StreakCard`, `BadgeTile` và `BadgeUnlockedDialog` hiển thị thành tích và thông báo mở khóa.
