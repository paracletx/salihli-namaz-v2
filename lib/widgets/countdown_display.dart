import 'package:flutter/material.dart';

import '../models/prayer_times.dart';
import '../utils/turkish_date_formatter.dart';

/// Ekranın görsel odağı: bir sonraki vakit ve o vakte kalan süre.
/// Buradaki geri sayım metni ekrandaki en büyük yazı olmalıdır.
class CountdownDisplay extends StatelessWidget {
  final PrayerName nextPrayerName;
  final Duration remaining;

  const CountdownDisplay({
    super.key,
    required this.nextPrayerName,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final countdownText = TurkishDateFormatter.formatCountdown(remaining);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SIRADAKİ VAKİT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          nextPrayerName.upperLabel,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Color(0xFFE8C077),
          ),
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            countdownText,
            style: const TextStyle(
              fontSize: 84,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
