import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // i-init yung Firebase — kung placeholder pa yung config, show setup screen
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!DefaultFirebaseOptions.currentPlatform.projectId.contains('YOUR_')) {
      firebaseReady = true;
    }
  } catch (_) {
    firebaseReady = false;
  }

  runApp(TapArtApp(firebaseReady: firebaseReady));
}

class TapArtApp extends StatelessWidget {
  final bool firebaseReady;
  const TapArtApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapArt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE07B39)),
        textTheme: GoogleFonts.nunitoTextTheme(),
        useMaterial3: true,
      ),
      home: firebaseReady ? const _AuthWrapper() : const _SetupBanner(),
    );
  }
}

// listens sa Firebase auth state — auto-redirect pag nag-login o nag-logout
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // loading pa — show spinner muna
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = snapshot.data;
        if (user != null) {
          // may naka-login — kunin yung display name na ni-set niya sa registration
          // kung wala pa (baka lumang account), fallback sa email prefix
          final name = (user.displayName?.trim().isNotEmpty == true)
              ? user.displayName!.trim()
              : user.email?.split('@').first ?? 'Artist';

          return HomeScreen(userName: name);
        }

        // walang naka-login — go to welcome/login screen
        return const WelcomeScreen();
      },
    );
  }
}

// splash screen habang nag-lo-load yung auth state
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF0F5),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
      ),
    );
  }
}

// setup screen — lalabas kung hindi pa na-configure yung Firebase
class _SetupBanner extends StatelessWidget {
  const _SetupBanner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFF8E7), Color(0xFFE8F4FD)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  Text(
                    'Firebase Setup Required',
                    style: GoogleFonts.pacifico(
                      fontSize: 28,
                      color: const Color(0xFFFF6B9D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B9D).withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Run these commands in your project folder:',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF5C4033),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _CodeBlock('dart pub global activate flutterfire_cli'),
                        const SizedBox(height: 8),
                        _CodeBlock('flutterfire configure'),
                        const SizedBox(height: 16),
                        Text(
                          'Then enable Email/Password auth in your Firebase console.',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7B68EE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock(this.code);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(0xFF7EC8E3),
        ),
      ),
    );
  }
}
