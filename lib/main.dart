import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/controllers/theme_controller.dart';
import 'package:talkzy_beta1/controllers/chat_theme_controller.dart';
import 'package:talkzy_beta1/firebase_options.dart';
import 'package:talkzy_beta1/routes/app_pages.dart';
import 'package:talkzy_beta1/services/notification_service.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:talkzy_beta1/services/firestore_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialized successfully');
    
    // Initialize ThemeController first
    Get.put(ThemeController(), permanent: true);
    print('✅ ThemeController initialized');
    // Initialize ChatThemeController for chat theming
    Get.put(ChatThemeController(), permanent: true);
    print('✅ ChatThemeController initialized');
    
    // Initialize AuthController if not already initialized
    Get.put(AuthController(), permanent: true);
    print('✅ AuthController initialized');
    
    // 🔥 AUTOMATIC FIREBASE SETUP - Disabled for now
    // Collections will be created automatically when you register users
    // No need for manual setup - your code already handles this!
    print('💡 Collections will be created when you register users');
    
    // Initialize Notification Service
    try {
      final notificationService = Get.put(NotificationService(), permanent: true);
      // Initialize in background to avoid blocking app startup
      notificationService.initialize().catchError((e) {
        print('❌ Error initializing Notification Service: $e');
      });
      print('✅ Notification Service registered');
    } catch (e) {
      print('❌ Error registering Notification Service: $e');
    }
    
    runApp(const MyApp());
  } catch (e) {
    print('❌ Error during app initialization: $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  AppLifecycleState? _lastState;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
    _startHeartbeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastState = state;
    print('App Lifecycle State Changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        print('App Resumed - Updating online status');
        _setOnline(true);
        _startHeartbeat();
        break;

      case AppLifecycleState.inactive:
        print('App Inactive');
        break;

      case AppLifecycleState.paused:
        print('App Paused - Updating offline status');
        _stopHeartbeat();
        _setOnline(false);
        break;

      case AppLifecycleState.detached:
        print('App Detached');
        _stopHeartbeat();
        _setOnline(false);
        break;

      case AppLifecycleState.hidden:
        print('App Hidden');
        break;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        print('Heartbeat - Updating online status');
        _setOnline(true);
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _setOnline(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.updateUserOnlineStatus(uid, isOnline);
      print('Updated online status: $isOnline for user: $uid');
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  @override
  void dispose() {
    _stopHeartbeat();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: "Talkzy Chat",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        GetObserver(),
      ],
      enableLog: true,
      logWriterCallback: (text, {bool isError = false}) {
        if (isError) {
          print('GetX Error: $text');
        }
      },
      defaultTransition: Transition.native,
      transitionDuration: Duration(milliseconds: 300),
    ));
  }
}

class GetObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('GetX Navigation: Pushed ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('GetX Navigation: Popped ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('GetX Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }
}