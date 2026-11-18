/// Ngôn ngữ giao diện được ViewModel quản lý.
enum NgonNgu {
  vi,
  en;

  String get ma => name;

  static NgonNgu tuMa(String? ma) => ma == 'en' ? NgonNgu.en : NgonNgu.vi;

  NgonNgu get nguoc => this == NgonNgu.vi ? NgonNgu.en : NgonNgu.vi;
}
