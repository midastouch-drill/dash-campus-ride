
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/core/services/navigation_service.dart';
import 'package:campus_dash/core/services/notification_service.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';
import 'package:campus_dash/core/router/app_router.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set up FCM background message handling
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Set preferred device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const ProviderScope(child: CampusDashApp()));
}

class CampusDashApp extends ConsumerWidget {
  const CampusDashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(appRouterProvider);

    // Initialize notification service
    ref.read(notificationServiceProvider);
    
    return MaterialApp.router(
      title: 'Campus Dash',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      builder: (context, child) {
        final textScaleFactor = MediaQuery.of(context).textScaleFactor;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: textScaleFactor.clamp(0.85, 1.15),
          ),
          child: child!,
        );
      },
    );
  }
}
