import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_times.dart';

/// Namaz vakti verilerini ve çözümlenmiş konum kodlarını cihazda
/// kalıcı olarak saklamaktan sorumludur. Böylece internet bağlantısı
/// olmadığında uygulama en son indirilen vakitlerle çalışmaya devam edebilir.
class StorageService {
  static const _keyIlceId = 'salihli_ilce_id';
  static const _keyIlceAdi = 'salihli_ilce_adi';
  static const _keyPrayerDataJson = 'cached_prayer_data_v1';
  static const _keyLastFetchIso = 'cached_prayer_data_last_fetch';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Daha önce çözümlenmiş Salihli ilçe kodunu döndürür (varsa).
  Future<String?> readCachedIlceId() async {
    final prefs = await _prefs;
    return prefs.getString(_keyIlceId);
  }

  /// Önbellekteki ilçe koduna karşılık gelen, API'den dönen ilçe adını
  /// döndürür. Bu, önbellekteki kodun gerçekten Salihli'ye ait olduğunu
  /// her açılışta doğrulamak için kullanılır — yanlış/bozuk bir kodun
  /// sessizce kalıcı olmasını engeller.
  Future<String?> readCachedIlceAdi() async {
    final prefs = await _prefs;
    return prefs.getString(_keyIlceAdi);
  }

  Future<void> saveIlceId(String ilceId, String ilceAdi) async {
    final prefs = await _prefs;
    await prefs.setString(_keyIlceId, ilceId);
    await prefs.setString(_keyIlceAdi, ilceAdi);
  }

  /// Daha önce indirilmiş namaz vakti listesini diskten okur.
  Future<List<DailyPrayerTimes>?> readCachedPrayerData() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyPrayerDataJson);
    if (raw == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) =>
              DailyPrayerTimes.fromEzanVaktiJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Bozuk/eski format önbellek varsa yok say.
      return null;
    }
  }

  Future<DateTime?> readLastFetchTime() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyLastFetchIso);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> savePrayerData(List<DailyPrayerTimes> data) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(data.map((e) => e.toCacheJson()).toList());
    await prefs.setString(_keyPrayerDataJson, encoded);
    await prefs.setString(_keyLastFetchIso, DateTime.now().toIso8601String());
  }
}
