import 'dart:async';

import 'package:flutter/material.dart';

import '../services/prayer_time_service.dart';
import '../utils/prayer_time_calculator.dart';
import '../utils/turkish_date_formatter.dart';
import '../widgets/countdown_display.dart';
import '../widgets/prayer_time_list.dart';
import '../widgets/status_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final PrayerTimeService _service = PrayerTimeService();

  PrayerDataResult? _data;
  String? _errorMessage;
  bool _loading = true;
  bool _cevrimdisi = false;

  Timer? _ticker;
  DateTime _now = DateTime.now();
  DateTime _loadedForDay = DateTime(0);
  DateTime? _lastAttemptAt;
  bool _reloadInProgress = false;

  static const Duration _hataSonrasiTekrarAraligi = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    // Geri sayımın telefon uykuya girse/arka plana düşse bile doğru
    // kalması için her saniyede bir mevcut sistem saatinden süreyi
    // yeniden hesaplıyoruz (biriktirerek azaltmıyoruz).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama tekrar ön plana geldiğinde saat/gün sıçraması olmuş
    // olabilir; bir sonraki tick zaten kontrol edecek ama burada da
    // anında tetikleyerek gecikmeyi önlüyoruz.
    if (state == AppLifecycleState.resumed) {
      _onTick();
    }
  }

  void _onTick() {
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);

    setState(() => _now = now);

    if (_loading || _reloadInProgress) return;

    final gunDegisti = bugun != _loadedForDay;
    final hataVarVeTekrarZamaniGeldi = _errorMessage != null &&
        (_lastAttemptAt == null ||
            now.difference(_lastAttemptAt!) >= _hataSonrasiTekrarAraligi);

    if (gunDegisti || hataVarVeTekrarZamaniGeldi) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    _reloadInProgress = true;
    _lastAttemptAt = DateTime.now();
    if (_data == null) {
      setState(() => _loading = true);
    }
    try {
      final result = await _service.loadPrayerData();
      final now = DateTime.now();
      if (!mounted) return;
      setState(() {
        _data = result;
        _cevrimdisi = result.cevrimdisi;
        _loading = false;
        _errorMessage = null;
        _loadedForDay = DateTime(now.year, now.month, now.day);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'Namaz vakitleri yüklenemedi.\nİnternet bağlantınızı kontrol edip tekrar deneyin.';
      });
    } finally {
      _reloadInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10192E), Color(0xFF070B14)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(
          child: StatusView(message: 'Namaz vakitleri yükleniyor...'),
        ),
      );
    }

    if (_errorMessage != null && _data == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: StatusView(
            message: _errorMessage!,
            isError: true,
            onRetry: _loadData,
          ),
        ),
      );
    }

    final data = _data!;
    final bugun = DateTime(_now.year, _now.month, _now.day);
    final yarin = bugun.add(const Duration(days: 1));

    final bugununVakitleri = data.findByDate(bugun);
    final yarininVakitleri = data.findByDate(yarin);

    if (bugununVakitleri == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: StatusView(
            message:
                'Bugüne ait namaz vakti verisi bulunamadı.\nGüncel veriler indiriliyor, lütfen bekleyin.',
            isError: true,
            onRetry: _loadData,
          ),
        ),
      );
    }

    final next = PrayerTimeCalculator.computeNext(
      today: bugununVakitleri,
      tomorrow: yarininVakitleri,
      now: _now,
    );

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildHeader(),
        const SizedBox(height: 6),
        Text(
          TurkishDateFormatter.formatLong(_now),
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_cevrimdisi) ...[
          const SizedBox(height: 10),
          const _OfflineBadge(),
        ],
        const SizedBox(height: 30),
        if (next != null)
          CountdownDisplay(
            nextPrayerName: next.name,
            remaining: next.remaining(_now),
          )
        else
          const StatusView(message: 'Yarının vakti hazırlanıyor...'),
        const SizedBox(height: 34),
        PrayerTimeList(
          gununVakitleri: bugununVakitleri,
          highlightedName:
              (next != null && next.belongsToToday) ? next.name : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'SALİHLİ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'MANİSA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 13, color: Colors.white.withValues(alpha: 0.55)),
          const SizedBox(width: 6),
          Text(
            'Çevrimdışı • önbellek verisi',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
