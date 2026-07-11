import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/analysis_provider.dart';
import 'services/backend_service.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/recording_guide/recording_guide_screen.dart';
import 'screens/recording/recording_screen.dart';
import 'screens/analysis/analysis_loading_screen.dart';
import 'screens/result/result_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Mode local pour le développement (debug)
  if (bool.hasEnvironment('USE_LOCAL_BACKEND')
      ? const bool.fromEnvironment('USE_LOCAL_BACKEND')
      : false) {
    BackendService.useLocal(true);
  }

  runApp(const VoxcordisApp());
}

class VoxcordisApp extends StatelessWidget {
  const VoxcordisApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instance partagée du BackendService (token partagé entre Auth et Analysis)
    final backendService = BackendService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(backend: backendService),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(backend: backendService),
        ),
      ],
      child: MaterialApp(
        title: 'Voxcordis',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR')],
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash:          (_) => const SplashScreen(),
          AppRoutes.login:           (_) => const LoginScreen(),
          AppRoutes.register:        (_) => const RegisterScreen(),
          AppRoutes.dashboard:       (_) => const DashboardScreen(),
          AppRoutes.recordingGuide:  (_) => const RecordingGuideScreen(),
          AppRoutes.recording:       (_) => const RecordingScreen(),
          AppRoutes.analysisLoading: (_) => const AnalysisLoadingScreen(),
          AppRoutes.result:          (_) => const ResultScreen(),
          AppRoutes.history:         (_) => const HistoryScreen(),
          AppRoutes.profile:         (_) => const ProfileScreen(),
        },
      ),
    );
  }
}