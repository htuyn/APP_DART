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
* **Chuỗi ngày học (Streak):** Ghi nhận ngày có hoạt động học, số ngày liên tiếp và kỷ lục chuỗi dài nhất.
* **Bảo vệ chuỗi (Streak Freeze):** Mỗi tuần tự động cấp 1 lượt bảo vệ chuỗi theo tuần để bù 1 ngày lỡ học, duy trì chuỗi Streak mà không bị đứt đoạn.
* **Mục tiêu học mỗi ngày:** Tùy chọn mục tiêu học 5, 10 hoặc 20 câu mỗi ngày với vòng tròn tiến độ trực quan, tự động làm mới (`todayAnswered` reset về 0) khi bước sang ngày mới.
* **Thử thách hằng ngày:** Chọn cố định 5 câu hỏi từ ngân hàng theo ngày, hiển thị đáp án và giải thích; hoàn thành lần đầu trong ngày nhận thêm 50 XP thưởng.
* **Hệ thống huy hiệu & Thành tích:** Tự động mở khóa 9 huy hiệu theo số câu trả lời, streak, số bài thi và bài thi đạt 100%. Các ô huy hiệu chưa mở hiển thị thanh tiến độ trực quan dạng `hiện tại/mục tiêu`.
* **Popup mở khóa huy hiệu:** Khi mở khóa huy hiệu mới, hiển thị dialog chúc mừng với hiệu ứng phóng to (scale transition), rung nhẹ (haptic feedback) và nút chia sẻ thành tích (sao chép vào clipboard).
* **Điểm kinh nghiệm (XP) & Cấp độ / Danh hiệu:** Tích lũy XP khi trả lời câu hỏi (+10 XP câu đúng, +2 XP câu sai), nộp bài thi (+50 XP) và đạt điểm tuyệt đối (+100 XP). Tự động thăng cấp (Cấp 1 Người mới / Newcomer, Cấp 2-4 Người chăm học / Dedicated Learner, Cấp 5+ Bậc thầy / Master) kèm thanh tiến độ XP trực quan.
* **Gia sư AI:** Cung cấp hỗ trợ giải thích trong quá trình học thông qua luồng gia sư AI.
* **Giao diện và trợ năng:** Hỗ trợ giao diện sáng/tối (Material 3 Light/Dark mode), bố cục co giãn và vùng chạm tối thiểu 48dp cho các thành phần tương tác.

---

## 🏗️ Kiến Trúc và Cấu Trúc Mã Nguồn

Ứng dụng tổ chức theo các lớp `core`, `data`, `domain` và `presentation`, kết hợp Repository Pattern với package `provider` cho các luồng giao diện hiện tại. `lib/viewmodels/` chứa các ViewModel và logic bài thi riêng của dự án.

