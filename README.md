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
* **Chứng chỉ & Chứng nhận Blockchain (On-Chain Certificates):** Tích hợp hợp đồng thông minh (Smart Contract) trên mạng Ethereum Sepolia. Tự động kiểm tra điều kiện đủ (Eligibility) cho các thành tích (Điểm tuyệt đối, Chuỗi 7 ngày, Flutter Master, Khám phá kiến thức) và Tiến độ khóa học (Hoàn thành % câu hỏi). Hỗ trợ nhập địa chỉ ví recipient, tạo yêu cầu cấp chứng chỉ (Pending), băm SHA-256 dữ liệu xác thực (`achievementHash` / `certificateId`), đồng bộ & xác minh trạng thái từ Blockchain (Confirmed / Revoked) qua JSON-RPC, tra cứu trực tiếp giao dịch và sự kiện `CertificateIssued` trên Sepolia Etherscan.
* **Giao diện và trợ năng:** Hỗ trợ giao diện sáng/tối (Material 3 Light/Dark mode), bố cục co giãn và vùng chạm tối thiểu 48dp cho các thành phần tương tác.

---

## 🏗️ Kiến Trúc và Cấu Trúc Mã Nguồn

Ứng dụng tổ chức theo các lớp `core`, `data`, `domain` và `presentation`, kết hợp Repository Pattern với package `provider` cho các luồng giao diện hiện tại. `lib/viewmodels/` chứa các ViewModel và logic bài thi riêng của dự án.

