import 'package:flutter/material.dart';

/// Yükleniyor veya hata durumlarında ana ekranın ortasında gösterilen
/// sade bilgilendirme görünümü.
class StatusView extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const StatusView({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isError)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8C077)),
              ),
            )
          else
            Icon(
              Icons.wifi_off_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 40,
            ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          if (isError && onRetry != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE8C077),
              ),
              child: const Text('Tekrar dene'),
            ),
          ],
        ],
      ),
    );
  }
}
