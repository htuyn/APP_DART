# Tech Context

## 1. Môi trường & SDK
- **Framework**: Flutter (Material 3 enabled)
- **Dart SDK**: `^3.13.4` (theo `pubspec.yaml`)
- **Nền tảng mục tiêu**: Android, iOS, Web, Windows, macOS, Linux (đã tạo sẵn thư mục platform).
- **Version hiện tại**: `1.0.0+1`

## 2. Dependencies (`pubspec.yaml`)
### Production
- `flutter` (SDK)
- `cupertino_icons: ^1.0.8`
- `provider: ^6.1.5+1` — Quản lý trạng thái (State Management)
- `shared_preferences: ^2.5.6` — Lưu trữ key-value cục bộ

### Development
- `flutter_test` (SDK)
- `flutter_lints: ^6.0.0` — Bộ quy tắc lint chuẩn (`analysis_options.yaml`)

## 3. Assets
- Khai báo trong `pubspec.yaml`:
  ```yaml
  assets:
    - assets/data/
  ```
- Đường dẫn dữ liệu câu hỏi mặc định trong `QuizLocalDataSource`: `assets/data/questions.json`.

## 4. Quy ước Code & Theme
- **Linting**: Tuân thủ `package:flutter_lints/flutter.yaml` (`analysis_options.yaml`).
- **Màu sắc (`AppColors`)**:
  - Primary: `#0D47A1`, Secondary: `#00897B`
  - Success: `#2E7D32`, Error: `#C62828`, Warning: `#EF6C00`
  - Light Background: `#F8F9FA`, Dark Background: `#121212`, Dark Card: `#1E1E1E`
- **Theme (`AppTheme`)**:
  - `useMaterial3: true`, `ColorScheme.fromSeed(seedColor: AppColors.primary)`
  - `ElevatedButton` mặc định cao `48dp`, rộng `double.infinity`, bo góc `10dp`.
  - `Card` bo góc `12dp`, `elevation: 2`.
