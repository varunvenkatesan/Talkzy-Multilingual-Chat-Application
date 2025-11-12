import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    print('SplashView initState called');
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );

      _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      );

      _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );

      _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );

      // Start all animations together
      _controller.forward();

      // Navigate after delay
      Future.delayed(const Duration(milliseconds: 3500), _checkAuthAndNavigate);
    } catch (e) {
      print('Error in SplashView initState: $e');
      // If there's an error, still try to navigate
      Future.delayed(const Duration(milliseconds: 1000), _checkAuthAndNavigate);
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      print('Checking authentication status...');
      await Future.delayed(Duration(seconds: 2));

      final authController = Get.find<AuthController>() ?? Get.put(AuthController(), permanent: true);
      print('Auth controller found, isAuthenticated: ${authController.isAuthenticated}');
      
      if (authController.isAuthenticated) {
        print('User is authenticated, navigating to main screen');
        Get.offAllNamed(AppRoutes.main);
      } else {
        print('User is not authenticated, navigating to welcome screen');
        Get.offAllNamed(AppRoutes.welcome);
      }
    } catch (e, stackTrace) {
      print('Error in _checkAuthAndNavigate: $e');
      print('Stack trace: $stackTrace');
      // Navigate to welcome as fallback
      try {
        Get.offAllNamed(AppRoutes.welcome);
      } catch (navError) {
        print('Error navigating to welcome: $navError');
      }
    }
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      print('Error in SplashView dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      print('SplashView build called');
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF04F6D2),
                Color(0xFFE206B3),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/images/talkzy_SS_AN.png",
                      width: 140,
                      height: 140,
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Text(
                            "Talkzy",
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black45,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Breaking Language Barriers",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                              shadows: const [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black38,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),

                          ),
                             SizedBox(height: 10),
                              Text(
            "Chat • Translate • Connect",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.5,
            ),
          ),
                          const SizedBox(height: 30),

                          LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 40,
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
    } catch (e) {
      print('Error in SplashView build: $e');
      // Return a simple splash screen as fallback
      return Scaffold(
        backgroundColor: Colors.purple,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Talkzy",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      );
    }
  }
}


















