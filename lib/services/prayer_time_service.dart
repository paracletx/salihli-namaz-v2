import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prayer_times.dart';
import 'storage_service.dart';

/// Uygulamanın istisnasız olarak Salihli, Manisa, Türkiye için namaz
/// vakitlerini getirmesinden sorumlu servis.
///
/// Veri kaynağı: T.C. Diyanet İşleri Başkanlığı'nın yayınladığı resmi
/// namaz vakitleri. Diyanet'in doğrudan genel kullanıma açık bir REST
/// API'si bulunmadığından, Diyanet verilerini birebir ileten, yaygın
/// olarak kullanılan açık kaynak "EzanVakti API" (ezanvakti.emushaf.net)
/// aracı olarak kullanılır. Bu servis; ülke, şehir ve ilçe kodlarını
/// hiyerarşik biçimde çözerek Salihli'ye özel vakitleri getirir.
///
/// Konum kodları uygulama içinde SABİT DEĞİLDİR; ilk çalıştırmada API
/// üzerinden isimle aranarak bulunur ve cihazda önbelleğe alınır. Bu
/// sayede API tarafında kodlar değişse bile uygulama kendini düzeltir.
class PrayerTimeService {
  PrayerTimeService({http.Client? client, StorageService? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? StorageService();

  final http.Client _client;
  final StorageService _storage;

  static const String _baseUrl = 'https://ezanvakti.emushaf.net';

  // Diyanet'in ülke listesinde Türkiye için bilinen kod. Doğrulama
  // amacıyla yine de isimden aranır; bu sadece bir başlangıç ipucudur.
  static const String _bilinenTurkiyeUlkeKodu = '2';

  static const String _ilAdi = 'MANİSA';
  static const List<String> _ilAdiAlternatifleri = ['MANİSA', 'MANISA'];
  static const String _ilceAdi = 'SALİHLİ';
  static const List<String> _ilceAdiAlternatifleri = ['SALİHLİ', 'SALIHLI'];

  /// Salihli ilçesinin EzanVakti API'sindeki ilçe kodunu döndürür.
  /// Önce cihaz önbelleğine bakar; ANCAK önbellekteki kodu sadece
  /// yanında saklanan ilçe adı gerçekten "Salihli" ile eşleşiyorsa
  /// güvenilir kabul eder. Eşleşmiyorsa (veya önbellek hiç yoksa),
  /// API üzerinde ülke -> şehir -> ilçe hiyerarşisinde isimle yeniden
  /// arama yapılır. Bu, yanlış/bozuk bir ilçe kodunun sessizce
  /// kullanılmaya devam etmesini engeller.
  Future<String> _resolveSalihliIlceId() async {
    final cachedId = await _storage.readCachedIlceId();
    final cachedAdi = await _storage.readCachedIlceAdi();
    if (cachedId != null &&
        cachedId.isNotEmpty &&
        cachedAdi != null &&
        _ilceAdiAlternatifleri.contains(cachedAdi.toUpperCase())) {
      return cachedId;
    }

    final sonuc = await _resolveSalihliIlceIdFromNetwork();
    await _storage.saveIlceId(sonuc.ilceId, sonuc.ilceAdi);
    return sonuc.ilceId;
  }

  Future<_IlceCozumSonucu> _resolveSalihliIlceIdFromNetwork() async {
    final ulkeKodu = await _findTurkiyeUlkeKodu();
    final sehirKodu = await _findSehirKodu(ulkeKodu, _ilAdiAlternatifleri);
    return _findIlceKodu(sehirKodu, _ilceAdiAlternatifleri);
  }

  Future<String> _findTurkiyeUlkeKodu() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/ulkeler'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final ad = (map['UlkeAdi'] as String?)?.toUpperCase() ?? '';
          if (ad.contains('TÜRKİYE') || ad.contains('TURKIYE')) {
            return map['UlkeID'].toString();
          }
        }
      }
    } catch (_) {
      // Ağ hatası olursa bilinen koda düşülecek.
    }
    return _bilinenTurkiyeUlkeKodu;
  }

  Future<String> _findSehirKodu(
      String ulkeKodu, List<String> adAlternatifleri) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/sehirler/$ulkeKodu'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw PrayerTimeException(
          'Şehir listesi alınamadı (HTTP ${response.statusCode}).');
    }
    final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final ad = (map['SehirAdi'] as String?)?.toUpperCase() ?? '';
      final adEn = (map['SehirAdiEn'] as String?)?.toUpperCase() ?? '';
      if (adAlternatifleri.any((a) => ad == a || adEn == a)) {
        return map['SehirID'].toString();
      }
    }
    throw const PrayerTimeException('$_ilAdi için şehir kodu bulunamadı.');
  }

  Future<_IlceCozumSonucu> _findIlceKodu(
      String sehirKodu, List<String> adAlternatifleri) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/ilceler/$sehirKodu'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw PrayerTimeException(
          'İlçe listesi alınamadı (HTTP ${response.statusCode}).');
    }
    final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      // API dokümantasyonu ilçe kayıtlarının alan adlarını net olarak
      // belirtmiyor; hiyerarşinin diğer seviyeleriyle (ülke/şehir) aynı
      // "Sehir*" isimlendirmesini yeniden kullanma ihtimaline karşı her
      // iki olası alan adı seti de denenir.
      final id = (map['IlceID'] ?? map['SehirID'])?.toString();
      final adRaw = (map['IlceAdi'] ?? map['SehirAdi']) as String?;
      final adEnRaw = (map['IlceAdiEn'] ?? map['SehirAdiEn']) as String?;
      final ad = adRaw?.toUpperCase() ?? '';
      final adEn = adEnRaw?.toUpperCase() ?? '';
      if (id != null && adAlternatifleri.any((a) => ad == a || adEn == a)) {
        return _IlceCozumSonucu(ilceId: id, ilceAdi: ad);
      }
    }
    throw const PrayerTimeException('$_ilceAdi için ilçe kodu bulunamadı.');
  }

  Future<List<DailyPrayerTimes>> _fetchVakitler(String ilceId) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/vakitler/$ilceId'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw PrayerTimeException(
          'Namaz vakitleri alınamadı (HTTP ${response.statusCode}).');
    }
    final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => DailyPrayerTimes.fromEzanVaktiJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Salihli için güncel namaz vakti verilerini getirir.
  ///
  /// Davranış:
  /// 1) İnternet varsa API'den güncel (yaklaşık 30 günlük, bugünden
  ///    itibaren ileriye dönük) vakit listesini indirir ve cihaza kaydeder.
  /// 2) İnternet yoksa veya istek başarısız olursa, daha önce indirilmiş
  ///    ve cihazda saklanan vakitler kullanılır.
  /// 3) Hiç önbellek yoksa ve ağ da başarısızsa hata fırlatılır; arayüz
  ///    bu durumda kullanıcıya anlaşılır bir mesaj gösterir.
  Future<PrayerDataResult> loadPrayerData() async {
    try {
      final ilceId = await _resolveSalihliIlceId();
      final veriler = await _fetchVakitler(ilceId);
      await _storage.savePrayerData(veriler);
      return PrayerDataResult(gunler: veriler, cevrimdisi: false);
    } catch (_) {
      final cached = await _storage.readCachedPrayerData();
      if (cached != null && cached.isNotEmpty) {
        return PrayerDataResult(gunler: cached, cevrimdisi: true);
      }
      rethrow;
    }
  }
}

class PrayerDataResult {
  final List<DailyPrayerTimes> gunler;

  /// Veri, ağdan değil cihazdaki önbellekten geldiyse true olur.
  final bool cevrimdisi;

  const PrayerDataResult({required this.gunler, required this.cevrimdisi});

  /// Belirtilen tarihe ait günü bulur (yıl/ay/gün eşleşmesiyle).
  DailyPrayerTimes? findByDate(DateTime date) {
    for (final gun in gunler) {
      if (gun.date.year == date.year &&
          gun.date.month == date.month &&
          gun.date.day == date.day) {
        return gun;
      }
    }
    return null;
  }
}

class PrayerTimeException implements Exception {
  final String message;
  const PrayerTimeException(this.message);

  @override
  String toString() => message;
}

/// İlçe çözümleme sonucunu (kod + eşleşen ad) birlikte taşır; böylece
/// önbelleğe kod ile birlikte ad da yazılıp sonraki açılışlarda
/// doğrulanabilir.
class _IlceCozumSonucu {
  final String ilceId;
  final String ilceAdi;
  const _IlceCozumSonucu({required this.ilceId, required this.ilceAdi});
}
