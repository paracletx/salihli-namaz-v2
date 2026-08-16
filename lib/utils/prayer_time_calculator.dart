import '../models/prayer_times.dart';

/// Belirli bir "şimdi" anına göre bir sonraki namaz vaktini ve o vakte
/// kalan süreyi hesaplamaktan sorumludur.
///
/// Kural: Sabah -> Güneş -> Öğle -> İkindi -> Akşam -> Yatsı sırasıyla
/// bugünün vakitleri taranır; geçmemiş ilk vakit "sıradaki vakit" olur.
/// Bugünün tüm vakitleri geçtiyse (Yatsı'dan sonrası), sıradaki vakit
/// yarının Sabah vaktidir.
class PrayerTimeCalculator {
  const PrayerTimeCalculator._();

  static NextPrayerInfo? computeNext({
    required DailyPrayerTimes today,
    required DailyPrayerTimes? tomorrow,
    required DateTime now,
  }) {
    for (final entry in today.orderedEntries) {
      final hedefZaman = today.timeOn(entry.time);
      if (hedefZaman.isAfter(now)) {
        return NextPrayerInfo(
          name: entry.name,
          targetDateTime: hedefZaman,
          belongsToToday: true,
        );
      }
    }

    if (tomorrow != null) {
      final hedefZaman = tomorrow.timeOn(tomorrow.sabah);
      return NextPrayerInfo(
        name: PrayerName.sabah,
        targetDateTime: hedefZaman,
        belongsToToday: false,
      );
    }

    // Yarının verisi henüz yoksa hesaplanamaz; çağıran taraf yeniden
    // veri çekmeyi deneyebilir.
    return null;
  }
}

class NextPrayerInfo {
  final PrayerName name;
  final DateTime targetDateTime;

  /// Sıradaki vakit bugüne mi (true) yoksa yarına mı (false) ait.
  /// Listede vurgulama yaparken kullanılır: sadece bugüne ait ise
  /// ilgili satır vurgulanır.
  final bool belongsToToday;

  const NextPrayerInfo({
    required this.name,
    required this.targetDateTime,
    required this.belongsToToday,
  });

  Duration remaining(DateTime now) {
    final fark = targetDateTime.difference(now);
    return fark.isNegative ? Duration.zero : fark;
  }
}
