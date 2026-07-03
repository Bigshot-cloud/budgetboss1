import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/profile/pin_lock_screen.dart';

import 'providers/transaction_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/security_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  await _initFirebase();

  runApp(const BudgetBossApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    print('App Check initialized successfully');
  } catch (e) {
    debugPrint('Firebase/AppCheck initialization error: $e');
  }
}

class BudgetBossApp extends StatelessWidget {
  const BudgetBossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SecurityProvider>(
          create: (_) => SecurityProvider(),
          update: (_, auth, security) {
            if (auth.user != null) {
              security?.syncSettings(auth.user!.securitySettings);
            }
            return security!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, tx) {
            tx?.setUser(auth.user?.id);
            return tx!;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, notify) {
            notify?.setUser(auth.user?.id);
            return notify!;
          },
        ),
      ],
      child: Consumer<SecurityProvider>(
        builder: (context, security, child) {
          return MaterialApp(
            title: 'BudgetBoss',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const SplashScreen(),
            builder: (context, child) {
              return Stack(
                children: [
                  Listener(
                    onPointerDown: (_) => security.resetTimer(),
                    onPointerMove: (_) => security.resetTimer(),
                    child: child!,
                  ),
                  if (security.isLocked)
                    const PinLockScreen(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}