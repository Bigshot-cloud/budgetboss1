import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/profile/pin_lock_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

import 'providers/transaction_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/security_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Ensure it exists in the project root.");
  }

  await _initFirebase();

  runApp(const BudgetBossApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    // Activate App Check without blocking the main thread
    FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    ).then((_) {
      debugPrint('App Check initialized successfully');
    }).catchError((e) {
      debugPrint('App Check initialization error: $e');
    });
    
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

class BudgetBossApp extends StatelessWidget {
  const BudgetBossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProxyProvider<AuthProvider, SecurityProvider>(
          create: (_) => SecurityProvider(),
          update: (_, authProvider, security) {
            if (authProvider.user != null) {
              security?.syncSettings(authProvider.user!.securitySettings);
            }
            return security!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, authProvider, tx) {
            tx?.setUser(authProvider.user?.id);
            return tx!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, authProvider, notify) {
            notify?.setUser(authProvider.user?.id);
            return notify!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, DebtProvider>(
          create: (_) => DebtProvider(),
          update: (_, authProvider, debt) {
            debt?.setUser(authProvider.user?.id);
            return debt!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, SavingsProvider>(
          create: (_) => SavingsProvider(),
          update: (_, authProvider, savings) {
            savings?.setUser(authProvider.user?.id);
            return savings!;
          },
        ),
      ],
      child: Consumer2<SecurityProvider, ThemeProvider>(
        builder: (context, security, theme, child) {
          return MaterialApp(
            title: 'BudgetBoss',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            home: StreamBuilder<auth.User?>(
              stream: auth.FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }
                if (snapshot.hasData) {
                  return const MainScreen();
                }
                return const LoginScreen();
              },
            ),
            builder: (context, child) {
              return Listener(
                onPointerDown: (_) => security.resetTimer(),
                child: Stack(
                  children: [
                    child!,
                    if (security.isLocked)
                      const Positioned.fill(
                        child: PinLockScreen(),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