### 📁 Cấu trúc cây thư mục `lib/`

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart                 # Định nghĩa bảng màu chủ đạo (Material 3) cho ứng dụng ở cả chế độ sáng và tối
│   ├── l10n/
│   │   └── app_strings.dart                # Quản lý chuỗi văn bản song ngữ (Tiếng Việt & Tiếng Anh) cho giao diện
│   ├── navigation/
│   │   └── app_page_route.dart             # Định nghĩa các tuyến đường điều hướng (page routes) trong ứng dụng
│   ├── theme/
│   │   └── app_theme.dart                  # Định nghĩa ThemeData (Light & Dark mode) chuẩn Material 3
│   └── utils/
│       ├── clock.dart                      # Abstraction thời gian hệ thống, hỗ trợ mock thời gian khi kiểm thử
│       └── date_key.dart                   # Utility chuyển đổi DateTime thành chuỗi ngày YYYY-MM-DD chuẩn hóa
├── data/
│   ├── datasources/
│   │   ├── ai_tutor_datasource.dart        # Nguồn dữ liệu giả lập/kết nối dịch vụ Gia sư AI giải thích câu hỏi
│   │   ├── gamification_storage_datasource.dart # Nguồn dữ liệu lưu trữ ngoại tuyến thông tin Gamification qua SharedPreferences
│   │   ├── quiz_local_datasource.dart      # Nguồn dữ liệu đọc ngân hàng câu hỏi từ file JSON assets
│   │   └── quiz_storage_datasource.dart    # Nguồn dữ liệu lưu trữ tiến trình làm bài, câu sai và lịch sử thi
│   ├── models/
│   │   ├── gamification_model.dart         # Model lưu trữ điểm XP, chuỗi ngày, mục tiêu, lượt bảo vệ chuỗi và danh sách huy hiệu
│   │   ├── question_model.dart             # Model biểu diễn cấu trúc một câu hỏi trắc nghiệm song ngữ
│   │   ├── quiz_result_model.dart          # Model lưu trữ kết quả bài thi thử (điểm số, thời gian, đáp án)
│   │   └── thong_ke.dart                   # Model thống kê tiến độ học tập theo khối kiến thức và tổng quan
│   ├── repositories/
│   │   ├── gamification_repository_impl.dart # Triển khai repository quản lý dữ liệu gamification từ datasource
│   │   └── quiz_repository_impl.dart       # Triển khai repository quản lý dữ liệu trắc nghiệm và kết quả thi
│   ├── kho_bo_nho.dart                     # Kho lưu trữ bộ nhớ tạm / SharedPreferences trợ giúp cho ứng dụng
│   └── kho_du_lieu.dart                    # Lớp trợ giúp nạp và truy xuất dữ liệu câu hỏi trắc nghiệm
├── domain/
│   ├── gamification/
│   │   ├── badge_catalog.dart              # Định nghĩa danh mục 9 huy hiệu thành tích và tiêu chí mở khóa
│   │   └── gamification_engine.dart        # Core xử lý logic Streak, XP, Level, Streak Freeze, Thử thách hằng ngày và Huy hiệu
│   └── repositories/
│       ├── ai_repository.dart              # Interface trừu tượng cho repository Gia sư AI
│       ├── i_gamification_repository.dart  # Interface trừu tượng cho repository Gamification
│       └── quiz_repository.dart            # Interface trừu tượng cho repository Trắc nghiệm
├── presentation/
│   ├── providers/
│   │   ├── ai_tutor_provider.dart          # Provider quản lý trạng thái hội thoại và giải thích của Gia sư AI
│   │   ├── exam_provider.dart              # Provider quản lý trạng thái bài thi thử, đếm ngược thời gian và tính điểm
│   │   ├── gamification_provider.dart      # Provider quản lý trạng thái gamification, đồng bộ XP/Streak và thông báo mở huy hiệu
│   │   ├── language_provider.dart          # Provider quản lý chuyển đổi ngôn ngữ (Tiếng Việt / Tiếng Anh)
│   │   ├── quiz_provider.dart              # Provider quản lý danh sách câu hỏi, chế độ luyện tập và câu sai
│   │   ├── stats_provider.dart             # Provider tính toán và cung cấp dữ liệu thống kê tiến độ học
│   │   └── theme_provider.dart             # Provider quản lý chế độ giao diện sáng/tối (Light/Dark Theme)
│   ├── screens/
│   │   ├── achievements_screen.dart        # Màn hình thành tích: hiển thị Streak, cấp độ XP, chọn mục tiêu ngày và lưới huy hiệu
│   │   ├── exam_result_screen.dart         # Màn hình kết quả thi thử: hiển thị điểm số, thời gian và chi tiết đáp án/giải thích
│   │   ├── exam_screen.dart                # Màn hình giao diện thi thử trắc nghiệm có đếm ngược thời gian
│   │   ├── home_screen.dart                # Màn hình chính mới: tổng quan tiến độ, Streak card, menu luyện tập và thi thử
│   │   ├── practice_screen.dart            # Màn hình luyện tập trắc nghiệm theo khối kiến thức hoặc Thử thách hằng ngày
│   │   ├── stats_screen.dart               # Màn hình thống kê chi tiết tiến độ học tập và lịch sử làm bài
│   │   └── wrong_questions_screen.dart     # Màn hình sổ câu sai: xem và ôn tập lại các câu làm sai
│   └── widgets/
│       ├── ai_tutor_sheet.dart             # Bottom sheet hiển thị nội dung trao đổi và giải thích từ Gia sư AI
│       ├── badge_tile.dart                 # Widget hiển thị ô huy hiệu kèm thanh tiến độ hiện tại/mục tiêu
│       ├── badge_unlocked_dialog.dart      # Dialog chúc mừng mở khóa huy hiệu kèm hiệu ứng phóng to, rung và chia sẻ
│       ├── countdown_timer_widget.dart     # Widget hiển thị đồng hồ đếm ngược thời gian thi thử
│       ├── explanation_card.dart           # Widget hiển thị thẻ giải thích chi tiết đáp án đúng/sai
│       ├── language_button.dart            # Widget nút bấm chuyển đổi ngôn ngữ nhanh trên thanh ứng dụng
│       ├── option_tile.dart                # Widget hiển thị phương án lựa chọn đáp án trắc nghiệm
│       ├── responsive_body.dart            # Widget co giãn giao diện tương thích đa màn hình
│       ├── state_views.dart                # Widget hiển thị các trạng thái đang tải (loading) hoặc lỗi (error)
│       └── streak_card.dart                # Widget hiển thị thẻ Streak, cấp độ XP, mục tiêu ngày và bảo vệ chuỗi
├── screens/
│   ├── chon_de_screen.dart                 # Màn hình chọn đề thi thử (cấu hình giao diện ViewModels)
│   ├── chon_khoi_screen.dart               # Màn hình chọn khối kiến thức luyện tập (cấu hình giao diện ViewModels)
│   ├── cua_toi_screen.dart                 # Màn hình cá nhân / thành tích (cấu hình giao diện ViewModels)
│   └── trang_chu_screen.dart               # Màn hình trang chủ khởi chạy mặc định của ứng dụng
├── viewmodels/
│   ├── bai_thi_state.dart                  # Trạng thái dữ liệu bài thi (câu hỏi, câu trả lời, thời gian)
│   ├── bai_thi_vm.dart                     # ViewModel điều khiển logic làm bài thi thử
│   ├── dong_ho_vm.dart                     # ViewModel điều khiển đồng hồ đếm ngược thời gian thi
│   ├── logic_thi.dart                      # Logic tính toán điểm số và xếp loại kết quả bài thi
│   ├── ngon_ngu.dart                       # Enum định nghĩa các ngôn ngữ được hỗ trợ
│   ├── ngon_ngu_vm.dart                    # ViewModel quản lý thay đổi ngôn ngữ cũ
│   ├── providers.dart                      # Khai báo danh sách các Provider dùng trong ứng dụng
│   └── thong_ke_vm.dart                    # ViewModel xử lý logic dữ liệu thống kê
└── main.dart                               # Điểm khởi chạy ứng dụng (main), cấu hình MultiProvider, giao diện và định tuyến
```

### 📁 Cấu trúc cây thư mục `test/`

```text
test/
├── unit/
│   ├── ai_tutor_provider_test.dart         # Unit test cho Provider Gia sư AI
│   ├── exam_provider_test.dart             # Unit test cho Provider thi thử và đếm ngược thời gian
│   ├── gamification_engine_test.dart       # Unit test cho logic Streak, XP, Level, Freeze, Thử thách hằng ngày và Huy hiệu
│   ├── gamification_storage_test.dart      # Unit test cho lưu trữ dữ liệu Gamification qua SharedPreferences
│   ├── question_model_test.dart            # Unit test cho model câu hỏi trắc nghiệm và parse JSON
│   ├── quiz_provider_test.dart             # Unit test cho Provider trắc nghiệm và sổ câu sai
│   └── stats_provider_test.dart            # Unit test cho Provider tính toán thống kê
├── viewmodels/
│   ├── bai_thi_vm_test.dart                # Unit test cho ViewModel bài thi thử
│   ├── dong_ho_vm_test.dart                # Unit test cho ViewModel đồng hồ đếm ngược
│   ├── logic_thi_test.dart                 # Unit test cho logic tính điểm bài thi
│   └── ngon_ngu_vm_test.dart               # Unit test cho ViewModel quản lý ngôn ngữ
├── widget/
│   ├── accessibility_test.dart             # Widget test kiểm tra vùng chạm tối thiểu 48x48dp theo tiêu chuẩn Accessibility
│   └── achievements_screen_test.dart       # Widget test cho màn hình Thành tích (Streak, mục tiêu ngày, huy hiệu, XP)
└── widget_test.dart                        # Test tổng quan giao diện khởi chạy ứng dụng
```

Màn hình khởi chạy hiện tại là `screens/trang_chu_screen.dart` (`TrangChuScreen`).

---

## 💾 Lưu Trữ Dữ Liệu (Data Storage)

* **Ngân hàng câu hỏi:** Lưu trữ ngoại tuyến tại `assets/data/questions.json` (đóng gói cùng ứng dụng, hoạt động 100% offline).
* **Tiến trình câu sai & Lịch sử thi & Gamification:** Lưu tại `SharedPreferences` trên thiết bị người dùng.
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

Chạy bộ kiểm thử tự động (gồm **54 tests** - 100% passed) bằng `flutter test`. Các nhóm file test trong `test/` bao gồm:

* **Unit tests (`test/unit/`):** Parse dữ liệu & tương thích JSON cũ, nghiệp vụ bài thi, lưu trữ `SharedPreferences`, chuỗi ngày học Streak, bảo vệ chuỗi Streak Freeze theo tuần, tính toán XP/cấp độ (Level), Thử thách hằng ngày và tiêu chí mở khóa 9 huy hiệu.
* **ViewModel tests (`test/viewmodels/`):** Kiểm thử nghiệp vụ bài thi thử, ViewModel đồng hồ đếm ngược thời gian, logic xếp loại điểm thi và chuyển đổi ngôn ngữ ViewModel.
* **Widget tests (`test/widget/` và `test/widget_test.dart`):** Khởi tạo ứng dụng, màn hình Thành tích (vòng tròn tiến độ mục tiêu 5/10/20 câu, ô huy hiệu kèm thanh tiến độ `hiện tại/mục tiêu`, thanh XP), chuyển đổi ngôn ngữ và tương tác người dùng.
* **Accessibility tests (`test/widget/accessibility_test.dart`):** Kiểm tra vùng chạm tối thiểu `48x48dp` (`androidTapTargetGuideline`).

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
* `GamificationEngine` xử lý ngày học liên tiếp, bảo vệ chuỗi Streak Freeze theo tuần, cộng điểm XP, thăng cấp, Thử thách hằng ngày và điều kiện mở huy hiệu; `GamificationProvider` giữ tiến độ, phối hợp với luồng quiz/thi và cung cấp huy hiệu mới mở khóa cho giao diện.
* Tiến độ gamification được lưu cục bộ dưới khóa `gamification_v1` (tương thích ngược an toàn khi nạp dữ liệu cũ thiếu `daily_goal` hoặc `xp`); `Clock` cho phép kiểm thử logic đổi ngày.
* `BadgeCatalog` định nghĩa 9 huy hiệu; `AchievementsScreen`, `StreakCard`, `BadgeTile` và `BadgeUnlockedDialog` hiển thị thành tích, vòng tròn tiến độ mục tiêu, thanh XP và thông báo mở khóa kèm hiệu ứng & nút chia sẻ.

