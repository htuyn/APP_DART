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
* **Chứng chỉ & Chứng nhận Blockchain (On-Chain Certificates) & Thẻ bằng Web3 (`DigitalCertificateCard`):** Tích hợp hợp đồng thông minh (Smart Contract) trên mạng Ethereum Sepolia. Tự động kiểm tra điều kiện đủ (Eligibility) cho các thành tích (Điểm tuyệt đối, Chuỗi 7 ngày, Flutter Master, Khám phá kiến thức) và Tiến độ khóa học. Trình diễn giao diện **Bằng chứng nhận Kỹ thuật số cao cấp (`DigitalCertificateCard`)** phong cách Web3 Dark Theme với khung viền kép màu vàng ánh kim, họa tiết lưới mờ & radial glow, huy hiệu trạng thái Pill (Đã xác thực On-chain / Đang chờ xác nhận / Đã thu hồi), cúp vàng thành tích, khung địa chỉ ví người nhận & mã giao dịch kèm nút **Copy** 1-touch hiển thị SnackBar phản hồi, cùng con dấu xác thực **Ethereum Sepolia** chính thức. Hỗ trợ tạo yêu cầu cấp chứng chỉ (Pending), băm SHA-256 dữ liệu xác thực (`achievementHash` / `certificateId`), đồng bộ & xác minh trạng thái từ Blockchain (Confirmed / Revoked) qua JSON-RPC (`https://ethereum-sepolia-rpc.publicnode.com`), tra cứu trực tiếp giao dịch và sự kiện `CertificateIssued` trên Sepolia Etherscan.
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
│   │   ├── certificate_detail_screen.dart  # Màn hình chi tiết chứng chỉ: tích hợp bằng chứng nhận Web3 Digital Certificate Card, nút copy ví/hash kèm SnackBar, xác minh on-chain và link Sepolia Explorer
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
│       ├── digital_certificate_card.dart   # Widget bằng chứng nhận kỹ thuật số cao cấp (Web3 Digital Diploma Card) với viền kép vàng kim, status pill, copy 1-touch và con dấu Sepolia
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

## ⛓️ Blockchain Certificate System (Hệ Thống Chứng Chỉ Blockchain)

Hệ thống tích hợp giải pháp cấp chứng chỉ số phi tập trung (Decentralized Achievement Certificates) dựa trên công nghệ Blockchain Ethereum Sepolia Testnet. Giải pháp kết hợp giữa kiểm tra điều kiện đủ (Eligibility Engine) cục bộ tại thiết bị di động và hợp đồng thông minh (Smart Contract) trên On-Chain để đảm bảo tính minh bạch, chống giả mạo và dễ dàng xác minh độc lập.

---

### 📜 1. Hợp Đồng Thông Minh (Smart Contract Specification)

Hợp đồng `contracts/AchievementCertificate.sol` được viết bằng Solidity (`^0.8.20`) và quản lý/kiểm thử qua Hardhat framework.

* **Địa chỉ Contract (Sepolia Testnet):** `0x40Cc19d362D52f6d7bf2A3bC5C3298B204ECFEa9` (Được cấu hình trong `lib/core/constants/blockchain_config.dart`).
* **Phân loại chứng chỉ (`uint8 certificateType`):**
  * `1` — `ACHIEVEMENT_CERTIFICATE`: Chứng chỉ thành tích cá nhân (Perfect Score, 7-Day Streak, Flutter Master, Knowledge Explorer).
  * `2` — `COURSE_COMPLETION_CERTIFICATE`: Chứng chỉ hoàn thành toàn bộ khóa học Flutter.
* **Cấu trúc dữ liệu chứng chỉ (`struct Certificate`):**
  ```solidity
  struct Certificate {
      bytes32 certificateId;     // Định danh duy nhất của chứng chỉ (derived SHA-256)
      uint8 certificateType;    // Loại chứng chỉ (1: Thành tích, 2: Hoàn thành khóa học)
      address recipient;        // Địa chỉ ví Ethereum của người học
      bytes32 achievementHash;  // Băm cryptographic SHA-256 của dữ liệu thành tích/tiêu chí
      uint256 issuedAt;         // Timestamp thời điểm cấp phát (block.timestamp)
      bool revoked;             // Trạng thái thu hồi (true/false)
  }
  ```
