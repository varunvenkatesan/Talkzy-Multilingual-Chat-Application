import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final RxBool _isDarkMode = false.obs;
  
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }
  
  // Load theme preference from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _isDarkMode.value = isDark;
      print('🎨 Theme loaded: ${isDark ? "Dark" : "Light"}');
    } catch (e) {
      print('❌ Error loading theme: $e');
    }
  }
  
  // Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDark);
      print('💾 Theme saved: ${isDark ? "Dark" : "Light"}');
    } catch (e) {
      print('❌ Error saving theme: $e');
    }
  }
  
  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    await _saveThemeToPrefs(_isDarkMode.value);
    
    // Update GetX theme
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    
    print('🎨 Theme toggled to: ${_isDarkMode.value ? "Dark" : "Light"}');
  }
  
  // Set theme explicitly
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode.value != isDark) {
      _isDarkMode.value = isDark;
      await _saveThemeToPrefs(isDark);
      Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
      print('🎨 Theme set to: ${isDark ? "Dark" : "Light"}');
    }
  }
}
