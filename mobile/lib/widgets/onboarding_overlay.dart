import 'package:flutter/material.dart';

class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingOverlay({super.key, required this.onDone});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String desc;
  const _OnboardingStep(this.icon, this.title, this.desc);
}

const _steps = [
  _OnboardingStep(Icons.text_fields_rounded, 'Translate Text',
      'Type or paste text and translate it to any language instantly.'),
  _OnboardingStep(Icons.mic_rounded, 'Voice Translation',
      'Speak naturally — we convert your speech to text and translate it.'),
  _OnboardingStep(Icons.camera_alt_rounded, 'Camera Translation',
      'Point your camera at text and get an instant translation.'),
  _OnboardingStep(Icons.description_rounded, 'Document Translation',
      'Upload a PDF, Word or text file for full document translation.'),
  _OnboardingStep(Icons.forum_rounded, 'Conversation Mode',
      'Chat back and forth across languages in real time.'),
];

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int _step = 0;

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final step = _steps[_step];

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: widget.onDone,
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(step.icon, size: 34, color: primary),
                ),
                const SizedBox(height: 18),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  step.desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _steps.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 5),
                          width: i == _step ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _step ? primary : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _step < _steps.length - 1 ? 'Next' : 'Get Started',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