### 📁 Cấu trúc cây thư mục `lib/`

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                 # Định nghĩa bảng màu chủ đạo (Material 3) cho ứng dụng ở cả chế độ sáng và tối
│   │   └── blockchain_config.dart          # Cấu hình địa chỉ hợp đồng Smart Contract, Sepolia RPC URL và Etherscan URL
│   ├── l10n/
│   │   └── app_strings.dart                # Quản lý chuỗi văn bản song ngữ (Tiếng Việt & Tiếng Anh) cho giao diện
│   ├── navigation/
│   │   └── app_page_route.dart             # Định nghĩa các tuyến đường điều hướng (page routes) trong ứng dụng
│   ├── theme/
│   │   └── app_theme.dart                  # Định nghĩa ThemeData (Light & Dark mode) chuẩn Material 3
│   └── utils/
│       ├── achievement_hasher.dart         # Chuẩn hóa dữ liệu thành tích và băm SHA-256 ổn định
│       ├── certificate_hasher.dart         # Utility khởi tạo certificateId và achievementHash chuẩn hóa
│       ├── clock.dart                      # Abstraction thời gian hệ thống, hỗ trợ mock thời gian khi kiểm thử
│       └── date_key.dart                   # Utility chuyển đổi DateTime thành chuỗi ngày YYYY-MM-DD chuẩn hóa
├── data/
│   ├── datasources/
│   │   ├── ai_tutor_datasource.dart        # Nguồn dữ liệu giả lập/kết nối dịch vụ Gia sư AI giải thích câu hỏi
│   │   ├── blockchain_storage_datasource.dart # Nguồn dữ liệu lưu trữ danh sách chứng chỉ và địa chỉ ví cục bộ qua SharedPreferences
│   │   ├── course_progress_storage_datasource.dart # Nguồn dữ liệu lưu trữ tiến độ khóa học
│   │   ├── ethereum_blockchain_datasource.dart # Nguồn dữ liệu đọc hợp đồng thông minh qua Ethereum JSON-RPC và tra cứu event log
│   │   ├── gamification_storage_datasource.dart # Nguồn dữ liệu lưu trữ ngoại tuyến thông tin Gamification qua SharedPreferences
│   │   ├── quiz_local_datasource.dart      # Nguồn dữ liệu đọc ngân hàng câu hỏi từ file JSON assets
│   │   └── quiz_storage_datasource.dart    # Nguồn dữ liệu lưu trữ tiến trình làm bài, câu sai và lịch sử thi
│   ├── models/
│   │   ├── achievement_certificate_model.dart # Model biểu diễn chứng chỉ blockchain, trạng thái pending/confirmed/revoked và txHash
│   │   ├── course_progress_model.dart      # Model lưu trữ tiến độ hoàn thành bài học và tiêu chuẩn cấp chứng chỉ khóa học
│   │   ├── gamification_model.dart         # Model lưu trữ điểm XP, chuỗi ngày, mục tiêu, lượt bảo vệ chuỗi và danh sách huy hiệu
│   │   ├── question_model.dart             # Model biểu diễn cấu trúc một câu hỏi trắc nghiệm song ngữ
│   │   ├── quiz_result_model.dart          # Model lưu trữ kết quả bài thi thử (điểm số, thời gian, đáp án)
│   │   └── thong_ke.dart                   # Model thống kê tiến độ học tập theo khối kiến thức và tổng quan
│   ├── repositories/
│   │   ├── blockchain_repository_impl.dart # Triển khai repository chứng chỉ blockchain, quản lý cache và đối chiếu dữ liệu on-chain
│   │   ├── gamification_repository_impl.dart # Triển khai repository quản lý dữ liệu gamification từ datasource
│   │   └── quiz_repository_impl.dart       # Triển khai repository quản lý dữ liệu trắc nghiệm và kết quả thi
│   ├── kho_bo_nho.dart                     # Kho lưu trữ bộ nhớ tạm / SharedPreferences trợ giúp cho ứng dụng
│   └── kho_du_lieu.dart                    # Lớp trợ giúp nạp và truy xuất dữ liệu câu hỏi trắc nghiệm
├── domain/
│   ├── blockchain/
│   │   ├── achievement_verifier.dart       # Lớp xác minh băm thành tích và đối chiếu dữ liệu
│   │   └── certificate_eligibility_engine.dart # Core xử lý logic kiểm tra điều kiện đủ nhận chứng chỉ thành tích và khóa học
│   ├── gamification/
│   │   ├── badge_catalog.dart              # Định nghĩa danh mục 9 huy hiệu thành tích và tiêu chí mở khóa
│   │   └── gamification_engine.dart        # Core xử lý logic Streak, XP, Level, Streak Freeze, Thử thách hằng ngày và Huy hiệu
│   └── repositories/
│       ├── ai_repository.dart              # Interface trừu tượng cho repository Gia sư AI
│       ├── i_blockchain_repository.dart    # Interface trừu tượng cho repository quản lý chứng chỉ blockchain
│       ├── i_gamification_repository.dart  # Interface trừu tượng cho repository Gamification
│       └── quiz_repository.dart            # Interface trừu tượng cho repository Trắc nghiệm
├── presentation/
│   ├── providers/
│   │   ├── ai_tutor_provider.dart          # Provider quản lý trạng thái hội thoại và giải thích của Gia sư AI
│   │   ├── blockchain_provider.dart        # Provider quản lý trạng thái chứng chỉ, địa chỉ ví, yêu cầu cấp và đồng bộ xác minh từ blockchain
│   │   ├── course_progress_provider.dart   # Provider quản lý tiến độ hoàn thành khóa học và liên kết điều kiện nhận chứng chỉ
│   │   ├── exam_provider.dart              # Provider quản lý trạng thái bài thi thử, đếm ngược thời gian và tính điểm
│   │   ├── gamification_provider.dart      # Provider quản lý trạng thái gamification, đồng bộ XP/Streak và thông báo mở huy hiệu
│   │   ├── language_provider.dart          # Provider quản lý chuyển đổi ngôn ngữ (Tiếng Việt / Tiếng Anh)
│   │   ├── quiz_provider.dart              # Provider quản lý danh sách câu hỏi, chế độ luyện tập và câu sai
│   │   ├── stats_provider.dart             # Provider tính toán và cung cấp dữ liệu thống kê tiến độ học
│   │   └── theme_provider.dart             # Provider quản lý chế độ giao diện sáng/tối (Light/Dark Theme)
│   ├── screens/
│   │   ├── achievements_screen.dart        # Màn hình thành tích: hiển thị Streak, cấp độ XP, chọn mục tiêu ngày và lưới huy hiệu
│   │   ├── blockchain_certificates_screen.dart # Màn hình danh sách chứng chỉ blockchain, quản lý ví và theo dõi điều kiện nhận
│   │   ├── certificate_detail_screen.dart  # Màn hình chi tiết chứng chỉ: hiển thị Certificate ID, achievement hash, QR/trạng thái và link Sepolia Explorer
│   │   ├── certificates_screen.dart        # Màn hình giao diện chứng chỉ tổng hợp
│   │   ├── course_progress_screen.dart     # Màn hình theo dõi tiến độ hoàn thành các khối bài học và khóa học
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
│       ├── blockchain_status_badge.dart    # Widget hiển thị badge trạng thái chứng chỉ (Chờ cấp / Đã xác thực / Bị thu hồi)
│       ├── certificate_card.dart           # Widget thẻ hiển thị tóm tắt thông tin chứng chỉ
│       ├── certificate_type_badge.dart     # Widget badge phân loại chứng chỉ (Thành tích / Hoàn thành khóa học)
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
│   ├── achievement_hasher_test.dart        # Unit test cho logic băm SHA-256 dữ liệu thành tích
│   ├── ai_tutor_provider_test.dart         # Unit test cho Provider Gia sư AI
│   ├── blockchain_provider_test.dart       # Unit test cho Provider chứng chỉ blockchain và xử lý trạng thái
│   ├── blockchain_repository_test.dart     # Unit test cho Repository quản lý chứng chỉ và cache
│   ├── certificate_eligibility_test.dart   # Unit test cho engine kiểm tra điều kiện đủ cấp chứng chỉ
│   ├── course_progress_test.dart           # Unit test cho tính toán tiến độ khóa học
│   ├── ethereum_blockchain_datasource_test.dart # Unit test cho datasource kết nối RPC Ethereum Sepolia
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
│   ├── achievements_screen_test.dart       # Widget test cho màn hình Thành tích (Streak, mục tiêu ngày, huy hiệu, XP)
│   ├── blockchain_certificates_screen_test.dart # Widget test cho màn hình danh sách chứng chỉ blockchain và nhập ví
│   └── certificate_detail_screen_test.dart # Widget test cho màn hình chi tiết chứng chỉ, hiển thị hash và xác minh on-chain
└── widget_test.dart                        # Test tổng quan giao diện khởi chạy ứng dụng
```

Màn hình khởi chạy hiện tại là `screens/trang_chu_screen.dart` (`TrangChuScreen`).

---

## 💾 Lưu Trữ Dữ Liệu (Data Storage)

* **Ngân hàng câu hỏi:** Lưu trữ ngoại tuyến tại `assets/data/questions.json` (đóng gói cùng ứng dụng, hoạt động 100% offline).
* **Tiến trình câu sai & Lịch sử thi & Gamification:** Lưu tại `SharedPreferences` trên thiết bị người dùng.
* **Chứng chỉ Blockchain & Tiến độ khóa học:** Dữ liệu chứng chỉ (địa chỉ ví, certificate ID, hash, trạng thái cache local) và tiến độ khóa học được lưu trữ tại `SharedPreferences`. Trạng thái xác thực chính thức được truy vấn đọc trực tiếp từ hợp đồng thông minh trên mạng Ethereum Sepolia.
* **Bảo mật:** Ứng dụng **không chứa bất kỳ API Key hay private key nào**. Không yêu cầu quyền hệ thống nguy hiểm.

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

Chạy toàn bộ bộ kiểm thử bằng `flutter test` (tất cả đều pass):

* **Unit tests (`test/unit/`):** Parse dữ liệu, thống kê, gamification, deterministic certificate hashing, các biên eligibility, đồng bộ repository với pending/confirmed/revoked và tiến độ khóa học.
* **ViewModel tests (`test/viewmodels/`):** Nghiệp vụ bài thi thử, đồng hồ đếm ngược, logic chấm điểm và chuyển đổi ngôn ngữ.
* **Widget tests (`test/widget/` và `test/widget_test.dart`):** Khởi tạo ứng dụng, thành tích, validate ví Blockchain, trạng thái/loại chứng chỉ, chi tiết và xác minh on-chain.
* **Accessibility tests:** Kiểm tra vùng chạm tối thiểu `48x48dp` (`androidTapTargetGuideline`).

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

* Giao diện hiện khởi tạo các `ChangeNotifier` bằng package `provider` trong `main.dart`, gồm quiz, thi thử, thống kê, ngôn ngữ, giao diện, gia sư AI, gamification, chứng chỉ blockchain và tiến độ khóa học.
* `lib/viewmodels/` chứa các ViewModel/logic bài thi, đồng hồ, ngôn ngữ và thống kê; `bai_thi_state.dart` cùng `logic_thi.dart` biểu diễn trạng thái và nghiệp vụ bài thi.
* `GamificationEngine` xử lý ngày học liên tiếp, bảo vệ chuỗi Streak Freeze theo tuần, cộng điểm XP, thăng cấp, Thử thách hằng ngày và điều kiện mở huy hiệu; `GamificationProvider` giữ tiến độ, phối hợp với luồng quiz/thi và cung cấp huy hiệu mới mở khóa cho giao diện. `BlockchainProvider` và `CourseProgressProvider` lắng nghe các sự thay đổi tiến độ từ `GamificationProvider` để tự động tính toán lại điều kiện nhận chứng chỉ on-chain.
* Tiến độ gamification được lưu cục bộ dưới khóa `gamification_v1` (tương thích ngược an toàn khi nạp dữ liệu cũ thiếu `daily_goal` hoặc `xp`); `Clock` cho phép kiểm thử logic đổi ngày.
* `BadgeCatalog` định nghĩa 9 huy hiệu; `AchievementsScreen`, `StreakCard`, `BadgeTile` và `BadgeUnlockedDialog` hiển thị thành tích, vòng tròn tiến độ mục tiêu, thanh XP và thông báo mở khóa kèm hiệu ứng & nút chia sẻ.

---

## ⛓️ Blockchain Certificate System

Hệ thống dùng một contract `AchievementCertificate` trên Ethereum Sepolia. Flutter chỉ tạo yêu cầu và SHA-256 hash xác định; private key Issuer không được lưu trong app. Trạng thái trong SharedPreferences chỉ là cache — khi đồng bộ, app gọi `verifyCertificate(bytes32)` trên contract để lấy trạng thái hiện tại.

* `lib/core/utils/achievement_hasher.dart`: chuẩn hóa dữ liệu criteria rồi tạo SHA-256 ổn định.
* `lib/domain/blockchain/certificate_eligibility_engine.dart`: pure Dart eligibility cho bốn thành tích (Perfect Score, 7-Day Streak, Flutter Master, Knowledge Explorer) và khóa học.
* `lib/data/datasources/`: lưu yêu cầu/địa chỉ ví cục bộ và đọc contract qua Ethereum RPC; datasource đọc blockchain không ký giao dịch.
* `lib/data/repositories/blockchain_repository_impl.dart`: ghi cache và đối chiếu certificate ID, type, recipient, hash cùng trạng thái on-chain.
* `lib/presentation/providers/blockchain_provider.dart` và `course_progress_provider.dart`: nối tiến độ hiện có với yêu cầu chứng chỉ và đồng bộ.
* `lib/presentation/screens/blockchain_certificates_screen.dart`, `certificate_detail_screen.dart`, `course_progress_screen.dart`: nhập ví, theo dõi điều kiện, xem/xác minh chứng chỉ.
* `contracts/AchievementCertificate.sol`: `certificateType = 1` là Achievement; `certificateType = 2` là Course Completion.

### Quy trình demo cấp chứng chỉ thủ công trên Sepolia

1. Cài ví MetaMask và chọn **Sepolia Test Network**. Dùng faucet để nạp Sepolia ETH vào ví Issuer; recipient dùng địa chỉ ví công khai của người nhận.
2. Đảm bảo địa chỉ Issuer trong ví MetaMask trùng với `issuer` của contract. Địa chỉ contract hiện tại nằm trong `lib/core/constants/blockchain_config.dart`. Mở địa chỉ đó trên [Sepolia Etherscan](https://sepolia.etherscan.io/) → tab **Contract** → **Write Contract** → **Connect to Web3** bằng ví Issuer. Nếu Etherscan chưa có ABI/source verified, verify contract trước hoặc dùng Hardhat console/script tại thư mục `contracts/`.
3. Trong app, mở **Cá nhân → Chứng chỉ Blockchain**, nhập địa chỉ ví recipient, lưu ví. Khi đủ điều kiện, nhấn **Yêu cầu chứng chỉ**. Yêu cầu được lưu local ở trạng thái pending; mở chi tiết để lấy certificate ID và achievement hash. Không nhập private key vào app.
4. Trên Etherscan **Write Contract**, gọi `issueCertificate` với:
   * `certificateId`: bytes32 từ app (giữ nguyên 0x nếu form chấp nhận).
   * `certificateType`: `1` cho Achievement hoặc `2` cho Course Completion.
   * `recipient`: địa chỉ ví người học.
   * `achievementHash`: bytes32 hash từ chi tiết chứng chỉ.
   Xác nhận giao dịch trong ví Issuer và đợi transaction được mined trên Sepolia.
5. Khi transaction đã mined, mở app và nhấn **Đồng bộ / Xác minh từ Blockchain**. App đọc record contract rồi truy vấn event `CertificateIssued` theo indexed `certificateId`; transaction hash và block number được lưu cùng chứng chỉ. Nút Sepolia Explorer bật sau khi metadata được đồng bộ. Nếu Issuer thu hồi chứng chỉ, gọi `revokeCertificate(certificateId)` từ trang Write Contract rồi đồng bộ lại để thấy **Revoked**.
6. Nhấn **Xem trên Sepolia Explorer** để trình bày transaction receipt/event `CertificateIssued` trong buổi demo. Mặc định app quét tối đa 5.000 block gần nhất; nếu contract được deploy lâu hơn, cấu hình block deploy bằng `--dart-define=CERTIFICATE_CONTRACT_DEPLOYMENT_BLOCK=<block_number>` để tra cứu từ block đó. Event `CertificateIssued` vẫn giữ transaction gốc ngay cả khi chứng chỉ bị thu hồi; giao dịch thu hồi là event riêng `CertificateRevoked`.

**Bảo mật:** `contracts/.env` chứa cấu hình Issuer/RPC cho Hardhat và phải được giữ ngoài Git. Không đưa private key vào source, README, ảnh chụp demo hoặc build Flutter. Flutter chỉ cần RPC URL công khai và contract address.

### Kiểm thử Blockchain

* Unit tests cho deterministic hashing, biên eligibility (199/200 câu, 79/80%), trạng thái repository pending/confirmed/revoked và tiến độ khóa học nằm trong `test/unit/`.
* Widget tests cho validate địa chỉ ví, loại/trạng thái chứng chỉ và màn hình chi tiết nằm trong `test/widget/`.
* Chạy `flutter analyze` và `flutter test` để kiểm tra toàn bộ ứng dụng.
