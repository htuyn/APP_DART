/// NgÃ´n ngá»¯ giao diá»‡n Ä‘Æ°á»£c ViewModel quáº£n lÃ½.
enum NgonNgu {
  vi,
  en;

  String get ma => name;

  static NgonNgu tuMa(String? ma) => ma == 'en' ? NgonNgu.en : NgonNgu.vi;

  NgonNgu get nguoc => this == NgonNgu.vi ? NgonNgu.en : NgonNgu.vi;
}
