import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/settings_provider.dart';
import '../tabs/text_tab.dart';
import '../tabs/voice_tab.dart';
import '../tabs/camera_tab.dart';
import '../tabs/document_tab.dart';
import '../tabs/conversation_tab.dart';
import '../tabs/history_tab.dart';
import '../tabs/settings_tab.dart';
import '../widgets/onboarding_overlay.dart';
import '../widgets/rating_prompt.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _translateSubIndex = 0;
  bool _showOnboarding = false;
  bool _onboardingChecked = false;
  bool _ratingPrompted = false;
  SettingsProvider? _settings;

  final List<Widget> _translateTabs = const [
    TextTab(),
    VoiceTab(),
    CameraTab(),
    DocumentTab(),
    ConversationTab(),
  ];

  final List<Widget> _sections = const [
    SizedBox.shrink(), // replaced in build (translate section)
    HistoryTab(onlyFavorites: false),
    HistoryTab(onlyFavorites: true),
    SettingsTab(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!identical(_settings, settings)) {
      _settings?.removeListener(_maybeShowRating);
      _settings = settings;
      settings.addListener(_maybeShowRating);

      if (!_onboardingChecked) {
        _onboardingChecked = true;
        if (!settings.onboardingDone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showOnboarding = true);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _settings?.removeListener(_maybeShowRating);
    super.dispose();
  }

  void _maybeShowRating() {
    final settings = _settings;
    if (settings == null || _ratingPrompted) return;
    if (settings.translateCount >= 3 && !settings.ratingShown) {
      _ratingPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showRatingPrompt(context);
        await settings.markRatingShown();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    final sections = List<Widget>.from(_sections);
    sections[0] = IndexedStack(
      index: _translateSubIndex,
      children: _translateTabs,
    );

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B0F19),
                      Color(0xFF111827),
                      Color(0xFF0F172A),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEEF2FF),
                      Color(0xFFF5F3FF),
                      Color(0xFFEDE9FE),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.translate,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentIndex == 0
                              ? 'LingoVerse AI'
                              : _currentIndex == 1
                                  ? 'History'
                                  : _currentIndex == 2
                                      ? 'Favorites'
                                      : 'Settings',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        Text(
                          _currentIndex == 0
                              ? 'Smart AI Translation'
                              : 'Saved translations',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: _currentIndex == 0
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(56),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2540)
                              : const Color(0xFFDDD6FE).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _buildSubTabItem(
                                0, Icons.text_fields_rounded, 'Text'),
                            _buildSubTabItem(1, Icons.mic_rounded, 'Voice'),
                            _buildSubTabItem(
                                2, Icons.camera_alt_rounded, 'Cam'),
                            _buildSubTabItem(
                                3, Icons.description_rounded, 'Doc'),
                            _buildSubTabItem(4, Icons.forum_rounded, 'Chat'),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            body: Column(
              children: [
                if (!isOnline) _offlineBanner(theme),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: sections,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _bottomNav(isDark),
          ),
        ),
        if (_showOnboarding)
          OnboardingOverlay(
            onDone: () {
              setState(() => _showOnboarding = false);
              _settings?.markOnboardingDone();
            },
          ),
      ],
    );
  }

  Widget _offlineBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB45309),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You are offline. Some features may not work.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B0F19).withValues(alpha: 0.95)
            : const Color(0xFFEEF2FF).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDDD6FE),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.translate_rounded, 'Translate'),
              _buildNavItem(1, Icons.history_rounded, 'History'),
              _buildNavItem(2, Icons.favorite_rounded, 'Favorites'),
              _buildNavItem(3, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : Colors.grey,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabItem(int index, IconData icon, String label) {
    final isSelected = _translateSubIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _translateSubIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
