import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'services/live_chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ApiClient().init();
  } catch (e) {
    debugPrint("ApiClient init error: $e");
  }

  final settingsProvider = SettingsProvider();
  try {
    await settingsProvider.init();
  } catch (e) {
    debugPrint("SettingsProvider init error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => LiveChatService()..init()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const TranslaterApp(),
    ),
  );
}

class TranslaterApp extends StatelessWidget {
  const TranslaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    // Ultra Premium Indigo & Violet Theme with smooth typography
    const primaryColor = Color(0xFF6366F1); // Indigo
    const secondaryColor = Color(0xFF8B5CF6); // Purple
    const accentColor = Color(0xFF06B6D4); // Cyan

    return MaterialApp(
      title: 'LingoVerse',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: accentColor,
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF1F5F9),
        ),
        textTheme:
            GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: primaryColor.withValues(alpha: 0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: const Color(0xFF818CF8),
          secondary: const Color(0xFFA78BFA),
          tertiary: const Color(0xFF22D3EE),
          surface: const Color(0xFF1E293B),
          surfaceContainerHighest: const Color(0xFF334155),
        ),
        textTheme:
            GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0B0F19), // Deep rich dark
        cardTheme: CardThemeData(
          color: const Color(0xFF131C2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
