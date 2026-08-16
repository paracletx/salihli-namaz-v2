import 'package:flutter/material.dart';

import '../models/prayer_times.dart';

/// Sabah, Güneş, Öğle, İkindi, Akşam, Yatsı vakitlerini sabit sırayla
/// listeler. Sıradaki vakit diğerlerinden hafifçe daha belirgin gösterilir.
class PrayerTimeList extends StatelessWidget {
  final DailyPrayerTimes gununVakitleri;
  final PrayerName? highlightedName;

  const PrayerTimeList({
    super.key,
    required this.gununVakitleri,
    required this.highlightedName,
  });

  @override
  Widget build(BuildContext context) {
    final entries = gununVakitleri.orderedEntries;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            _PrayerRow(
              entry: entries[i],
              isNext: entries[i].name == highlightedName,
            ),
            if (i != entries.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
                color: Colors.white.withValues(alpha: 0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final PrayerTimeEntry entry;
  final bool isNext;

  const _PrayerRow({required this.entry, required this.isNext});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8C077);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isNext ? accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          if (isNext)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              entry.name.label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                color: isNext ? accent : Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Text(
            entry.time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
              color: isNext ? accent : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
