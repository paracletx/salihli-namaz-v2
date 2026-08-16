/// Tek bir güne ait namaz vakitlerini temsil eder.
///
/// Not: "Güneş" vakti geleneksel olarak 6 vakitten biri sayılmaz
/// (farz namaz vakti değildir) ancak kullanıcı isteği gereği
/// uygulamada 6. satır olarak gösterilir.
class DailyPrayerTimes {
  final DateTime date;
  final String sabah;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;

  const DailyPrayerTimes({
    required this.date,
    required this.sabah,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
  });

  /// Vakitleri sıralı şekilde (isim, saat) çiftleri olarak döndürür.
  /// Sıra: Sabah, Güneş, Öğle, İkindi, Akşam, Yatsı.
  List<PrayerTimeEntry> get orderedEntries => [
        PrayerTimeEntry(PrayerName.sabah, sabah),
        PrayerTimeEntry(PrayerName.gunes, gunes),
        PrayerTimeEntry(PrayerName.ogle, ogle),
        PrayerTimeEntry(PrayerName.ikindi, ikindi),
        PrayerTimeEntry(PrayerName.aksam, aksam),
        PrayerTimeEntry(PrayerName.yatsi, yatsi),
      ];

  /// EzanVakti API'sinin (ezanvakti.emushaf.net) döndürdüğü tek bir günlük
  /// kaydı DailyPrayerTimes nesnesine çevirir.
  ///
  /// API alanları (Diyanet kaynaklı): MiladiTarihKisa (gg.aa.yyyy),
  /// Imsak, Gunes, Ogle, Ikindi, Aksam, Yatsi.
  factory DailyPrayerTimes.fromEzanVaktiJson(Map<String, dynamic> json) {
    final tarihStr = json['MiladiTarihKisa'] as String; // "16.08.2026"
    final parcalar = tarihStr.split('.');
    final tarih = DateTime(
      int.parse(parcalar[2]),
      int.parse(parcalar[1]),
      int.parse(parcalar[0]),
    );

    return DailyPrayerTimes(
      date: tarih,
      // Diyanet verisinde "Sabah" namazı vakti "Imsak" alanı ile birlikte
      // gelir; Diyanet'in resmi vakit isimlendirmesinde sabah namazı vakti
      // imsak ile aynı anda başlar, bu yüzden Imsak = Sabah olarak kullanılır.
      sabah: json['Imsak'] as String,
      gunes: json['Gunes'] as String,
      ogle: json['Ogle'] as String,
      ikindi: json['Ikindi'] as String,
      aksam: json['Aksam'] as String,
      yatsi: json['Yatsi'] as String,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'MiladiTarihKisa':
            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
        'Imsak': sabah,
        'Gunes': gunes,
        'Ogle': ogle,
        'Ikindi': ikindi,
        'Aksam': aksam,
        'Yatsi': yatsi,
      };

  /// "HH:mm" formatındaki bir vaktin, bu nesnenin tarihine ait tam
  /// bir DateTime karşılığını üretir.
  DateTime timeOn(String hhmm) {
    final parcalar = hhmm.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parcalar[0]),
      int.parse(parcalar[1]),
    );
  }
}

enum PrayerName { sabah, gunes, ogle, ikindi, aksam, yatsi }

extension PrayerNameTurkish on PrayerName {
  String get label {
    switch (this) {
      case PrayerName.sabah:
        return 'Sabah';
      case PrayerName.gunes:
        return 'Güneş';
      case PrayerName.ogle:
        return 'Öğle';
      case PrayerName.ikindi:
        return 'İkindi';
      case PrayerName.aksam:
        return 'Akşam';
      case PrayerName.yatsi:
        return 'Yatsı';
    }
  }

  /// Türkçe büyük harfe çevirme kuralı Dart'ın varsayılan `toUpperCase()`
  /// metodundan farklıdır (özellikle "i" -> "İ" dönüşümü). Örneğin
  /// "İkindi".toUpperCase() Dart'ta yanlışlıkla "İKINDI" üretir
  /// (noktasız I ile). Bu yüzden büyük harfli etiketler burada açıkça
  /// doğru Türkçe karşılıklarıyla tanımlanır.
  String get upperLabel {
    switch (this) {
      case PrayerName.sabah:
        return 'SABAH';
      case PrayerName.gunes:
        return 'GÜNEŞ';
      case PrayerName.ogle:
        return 'ÖĞLE';
      case PrayerName.ikindi:
        return 'İKİNDİ';
      case PrayerName.aksam:
        return 'AKŞAM';
      case PrayerName.yatsi:
        return 'YATSI';
    }
  }
}

class PrayerTimeEntry {
  final PrayerName name;
  final String time; // "HH:mm"

  const PrayerTimeEntry(this.name, this.time);
}