* **Các phương thức chính trên Smart Contract:**
  * `issueCertificate(bytes32 certificateId, uint8 certificateType, address recipient, bytes32 achievementHash)`: Hàm cấp chứng chỉ chỉ dành cho Issuer (`onlyIssuer`). Tự động kiểm tra điều kiện đầu vào và chống trùng lặp `certificateId` hoặc `achievementHash`.
  * `revokeCertificate(bytes32 certificateId)`: Hàm thu hồi chứng chỉ đã cấp (Chỉ `issuer`).
  * `verifyCertificate(bytes32 certificateId)`: Hàm đọc trực tiếp (`view`) trả về thông tin chứng chỉ kèm trạng thái hợp lệ (`valid = !revoked`).
* **Sự kiện On-Chain (Events):**
  * `event CertificateIssued(bytes32 indexed certificateId, uint8 indexed certificateType, address indexed recipient, bytes32 achievementHash, uint256 issuedAt)`
  * `event CertificateRevoked(bytes32 indexed certificateId, address indexed issuer)`
* **Chống gian lận & Trùng lặp:**
  * Mappings `certificateIdExists` và `achievementHashExists` ngăn chặn việc cấp lại cùng một thành tích cho cùng địa chỉ ví hoặc tạo trùng mã chứng chỉ trên Blockchain.

---

### 🔐 2. Thuật Toán Băm Cryptographic Deterministic Hashing

Ứng dụng đảm bảo tính nhất quán dữ liệu giữa Flutter Client và Smart Contract bằng cơ chế băm SHA-256 chuẩn hóa dữ liệu:

1. **Chuẩn hóa & Băm Thành Tích (`achievementHash`):**
   * Sử dụng `AchievementHasher`: Sắp xếp các từ khóa (keys) trong bảng tiêu chí `criteria` theo thứ tự bảng chữ cái alphabet (`_canonicalize`), đảm bảo JSON output đồng nhất 100% ở mọi thời điểm.
   * Cấu trúc Payload băm:
     ```json
     {
       "schema": "app-dart-certificate-v1",
       "subject_id": "0xrecipient_address_lowercased",
       "certificate_type": 1,
       "achievement_code": "perfectScore",
       "criteria": { ... }
     }
     ```
   * Tạo digest SHA-256: `sha256(utf8.encode(jsonEncode(payload)))` $\rightarrow$ Trả về chuỗi `achievementHash` định dạng `0x...` (bytes32).

2. **Mã Chứng Chỉ (`certificateId`):**
   * Được tạo độc lập từ `achievementHash` thông qua `CertificateHasher`: `sha256('app-dart-certificate-id-v1:' + achievementHash)`.
   * Đảm bảo tính suy rộng 1-1 không thể đảo ngược, sử dụng làm khóa chính tra cứu `bytes32` trên Blockchain.

---

### 🎯 3. Bộ Quy Tắc Đủ Điều Kiện (Certificate Eligibility Engine)

Lớp `CertificateEligibilityEngine` (Pure Dart Engine) tự động tính toán các tiêu chí nhận chứng chỉ mà không phụ thuộc vào bộ nhớ mạng:

#### A. Chứng Chỉ Thành Tích (`CertificateType.achievement`)
* **Perfect Score (`perfectScore`):** Đạt điểm tuyệt đối 100% trong ít nhất 1 bài thi thử hoặc bài luyện tập.
* **7-Day Streak (`sevenDayStreak`):** Duy trì chuỗi ngày học liên tiếp $\ge 7$ ngày.
* **Flutter Master (`flutterMaster`):** Đạt cấp độ Level $\ge 5$ VÀ đã hoàn thành nộp bài $\ge 10$ bài thi thử.
* **Knowledge Explorer (`knowledgeExplorer`):** Hoàn thành tất cả các khối kiến thức trong ứng dụng.

#### B. Chứng Chỉ Hoàn Thành Khóa Học (`CertificateType.courseCompletion`)
Yêu cầu đạt đồng thời 4 điều kiện:
1. Hoàn thành 100% các khối bài học kiến thức.
2. Số câu hỏi luyện tập đã làm $\ge 100$ câu (`requiredPracticeQuestions`).
3. Tỷ lệ trả lời đúng tích lũy $\ge 80\%$.
4. Đạt điểm bài thi tổng hợp cuối khóa (Capstone Exam) $\ge 80\%$.

---

### 💼 4. Kiến Trúc Ví Hybrid (Hybrid Wallet) & Auto-Issuer Relayer

* **Ví nhúng (Embedded Local Wallet):**
  * Tự động khởi tạo cặp khóa ví Ethereum bí mật cục bộ bằng package `wallet` (lưu an toàn trong `SharedPreferences`).
  * Người học có thể sử dụng ngay lập tức mà không cần cài đặt các phần mềm ví Web3 bên thứ ba.
  * Hỗ trợ sao lưu khóa riêng tư (Private Key) hoặc linh hoạt chuyển đổi nhập địa chỉ ví bên ngoài (ví dụ: ví MetaMask).
