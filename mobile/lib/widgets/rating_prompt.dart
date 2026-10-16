import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a "rate the app" bottom sheet. Returns the selected rating (0 if
/// dismissed) so the caller can persist that the prompt was shown.
Future<void> showRatingPrompt(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RatingSheet(),
  );
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet();

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  bool _submitted = false;

  Future<void> _rate(int value) async {
    setState(() {
      _rating = value;
      _submitted = true;
    });

    if (value >= 4) {
      final uri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.tabiqchohan.translater');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _submitted
        ? (_rating >= 4
            ? 'Thank you! Opening Google Play...'
            : 'Thanks for your feedback. We will improve!')
        : 'Tap a star to rate';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Enjoying LingoVerse?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final n = i + 1;
              return IconButton(
                onPressed: _submitted ? null : () => _rate(n),
                icon: Icon(
                  n <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 36,
                  color: n <= _rating
                      ? const Color(0xFFF59E0B)
                      : Colors.grey.shade400,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
