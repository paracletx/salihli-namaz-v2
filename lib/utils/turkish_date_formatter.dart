/// Cihazın yerel tarihini Türkçe olarak biçimlendirmek için kullanılır.
/// Örnek çıktı: "16 Ağustos 2026 Pazar".
class TurkishDateFormatter {
  static const List<String> _aylar = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static const List<String> _gunler = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  /// [date] -> "16 Ağustos 2026 Pazar"
  static String formatLong(DateTime date) {
    final gunAdi = _gunler[date.weekday - 1]; // DateTime.weekday: 1=Pazartesi
    final ayAdi = _aylar[date.month - 1];
    return '${date.day} $ayAdi ${date.year} $gunAdi';
  }

  /// İki basamaklı saat:dakika:saniye biçimi, örn. "01:24:36".
  static String formatCountdown(Duration remaining) {
    if (remaining.isNegative) {
      return '00:00:00';
    }
    final saat = remaining.inHours;
    final dakika = remaining.inMinutes % 60;
    final saniye = remaining.inSeconds % 60;
    return '${_iki(saat)}:${_iki(dakika)}:${_iki(saniye)}';
  }

  static String _iki(int deger) => deger.toString().padLeft(2, '0');
}