* **Cơ chế Cấp Phát Tự Động (Auto-Issuer Relayer Service):**
  * Flutter không chứa `ISSUER_PRIVATE_KEY`; server đọc issuer key và `RELAYER_API_KEY` từ `contracts/.env`.
  * Chạy server bằng `cd contracts && npm run relayer`. Server chỉ bind `127.0.0.1:8787`, yêu cầu header `X-API-Key`, và giới hạn 10 request/phút.
  * Flutter gọi `POST /api/certificates/issue` qua `ISSUER_RELAYER_URL` (mặc định `http://localhost:8787`) và gửi `ISSUER_RELAYER_API_KEY` trong header. Ví dụ dev key được đặt trong `.env.example`; hãy thay bằng khóa ngẫu nhiên riêng trong `.env` và truyền cùng giá trị qua `--dart-define=ISSUER_RELAYER_API_KEY=...`.
  * Request payload gồm `certificateId`, `certificateType` (`0` thành tích, `1` hoàn thành khóa học), `recipientAddress`, `achievementHash`; server ánh xạ sang giá trị contract `1/2`.
  * Nếu relayer offline, yêu cầu được lưu `pending`; `synchronize()` sẽ thử gửi lại và cập nhật `confirmed` cùng transaction hash/block khi nhận xác nhận.

---

### 🔍 5. Đồng Bộ Trạng Thái On-Chain & Tra Cứu Sự Kiện Event Log

* **Đồng bộ & Đối chiếu (`AchievementVerifier` & `EthereumBlockchainDataSource`):**
  * Đọc dữ liệu trực tiếp từ Ethereum Sepolia RPC URL (`https://ethereum-sepolia-rpc.publicnode.com`) qua thư viện `web3dart`.
  * Gửi lời gọi hàm `verifyCertificate(bytes32)` để đối chiếu địa chỉ recipient, `achievementHash` và thời điểm cấp `issuedAt`.
  * Xác định chính xác các trạng thái chứng chỉ: `eligible` (đủ điều kiện), `requested` / `pending` (đang chờ cấp/đang xử lý), `confirmed` (đã cấp và xác thực thành công on-chain), `revoked` (đã bị thu hồi), `failed` (dữ liệu không trùng khớp).
* **Tra cứu Transaction Log (`findCertificateIssuedEvent`):**
  * Sử dụng filter `getLogs` quét sự kiện `CertificateIssued` trong cửa sổ block xác định (`BlockchainConfig.eventScanWindow = 5000` block hoặc `CERTIFICATE_CONTRACT_DEPLOYMENT_BLOCK`).
  * Trích xuất `transactionHash` và `blockNumber` của giao dịch cấp chứng chỉ.
* **Tích hợp Trình Khám Phá Khối (Sepolia Etherscan Integration):**
  * Cung cấp đường dẫn tra cứu trực tiếp trên Sepolia Etherscan:
    * Tra cứu giao dịch: `https://sepolia.etherscan.io/tx/{transactionHash}`
    * Tra cứu địa chỉ ví: `https://sepolia.etherscan.io/address/{recipientAddress}`

---

### 🛠️ 6. Hướng Dẫn Cấu Hình & Kiểm Thử Hardhat Smart Contract

Thư mục `contracts/` chứa toàn bộ mã nguồn hợp đồng thông minh Solidity và bộ kịch bản kiểm thử/deploy:

1. **Cài đặt thư viện phát triển contract:**
   ```bash
   cd contracts
   npm install
   ```
2. **Biên dịch hợp đồng Solidity:**
   ```bash
   npx hardhat compile
   ```
3. **Chạy kịch bản kiểm thử tự động (Contract Tests):**
   ```bash
   npx hardhat test
   ```
   *(File `contracts/test/AchievementCertificate.test.js` kiểm thử toàn bộ logic: cấp phát chứng chỉ thành tích & khóa học, từ chối người dùng không phải Issuer, chống trùng lặp `certificateId` & `achievementHash`, thu hồi chứng chỉ và kiểm tra tính hợp lệ).*

4. **Triển khai (Deploy) Hợp Đồng Lên Ethereum Sepolia:**
   * Tạo file `.env` từ `.env.example`:
     ```env
     SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
     ISSUER_PRIVATE_KEY=your_private_key_here
     ```
   * Chạy kịch bản deploy:
     ```bash
     npx hardhat run scripts/deploy.js --network sepolia
     ```

---

