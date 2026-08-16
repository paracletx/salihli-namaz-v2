# Salihli Namaz Vakitleri

Yalnızca **Salihli, Manisa, Türkiye** için namaz vakitlerini ve bir sonraki
vakte kalan süreyi gösteren sade, modern bir Flutter uygulaması.

## Özellikler

- Konum sabittir: GPS yok, şehir seçimi yok, hesap yok, ayarlar yok.
- Uygulama doğrudan namaz vakitleri ekranıyla açılır.
- Sabah, Güneş, Öğle, İkindi, Akşam, Yatsı vakitleri sabit sırayla listelenir.
- Bir sonraki vakte kalan süre, gerçek zamanlı ve büyük punto ile gösterilir.
- Veriler T.C. Diyanet İşleri Başkanlığı kaynaklıdır (bkz. "Veri Kaynağı").
- İnternet yoksa daha önce indirilmiş vakitlerle çalışmaya devam eder.
- Gece yarısı geçişi ve gün değişimi otomatik olarak yönetilir.

## Veri kaynağı

Diyanet İşleri Başkanlığı'nın doğrudan genel kullanıma açık bir REST API'si
bulunmadığından, Diyanet verilerini birebir dağıtan, yaygın kullanılan açık
kaynaklı **EzanVakti API**'si (`https://ezanvakti.emushaf.net`) kullanılır.
Uygulama; ülke → şehir → ilçe hiyerarşisinde "Türkiye → Manisa → Salihli"yi
isimle arayarak ilgili ilçe kodunu bulur ve bu kodu cihazda saklar; sonraki
açılışlarda doğrudan bu koddan vakitleri çeker. Kod, `lib/services/prayer_time_service.dart`
dosyasındadır.

## Proje yapısı

```
lib/
 ├── main.dart                       # Uygulama girişi
 ├── models/prayer_times.dart        # Namaz vakti veri modeli
 ├── services/
 │    ├── prayer_time_service.dart   # API'den veri çekme + konum çözümleme
 │    └── storage_service.dart       # Yerel önbellekleme (çevrimdışı destek)
 ├── screens/home_screen.dart        # Ana ekran, zamanlayıcı, durum yönetimi
 ├── widgets/
 │    ├── countdown_display.dart     # Büyük geri sayım (görsel odak)
 │    ├── prayer_time_list.dart      # 6 vakitlik liste
 │    └── status_view.dart           # Yükleniyor / hata görünümü
 └── utils/
      ├── prayer_time_calculator.dart   # Sıradaki vakit hesaplama
      └── turkish_date_formatter.dart   # Türkçe tarih ve geri sayım biçimi
```

## Çalıştırma

Ayrıntılı adımlar için sohbetteki yanıta bakın; özetle:

```bash
flutter pub get
flutter run
```

## APK oluşturma

```bash
flutter build apk --release
```

Çıktı: `build/app/outputs/flutter-apk/app-release.apk`