### 🧪 7. Kiểm Thử Hệ Thống Blockchain Trên Flutter

* **Unit Tests (`test/unit/`):**
  * `achievement_hasher_test.dart`: Kiểm thử tính ổn định của hàm băm SHA-256.
  * `certificate_eligibility_test.dart`: Kiểm thử chính xác các quy tắc đủ điều kiện cho 4 thành tích và hoàn thành khóa học.
  * `ethereum_blockchain_datasource_test.dart`: Kiểm thử đọc dữ liệu contract RPC và tra cứu log sự kiện.
  * `blockchain_repository_test.dart`: Kiểm thử đối chiếu dữ liệu local cache và trạng thái on-chain.
  * `blockchain_provider_test.dart`: Kiểm thử quản lý trạng thái, tự động kết nối và yêu cầu cấp chứng chỉ.
* **Widget Tests (`test/widget/`):**
  * `blockchain_certificates_screen_test.dart`: Kiểm thử giao diện danh sách chứng chỉ, nhập/validate địa chỉ ví.
  * `certificate_detail_screen_test.dart`: Kiểm thử màn hình chi tiết chứng chỉ, thẻ Web3 Digital Certificate Card, thao tác sao chép địa chỉ ví/hash kèm SnackBar, hiển thị mã băm, trạng thái badge xác nhận và liên kết Explorer.

---

### 🎨 8. Giao Diện Tấm Bằng Chứng Nhận Kỹ Thuật Số (Web3 Digital Diploma Card UI)

Lớp hiển thị giao diện `DigitalCertificateCard` trong `lib/presentation/widgets/digital_certificate_card.dart` cung cấp thiết kế văn bằng kỹ thuật số cao cấp đồng bộ với Dark Theme của ứng dụng:

* **Thiết Kế Khung Bằng Kép (Double Border):**
  * Viền ngoài gradient vàng ánh kim (`#F59E0B` $\rightarrow$ `#FDE68A` $\rightarrow$ `#D97706`) bo góc `20px` với độ dầy 2px.
  * Viền trong bo góc `18px` nét mảnh `1px` trên nền gradient tối sâu (`#0F172A` $\rightarrow$ `#1E293B`).
  * Kết hợp hiệu ứng tỏa sáng góc (Subtle Radial Glow) cùng họa tiết lưới mờ `_DiplomaGridPainter` tạo chiều sâu và thẩm mỹ cao cấp.
* **Đầu Bằng (Header):**
  * Tên học viện `APP DART ACADEMY` kèm biểu tượng trường học ở góc trái.
  * Huy hiệu trạng thái Pill ở góc phải: `Đã xác thực On-chain` màu xanh ngọc (`#10B981`) đối với chứng chỉ `confirmed`, `Đang chờ xác nhận` màu hổ phách (`#F59E0B`) đối với trạng thái `pending`, hoặc màu đỏ đối với `revoked`.
* **Thân Bằng (Body):**
  * Tiêu đề trang trọng `CHỨNG NHẬN THÀNH TÍCH` / `CERTIFICATE OF ACHIEVEMENT` (tracking chữ rộng, màu vàng kim).
  * Biểu tượng cúp/sao vàng `Icons.workspace_premium_rounded` và tên chứng chỉ in hoa nổi bật ở trung tâm (ví dụ: **FLUTTER MASTER**).
  * Khung địa chỉ ví người nhận (`recipientAddress`) rút gọn gọn gàng (dạng `0x11111111…11111111`) kèm nút **Copy** 1-touch.
* **Chân Bằng (On-Chain Proof Footer):**
  * Hộp thông tin xác thực bán trong suốt (`Colors.black26`) trình bày gọn gàng: **Mã chứng chỉ** (`certificateId`), **Mã băm thành tích** (`achievementHash`), **Mã giao dịch** (`transactionHash` kèm nút Copy), **Block Number** (`#...`) và **Ngày cấp** (`issuedAt`).
  * Con dấu xác thực **ETHEREUM SEPOLIA** chính thức với biểu tượng xác thực ở góc dưới bên phải.
* **Tương Tác & Phản Hồi (SnackBar Feedback):**
  * Bấm nút Copy địa chỉ ví hoặc mã giao dịch sẽ ngay lập tức kích hoạt thanh thông báo SnackBar nổi trên màn hình (`Đã sao chép địa chỉ ví` / `Đã sao chép mã giao dịch`).
  * Đảm bảo hỗ trợ song ngữ Việt / Anh qua `app_strings.dart` và tự động điều chỉnh co giãn bố cục, không tràn chữ (overflow) trên mọi kích thước màn hình thiết bị di động.

